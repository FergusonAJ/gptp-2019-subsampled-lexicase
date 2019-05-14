#ifndef COHORT_EXP_GRADE_H
#define COHORT_EXP_GRADE_H

#include <iostream>
#include <array>
#include <utility>
#include <algorithm>
#include <cmath>

//Empricial includes
#include "./base/assert.h"

//Local includes
#include "./experiment.h"
#include "./TestCaseSet.h"
#include "Selection.h"

#define STR_A "A"
#define STR_B "B"
#define STR_C "C"
#define STR_D "D"
#define STR_F "F"

class Experiment_Grade : public Experiment{
    public:
        // Readability aliases
        using this_t = Experiment_Grade;
        using input_t = std::pair<std::array<int, 5>, bool>; // bool is for auto-pass
        using output_t = std::string;                        // (used for "watering down" cases)
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
        void Inst_LoadThreshA(hardware_t & hw, const inst_t & inst);
        void Inst_LoadThreshB(hardware_t & hw, const inst_t & inst);
        void Inst_LoadThreshC(hardware_t & hw, const inst_t & inst);
        void Inst_LoadThreshD(hardware_t & hw, const inst_t & inst);
        void Inst_LoadGrade(hardware_t & hw, const inst_t & inst);
        void Inst_Submit_A(hardware_t & hw, const inst_t & inst);
        void Inst_Submit_B(hardware_t & hw, const inst_t & inst);
        void Inst_Submit_C(hardware_t & hw, const inst_t & inst);
        void Inst_Submit_D(hardware_t & hw, const inst_t & inst);
        void Inst_Submit_F(hardware_t & hw, const inst_t & inst);
        
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
        Experiment_Grade();
        ~Experiment_Grade();
};

Experiment_Grade::Experiment_Grade():
    training_set(this_t::LoadTestCaseFromLine),
    test_set(this_t::LoadTestCaseFromLine),
    problems_loaded(false){
}

Experiment_Grade::~Experiment_Grade(){

}


