#ifndef COHORT_EXP_H
#define COHORT_EXP_H

#include <iostream>
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

#include "organism.h"

constexpr size_t TAG_WIDTH = 16;
constexpr size_t MEM_SIZE = TAG_WIDTH;

class Experiment{
public:
    using org_t = Organism<TAG_WIDTH>;
    
    using world_t = emp::World<org_t>;
    
    using hardware_t = typename TagLGP::TagLinearGP_TW<TAG_WIDTH>;
    using inst_lib_t = typename TagLGP::InstLib<hardware_t>;
    using inst_t = typename hardware_t::inst_t; 

    enum TreatmentType{
        REDUCED_LEXICASE = 0,
        COHORT_LEXICASE, 
        DOWNSAMPLED_LEXICASE
    };

protected:
    emp::Ptr<emp::Random> randPtr;
    void CopyConfig(const ExperimentConfig& config);
    void SetupEvaluation();
    void InitializePopulation();
    void SetupHardware(); 

    // Bookkeeping variables
    bool setupDone = false;
    
    //Hardware variables
    emp::Ptr<inst_lib_t> inst_lib;
    emp::Ptr<hardware_t> hardware;
    emp::BitSet<TAG_WIDTH> call_tag;   
 
    //Evolution variables
    emp::Ptr<world_t> world;
    TreatmentType treatment_type;

    // Configurable parameters read in from .cfg file
    // General
    int SEED;
    int TREATMENT;
    int POP_SIZE;
    // Program
    int MIN_PROG_SIZE;
    int MAX_PROG_SIZE;
    int PROG_EVAL_TIME;
    // Hardware
    double MIN_TAG_SPECIFICITY;
    int MAX_CALL_DEPTH;
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
    treatment_type = (TreatmentType)TREATMENT;
    world = emp::NewPtr<world_t>(*randPtr);
    world->SetPopStruct_Mixed(true);
    //Setup the different pieces of the experiment
    SetupHardware();

    
    InitializePopulation();
    world->SetAutoMutate(true);
    setupDone = true;
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

void Experiment::Run(){
    if(!setupDone){
        std::cout << "Error! You must call Setup() before calling run on your experiment!" 
            << std::endl;
        exit(-1);
    }

}

void Experiment::CopyConfig(const ExperimentConfig& config){
    // General 
    SEED = config.SEED(); 
    TREATMENT = config.TREATMENT(); 
    POP_SIZE = config.POP_SIZE(); 
    // Program
    MIN_PROG_SIZE = config.MIN_PROG_SIZE();
    MAX_PROG_SIZE = config.MAX_PROG_SIZE();
    PROG_EVAL_TIME = config.PROG_EVAL_TIME();
    // Hardware
    MIN_TAG_SPECIFICITY = config.MIN_TAG_SPECIFICITY();
    MAX_CALL_DEPTH = config.MAX_CALL_DEPTH();
}

void Experiment::InitializePopulation(){
    for(int i = 0; i < POP_SIZE; ++i)
        world->Inject(TagLGP::GenRandTagGPProgram(*randPtr, inst_lib, MIN_PROG_SIZE, 
            MAX_PROG_SIZE), 1);      
}

#endif
