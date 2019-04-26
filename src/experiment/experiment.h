#ifndef COHORT_EXP_H
#define COHORT_EXP_H

#include <iostream>
#include <algorithm>

// Empirical includes
#include "base/Ptr.h"
#include "base/vector.h"
#include "base/assert.h"
#include "tools/Random.h"
#include "tools/random_utils.h"
#include "tools/BitSet.h"
#include "Evolve/World.h"
#include "Evolve/World_select.h"

//Local includes
#include "../gp/TagLinearGP.h"
#include "../gp/TagLinearGP_InstLib.h"
#include "../gp/TagLinearGP_Utilities.h"
#include "./Selection.h"
#include "./organism.h"

constexpr size_t TAG_WIDTH = 16;
constexpr size_t MEM_SIZE = TAG_WIDTH;

class Experiment{
public:
    using org_t = Organism<TAG_WIDTH>;
    
    using world_t = emp::World<org_t>;
    
    using hardware_t = typename TagLGP::TagLinearGP_TW<TAG_WIDTH>;
    using inst_lib_t = typename TagLGP::InstLib<hardware_t>;
    using inst_t = typename hardware_t::inst_t; 

    enum TreatmentType{
        REDUCED_LEXICASE = 0,
        COHORT_LEXICASE, 
        DOWNSAMPLED_LEXICASE
    };

protected:
    emp::Ptr<emp::Random> randPtr;
    void CopyConfig(const ExperimentConfig& config);
    void InitializePopulation();
    void SetupHardware(); 
    void SetupEvaluation(); 
    void SetupSelection(); 
    void Step();
    void Evaluate();
    void Selection();
    void Update();
    void AddDefaultInstructions(const std::unordered_set<std::string> & includes);

    // To be defined per problem
    virtual void SetupProblem() = 0;
    // Initialize the problem and test case. 
    virtual void SetupSingleTest(org_t& org, size_t test_id) = 0;
    // Run the given program on the specified test case 
    virtual void RunSingleTest(org_t& org, size_t test_id) = 0;

    // Bookkeeping variables
    bool setup_done = false;
    size_t cur_gen;
    size_t num_training_cases;
    size_t num_test_cases;
    
    // Cohort Lexicase variables
    size_t num_cohorts;
    emp::vector<size_t> program_ids;
    emp::vector<size_t> test_case_ids;
    
    //Hardware variables
    emp::Ptr<inst_lib_t> inst_lib;
    emp::Ptr<hardware_t> hardware;
    emp::BitSet<TAG_WIDTH> call_tag;   
 
    //Evolution variables
    emp::Ptr<world_t> world;
    TreatmentType treatment_type;
    emp::vector<std::function<double(org_t&)>> lexicase_fit_funcs;

    // Configurable parameters read in from .cfg file
    // General
    int SEED;
    size_t TREATMENT;
    size_t POP_SIZE;
    size_t GENERATIONS;
    // Program
    size_t MIN_PROG_SIZE;
    size_t MAX_PROG_SIZE;
    size_t PROG_EVAL_TIME;
    // Hardware
    double MIN_TAG_SPECIFICITY;
    size_t MAX_CALL_DEPTH;
    // Problem
    size_t PROBLEM_ID;
    std::string TRAINING_SET_FILENAME;
    std::string TEST_SET_FILENAME;
    //Cohort Lexicase
    size_t PROG_COHORT_SIZE;    
    size_t TEST_COHORT_SIZE;   
    size_t COHORT_MAX_FUNCS; 

public: 
    Experiment();
    virtual ~Experiment();
    void Setup(const ExperimentConfig& config);
    void Run();
};

Experiment::Experiment(){

}

Experiment::~Experiment(){
    std::cout << "Cleaning up experiment..." << std::endl;
    if(setup_done){
        world.Delete();
        randPtr.Delete();
    }
}