void Experiment_Grade::SetupProblem(){
    std::cout << "Setting up problem: \"grade\"" << std::endl;
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
void Experiment_Grade::SetupSingle(org_t& org, const input_t& input){
    // Reset virtual hardware (global memory and callstack)
    // This is from Alex and Jose's work (Alex created the virtual hardware system)
    hardware->Reset();
    hardware->SetProgram(org.GetGenome());
    hardware->CallModule(call_tag, MIN_TAG_SPECIFICITY, true, false); 
    emp_assert(hardware->GetMemSize() >= 5, "Grade requires a memory size of at least 5");
    submitted = false;
    submitted_val = "";
    // Configure inputs.
    if (hardware->GetCallStackSize()) {
        hardware_t::CallState & state = hardware->GetCurCallState();
        hardware_t::Memory & wmem = state.GetWorkingMem();
        // Set hardware input.
        wmem.Set(0, input.first[0]);
        wmem.Set(1, input.first[1]);
        wmem.Set(2, input.first[2]);
        wmem.Set(3, input.first[3]);
    }
    else{
        std::cout << "Error in DoSingleTest, GetCallStackSize() returned 0." << std::endl;
        exit(-1);
    }
}

void Experiment_Grade::SetupDilution(){
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

void Experiment_Grade::SetupProblemDataCollectionFunctions(){
    program_stats.get_prog_behavioral_diversity = [this]() { 
        return emp::ShannonEntropy(validation_outputs); 
    };
    program_stats.get_prog_unique_behavioral_phenotypes = [this]() { 
        return emp::UniqueCount(validation_outputs); 
    };
}

void Experiment_Grade::SetupSingleTest(org_t& org, size_t test_id){
    input_t & input = training_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = training_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_Grade::SetupSingleValidation(org_t& org, size_t test_id){
    input_t & input = test_set.GetInput(test_id);
    cur_test_id = test_id;
    cur_input = input;
    cur_output = test_set.GetOutput(test_id);
    SetupSingle(org, input);
}

void Experiment_Grade::RunSingleTest(org_t& org, size_t test_id, size_t local_test_id){
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

Experiment::TestResult Experiment_Grade::RunSingleValidation(size_t org_id, org_t& org, 
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

void Experiment_Grade::ResetValidation(){
    validation_outputs.resize(POP_SIZE);
    for(size_t prog_id = 0; prog_id < POP_SIZE; ++prog_id){
        validation_outputs[prog_id].resize(num_test_cases);
    }
}  

Experiment::hardware_t::Program Experiment_Grade::GetKnownSolution(){
    emp::vector<emp::BitSet<TAG_WIDTH>> matrix = GenHadamardMatrix<TAG_WIDTH>();
    hardware_t::Program sol(inst_lib);
    
    sol.PushInst("LoadThreshA",        {matrix[0], matrix[8], matrix[8]});
    sol.PushInst("LoadThreshB",        {matrix[1], matrix[8], matrix[8]});
    sol.PushInst("LoadThreshC",        {matrix[2], matrix[8], matrix[8]});
    sol.PushInst("LoadThreshD",        {matrix[3], matrix[8], matrix[8]});
    sol.PushInst("LoadGrade",          {matrix[4], matrix[8], matrix[8]});
    sol.PushInst("TestNumGreaterTEqu", {matrix[4], matrix[0], matrix[5]});
    sol.PushInst("If",                 {matrix[5], matrix[8], matrix[8]});
    sol.PushInst("Submit_A",          {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Return",           {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Close",              {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("TestNumGreaterTEqu", {matrix[4], matrix[1], matrix[5]});
    sol.PushInst("If",                 {matrix[5], matrix[8], matrix[8]});
    sol.PushInst("Submit_B",          {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Return",           {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Close",              {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("TestNumGreaterTEqu", {matrix[4], matrix[2], matrix[5]});
    sol.PushInst("If",                 {matrix[5], matrix[8], matrix[8]});
    sol.PushInst("Submit_C",          {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Return",           {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Close",              {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("TestNumGreaterTEqu", {matrix[4], matrix[3], matrix[5]});
    sol.PushInst("If",                 {matrix[5], matrix[8], matrix[8]});
    sol.PushInst("Submit_D",          {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Return",           {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Close",              {matrix[8], matrix[8], matrix[8]});
    sol.PushInst("Submit_F",            {matrix[8], matrix[8], matrix[8]});

    return sol;
}
 
std::pair<Experiment_Grade::input_t, Experiment_Grade::output_t> 
            Experiment_Grade::LoadTestCaseFromLine(const emp::vector<std::string> & line) {
    input_t input;   
    output_t output; 
    // Load input.
    input.first[0] = std::atof(line[0].c_str());
    input.first[1] = std::atof(line[1].c_str());
    input.first[2] = std::atof(line[2].c_str());
    input.first[3] = std::atof(line[3].c_str());
    input.first[4] = std::atof(line[4].c_str());
    input.second = false;
    // Load output.
    if (line[5] == "Student has a A grade.") {
      output = STR_A;
    } else if (line[5] == "Student has a B grade.") {
      output = STR_B;
    } else if (line[5] == "Student has a C grade.") {
      output = STR_C;
    } else if (line[5] == "Student has a D grade.") {
      output = STR_D;
    } else if (line[5] == "Student has a F grade.") {
      output = STR_F;
    } else {
      std::cout << "Error, invalid grade in test case: " << line[5] << std::endl;
      exit(-1);
    }
    emp_assert(output == GenCorrectOutput(input));
    return {input, output};
}

Experiment_Grade::output_t Experiment_Grade::GenCorrectOutput(input_t &input){
    if      (input.first[4] >= input.first[0]) { return STR_A; }
    else if (input.first[4] >= input.first[1]) { return STR_B; }
    else if (input.first[4] >= input.first[2]) { return STR_C; }
    else if (input.first[4] >= input.first[3]) { return STR_D; }
    else { return STR_F; }
}

void Experiment_Grade::SetupInstructions(){
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
    inst_lib->AddInst("LoadThreshA", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadThreshA(hw, inst);
    }, 1);
    inst_lib->AddInst("LoadThreshB", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadThreshB(hw, inst);
    }, 1);
    inst_lib->AddInst("LoadThreshC", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadThreshC(hw, inst);
    }, 1);
    inst_lib->AddInst("LoadThreshD", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadThreshD(hw, inst);
    }, 1);
    inst_lib->AddInst("LoadGrade", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_LoadGrade(hw, inst);
    }, 1);

    inst_lib->AddInst("Submit_A", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_Submit_A(hw, inst);
    }, 1);
    inst_lib->AddInst("Submit_B", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_Submit_B(hw, inst);
    }, 1);
    inst_lib->AddInst("Submit_C", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_Submit_C(hw, inst);
    }, 1);
    inst_lib->AddInst("Submit_D", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_Submit_D(hw, inst);
    }, 1);
    inst_lib->AddInst("Submit_F", [this](hardware_t & hw, const inst_t & inst) {
        this->Inst_Submit_F(hw, inst);
    }, 1);


}

void Experiment_Grade::Inst_LoadThreshA(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[0]);
}

void Experiment_Grade::Inst_LoadThreshB(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[1]);
}

void Experiment_Grade::Inst_LoadThreshC(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[2]);
}

void Experiment_Grade::Inst_LoadThreshD(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[3]);
}

void Experiment_Grade::Inst_LoadGrade(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, cur_input.first[4]);
}

void Experiment_Grade::Inst_Submit_A(hardware_t & hw, const inst_t & inst) {
    submitted = true;
    submitted_val = STR_A;
}

void Experiment_Grade::Inst_Submit_B(hardware_t & hw, const inst_t & inst) {
    submitted = true;
    submitted_val = STR_B;
}

void Experiment_Grade::Inst_Submit_C(hardware_t & hw, const inst_t & inst) {
    submitted = true;
    submitted_val = STR_C;
}

void Experiment_Grade::Inst_Submit_D(hardware_t & hw, const inst_t & inst) {
    submitted = true;
    submitted_val = STR_D;
}

void Experiment_Grade::Inst_Submit_F(hardware_t & hw, const inst_t & inst) {
    submitted = true;
    submitted_val = STR_F;
}


#endif
