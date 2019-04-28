#ifndef COHORT_EXP_H
#define COHORT_EXP_H

#include <iostream>
#include <algorithm>
#include <fstream>
#include <functional>
#include <sys/stat.h>
#include <utility>

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
    #include "../gp/Mutators.h"
    #include "./organism.h"
#include "./Selection.h"

constexpr size_t TAG_WIDTH = 16;
constexpr size_t MEM_SIZE = TAG_WIDTH;

class Experiment{
public:
    //Handy aliases
    using org_t = Organism<TAG_WIDTH>;
    using org_gen_t = Organism<TAG_WIDTH>::genome_t;
    
    using world_t = emp::World<org_t>;
    
    using hardware_t = typename TagLGP::TagLinearGP_TW<TAG_WIDTH>;
    using inst_lib_t = typename TagLGP::InstLib<hardware_t>;
    using inst_t = typename hardware_t::inst_t; 

    enum TreatmentType{
        REDUCED_LEXICASE = 0,
        COHORT_LEXICASE, 
        DOWNSAMPLED_LEXICASE
    };
    struct ProgramStats{
        // Generic stuff
        std::function<size_t(void)> get_id;
        std::function<double(void)> get_fitness;

        // Fitness evaluation stats
        std::function<double(void)> get_fitness_eval__total_score;
        std::function<size_t(void)> get_fitness_eval__num_passes;           
        std::function<size_t(void)> get_fitness_eval__num_fails;
        std::function<size_t(void)> get_fitness_eval__num_tests;
        std::function<std::string(void)> get_fitness_eval__passes_by_test;

        // Actual stats (auto-pass has no effect)
        std::function<size_t(void)> get_fitness_eval__num_actual_passes;
        std::function<size_t(void)> get_fitness_eval__num_actual_fails;
        std::function<std::string(void)> get_fitness_eval__actual_passes_by_test;
        
        // program validation stats
        std::function<size_t(void)> get_validation_eval__num_passes;
        std::function<size_t(void)> get_validation_eval__num_tests;
        std::function<std::string(void)> get_validation_eval__passes_by_test;
        
        std::function<double(void)> get_prog_behavioral_diversity;
        std::function<double(void)> get_prog_unique_behavioral_phenotypes;
    
        // program 'morphology' stats
        std::function<size_t(void)> get_program_len;
        std::function<std::string(void)> get_program;
    } program_stats;
    struct TestResult{
        bool passed;
        bool submitted;
        TestResult(bool p, bool s) : passed(p), submitted(s) { ; }
        TestResult() : passed(false), submitted(false) { ; }
    };
protected:
    emp::Ptr<emp::Random> randPtr;
    void CopyConfig(const ExperimentConfig& config);
    void InitializePopulation();
    void SetupHardware(); 
    void SetupEvaluation(); 
    void SetupSelection(); 
    void SetupMutation(); 
    void SetupDataCollection(); 
    void SetupDataCollectionFunctions(); 
    void Step();
    void Evaluate();
    void Select();
    void UpdateRecords();
    void SavePopSnapshot();
    void Update();
    bool TestValidation(org_t& org);
    void RunAllValidations(org_t& org);
    void AddDefaultInstructions(const std::unordered_set<std::string> & includes);

    // To be defined per problem
    virtual void SetupProblem() = 0;
    // Make some tests non-discrimnatory
    virtual void SetupDilution() = 0;
    // Initialize the problem and test case. 
    virtual void SetupSingleTest(org_t& org, size_t test_id) = 0;
    // Run the given program on the specified test case 
    virtual void RunSingleTest(org_t& org, size_t test_id, size_t local_test_id) = 0;
    // Initialize the problem and validation case. 
    virtual void SetupSingleValidation(org_t& org, size_t test_id) = 0;
    // Run the given program on the specified validation case 
    virtual TestResult RunSingleValidation(org_t& org, size_t test_id) = 0;

    // Bookkeeping variables
    bool setup_done = false;
    size_t cur_gen;
    size_t num_training_cases;
    size_t num_test_cases;
    size_t cur_update;
    
