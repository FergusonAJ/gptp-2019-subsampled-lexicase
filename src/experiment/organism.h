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
        FAIL = 2, 
        AUTO_PASS = 3
    };
    genome_t genome;
    size_t num_passes;
    size_t num_fails;
    size_t num_submissions;
    size_t num_actual_passes; // _actual_ variables are recalculated from scratch, 
    size_t num_actual_fails;  //    ignoring auto-passes, it gives the true pass/fail result
    size_t num_actual_submissions;
    emp::vector<TestStatus> status_vec; // Covers every single test case
    emp::vector<TestStatus> local_status_vec; // Only covers the cases to be encountered
    emp::vector<TestStatus> actual_local_status_vec; // Only covers the cases to be encountered
    

public:
    Organism(){
    }

    Organism(const genome_t & genome_) :
        genome(genome_){
    }
    const genome_t & GetGenome() const { 
        return genome;
    }
    genome_t & GetGenome() { 
        return genome;
    }

    void Reset(size_t num_cases){
        num_passes = 0;   
        num_fails = 0;   
        num_submissions = 0;   
        num_actual_passes = 0;   
        num_actual_fails = 0;   
        num_actual_submissions = 0;   
        status_vec.clear();
        status_vec.resize(num_cases, TestStatus::UNTESTED);
    }
    void Reset(size_t num_cases, size_t num_local_cases){
        Reset(num_cases);
        local_status_vec.clear();
        local_status_vec.resize(num_local_cases, TestStatus::UNTESTED);
        actual_local_status_vec.clear();
        actual_local_status_vec.resize(num_local_cases, TestStatus::UNTESTED);
    }

    void Record(size_t test_id, bool pass, bool submitted){
        if(test_id >= status_vec.size()){
            std::cout << "Error! Tried to assign score for test case #" << test_id;
            std::cout << " while organism's vector has length" << status_vec.size() << std::endl;
        }
        if(pass){ 
            ++num_passes;
            if(submitted)
                status_vec[test_id] = TestStatus::PASS;
            else
                status_vec[test_id] = TestStatus::AUTO_PASS;
        }
        else{
            ++num_fails;
            status_vec[test_id] = TestStatus::FAIL;
        }
        if(submitted)
            ++num_submissions;
    }
    void Record(size_t test_id, bool pass, bool submitted, size_t local_test_id){
        Record(test_id, pass, submitted);
        if(local_test_id >= local_status_vec.size()){
            std::cout << "Error! Tried to assign score for local test case #" << local_test_id;
            std::cout << " while organism's local vector has length" << local_status_vec.size();
            std::cout << std::endl;
            exit(-1);
        }
        if(pass){ 
            if(submitted)
                local_status_vec[local_test_id] = TestStatus::PASS;
            else
                local_status_vec[local_test_id] = TestStatus::AUTO_PASS;
        }
        else
            local_status_vec[local_test_id] = TestStatus::FAIL;
    }

    void RecordActual(bool pass, bool submitted, size_t local_test_id){
        if(local_test_id >= actual_local_status_vec.size()){
            std::cout << "Error! Tried to assign score for actual local test case #"
                      << local_test_id
                      << " while organism's atual local vector has length" 
                      << actual_local_status_vec.size()
                      << std::endl;
            exit(-1);
        }
        if(pass){ 
            ++num_actual_passes;
            actual_local_status_vec[local_test_id] = TestStatus::PASS;
        }
        else{
            ++num_actual_fails;
            actual_local_status_vec[local_test_id] = TestStatus::FAIL;        
        }
        if(submitted)
            ++num_actual_submissions;
    }


    
    double GetScore(size_t test_id){
        emp_assert(test_id < status_vec.size(), "Trying to get invalid score!");
        double res = status_vec[test_id] == TestStatus::PASS;
        return res;
    }

    double GetLocalScore(size_t local_test_id){
        emp_assert(local_test_id < local_status_vec.size(), "Trying to get invalid local score!");
        double res = (local_status_vec[local_test_id] == TestStatus::PASS);
        return res;
    }

    size_t GetActualLocalScore(size_t local_test_id){
        emp_assert(local_test_id < actual_local_status_vec.size(), "Trying to get invalid "
            "actual local score!");
        size_t res = (actual_local_status_vec[local_test_id] == TestStatus::PASS);
        return res;
    }

    //Also shows if its unseen   
    size_t GetRawScore(size_t test_id){
        emp_assert(test_id < status_vec.size(), "Trying to get invalid score!");
        return (size_t)status_vec[test_id];
    }
    //Also shows if its unseen   
    size_t GetRawLocalScore(size_t local_test_id){
        emp_assert(local_test_id < local_status_vec.size(), "Trying to get invalid local score!");
        return (size_t)local_status_vec[local_test_id];
    }
    //No need for raw actual local score, cannot be unseen

    size_t GetNumPasses(){
        return num_passes;
    } 
    
    size_t GetNumFails(){
        return num_fails;
    } 
    
    size_t GetNumSubmissions(){
        return num_submissions;
    }

    size_t GetLocalSize(){
        if(local_status_vec.size() == 0)
            return status_vec.size();
        return local_status_vec.size();        
    }
 
    size_t GetNumActualPasses(){
        return num_actual_passes;
    } 
    
    size_t GetNumActualFails(){
        return num_actual_fails;
    } 
    
    size_t GetNumActualSubmissions(){
        return num_actual_submissions;
    }
};

#endif
