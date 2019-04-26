#ifndef COHORT_EXP_SMALLEST_H
#define COHORT_EXP_SMALLEST_H

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

class Experiment_Smallest : public Experiment{
    public:
        // Readability aliases
        using this_t = Experiment_Smallest;
        using input_t = std::pair<std::array<int, 4>, bool>; // bool is for auto-pass
        using output_t = int;                                   // (used for "watering down" cases)
        using test_case_set_t = TestCaseSet<input_t, output_t>;

    protected:
        // Implementations of abstract methods from base class
        void SetupProblem();
        void SetupDilution();
        void SetupSingleTest(org_t& org, size_t test_id);
        void SetupSingleValidation(org_t& org, size_t test_id);
        void RunSingleTest(org_t& org, size_t test_id);
        bool RunSingleValidation(org_t& org, size_t test_id);
        bool TestValidation(org_t& org);
    
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
        void Inst_LoadNum4(hardware_t & hw, const inst_t & inst);
        void Inst_SubmitNum(hardware_t & hw, const inst_t & inst);
        
        std::string filename;
        test_case_set_t training_set;
        test_case_set_t test_set;
        size_t num_discriminatory_tests;
        bool problems_loaded;
    
        // Variables for a specific run
        size_t cur_test_id;
        size_t cur_validation_id;
        int submitted_val;
        bool submitted;
         
        
    public:
        Experiment_Smallest();
        ~Experiment_Smallest();
};

Experiment_Smallest::Experiment_Smallest():
    training_set(this_t::LoadTestCaseFromLine),
    test_set(this_t::LoadTestCaseFromLine),
    problems_loaded(false){
}

Experiment_Smallest::~Experiment_Smallest(){

}


void Experiment_Smallest::SetupProblem(){
    std::cout << "Setting up problem: \"smallest\"" << std::endl;
    std::cout << "Loading training set from " << TRAINING_SET_FILENAME << std::endl;
    training_set.LoadTestCasesWithCSVReader(TRAINING_SET_FILENAME);
    std::cout << "Found " << training_set.GetSize() << " test cases in training set." << std::endl;
    std::cout << "Loading validation set from " << TRAINING_SET_FILENAME << std::endl;
    test_set.LoadTestCasesWithCSVReader(TEST_SET_FILENAME);
    std::cout << "Found " << test_set.GetSize() << " test cases in validation set." << std::endl;
    num_training_cases = training_set.GetSize();
    num_test_cases = test_set.GetSize();
    SetupInstructions();
    problems_loaded = true;
}

// Sets up a run for a given program for the specifed input
void Experiment_Smallest::SetupSingle(org_t& org, const input_t& input){
    // Reset virtual hardware (global memory and callstack)
    // This is from Alex and Jose's work (Alex created the virtual hardware system)
    hardware->ResetHardware();
    hardware->SetProgram(org.GetGenome());
    hardware->CallModule(call_tag, MIN_TAG_SPECIFICITY, true, false); 
    emp_assert(hardware->GetMemSize() >= 4, "Smallest requires a memory size of at least 4");
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
        wmem.Set(3, input.first[3]);
    }
    else{
        std::cout << "Error in DoSingleTest, GetCallStackSize() returned 0." << std::endl;
        exit(-1);
    }
}

void Experiment_Smallest::SetupDilution(){
    if(!problems_loaded){
        std::cout << "Cannot dilute problems that have not been loaded. Terminating." << std::endl;
        exit(-1);
    }
    num_discriminatory_tests = (size_t)ceil(training_set.GetSize() * (1 - DILUTION_PCT));
    std::cout << "Number of discriminatory tests: " << num_discriminatory_tests << std::endl;
    emp_assert(num_discriminatory != 0, "Dilution percentage cannot be 0!");
    for(size_t test_id = num_discriminatory_tests; test_id < training_set.GetSize(); ++test_id){
        training_set.GetInput(test_id).second = true; 
    }
}