void Experiment::Setup(const ExperimentConfig& config){
    if(setup_done){
        std::cout << "Error! You can only setup the experiment one time!" << std::endl;
        exit(-1);
    }
    CopyConfig(config);
    randPtr = emp::NewPtr<emp::Random>(SEED);
    emp_assert(0 <= TREATMENT && TREATMENT <= 2, "Invalid treatment type."
        "Treatement type must be in the range [0,3]");
    treatment_type = (TreatmentType)TREATMENT;
    world = emp::NewPtr<world_t>(*randPtr);
    world->SetPopStruct_Mixed(true);
    //Setup the different pieces of the experiment
    SetupHardware();
    SetupProblem(); // This is pure virtual, so to change this we have to 
                    //      change/create a derived class
    SetupEvaluation();
   
    SetupSelection();    
 
    InitializePopulation();
    world->SetAutoMutate(true);
    setup_done = true;
}
    
void Experiment::SetupHardware(){
    // Create new instruction library.
    inst_lib = emp::NewPtr<inst_lib_t>();
    // Create evaluation hardware.
    hardware = emp::NewPtr<hardware_t>(inst_lib, randPtr);
    // Configure the CPU.
    hardware->SetMemSize(MEM_SIZE);                      // Configure size of memory.
    hardware->SetMinTagSpecificity(MIN_TAG_SPECIFICITY); // Configure minimum tag specificity
                                                                // required for tag-based referencing
    hardware->SetMaxCallDepth(MAX_CALL_DEPTH);          // Configure maximum depth of call 
                                                                // stack (recursion limit).
    hardware->SetMemTags(GenHadamardMatrix<TAG_WIDTH>());// Configure memory location tags. 
                                                                // Use Hadamard matrix for 
                                                                // given TAG_WIDTH.
    // Configure call tag (tag used to call initial module during test evaluation).
    call_tag.Clear(); // Set initial call tag to all 0s.

}