    // Cohort Lexicase variables
    size_t num_cohorts;
    emp::vector<size_t> program_ids;
    emp::vector<size_t> test_case_ids;
    
    //Hardware variables
    emp::Ptr<inst_lib_t> inst_lib;
    emp::Ptr<hardware_t> hardware;
    emp::BitSet<TAG_WIDTH> call_tag;   
    TagLGPMutator<TAG_WIDTH> mutator;
 
    //Evolution variables
    emp::Ptr<world_t> world;
    TreatmentType treatment_type;
    emp::vector<std::function<double(org_t&)>> lexicase_fit_funcs;
    size_t max_passes;
    
    //Stats and tracking
    size_t smallest_solution_size;
    bool solution_found;
    size_t update_first_solution_found;
    size_t current_best_prog_id;
    double current_best_score;
    size_t actual_current_best_prog_id;
    double actual_current_best_score;
    size_t stats_focus_org_id;
    emp::vector<TestResult> validation_results;
    size_t validation_passes;
    size_t validation_fails;
    size_t validation_submissions;
    emp::Ptr<emp::DataFile> solution_file;
    emp::Ptr<emp::DataFile> phen_diversity_file;

    // Configurable parameters read in from .cfg file
    // General
    int SEED;
    size_t TREATMENT;
    size_t POP_SIZE;
    size_t GENERATIONS;
    double DILUTION_PCT;
    // Program
    size_t MIN_PROG_SIZE;
    size_t MAX_PROG_SIZE;
    size_t PROG_EVAL_TIME;
    double MUT_PER_BIT_FLIP;
    double MUT_PER_INST_SUB;
    double MUT_PER_INST_INS;
    double MUT_PER_INST_DEL;
    double MUT_PER_PROG_SLIP;
    double MUT_PER_MOD_DUP;
    double MUT_PER_MOD_DEL;
    // Hardware
    double MIN_TAG_SPECIFICITY;
    size_t MAX_CALL_DEPTH;
    // Problem
    size_t PROBLEM_ID;
    std::string TRAINING_SET_FILENAME;
    std::string TEST_SET_FILENAME;
    // Cohort Lexicase
    size_t PROG_COHORT_SIZE;    
    size_t TEST_COHORT_SIZE;   
    size_t COHORT_MAX_FUNCS;
    // Standard Lexicase
    size_t LEXICASE_MAX_FUNCS;
    size_t NUM_TESTS;
    // Downsampled Lexicase
    size_t DOWNSAMPLED_MAX_FUNCS;
    size_t DOWNSAMPLED_NUM_TESTS;
    // Data Collection 
    std::string OUTPUT_DIR;
    size_t SNAPSHOT_INTERVAL;
    size_t SUMMARY_STATS_INTERVAL;
    size_t SOLUTION_SCREEN_INTERVAL;

public: 
    Experiment();
    virtual ~Experiment();
    void Setup(const ExperimentConfig& config);
    void Run();
};

Experiment::Experiment(): setup_done(false), cur_update(0), solution_found(false){

}

