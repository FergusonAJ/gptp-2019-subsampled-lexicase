#ifndef COHORT_EXP_MEDIAN_H
#define COHORT_EXP_MEDIAN_H

#include <iostream>
#include <array>
#include <utility>
#include <algorithm>
#include <cmath>

// Empricial includes
#include "./base/assert.h"

// Local includes
#include "./experiment.h"
#include "./TestCaseSet.h"
#include "Selection.h"

class Experiment_Median : public Experiment{
    public:
        // Readability aliases
        using this_t = Experiment_Median;
        using input_t = std::pair<std::array<int, 3>, bool>; // bool is for auto-pass
        using output_t = int;                                   // (used for "watering down" cases)
        using test_case_set_t = TestCaseSet<input_t, output_t>;

    protected:
        // Implementations of abstract methods from base class
        void SetupProblem();
        void SetupDilution();
        void SetupProblemDataCollectionFunctions();
        void SetupSingleTest(org_t& org, size_t test_id);
        void SetupSingleValidation(org_t& org, size_t test_id);
        void RunSingleTest(org_t& org, size_t test_id, size_t local_test_id);
        TestResult RunSingleValidation(size_t org_id, org_t& org, size_t test_id);
        void ResetValidation();   
        hardware_t::Program GetKnownSolution();
 
        static std::pair<input_t, output_t> LoadTestCaseFromLine
                (const emp::vector<std::string>& line);
        static output_t GenCorrectOutput(input_t &input);

        void SetupInstructions();
        void SetupSingle(org_t& org, const input_t& input);
        bool RunSingle();       
     
        // Custom virtual hardware instructions
        void Inst_LoadNum1(hardware_t & hw, const inst_t & inst);
        void Inst_LoadNum2(hardware_t & hw, const inst_t & inst);
        void Inst_LoadNum3(hardware_t & hw, const inst_t & inst);
        void Inst_SubmitNum(hardware_t & hw, const inst_t & inst);
        
        std::string filename;
        test_case_set_t training_set;
        test_case_set_t test_set;
        size_t num_discriminatory_tests;
        bool problems_loaded;
    
        // Variables for a specific run
        size_t cur_test_id;
        output_t submitted_val;
        bool submitted;
        input_t cur_input;
        output_t cur_output;
        
        // Validation Outputs for diversity tracking
        emp::vector<emp::vector<output_t>> validation_outputs;
        
    public:
        Experiment_Median();
        ~Experiment_Median();
};

Experiment_Median::Experiment_Median():
    training_set(this_t::LoadTestCaseFromLine),
    test_set(this_t::LoadTestCaseFromLine),
    problems_loaded(false){
}

Experiment_Median::~Experiment_Median(){

}


void Experiment_Median::SetupProblem(){
    std::cout << "Setting up problem: \"median\"" << std::endl;
    std::cout << "Loading training set from " << TRAINING_SET_FILENAME << std::endl;
    training_set.LoadTestCasesWithCSVReader(TRAINING_SET_FILENAME);
    std::cout << "Found " << training_set.GetSize() << " test cases in training set." << std::endl;
    std::cout << "Loading validation set from " << TEST_SET_FILENAME << std::endl;
    test_set.LoadTestCasesWithCSVReader(TEST_SET_FILENAME);
    std::cout << "Found " << test_set.GetSize() << " test cases in validation set." << std::endl;
    test_set.Append(training_set);
    std::cout << "Appended training cases to test set " << std::endl;
    std::cout << "Now " << test_set.GetSize() << " test cases in validation set." << std::endl;
    num_training_cases = training_set.GetSize();
    num_test_cases = test_set.GetSize();
    SetupInstructions();
    problems_loaded = true;
}

// Sets up a run for a given program for the specifed input
void Experiment_Median::SetupSingle(org_t& org, const input_t& input){
    // Reset virtual hardware (global memory and callstack)
    // This is from Alex and Jose's work (Alex created the virtual hardware system)
    hardware->Reset();
    hardware->SetProgram(org.GetGenome());
    hardware->CallModule(call_tag, MIN_TAG_SPECIFICITY, true, false); 
    emp_assert(hardware->GetMemSize() >= 3, "Median requires a memory size of at least 3");
    submitted = false;
    submitted_val = 0;
    // Configure inputs.
    if (hardware->GetCallStackSize()) {
        hardware_t::CallState & state = hardware->GetCurCallState();
        hardware_t::Memory & wmem = state.GetWorkingMem();
        // Set hardware input.
        wmem.Set(0, input.first[0]);
        wmem.Set(1, input.first[1]);
        wmem.Set(2, input.first[2]);
    }
    else{
        std::cout << "Error in DoSingleTest, GetCallStackSize() returned 0." << std::endl;
        exit(-1);
    }
}

