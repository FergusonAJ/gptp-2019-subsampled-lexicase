#ifndef COHORT_EXP_FOR_LOOP_INDEX_H
#define COHORT_EXP_FOR_LOOP_INDEX_H

#include <iostream>
#include <array>
#include <utility>
#include <algorithm>
#include <cmath>

//Empricial includes
#include "./base/assert.h"
#include "./tools/sequence_utils.h"

//Local includes
#include "./experiment.h"
#include "./TestCaseSet.h"
#include "Selection.h"

class Experiment_For_Loop_Index : public Experiment{
    public:
        // Readability aliases
        using this_t = Experiment_For_Loop_Index;
        using input_t = std::pair<std::array<int, 3>, bool>; // bool is for auto-pass
        using output_t = emp::vector<int>;                                   // (used for "watering down" cases)
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
        double GetSubmissionScore(const output_t& sub, const output_t& correct);        

        // Custom virtual hardware instructions
        void Inst_LoadStart(hardware_t & hw, const inst_t & inst);
        void Inst_LoadStop(hardware_t & hw, const inst_t & inst);
        void Inst_LoadStep(hardware_t & hw, const inst_t & inst);
        void Inst_SubmitNum(hardware_t & hw, const inst_t & inst);
       
 
        std::string filename;
        test_case_set_t training_set;
        test_case_set_t test_set;
        size_t num_discriminatory_tests;
        bool problems_loaded;
    
        // Variables for a specific run
        size_t cur_test_id;
        output_t submitted_vec;
        bool submitted;
        input_t cur_input;
        output_t cur_output;
        
        // Validation Outputs for diversity tracking
        emp::vector<emp::vector<output_t>> validation_outputs;
        
    public:
        Experiment_For_Loop_Index();
        ~Experiment_For_Loop_Index();
};

Experiment_For_Loop_Index::Experiment_For_Loop_Index():
    training_set(this_t::LoadTestCaseFromLine),
    test_set(this_t::LoadTestCaseFromLine),
    problems_loaded(false){
}

Experiment_For_Loop_Index::~Experiment_For_Loop_Index(){

}


void Experiment_For_Loop_Index::SetupProblem(){
    std::cout << "Setting up problem: \"for loop index\"" << std::endl;
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
void Experiment_For_Loop_Index::SetupSingle(org_t& org, const input_t& input){
    // Reset virtual hardware (global memory and callstack)
    // This is from Alex and Jose's work (Alex created the virtual hardware system)
    hardware->Reset();
    hardware->SetProgram(org.GetGenome());
    hardware->CallModule(call_tag, MIN_TAG_SPECIFICITY, true, false); 
    emp_assert(hardware->GetMemSize() >= 3, "For loop index requires a memory size of at least 3");
    submitted = false;
    submitted_vec = emp::vector<int>();
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

void Experiment_For_Loop_Index::SetupDilution(){
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

double Experiment_For_Loop_Index::GetSubmissionScore(const output_t& sub, const output_t& correct){
    const double max_dist = emp::Max(sub.size(), correct.size());
    double dist = emp::calc_edit_distance(correct, sub);
    if(dist == 0)
        return 1.0;
    else
        return (max_dist - dist) / max_dist;
}

void Experiment_For_Loop_Index::SetupProblemDataCollectionFunctions(){
    program_stats.get_prog_behavioral_diversity = [this]() { 
        return emp::ShannonEntropy(validation_outputs); 
    };
    program_stats.get_prog_unique_behavioral_phenotypes = [this]() { 
        return emp::UniqueCount(validation_outputs); 
    };
}

void Experiment_For_Loop_Index::SetupSingleTest(org_t& org, size_t test_id){
    input_t & input = training_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = training_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_For_Loop_Index::SetupSingleValidation(org_t& org, size_t test_id){
    input_t & input = test_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = test_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_For_Loop_Index::RunSingleTest(org_t& org, size_t test_id, size_t local_test_id){
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
            org.RecordActual(
                submitted_vec == training_set.GetOutput(test_id), //Pass?
                true, // Submit?
                GetSubmissionScore(submitted_vec, training_set.GetOutput(test_id)), // Score 
                local_test_id); // Local id
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
            bool is_correct = submitted_vec == training_set.GetOutput(test_id);
            double score = GetSubmissionScore(submitted_vec, training_set.GetOutput(test_id));
            org.Record(test_id, is_correct, true, score, local_test_id);
            org.RecordActual(is_correct, true, score, local_test_id);
        }
        else{
            org.Record(test_id, false, false, 0.0, local_test_id);
            org.RecordActual(false, false, 0.0, local_test_id);
        }
    }
}

Experiment::TestResult Experiment_For_Loop_Index::RunSingleValidation(size_t org_id, org_t& org, 
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
            validation_outputs[org_id][test_id] = submitted_vec;
            return TestResult(
                submitted_vec == test_set.GetOutput(test_id), // Pass? 
                true, // Submitted?
                GetSubmissionScore(submitted_vec, test_set.GetOutput(test_id)));
        }
        else{
            return TestResult(false, false, 0.0);
        }
    }
}

void Experiment_For_Loop_Index::ResetValidation(){
    validation_outputs.resize(POP_SIZE);
    for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
        validation_outputs[prog_id].resize(num_test_cases);
    }
}  