//TODO: Delete phylo ptr after implementing phylo tracking
Experiment::~Experiment(){
    std::cout << "Cleaning up experiment..." << std::endl;
    if(setup_done){
        solution_file.Delete();
        hardware.Delete();
        inst_lib.Delete();
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

    // Update record keeping vars
    smallest_solution_size = MAX_PROG_SIZE + 1;
    solution_found = false;
    update_first_solution_found = GENERATIONS + 1;
    current_best_prog_id = 0;
    actual_current_best_prog_id = 0;


    // Setup the different pieces of the experiment
    SetupHardware();
    
    SetupProblem(); // This is pure virtual, so to change this we have to 
                    //      change/create a derived class
    
    SetupDilution(); // Handled by the derived class

    if(NUM_TESTS == 0){
        NUM_TESTS = num_training_cases;
    }

    SetupEvaluation();
   
    SetupSelection();    

    SetupMutation();

    SetupDataCollection();

    //TODO: Add smallest pressure
    world->SetFitFun([this](org_t& org){
        double fitness = (double)org.GetNumPasses();
        return fitness;
    });
 
    InitializePopulation();
    world->SetAutoMutate();
    setup_done = true;
}
    
void Experiment::CopyConfig(const ExperimentConfig& config){
    // General 
    SEED = config.SEED(); 
    TREATMENT = config.TREATMENT(); 
    POP_SIZE = config.POP_SIZE(); 
    GENERATIONS = config.GENERATIONS(); 
    DILUTION_PCT = config.DILUTION_PCT();
    // Program
    MIN_PROG_SIZE = config.MIN_PROG_SIZE();
    MAX_PROG_SIZE = config.MAX_PROG_SIZE();
    PROG_EVAL_TIME = config.PROG_EVAL_TIME();
    MUT_PER_BIT_FLIP = config.MUT_PER_BIT_FLIP();
    MUT_PER_INST_SUB = config.MUT_PER_INST_SUB();
    MUT_PER_INST_INS = config.MUT_PER_INST_INS();
    MUT_PER_INST_DEL = config.MUT_PER_INST_DEL();
    MUT_PER_PROG_SLIP = config.MUT_PER_PROG_SLIP();
    MUT_PER_MOD_DUP = config.MUT_PER_MOD_DUP();
    MUT_PER_MOD_DEL = config.MUT_PER_MOD_DEL();
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
    // Standard Lexicase
    LEXICASE_MAX_FUNCS = config.LEXICASE_MAX_FUNCS();
    NUM_TESTS = config.NUM_TESTS();
    // Downsampled Lexicase
    DOWNSAMPLED_MAX_FUNCS = config.DOWNSAMPLED_MAX_FUNCS();
    DOWNSAMPLED_NUM_TESTS = config.DOWNSAMPLED_NUM_TESTS();
    // Data Collection
    OUTPUT_DIR = config.OUTPUT_DIR();
    SNAPSHOT_INTERVAL = config.SNAPSHOT_INTERVAL();
    SUMMARY_STATS_INTERVAL = config.SUMMARY_STATS_INTERVAL();
    SOLUTION_SCREEN_INTERVAL = config.SOLUTION_SCREEN_INTERVAL();
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
            std::cout << "Setting up REDUCED Lexicase evaluation" << std::endl;
            // Create id arrays to randomize training cases (only one time)
            program_ids.resize(POP_SIZE);
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                program_ids[prog_id] = prog_id;
            }
            test_case_ids.resize(num_training_cases);
            for(size_t test_id = 0; test_id < num_training_cases; ++test_id){
                test_case_ids[test_id] = test_id;
            }
            // Shuffle ONCE to simulate taking a random subset at the beginning
            emp::Shuffle(*randPtr, program_ids);
            emp::Shuffle(*randPtr, test_case_ids);
            // To be a potential solution, a program must solve the given number of training cases
            max_passes = NUM_TESTS;
            break;
        }
        case COHORT_LEXICASE: {
            std::cout << "Setting up COHORT Lexicase evaluation" << std::endl;
            // Verify the parameters make sense
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
            // Calculate the number of cohorts for both programs and test, they should match
            num_cohorts = POP_SIZE / PROG_COHORT_SIZE;
            std::cout << "Number of cohorts: " << num_cohorts << std::endl;
            if(num_training_cases / TEST_COHORT_SIZE != num_cohorts){ 
                std::cout << "Number of program cohorts must be equal to the number"
                    " of test cohorts" << std::endl;
                exit(-1); 
            }
            // Create id lists to use as cohorts
            program_ids.resize(POP_SIZE);
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                program_ids[prog_id] = prog_id;
            }
            test_case_ids.resize(num_training_cases);
            for(size_t test_id = 0; test_id < num_training_cases; ++test_id){
                test_case_ids[test_id] = test_id;
            }
            // For a program to be a potential solution, it must solve all tests in its cohort
            max_passes = TEST_COHORT_SIZE;
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            std::cout << "Setting up DOWNSAMPLED Lexicase evaluation" << std::endl;
            //Create id arrays that will be shuffled per update to give us random execution ordering
            program_ids.resize(POP_SIZE);
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                program_ids[prog_id] = prog_id;
            }
            test_case_ids.resize(num_training_cases);
            for(size_t test_id = 0; test_id < num_training_cases; ++test_id){
                test_case_ids[test_id] = test_id;
            }
            // Program is potentially done when it solves all the tests of the current update
            max_passes = DOWNSAMPLED_NUM_TESTS;
            break;
        }
        default: {
            std::cout << "Error in evaluation setup: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

//TODO: Add selection pressure for smaller program size? (For each treatment)
void Experiment::SetupSelection(){
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            std::cout << "Setting up REDUCED Lexicase selection" << std::endl;
            for(size_t local_test_id = 0; local_test_id < NUM_TESTS; ++local_test_id){
                lexicase_fit_funcs.push_back(
                    [local_test_id](org_t& org){
                        return org.GetLocalScore(local_test_id);
                    }
                );        
            }
            break;
        }
        case COHORT_LEXICASE: {
            std::cout << "Setting up COHORT Lexicase selection" << std::endl;
            // Handle one cohort at a time
            for(size_t local_test_id = 0; local_test_id < TEST_COHORT_SIZE; ++local_test_id){
                lexicase_fit_funcs.push_back(
                    [local_test_id](org_t& org){
                        return org.GetLocalScore(local_test_id);
                    }
                );        
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            std::cout << "Setting up DOWNSAMPLED Lexicase selection" << std::endl;
            for(size_t local_test_id = 0; local_test_id < DOWNSAMPLED_NUM_TESTS; ++local_test_id){
                lexicase_fit_funcs.push_back(
                    [local_test_id](org_t& org){
                        return org.GetLocalScore(local_test_id);
                    }
                );        
            }
            break;
        }
        default: {
            std::cout << "Error in selection setup: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

void Experiment::SetupMutation(){
    // Configure the mutator for the program's genomes
    mutator.MAX_PROGRAM_LEN = MAX_PROG_SIZE;
    mutator.MIN_PROGRAM_LEN = MIN_PROG_SIZE;
    mutator.PER_BIT_FLIP = MUT_PER_BIT_FLIP;
    mutator.PER_INST_SUB = MUT_PER_INST_SUB;
    mutator.PER_INST_INS = MUT_PER_INST_INS;
    mutator.PER_INST_DEL = MUT_PER_INST_DEL;
    mutator.PER_PROG_SLIP = MUT_PER_PROG_SLIP;
    mutator.PER_MOD_DUP = MUT_PER_MOD_DUP;
    mutator.PER_MOD_DEL = MUT_PER_MOD_DEL;
    // Assign the world to use the mutator
    world->SetMutFun([this](org_t& org, emp::Random& rnd){
        return mutator.Mutate(rnd, org.GetGenome());
    });
}

void Experiment::SetupDataCollection(){
    //Create dir (Does this actually work?)
    mkdir(OUTPUT_DIR.c_str(), ACCESSPERMS);
    if(OUTPUT_DIR.back() != '/')
        OUTPUT_DIR += '/';
    SetupDataCollectionFunctions();
        
    // Define helper functions
    std::function<size_t(void)> get_update = [this]() { return world->GetUpdate(); };
    std::function<double(void)> get_evaluations = [this]() {
        if(treatment_type == REDUCED_LEXICASE)
           return (double)(world->GetUpdate() * POP_SIZE * NUM_TESTS); 
        else if(treatment_type == COHORT_LEXICASE)
            return (double)(world->GetUpdate() * PROG_COHORT_SIZE * TEST_COHORT_SIZE * num_cohorts); 
        else if(treatment_type == DOWNSAMPLED_LEXICASE)
            return (double)(world->GetUpdate() * POP_SIZE * DOWNSAMPLED_NUM_TESTS);
        else
            return 0.0;
    };
    // Create solution file
    solution_file = emp::NewPtr<emp::DataFile>(OUTPUT_DIR + "/solutions.csv");
    solution_file->AddFun(get_update, "update");
    solution_file->AddFun(get_evaluations, "evaluations");
    solution_file->AddFun(program_stats.get_id, "program_id");
    solution_file->AddFun(program_stats.get_program_len, "program_len");
    solution_file->AddFun(program_stats.get_program, "program");
    solution_file->PrintHeaderKeys();
    // Setup generic fitness tracking
    world->SetupFitnessFile(OUTPUT_DIR + "/fitness.csv").SetTimingRepeat(1);
}

void Experiment::SetupDataCollectionFunctions(){
    // Setup program stats functions.

    // Training
    program_stats.get_id = [this]() { 
        return stats_focus_org_id; 
    };
  
    program_stats.get_fitness = [this]() { 
        return world->CalcFitnessID(stats_focus_org_id); 
    };
     
    program_stats.get_fitness_eval__total_score = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetNumPasses(); 
    };
  
    program_stats.get_fitness_eval__num_passes = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetNumPasses(); 
    };

    program_stats.get_fitness_eval__num_fails = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetNumFails(); 
    };

    program_stats.get_fitness_eval__num_tests = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetLocalSize(); 
    };

    program_stats.get_fitness_eval__passes_by_test = [this]() { 
        org_t & org = world->GetOrg(stats_focus_org_id);
        std::string scores = "\"[";
        for (size_t test_id = 0; test_id < max_passes; ++test_id) {
            if (test_id) 
                scores += ",";
            scores += emp::to_string(org.GetRawLocalScore(test_id));
        }
        scores += "]\"";
        return scores;
    };
    
    program_stats.get_fitness_eval__num_actual_passes = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetNumActualPasses(); 
    };

    program_stats.get_fitness_eval__num_actual_fails = [this]() { 
        return world->GetOrg(stats_focus_org_id).GetNumActualFails(); 
    };

    program_stats.get_fitness_eval__actual_passes_by_test = [this]() { 
        org_t & org = world->GetOrg(stats_focus_org_id);
        std::string scores = "\"[";
        for (size_t test_id = 0; test_id < max_passes; ++test_id) {
            if (test_id) 
                scores += ",";
            scores += emp::to_string(org.GetActualLocalScore(test_id));
        }
        scores += "]\"";
        return scores;
    };

    // Validation
    program_stats.get_validation_eval__num_passes = [this]() {
        return validation_passes;
    };

    program_stats.get_validation_eval__num_tests = [this]() {
        return num_test_cases;
    };

    program_stats.get_validation_eval__passes_by_test = [this]() {
        std::string scores = "\"[";
        for (size_t test_id = 0; test_id < num_test_cases; ++test_id) {
            if (test_id) 
                scores += ",";
            scores += emp::to_string((size_t)validation_results[test_id].passed);
        }
        scores += "]\"";
        return scores; 
    };

    // Misc.
    program_stats.get_program_len = [this]() {
        return world->GetOrg(stats_focus_org_id).GetGenome().GetSize();
    };

    program_stats.get_program = [this]() {
        std::ostringstream stream;
        world->GetOrg(stats_focus_org_id).GetGenome().PrintCSVEntry(stream);
        return stream.str();
    }; 
}

