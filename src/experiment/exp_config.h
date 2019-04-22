
#ifndef COHORT_CONFIG_H
#define COHORT_CONFIG_H

#include "config/config.h"

EMP_BUILD_CONFIG(ExperimentConfig, 
    GROUP(GENERAL, "General settings"), 
    VALUE(SEED, int, 0, "Random number seed (-1 to use current time)")
)

#endif
