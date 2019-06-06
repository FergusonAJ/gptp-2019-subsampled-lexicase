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
    emp::vector<double> score_vec; // Covers every single test case 
    emp::vector<TestStatus> local_status_vec; // Only covers the cases to be encountered
    emp::vector<double> local_score_vec; // Only covers the cases to be encountered
    emp::vector<TestStatus> actual_local_status_vec; // Only covers the cases to be encountered
    emp::vector<double> actual_local_score_vec; // Only covers the cases to be encountered
    emp::vector<uint8_t> local_seen_vec; // For counting "optimized" evaluations
    size_t num_evals; //Used in conjunction with local_seen_vec to get the actual evaluation count
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
        score_vec.clear();
        score_vec.resize(num_cases, 0.0);
    }
    void Reset(size_t num_cases, size_t num_local_cases){
        Reset(num_cases);
        local_status_vec.clear();
        local_status_vec.resize(num_local_cases, TestStatus::UNTESTED);
        local_score_vec.clear();
        local_score_vec.resize(num_local_cases, 0.0);
        actual_local_status_vec.clear();
        actual_local_status_vec.resize(num_local_cases, TestStatus::UNTESTED);
        actual_local_score_vec.clear();
        actual_local_score_vec.resize(num_local_cases, 0.0);
        local_seen_vec.resize(num_local_cases, 0);
        num_evals = 0;
    }

    void Record(size_t test_id, bool pass, bool submitted, double score){
        if(test_id >= status_vec.size()){
            std::cout << "Error! Tried to assign score for test case #" << test_id;
            std::cout << " while organism's vector has length" << status_vec.size() << std::endl;
            exit(-1);
        }
        score_vec[test_id] = score;
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
    void Record(size_t test_id, bool pass, bool submitted, double score, size_t local_test_id){
        Record(test_id, pass, submitted, score);
        if(local_test_id >= local_status_vec.size()){
            std::cout << "Error! Tried to assign score for local test case #" << local_test_id;
            std::cout << " while organism's local vector has length" << local_status_vec.size();
            std::cout << std::endl;
            exit(-1);
        }
        local_score_vec[local_test_id] = score;
        if(pass){ 
            if(submitted)
                local_status_vec[local_test_id] = TestStatus::PASS;
            else
                local_status_vec[local_test_id] = TestStatus::AUTO_PASS;
        }
        else
            local_status_vec[local_test_id] = TestStatus::FAIL;
    }

    void RecordActual(bool pass, bool submitted, double score, size_t local_test_id){
        if(local_test_id >= actual_local_status_vec.size()){
            std::cout << "Error! Tried to assign score for actual local test case #"
                      << local_test_id
                      << " while organism's atual local vector has length" 
                      << actual_local_status_vec.size()
                      << std::endl;
            exit(-1);
        }
        actual_local_score_vec[local_test_id] = score;
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

    double GetTotalLocalScore(){
        double sum = 0.0;
        for(size_t i = 0; i < local_score_vec.size(); ++i){
            sum += local_score_vec[i];
        }
        return sum;
    }
    
    double GetScore(size_t test_id){
        emp_assert(test_id < score_vec.size(), "Trying to get invalid score!");
        return score_vec[test_id];
    }

    double GetLocalScore(size_t local_test_id){
        emp_assert(local_test_id < local_score_vec.size(), "Trying to get invalid local score!");
        if(!local_seen_vec[local_test_id]){
            local_seen_vec[local_test_id] = 1;
            num_evals++;
        }   
        return local_score_vec[local_test_id];
    }

    double GetActualLocalScore(size_t local_test_id){
        emp_assert(local_test_id < actual_local_score_vec.size(), "Trying to get invalid "
            "actual local score!");
        return actual_local_score_vec[local_test_id];
    }

    //Also shows if its unseen   
    size_t GetRawStatus(size_t test_id){
        emp_assert(test_id < status_vec.size(), "Trying to get invalid score!");
        return (size_t)status_vec[test_id];
    }
    //Also shows if its unseen   
    size_t GetRawLocalStatus(size_t local_test_id){
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
    
    size_t GetNumEvals(){
        return num_evals;
    }
};

#endif
