#ifndef COHORT_EXP_SMALLEST_H
#define COHORT_EXP_SMALLEST_H

#include <iostream>
//Empricial includes

//Local includes
#include "./experiment.h"

class Experiment_Smallest : public Experiment{
    protected:
        void SetupProblem();
    public:
        Experiment_Smallest();
        ~Experiment_Smallest();
};

Experiment_Smallest::Experiment_Smallest(){

}

Experiment_Smallest::~Experiment_Smallest(){

}

void Experiment_Smallest::SetupProblem(){
    std::cout << "Setting up smallest problem" << std::endl;
}

#endif