Experiment::hardware_t::Program Experiment_For_Loop_Index::GetKnownSolution(){
    emp::vector<emp::BitSet<TAG_WIDTH>> matrix = GenHadamardMatrix<TAG_WIDTH>();
    hardware_t::Program sol(inst_lib);
    
    sol.PushInst("CopyMem",     {matrix[0], matrix[4], matrix[7]});
    sol.PushInst("Inc",         {matrix[5], matrix[7], matrix[7]});
    sol.PushInst("While",       {matrix[5], matrix[7], matrix[7]});
    sol.PushInst("SubmitNum",   {matrix[4], matrix[7], matrix[7]});
    sol.PushInst("Add",         {matrix[4], matrix[2], matrix[4]});
    sol.PushInst("TestNumLess", {matrix[4], matrix[1], matrix[5]});
    sol.PushInst("Close",       {matrix[7], matrix[7], matrix[7]});
    sol.PushInst("Return",      {matrix[7], matrix[7], matrix[7]});

    return sol;
}
 
std::pair<Experiment_For_Loop_Index::input_t, Experiment_For_Loop_Index::output_t> 
            Experiment_For_Loop_Index::LoadTestCaseFromLine(const emp::vector<std::string> & line) {
    input_t input;   
    output_t output; 
    // Load input.
    input.first[0] = std::atof(line[0].c_str());
    input.first[1] = std::atof(line[1].c_str());
    input.first[2] = std::atof(line[2].c_str());
    input.second = false;
    // Load output.
    output = GenCorrectOutput(input);
    return {input, output};
}

Experiment_For_Loop_Index::output_t Experiment_For_Loop_Index::GenCorrectOutput(input_t &input){
    emp::vector<int> v;
    for(int i = input.first[0]; i < input.first[1]; i += input.first[2]){
        v.emplace_back(i);
    }
    return v;
}

void Experiment_For_Loop_Index::SetupInstructions(){
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
                          "ModuleDef"
    });
    // -- Custom Instructions --
    inst_lib->AddInst("LoadStart", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadStart(hw, inst);
    }, 1);

    inst_lib->AddInst("LoadStop", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadStop(hw, inst);
    }, 1);

    inst_lib->AddInst("LoadStep", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadStep(hw, inst);
    }, 1);
    
    inst_lib->AddInst("SubmitNum", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_SubmitNum(hw, inst);
    }, 1);


}

void Experiment_For_Loop_Index::Inst_LoadStart(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[0]);
}

void Experiment_For_Loop_Index::Inst_LoadStop(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[1]);
}

void Experiment_For_Loop_Index::Inst_LoadStep(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[2]);
}

void Experiment_For_Loop_Index::Inst_SubmitNum(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], 
        hw.GetMinTagSpecificity(), hardware_t::MemPosType::NUM);
    if (!hw.IsValidMemPos(posA)) return;

    submitted = true;
    submitted_vec.emplace_back((int)wmem.AccessVal(posA).GetNum());
}

#endif