void Experiment::InitializePopulation(){
    for(size_t i = 0; i < POP_SIZE; ++i)
        world->Inject(TagLGP::GenRandTagGPProgram(*randPtr, inst_lib, MIN_PROG_SIZE, 
            MAX_PROG_SIZE), 1);      
}

void Experiment::Run(){
    if(!setup_done){
        std::cout << "Error! You must call Setup() before calling run on your experiment!" 
            << std::endl;
        exit(-1);
    }
    for(cur_update = 0; cur_update <= GENERATIONS; ++cur_update){
        Step();
    }    
    std::cout << "Experiment finished!" << std::endl;
}

void Experiment::Step(){
    Evaluate();
    Select();
    Update();
}

void Experiment::Evaluate(){
    //Remember to reset hardware and load each program
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            // Do NOT shuffle - order must be static for test cases
            // Shouldn't matter for programs
            
            // Handle one program at a time
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                org_t & cur_prog = world->GetOrg(prog_id);
                cur_prog.Reset(num_training_cases, NUM_TESTS);
                // Test against first NUM_TESTS test cases
                for(size_t test_id = 0; test_id < NUM_TESTS; ++test_id){
                    // Do test
                    SetupSingleTest(cur_prog, test_case_ids[test_id]);
                    RunSingleTest(cur_prog, test_case_ids[test_id], test_id); 
                } 
            }
            break;
        }
        case COHORT_LEXICASE: {
            // Shuffle order for both cohorts
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
                        RunSingleTest(cur_prog, test_case_ids[test_id], test_id_off); 
                    } 
                }
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            // Shuffle order of test cases so we get fresh ones each update
            emp::Shuffle(*randPtr, test_case_ids);
            // Handle one program at a time
            for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
                org_t & cur_prog = world->GetOrg(prog_id);
                cur_prog.Reset(num_training_cases, DOWNSAMPLED_NUM_TESTS);
                // Test against first NUM_TESTS test cases
                for(size_t test_id = 0; test_id < DOWNSAMPLED_NUM_TESTS; ++test_id){
                    // Do test
                    SetupSingleTest(cur_prog, test_case_ids[test_id]);
                    RunSingleTest(cur_prog, test_case_ids[test_id], test_id); 
                } 
            }
            break;
        }
        default: {
            std::cout << "Error in evaluation: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

//TODO: Figure out the crazy assembler error
void Experiment::Select(){
    switch(treatment_type){
        case REDUCED_LEXICASE: {
            emp::LexicaseSelectWORKAROUND(*world,
                                lexicase_fit_funcs, 
                                POP_SIZE,
                                LEXICASE_MAX_FUNCS);
            break;
        }
        case COHORT_LEXICASE: {
            for(size_t cohort_id = 0; cohort_id < num_cohorts; ++cohort_id){
                emp::vector<size_t> cur_cohort(
                        program_ids.begin() + (cohort_id * PROG_COHORT_SIZE),
                        program_ids.begin() + ((cohort_id + 1) * PROG_COHORT_SIZE)
                );
                emp::CohortLexicaseSelect(*world,
                                                lexicase_fit_funcs,
                                                cur_cohort,
                                                PROG_COHORT_SIZE,
                                                COHORT_MAX_FUNCS);
                /*
                emp::CohortLexicaseSelect_NAIVE(*world,
                                                lexicase_fit_funcs,
                                                cur_cohort,
                                                PROG_COHORT_SIZE,
                                                COHORT_MAX_FUNCS);
                */
            }
            break;
        }
        case DOWNSAMPLED_LEXICASE: {
            emp::LexicaseSelectWORKAROUND(*world,
                                lexicase_fit_funcs, 
                                POP_SIZE,
                                DOWNSAMPLED_MAX_FUNCS);
            break;
        }
        default: {
            std::cout << "Error in selection: Invalid treament type!" << std::endl;
            exit(-1);
        };
    }
}

//TODO: Add phylo record keeping
void Experiment::UpdateRecords(){
    current_best_score = 0.0;
    actual_current_best_score = 0.0;
    for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
        emp_assert(world->IsOccupied(prog_id));
        org_t& cur_org = world->GetOrg(prog_id);
        const size_t pass_total = cur_org.GetNumPasses();
        if(pass_total > current_best_score){
            current_best_score = (double)pass_total;
            current_best_prog_id = prog_id;
        }
        // "Actual" counts give the true values, ignoring the auto-pass flag
        //      i.e., even tests with the auto-pass flag are computed normally
        const size_t actual_pass_total = cur_org.GetNumActualPasses();
        if(actual_pass_total > actual_current_best_score){
            actual_current_best_score = (double)actual_pass_total;
            actual_current_best_prog_id = prog_id;
        }
        // Test potential solutions
        if(actual_pass_total == max_passes
                && cur_org.GetGenome().GetSize() < smallest_solution_size){
            stats_focus_org_id = prog_id;
            RunAllValidations(cur_org);
            if(validation_passes == num_test_cases){
                std::cout << "Dominant solution found!" << std::endl;
                if(!solution_found){
                    update_first_solution_found = cur_update;
                }
                solution_found = true;
                smallest_solution_size = cur_org.GetGenome().GetSize();
                solution_file->Update();
            }
        } 
    }
    if(cur_update % SNAPSHOT_INTERVAL == 0 || update_first_solution_found == cur_update || 
            cur_update >= GENERATIONS){
        SavePopSnapshot();
    } 
}

