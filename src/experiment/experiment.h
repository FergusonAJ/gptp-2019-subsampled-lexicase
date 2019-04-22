#ifndef COHORT_EXP_H
#define COHORT_EXP_H

#include <iostream>
// Empirical includes
#include "base/Ptr.h"
#include "base/vector.h"
#include "tools/Random.h"
#include "tools/random_utils.h"
#include "Evolve/World.h"
#include "Evolve/World_select.h"

class Experiment{
private:
    emp::Ptr<emp::Random> randPtr;
    void CopyConfig(const ExperimentConfig& config);
    
    // Configurable parameters read in from .cfg file
    int SEED;

public: 
    Experiment();
    void Setup(const ExperimentConfig& config);
    void Run();
};

Experiment::Experiment(){

}

void Experiment::Setup(const ExperimentConfig& config){
    CopyConfig(config);
    randPtr = emp::NewPtr<emp::Random>(SEED);
}
    
void Experiment::Run(){

}

void Experiment::CopyConfig(const ExperimentConfig& config){
   SEED = config.SEED(); 
}
#endif