void Experiment_Smallest::SetupSingleTest(org_t& org, size_t test_id){
    input_t & input = training_set.GetInput(test_id);
    cur_test_id = test_id;
    SetupSingle(org, input);
}

void Experiment_Smallest::SetupSingleValidation(org_t& org, size_t test_id){
    input_t & input = test_set.GetInput(test_id);
    cur_validation_id = test_id;
    SetupSingle(org, input);
}

void Experiment_Smallest::RunSingleTest(org_t& org, size_t test_id){
    // Check for auto-pass cases
    if(training_set.GetInput(test_id).second){
        org.Record(test_id, true, false);
    }
    else{
        for(size_t eval_time = 0; eval_time < PROG_EVAL_TIME; ++eval_time){
            hardware->SingleProcess();
            if(hardware->GetCallStackSize() == 0) 
                break;
        }
        if(submitted){
            org.Record(test_id, submitted_val == training_set.GetOutput(test_id), false);
        }
        else{
            org.Record(test_id, false, false, test_id % TEST_COHORT_SIZE);
        }
    }
}

bool Experiment_Smallest::RunSingleValidation(org_t& org, size_t test_id){
    // Check for auto-pass cases
    if(test_set.GetInput(test_id).second){
        return true;
    }
    else{
        for(size_t eval_time = 0; eval_time < PROG_EVAL_TIME; ++eval_time){
            hardware->SingleProcess();
            if(hardware->GetCallStackSize() == 0) 
                break;
        }
        if(submitted){
            return submitted_val == test_set.GetOutput(test_id);
        }
        else{
            return false;
        }
    }
}

// Directly borrowed from Alex and Jose's work
std::pair<Experiment_Smallest::input_t, Experiment_Smallest::output_t> 
            Experiment_Smallest::LoadTestCaseFromLine(const emp::vector<std::string> & line) {
    emp_assert(dilution_setup, "You must set up the dilution before loading test cases!");
    input_t input;   
    output_t output; 
    // Load input.
    input.first[0] = std::atof(line[0].c_str());
    input.first[1] = std::atof(line[1].c_str());
    input.first[2] = std::atof(line[2].c_str());
    input.first[3] = std::atof(line[3].c_str());
    input.second = false;
    // Load output.
    output = std::atof(line[4].c_str());
    emp_assert(output == GenCorrectOutput(input));
    return {input, output};
  }

Experiment_Smallest::output_t Experiment_Smallest::GenCorrectOutput(input_t &input){
    return *std::min_element(input.first.begin(), input.first.end());
}

void Experiment_Smallest::SetupInstructions(){
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

    inst_lib->AddInst("LoadNum4", [this](hardware_t & hw, const inst_t & inst) {
    this->Inst_LoadNum4(hw, inst);
    }, 1);

    inst_lib->AddInst("SubmitNum", [this](hardware_t & hw, const inst_t & inst) {
    this->Inst_SubmitNum(hw, inst);
    }, 1);


}

void Experiment_Smallest::Inst_LoadNum1(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, training_set.GetInput(cur_test_id).first[0]);
}

void Experiment_Smallest::Inst_LoadNum2(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, training_set.GetInput(cur_test_id).first[1]);
}

void Experiment_Smallest::Inst_LoadNum3(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, training_set.GetInput(cur_test_id).first[2]);
}

void Experiment_Smallest::Inst_LoadNum4(hardware_t & hw, const inst_t & inst) {
    hardware_t::CallState & state = hw.GetCurCallState();
    hardware_t::Memory & wmem = state.GetWorkingMem();

    // Find arguments
    size_t posA = hw.FindBestMemoryMatch(wmem, inst.arg_tags[0], hw.GetMinTagSpecificity());
    if (!hw.IsValidMemPos(posA)) return;

    wmem.Set(posA, training_set.GetInput(cur_test_id).first[3]);
}

void Experiment_Smallest::Inst_SubmitNum(hardware_t & hw, const inst_t & inst) {
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