void Experiment_Median::SetupDilution(){
    if(!problems_loaded){
        std::cout << "Cannot dilute problems that have not been loaded. Terminating." << std::endl;
        exit(-1);
    }
    num_discriminatory_tests = (size_t)ceil(training_set.GetSize() * (1.0 - DILUTION_PCT));
    std::cout << "Number of discriminatory tests: " << num_discriminatory_tests << std::endl;
    if(num_discriminatory_tests == 0){
        std::cout << "Dilution percentage cannot be too close to 100%!" << std::endl;
        exit(-1);
    }
    for(size_t test_id = num_discriminatory_tests; test_id < training_set.GetSize(); ++test_id){
        training_set.GetInput(test_id).second = true; 
    }
}

void Experiment_Median::SetupProblemDataCollectionFunctions(){
    program_stats.get_prog_behavioral_diversity = [this]() { 
        return emp::ShannonEntropy(validation_outputs); 
    };
    program_stats.get_prog_unique_behavioral_phenotypes = [this]() { 
        return emp::UniqueCount(validation_outputs); 
    };
}

void Experiment_Median::SetupSingleTest(org_t& org, size_t test_id){
    input_t & input = training_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = training_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_Median::SetupSingleValidation(org_t& org, size_t test_id){
    input_t & input = test_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = test_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_Median::RunSingleTest(org_t& org, size_t test_id, size_t local_test_id){
    // Check for auto-pass cases
    if(training_set.GetInput(test_id).second){
        // Record the auto pass, still compute "actual" passes
        org.Record(test_id, true, false, 1.0, local_test_id);
        
        for(size_t eval_time = 0; eval_time < PROG_EVAL_TIME; ++eval_time){
            hardware->SingleProcess();
            if(hardware->GetCallStackSize() == 0) 
                break;
        }
        if(submitted){
            bool is_correct = submitted_val == training_set.GetOutput(test_id);
            org.RecordActual(is_correct, true, (double)is_correct, local_test_id);
        }
        else{
            org.RecordActual(false, false, 0.0,  local_test_id);
        }
    }
    else{
        for(size_t eval_time = 0; eval_time < PROG_EVAL_TIME; ++eval_time){
            hardware->SingleProcess();
            if(hardware->GetCallStackSize() == 0) 
                break;
        }
        if(submitted){
            bool is_correct = submitted_val == training_set.GetOutput(test_id);
            org.Record(test_id, is_correct, true, (double)is_correct, local_test_id);
            org.RecordActual(is_correct, true, (double)is_correct, local_test_id);
        }
        else{
            org.Record(test_id, false, false, 0.0, local_test_id);
            org.RecordActual(false, false, 0.0, local_test_id);
        }
    }
}

Experiment::TestResult Experiment_Median::RunSingleValidation(size_t org_id, org_t& org, 
    size_t test_id){
    // Check for auto-pass cases
    if(test_set.GetInput(test_id).second){
        std::cout << "Error! We should not have a validation case that is auto-pass!" << std::endl;
        exit(-1);
        return TestResult(true, false, 1.0);
    }
    else{
        for(size_t eval_time = 0; eval_time < PROG_EVAL_TIME; ++eval_time){
            hardware->SingleProcess();
            if(hardware->GetCallStackSize() == 0) 
                break;
        }
        if(submitted){
            validation_outputs[org_id][test_id] = submitted_val;
            bool is_correct = submitted_val == test_set.GetOutput(test_id);
            return TestResult(is_correct, true, (double)is_correct);
        }
        else{
            return TestResult(false, false, 0.0);
        }
    }
}

void Experiment_Median::ResetValidation(){
    validation_outputs.resize(POP_SIZE);
    for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
        validation_outputs[prog_id].resize(num_test_cases);
    }
}  

Experiment::hardware_t::Program Experiment_Median::GetKnownSolution(){
    emp::vector<emp::BitSet<TAG_WIDTH>> matrix = GenHadamardMatrix<TAG_WIDTH>();
    hardware_t::Program sol(inst_lib);
    
    sol.PushInst("MakeVector",    {matrix[0], matrix[2], matrix[4]});
    sol.PushInst("LoadNum1",      {matrix[5], matrix[0], matrix[0]});
    sol.PushInst("LoadNum1",      {matrix[6], matrix[0], matrix[0]});
    sol.PushInst("Foreach",       {matrix[0], matrix[4], matrix[0]});
    sol.PushInst(  "TestNumLess", {matrix[0], matrix[5], matrix[1]});
    sol.PushInst(  "If",          {matrix[1], matrix[0], matrix[0]});
    sol.PushInst(    "CopyMem",   {matrix[0], matrix[5], matrix[0]});
    sol.PushInst(  "Close",       {matrix[0], matrix[0], matrix[0]});
    sol.PushInst(  "TestNumLess", {matrix[6], matrix[0], matrix[1]});
    sol.PushInst(  "If",          {matrix[1], matrix[0], matrix[0]});
    sol.PushInst(    "CopyMem",   {matrix[0], matrix[6], matrix[0]});
    sol.PushInst(  "Close",       {matrix[0], matrix[0], matrix[0]});
    sol.PushInst(  "Add",         {matrix[0], matrix[7], matrix[7]});
    sol.PushInst("Close",         {matrix[0], matrix[0], matrix[0]});
    sol.PushInst("Sub",           {matrix[7], matrix[5], matrix[7]});
    sol.PushInst("Sub",           {matrix[7], matrix[6], matrix[7]});
    sol.PushInst("SubmitNum",     {matrix[7], matrix[0], matrix[0]});    

    return sol;
}
 
std::pair<Experiment_Median::input_t, Experiment_Median::output_t> 
            Experiment_Median::LoadTestCaseFromLine(const emp::vector<std::string> & line) {
    input_t input;   
    output_t output; 
    // Load input.
    input.first[0] = std::atof(line[0].c_str());
    input.first[1] = std::atof(line[1].c_str());
    input.first[2] = std::atof(line[2].c_str());
    input.second = false;
    // Load output.
    output = std::atof(line[3].c_str());
    emp_assert(output == GenCorrectOutput(input));
    return {input, output};
}

Experiment_Median::output_t Experiment_Median::GenCorrectOutput(input_t &input){
    int sum = input.first[0] + input.first[1] + input.first[2];
    sum -=  *std::min_element(input.first.begin(), input.first.end());
    sum -=  *std::max_element(input.first.begin(), input.first.end());
    return sum;
}

void Experiment_Median::SetupInstructions(){
    // Add default instructions to instruction set.
    AddDefaultInstructions({"Add",
                          "Sub",
                          "Mult",
                          "Div",
                          "Mod",
                          "TestNumEqu",
                          "TestNumNEqu",
                          "TestNumLess",
                          "TestNumLessTEqu",
                          "TestNumGreater",
                          "TestNumGreaterTEqu",
                          "Floor",
                          "Not",
                          "Inc",
                          "Dec",
                          "CopyMem",
                          "SwapMem",
                          "Input",
                          "Output",
                          "CommitGlobal",
                          "PullGlobal",
                          "TestMemEqu",
                          "TestMemNEqu",
                          "If",
                          "IfNot",
                          "While",
                          "Countdown",
                          "Foreach",
                          "Close",
                          "Break",
                          "Call",
                          "Routine",
                          "Return",
                          "ModuleDef",
                          "MakeVector",
                          "VecGet",
                          "VecSet",
                          "VecLen",
                          "VecAppend",
                          "VecPop",
                          "VecRemove",
                          "VecReplaceAll",
                          "VecIndexOf",
                          "VecOccurrencesOf",
                          "VecReverse",
                          "VecSwapIfLess",
                          "VecGetFront",
                          "VecGetBack",
                          "IsNum",
                          "IsVec"
    });
    // -- Custom Instructions --
    inst_lib->AddInst("LoadNum1", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadNum1(hw, inst);
    }, 1);

    inst_lib->AddInst("LoadNum2", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadNum2(hw, inst);
    }, 1);

    inst_lib->AddInst("LoadNum3", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadNum3(hw, inst);
    }, 1);
    inst_lib->AddInst("SubmitNum", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_SubmitNum(hw, inst);
    }, 1);


}

void Experiment_Median::Inst_LoadNum1(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[0]);
}

void Experiment_Median::Inst_LoadNum2(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[1]);
}

void Experiment_Median::Inst_LoadNum3(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[2]);
}

void Experiment_Median::Inst_SubmitNum(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], 
        hw.GetMinTagSpecificity(), hardware_t::MemPosType::NUM);
    if (!hw.IsValidMemPos(posA)) return;

    submitted = true;
    submitted_val = (int)wmem.AccessVal(posA).GetNum();
}


#endif
