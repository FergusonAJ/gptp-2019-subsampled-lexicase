#ifndef COHORT_ORG_H
#define COHORT_ORG_H


//Emprical inclues
#include "./base/vector.h"
// Local includes
#include "../gp/TagLinearGP.h"

template<size_t TAG_WIDTH>
class Organism{
public:
    using genome_t = typename TagLGP::TagLinearGP_TW<TAG_WIDTH>::Program;
protected:
    enum TestStatus{
        UNTESTED = 0, 
        PASS = 1, 
        FAIL = 2
    };
    genome_t genome;
    size_t num_passes;
    size_t num_fails;
    size_t num_submissions;
    emp::vector<TestStatus> status_vec;
public:
    Organism(){
    }

    Organism(const genome_t & genome_) :
        genome(genome_){
    }
    const genome_t & GetGenome() const { 
        return genome;
    }
    void Reset(size_t num_cases){
        num_passes = 0;   
        num_fails = 0;   
        num_submissions = 0;   
        status_vec.clear();
        status_vec.resize(num_cases, TestStatus::UNTESTED);
    }
    void Record(size_t test_id, bool pass, bool submitted){
        if(test_id >= status_vec.size()){
            std::cout << "Error! Tried to assign score for test case #" << test_id;
            std::cout << " while organism's vector has length" << status_vec.size() << std::endl;
        }
        if(pass){ 
            ++num_passes;
            status_vec[test_id] = TestStatus::PASS;
        }
        else{
            ++num_fails;
            status_vec[test_id] = TestStatus::FAIL;
        }
        if(submitted)
            ++num_submissions;
    }
};

#endif
