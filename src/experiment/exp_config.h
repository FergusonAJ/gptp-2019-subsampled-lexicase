
#ifndef COHORT_CONFIG_H
#define COHORT_CONFIG_H

#include "config/config.h"

EMP_BUILD_CONFIG(ExperimentConfig, 
    GROUP(GENERAL, "General settings"), 
    VALUE(SEED, int, 0, "Random number seed (-1 to use current time)"),
    VALUE(TREATMENT, int, 0, "0 for Reduced Lexicase, 1 for Cohort Lexicase,"
        " 2 for Downsampled Lexicase")
)

#endif
