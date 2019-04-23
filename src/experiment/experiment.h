#ifndef COHORT_EXP_H
#define COHORT_EXP_H

#include <iostream>
// Empirical includes
#include "base/Ptr.h"
#include "base/vector.h"
#include "base/assert.h"
#include "tools/Random.h"
#include "tools/random_utils.h"
#include "Evolve/World.h"
#include "Evolve/World_select.h"

//Local includes
#include "../gp/TagLinearGP.h"
#include "../gp/TagLinearGP_InstLib.h"
#include "../gp/TagLinearGP_Utilities.h"

#include "organism.h"

constexpr size_t TAG_WIDTH = 16;
constexpr size_t MEM_SIZE = TAG_WIDTH;

class Experiment{
public: 
    using org_t = Organism<TAG_WIDTH>;
    using world_t = emp::World<org_t>;
    enum TreatmentType{
        REDUCED_LEXICASE = 0,
        COHORT_LEXICASE, 
        DOWNSAMPLED_LEXICASE
    };

protected:
    emp::Ptr<emp::Random> randPtr;
    void CopyConfig(const ExperimentConfig& config);   

    bool setupDone = false;
    emp::Ptr<world_t> world;
    TreatmentType treatmentType;

    // Configurable parameters read in from .cfg file
    int SEED;
    int TREATMENT;

public: 
    Experiment();
    ~Experiment();
    void Setup(const ExperimentConfig& config);
    void Run();
};

Experiment::Experiment(){

}

Experiment::~Experiment(){
    if(setupDone){
        world.Delete();
        randPtr.Delete();
    }
}

void Experiment::Setup(const ExperimentConfig& config){
    if(setupDone){
        std::cout << "Error! You can only setup the experiment one time!" << std::endl;
        exit(-1);
    }
    CopyConfig(config);
    randPtr = emp::NewPtr<emp::Random>(SEED);
    emp_assert(0 <= TREATMENT && TREATMENT <= 2, "Invalid treatment type."
        "Treatement type must be in the range [0,3]");
    treatmentType = (TreatmentType)TREATMENT;
    world = emp::NewPtr<world_t>(*randPtr);
    world->SetPopStruct_Mixed(true);
    setupDone = true;
}
    


void Experiment::Run(){
    if(!setupDone){
        std::cout << "Error! You must call Setup() before calling run on your experiment!" 
            << std::endl;
        exit(-1);
    }

}

void Experiment::CopyConfig(const ExperimentConfig& config){
   SEED = config.SEED(); 
   TREATMENT = config.TREATMENT(); 
}
#endif