void Experiment::SetupEvaluation(){
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            break;
        }
        case COHORT_LEXICASE: {
            if(POP_SIZE % PROG_COHORT_SIZE != 0){
                std::cout << "Program population size must be evenly divisible by"
                    " the cohort size!" << std::endl;
                exit(-1);
            }
            if(num_training_cases % TEST_COHORT_SIZE != 0){
                std::cout <<  "Number of training cases must be evenly divisible by"
                    " the cohort size!" << std::endl;
                exit(-1);
            }
            num_cohorts = POP_SIZE / PROG_COHORT_SIZE;
            std::cout << "Number of cohorts: " << num_cohorts << std::endl;
            if(num_training_cases / TEST_COHORT_SIZE != num_cohorts){ 
                std::cout << "Number of program cohorts must be equal to the number"
                    " of test cohorts" << std::endl;
                exit(-1); 
            }
            program_ids.resize(POP_SIZE);
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                program_ids[prog_id] = prog_id;
            }
            test_case_ids.resize(num_training_cases);
            for(size_t test_id = 0; test_id < num_training_cases; ++test_id){
                test_case_ids[test_id] = test_id;
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            break;
        }
        default: {
            std::cout << "Error in evaluation setup: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

//TODO: Add selection pressure for smaller program size?
void Experiment::SetupSelection(){
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            break;
        }
        case COHORT_LEXICASE: {
            // Handle one cohort at a time
            for(size_t cohort_id = 0; cohort_id < num_cohorts; ++cohort_id){
                for(size_t local_test_id = 0; local_test_id < TEST_COHORT_SIZE; ++local_test_id){
                    lexicase_fit_funcs.push_back(
                        [local_test_id](org_t& org){
                            return org.GetLocalScore(local_test_id);
                        }
                    );        
                }
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            break;
        }
        default: {
            std::cout << "Error in selection setup: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

void Experiment::Run(){
    if(!setup_done){
        std::cout << "Error! You must call Setup() before calling run on your experiment!" 
            << std::endl;
        exit(-1);
    }
    for(size_t cur_gen = 0; cur_gen < GENERATIONS; ++cur_gen){
        std::cout << "Gen " << cur_gen << std::endl;
        Step();
    }    
    std::cout << "Experiment finished!" << std::endl;
}

void Experiment::Step(){
    Evaluate();
    Selection();
    Update();
}

void Experiment::CopyConfig(const ExperimentConfig& config){
    // General 
    SEED = config.SEED(); 
    TREATMENT = config.TREATMENT(); 
    POP_SIZE = config.POP_SIZE(); 
    GENERATIONS = config.GENERATIONS(); 
    // Program
    MIN_PROG_SIZE = config.MIN_PROG_SIZE();
    MAX_PROG_SIZE = config.MAX_PROG_SIZE();
    PROG_EVAL_TIME = config.PROG_EVAL_TIME();
    // Hardware
    MIN_TAG_SPECIFICITY = config.MIN_TAG_SPECIFICITY();
    MAX_CALL_DEPTH = config.MAX_CALL_DEPTH();
    // Problem
    PROBLEM_ID = config.PROBLEM_ID();
    TRAINING_SET_FILENAME = config.TRAINING_SET_FILENAME();
    TEST_SET_FILENAME = config.TEST_SET_FILENAME();
    // Cohort Lexicase
    PROG_COHORT_SIZE = config.PROG_COHORT_SIZE();
    TEST_COHORT_SIZE = config.TEST_COHORT_SIZE();
    COHORT_MAX_FUNCS = config.COHORT_MAX_FUNCS();
}

void Experiment::InitializePopulation(){
    for(size_t i = 0; i < POP_SIZE; ++i)
        world->Inject(TagLGP::GenRandTagGPProgram(*randPtr, inst_lib, MIN_PROG_SIZE, 
            MAX_PROG_SIZE), 1);      
}

//TODO: Keep tabs of best solutions thus far
//TODO: Hook up other treatments
void Experiment::Evaluate(){
    //Remember to reset hardware and load each program
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            break;
        }
        case COHORT_LEXICASE: {
            emp::Shuffle(*randPtr, program_ids);
            emp::Shuffle(*randPtr, test_case_ids);
            // Handle one cohort at a time
            for(size_t cohort_id = 0; cohort_id < num_cohorts; ++cohort_id){
                // Handle one program at a time
                for(size_t prog_id_off = 0; prog_id_off < PROG_COHORT_SIZE; ++prog_id_off){
                    size_t prog_id = cohort_id * PROG_COHORT_SIZE + prog_id_off; 
                    org_t & cur_prog = world->GetOrg(program_ids[prog_id]);
                    cur_prog.Reset(num_training_cases, TEST_COHORT_SIZE);
                    // Test against all test cases in the current cohort
                    for(size_t test_id_off = 0; test_id_off < TEST_COHORT_SIZE; ++test_id_off){
                        size_t test_id = cohort_id * TEST_COHORT_SIZE + test_id_off; 
                        // Do test
                        SetupSingleTest(cur_prog, test_case_ids[test_id]);
                        RunSingleTest(cur_prog, test_case_ids[test_id]); 
                    } 
                }
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            break;
        }
        default: {
            std::cout << "Error in evaluation: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

void Experiment::Selection(){
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            break;
        }
        case COHORT_LEXICASE: {
            for(size_t cohort_id = 0; cohort_id < num_cohorts; ++cohort_id){
                emp::vector<size_t> cur_cohort(
                        program_ids.begin() + (cohort_id * PROG_COHORT_SIZE),
                        program_ids.begin() + ((cohort_id + 1) * PROG_COHORT_SIZE)
                );
                emp::CohortLexicaseSelect_NAIVE(*world,
                                                lexicase_fit_funcs,
                                                cur_cohort,
                                                PROG_COHORT_SIZE,
                                                COHORT_MAX_FUNCS
                );
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            break;
        }
        default: {
            std::cout << "Error in selection: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

void Experiment::Update(){
}

//TODO: Format this
void Experiment::AddDefaultInstructions(const std::unordered_set<std::string> & 
    includes={"Add","Sub","Mult","Div","Mod", "TestNumEqu","TestNumNEqu","TestNumLess",
        "TestNumLessTEqu","TestNumGreater","TestNumGreaterTEqu","Floor","Not","Inc","Dec",
        "CopyMem","SwapMem","Input","Output","CommitGlobal","PullGlobal","TestMemEqu","TestMemNEqu",
        "MakeVector","VecGet","VecSet","VecLen","VecAppend","VecPop","VecRemove","VecReplaceAll",
        "VecIndexOf","VecOccurrencesOf","VecReverse","VecSwapIfLess","VecGetFront","VecGetBack",
        "StrLength","StrConcat","IsNum","IsStr","IsVec","If","IfNot","While","Countdown","Foreach",
        "Close","Break","Call","Routine","Return","ModuleDef"}) 
{
    // Configure instructions
    // Math
    if (emp::Has(includes, "Add")) inst_lib->AddInst("Add", hardware_t::Inst_Add, 3, "wmemANY[C] = wmemNUM[A] + wmemNUM[B]");
    if (emp::Has(includes, "Sub")) inst_lib->AddInst("Sub", hardware_t::Inst_Sub, 3, "wmemANY[C] = wmemNUM[A] - wmemNUM[B]");
    if (emp::Has(includes, "Mult")) inst_lib->AddInst("Mult", hardware_t::Inst_Mult, 3, "wmemANY[C] = wmemNUM[A] * wmemNUM[B]");
    if (emp::Has(includes, "Div")) inst_lib->AddInst("Div", hardware_t::Inst_Div, 3, "if (wmemNUM[B] != 0) wmemANY[C] = wmemNUM[A] / wmemNUM[B]; else NOP");
    if (emp::Has(includes, "Mod")) inst_lib->AddInst("Mod", hardware_t::Inst_Mod, 3, "if (wmemNUM[B] != 0) wmemANY[C] = int(wmemNUM[A]) % int(wmemNUM[B]); else NOP");
    if (emp::Has(includes, "TestNumEqu")) inst_lib->AddInst("TestNumEqu", hardware_t::Inst_TestNumEqu, 3, "wmemANY[C] = wmemNUM[A] == wmemNUM[B]");
    if (emp::Has(includes, "TestNumNEqu")) inst_lib->AddInst("TestNumNEqu", hardware_t::Inst_TestNumNEqu, 3, "wmemANY[C] = wmemNUM[A] != wmemNUM[B]");
    if (emp::Has(includes, "TestNumLess")) inst_lib->AddInst("TestNumLess", hardware_t::Inst_TestNumLess, 3, "wmemANY[C] = wmemNUM[A] < wmemNUM[B]");
    if (emp::Has(includes, "TestNumLessTEqu")) inst_lib->AddInst("TestNumLessTEqu", hardware_t::Inst_TestNumLessTEqu, 3, "wmemANY[C] = wmemNUM[A] <= wmemNUM[B]");
    if (emp::Has(includes, "TestNumGreater")) inst_lib->AddInst("TestNumGreater", hardware_t::Inst_TestNumGreater, 3, "wmemANY[C] = wmemNUM[A] > wmemNUM[B]");
    if (emp::Has(includes, "TestNumGreaterTEqu")) inst_lib->AddInst("TestNumGreaterTEqu", hardware_t::Inst_TestNumGreaterTEqu, 3, "wmemANY[C] = wmemNUM[A] >= wmemNUM[B]");
    if (emp::Has(includes, "Floor")) inst_lib->AddInst("Floor", hardware_t::Inst_Floor, 1, "wmemNUM[A] = floor(wmemNUM[A])");
    if (emp::Has(includes, "Not")) inst_lib->AddInst("Not", hardware_t::Inst_Not, 1, "wmemNUM[A] = !wmemNUM[A]"); 
    if (emp::Has(includes, "Inc")) inst_lib->AddInst("Inc", hardware_t::Inst_Inc, 1, "wmemNUM[A] = wmemNUM[A] + 1");
    if (emp::Has(includes, "Dec")) inst_lib->AddInst("Dec", hardware_t::Inst_Dec, 1, "wmemNUM[A] = wmemNUM[A] - 1");

    // Memory manipulation
    if (emp::Has(includes, "CopyMem")) inst_lib->AddInst("CopyMem", hardware_t::Inst_CopyMem, 2, "wmemANY[B] = wmemANY[A] // Copy mem[A] to mem[B]");
    if (emp::Has(includes, "SwapMem")) inst_lib->AddInst("SwapMem", hardware_t::Inst_SwapMem, 2, "swap(wmemANY[A], wmemANY[B])");
    if (emp::Has(includes, "Input")) inst_lib->AddInst("Input", hardware_t::Inst_Input, 2, "wmemANY[B] = imemANY[A]");
    if (emp::Has(includes, "Output")) inst_lib->AddInst("Output", hardware_t::Inst_Output, 2, "omemANY[B] = wmemANY[A]");
    if (emp::Has(includes, "CommitGlobal")) inst_lib->AddInst("CommitGlobal", hardware_t::Inst_CommitGlobal, 2, "gmemANY[B] = wmemANY[A]");
    if (emp::Has(includes, "PullGlobal")) inst_lib->AddInst("PullGlobal", hardware_t::Inst_PullGlobal, 2, "wmemANY[B] = gmemANY[A]");
    if (emp::Has(includes, "TestMemEqu")) inst_lib->AddInst("TestMemEqu", hardware_t::Inst_TestMemEqu, 3, "wmemANY[C] = wmemANY[A] == wmemANY[B]");
    if (emp::Has(includes, "TestMemNEqu")) inst_lib->AddInst("TestMemNEqu", hardware_t::Inst_TestMemNEqu, 3, "wmemANY[C] = wmemANY[A] != wmemANY[B]");

    // Vector-related instructions
    if (emp::Has(includes, "MakeVector")) inst_lib->AddInst("MakeVector", hardware_t::Inst_MakeVector, 3, "wmemANY[C]=Vector([wmemANY[min(A,B),max(A,B)])");  // TODO - more descriptions
    if (emp::Has(includes, "VecGet")) inst_lib->AddInst("VecGet", hardware_t::Inst_VecGet, 3, "wmemANY[C]=wmemVEC[A][wmemNUM[B]]");
    if (emp::Has(includes, "VecSet")) inst_lib->AddInst("VecSet", hardware_t::Inst_VecSet, 3, "wmemVEC[A][wmemNUM[B]]=wmemNUM/STR[C]");
    if (emp::Has(includes, "VecLen")) inst_lib->AddInst("VecLen", hardware_t::Inst_VecLen, 2, "wmemANY[B]=wmemVEC[A]");
    if (emp::Has(includes, "VecAppend")) inst_lib->AddInst("VecAppend", hardware_t::Inst_VecAppend, 2, "wmemVEC[A].Append(wmemNUM/STR[B])");
    if (emp::Has(includes, "VecPop")) inst_lib->AddInst("VecPop", hardware_t::Inst_VecPop, 2, "wmemANY[B]=wmemVEC[A].pop()");
    if (emp::Has(includes, "VecRemove")) inst_lib->AddInst("VecRemove", hardware_t::Inst_VecRemove, 2, "wmemVEC[A].Remove(wmemNUM[B])");
    if (emp::Has(includes, "VecReplaceAll")) inst_lib->AddInst("VecReplaceAll", hardware_t::Inst_VecReplaceAll, 3, "Replace all values (wmemNUM/STR[B]) in wmemVEC[A] with wmemNUM/STR[C]");
    if (emp::Has(includes, "VecIndexOf")) inst_lib->AddInst("VecIndexOf", hardware_t::Inst_VecIndexOf, 3, "wmemANY[C] = index of wmemNUM/STR[B] in wmemVEC[A]");
    if (emp::Has(includes, "VecOccurrencesOf")) inst_lib->AddInst("VecOccurrencesOf", hardware_t::Inst_VecOccurrencesOf, 3, "wmemANY[C]= occurrances of wmemNUM/STR[B] in wmemVEC[A]");
    if (emp::Has(includes, "VecReverse")) inst_lib->AddInst("VecReverse", hardware_t::Inst_VecReverse, 1, "wmemVEC[A] = Reverse(wmemVEC[A])");
    if (emp::Has(includes, "VecSwapIfLess")) inst_lib->AddInst("VecSwapIfLess", hardware_t::Inst_VecSwapIfLess, 3, "Swap two indices in wmemVEC[A] if vec[wmemNUM[A]] < vec[wmemNUM[B]].");
    if (emp::Has(includes, "VecGetFront")) inst_lib->AddInst("VecGetFront", hardware_t::Inst_VecGetFront, 2, "wmemANY[B] = front of wmemVEC[A]");
    if (emp::Has(includes, "VecGetBack")) inst_lib->AddInst("VecGetBack", hardware_t::Inst_VecGetBack, 2, "wmemANY[B] = back of wmemVEC[A]");

    // String
    if (emp::Has(includes, "StrLength")) inst_lib->AddInst("StrLength", hardware_t::Inst_StrLength, 2, "todo");
    if (emp::Has(includes, "StrConcat")) inst_lib->AddInst("StrConcat", hardware_t::Inst_StrConcat, 3, "todo");

    // Memory-type
    if (emp::Has(includes, "IsNum")) inst_lib->AddInst("IsNum", hardware_t::Inst_IsNum, 2, "wmemANY[B] = IsNum(wmemANY[A])");
    if (emp::Has(includes, "IsStr")) inst_lib->AddInst("IsStr", hardware_t::Inst_IsStr, 2, "wmemANY[B] = IsStr(wmemANY[A])");
    if (emp::Has(includes, "IsVec")) inst_lib->AddInst("IsVec", hardware_t::Inst_IsVec, 2, "wmemANY[B] = IsVec(wmemANY[A])");

    // Flow control
    if (emp::Has(includes, "If")) inst_lib->AddInst("If", hardware_t::Inst_If, 1, "Execute next flow if(wmemANY[A]) // To be true, mem loc must be non-zero number", {inst_lib_t::InstProperty::BEGIN_FLOW});
    if (emp::Has(includes, "IfNot")) inst_lib->AddInst("IfNot", hardware_t::Inst_IfNot, 1, "Execute next flow if(!wmemANY[A])", {inst_lib_t::InstProperty::BEGIN_FLOW});
    if (emp::Has(includes, "While")) inst_lib->AddInst("While", hardware_t::Inst_While, 1, "While loop over wmemANY[A]", {inst_lib_t::InstProperty::BEGIN_FLOW});
    if (emp::Has(includes, "Countdown")) inst_lib->AddInst("Countdown", hardware_t::Inst_Countdown, 1, "Countdown loop with wmemANY as index.", {inst_lib_t::InstProperty::BEGIN_FLOW});
    if (emp::Has(includes, "Foreach")) inst_lib->AddInst("Foreach", hardware_t::Inst_Foreach, 2, "For each thing in wmemVEC[B]", {inst_lib_t::InstProperty::BEGIN_FLOW});
    if (emp::Has(includes, "Close")) inst_lib->AddInst("Close", hardware_t::Inst_Close, 0, "Close flow", {inst_lib_t::InstProperty::END_FLOW});
    if (emp::Has(includes, "Break")) inst_lib->AddInst("Break", hardware_t::Inst_Break, 0, "Break current flow");
    if (emp::Has(includes, "Call")) inst_lib->AddInst("Call", hardware_t::Inst_Call, 1, "Call module using A for tag-based reference");
    if (emp::Has(includes, "Routine")) inst_lib->AddInst("Routine", hardware_t::Inst_Routine, 1, "Call module as a routine (don't use call stack)");
    if (emp::Has(includes, "Return")) inst_lib->AddInst("Return", hardware_t::Inst_Return, 0, "Return from current routine/call");

    // Module
    if (emp::Has(includes, "ModuleDef")) inst_lib->AddInst("ModuleDef", hardware_t::Inst_Nop, 1, "Define module with tag A", {inst_lib_t::InstProperty::MODULE});

    // Misc
    // inst_lib->AddInst("Nop", hardware_t::Inst_Nop, 3, "Do nothing");
}

#endif
