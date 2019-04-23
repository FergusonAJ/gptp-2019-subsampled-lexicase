#ifndef COHORT_ORG_H
#define COHORT_ORG_H

#include "../gp/TagLinearGP.h"

template<size_t TAG_WIDTH>
class Organism{
public:
    using genome_t = typename TagLGP::TagLinearGP_TW<TAG_WIDTH>::Program;
protected:
    genome_t genome;
public:
    Organism(){
    }
    Organism(const genome_t & genome_) :
        genome(genome_){
    }
};

#endif
