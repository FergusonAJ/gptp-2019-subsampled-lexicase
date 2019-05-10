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
#include "./experiment_triple_addition.h"
#include "./experiment_return_two.h"
#include "./experiment_add_two.h"
#include "./experiment_smallest_two.h"
#include "./experiment_smallest_three.h"

class ExperimentHandler{
public:
    enum ProblemType{
        SMALLEST = 0,
        TRIPLE_ADDITION = 10,
        RETURN_TWO = 11,
        ADD_TWO = 12,
        SMALLEST_TWO = 13,
        SMALLEST_THREE = 14
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
        case ProblemType::TRIPLE_ADDITION: {
            exp_ptr = emp::NewPtr<Experiment_Triple_Addition>();
            break;
        }
        case ProblemType::RETURN_TWO: {
            exp_ptr = emp::NewPtr<Experiment_Return_Two>();
            break;
        }
        case ProblemType::ADD_TWO: {
            exp_ptr = emp::NewPtr<Experiment_Add_Two>();
            break;
        }
        case ProblemType::SMALLEST_TWO: {
            exp_ptr = emp::NewPtr<Experiment_Smallest_Two>();
            break;
        }
        case ProblemType::SMALLEST_THREE: {
            exp_ptr = emp::NewPtr<Experiment_Smallest_Three>();
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