void Experiment::SavePopSnapshot(){
    std::string snapshot_dir = OUTPUT_DIR + "pop_" + emp::to_string((int)world->GetUpdate());
    mkdir(snapshot_dir.c_str(), ACCESSPERMS);
    std::cout << "Saving snapshot at " << snapshot_dir << std::endl;

    emp::DataFile file(snapshot_dir + "/program_pop_" 
            + emp::to_string((int)world->GetUpdate()) + ".csv");

    // Add functions to data file.
    file.AddFun(program_stats.get_id, "program_id", "Program ID");

    file.AddFun(program_stats.get_fitness, "fitness");
    file.AddFun(program_stats.get_fitness_eval__total_score, "total_score__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__num_passes, "num_passes__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__num_fails, "num_fails__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__num_tests, "num_tests__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__passes_by_test, "passes_by_test__fitness_eval");
    
    file.AddFun(program_stats.get_fitness_eval__num_actual_passes, "num_actual_passes__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__num_actual_fails, "num_actual_fails__fitness_eval");
    file.AddFun(program_stats.get_fitness_eval__actual_passes_by_test, "actual_passes_by_test__fitness_eval");

    file.AddFun(program_stats.get_validation_eval__num_passes, "num_passes__validation_eval");
    file.AddFun(program_stats.get_validation_eval__num_tests, "num_tests__validation_eval");
    file.AddFun(program_stats.get_validation_eval__passes_by_test, "passes_by_test__validation_eval");

    file.AddFun(program_stats.get_program_len, "program_len");
    file.AddFun(program_stats.get_program, "program");

    file.PrintHeaderKeys();

    // For each program in the population, dump the program and anything we want to know about it.
    for (stats_focus_org_id = 0; stats_focus_org_id < world->GetSize(); ++stats_focus_org_id) {
        if (!world->IsOccupied(stats_focus_org_id)) continue;
            //Do Validation check 
            RunAllValidations(world->GetOrg(stats_focus_org_id));
        // Update snapshot file
        file.Update();
    }
   //TODO: Hook up phylogeny metrics 
    /*
    // Take diversity snapshot
    prog_phen_diversity_file->Update();
    // Snapshot phylogeny
    prog_genotypic_systematics->Snapshot(snapshot_dir + 
            "/program_phylogeny_" + emp::to_string((int)prog_world->GetUpdate()) + ".csv");
    */
}

void Experiment::Update(){
    UpdateRecords();
    std::cout << "Update: " << cur_update << "; ";
    std::cout << "Best Score: " << current_best_score << "; ";
    std::cout << "Best Actual Score: " << actual_current_best_score << "; ";
    std::cout << "Solution Found?: " << solution_found << "; ";
    std::cout << std::endl;
    world->Update();
    world->ClearCache();
}

bool Experiment::TestValidation(org_t& org){
    for(size_t test_id = 0; test_id < num_test_cases; ++test_id){
        SetupSingleValidation(org, test_id);
        if(!RunSingleValidation(org, test_id).passed){
            return false;
        }
    }
    return true;
}

void Experiment::RunAllValidations(org_t& org){
    validation_results.resize(num_test_cases, TestResult());
    validation_passes = 0;  
    validation_fails = 0;  
    validation_submissions = 0;  
    for(size_t test_id = 0; test_id < num_test_cases; ++test_id){
        SetupSingleValidation(org, test_id);
        validation_results[test_id] = RunSingleValidation(org, test_id);
        if(validation_results[test_id].passed)
            ++validation_passes;
        else
            ++validation_fails;
        if(validation_results[test_id].submitted)
            ++validation_submissions;
    }
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
