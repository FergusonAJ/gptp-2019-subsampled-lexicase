// Shallow wrapper around the abstract experiment class to allow us to select different 
//   programming synthesis problems


#ifndef COHORT_EXP_HANDLER_H
#define COHORT_EXP_HANDLER_H

#include <iostream>
// Empirical includes
#include "./base/Ptr.h"
#include "./base/assert.h"
// Local includes
#include "./experiment_smallest.h"
#include "./experiment_for_loop_index.h"
#include "./experiment_median.h"
#include "./experiment_compare_string_lengths.h"
#include "./experiment_grade.h"

class ExperimentHandler{
public:
    enum ProblemType{
        SMALLEST = 0,
        FOR_LOOP_INDEX = 1,
        MEDIAN = 2,
        COMPARE_STRING_LENGTHS = 3, 
        GRADE = 4
    };
private:
    emp::Ptr<Experiment> exp_ptr;
    bool setup_done;
    ProblemType problem_type;
public:
    ExperimentHandler();
    ~ExperimentHandler();
    void Setup(const ExperimentConfig& config);
    void Run();
};

ExperimentHandler::ExperimentHandler() {
    setup_done = false;
}
ExperimentHandler::~ExperimentHandler() {
    if(setup_done){
        exp_ptr.Delete();
    }
}

void ExperimentHandler::Setup(const ExperimentConfig& config) {
    if(setup_done){
        std::cout << "You may only setup the experiment handler once!" << std::endl;
        exit(-1);
    }
    problem_type = (ProblemType)config.PROBLEM_ID();
    switch(problem_type){
        case ProblemType::SMALLEST: {
            exp_ptr = emp::NewPtr<Experiment_Smallest>();
            break;
        }
        case ProblemType::FOR_LOOP_INDEX: {
            exp_ptr = emp::NewPtr<Experiment_For_Loop_Index>();
            break;
        }
        case ProblemType::MEDIAN: {
            exp_ptr = emp::NewPtr<Experiment_Median>();
            break;
        }
        case ProblemType::COMPARE_STRING_LENGTHS: {
            exp_ptr = emp::NewPtr<Experiment_Compare_String_Lengths>();
            break;
        }
        case ProblemType::GRADE: {
            exp_ptr = emp::NewPtr<Experiment_Grade>();
            break;
        }
        default: {
            std::cout << "ProblemID of " << config.PROBLEM_ID() << " is invalid!" << std::endl; 
            break;
        }
    }    
    exp_ptr->Setup(config);  
    setup_done = true;
}

void ExperimentHandler::Run(){
    if(!setup_done){
        std::cout << "You must setup the experiment handler before calling run!" << std::endl;
        exit(-1);
    }
    exp_ptr->Run();
}

#endif
