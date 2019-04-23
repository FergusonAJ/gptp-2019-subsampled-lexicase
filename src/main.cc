//  Genetic Programming in Theory and Practice 2019
//  (Insert title here)
//  Austin J. Ferguson
//  4/22/2019

//  Main program to launch the runs 

//  This file uses parts of Empirical, https://github.com/devosoft/Empirical
//  Copyright (C) Michigan State University, 2016-2017.
//  Released under the MIT Software license; see doc/LICENSE

//Standard includes
#include <iostream>

// Empirical includes
#include "config/ArgManager.h"
#include "config/command_line.h"

// Local includes
#include "./experiment/exp_config.h"
#include "./experiment/experiment.h"


int main(int argc, char* argv[]){
    std::string config_fname = "experiment_config.cfg";
    auto args = emp::cl::ArgManager(argc, argv);
    ExperimentConfig config;
    config.Read(config_fname);
    if (args.ProcessConfigOptions(config, std::cout, config_fname, "exp_config-macros.h") 
            == false) 
        exit(0);
    if (args.TestUnknown() == false) 
        exit(0); // If there are leftover args, throw an error. 

    // Write to screen how the experiment is configured
    std::cout << "==============================" << std::endl;
    std::cout << "|    Current configuration   |" << std::endl;
    std::cout << "==============================" << std::endl;
    config.Write(std::cout);
    std::cout << "==============================\n" << std::endl;

    Experiment E;
    E.Setup(config);
    E.Run();
    std::cout << "Finished!" << std::endl;
        
    return 0;
}
