# Characterizing the Effects of Random Subsampling on Lexicase Selection
[![DOI](https://zenodo.org/badge/182839021.svg)](https://zenodo.org/badge/latestdoi/182839021)

This repository holds the code behind our work for the 2019 Genetic Programming Theory and Practice (GPTP) workshop.

All code is modified and simplified from GECCO 2019 code by Alexander Lalejini and Jose Hernandez here:
[https://github.com/amlalejini/GECCO-2019-cohort-lexicase](https://github.com/amlalejini/GECCO-2019-cohort-lexicase)

## Background
Previous work has shown that by applying random subsampling to lexicase selection, we can reduce the number of evaluations needed to acheive satisfactory results. However, while the theoretical differences between subsampled methods (e.g., cohort and downsampled lexicase) are obvious, in practice they seem to perform similarly. The aim of this work is to characterize the differences of these selection techniques to help guide when they should be used.

## Directory
- ./data - Contains all the training and test data used in the experiments. Data sets come from the [Program Synthesis Benchmark Suite](https://github.com/thelmuth/program-synthesis-benchmark-datasets).
- ./ouput - Contains all generated data (actual output data, plots, statistics, and example phylogenies)
    - ./output/plots - All plots generated for this work, including those not in the publication.
- ./specialist_experiment - All the data generated from specialist experiment, including all code to generate and run the experiment.
- ./src - The C++ source code used for the other experiments.
- ./tools/ - All the scripts used to analyze the data (.r files), as well Python scripts to generate jobs for and scrape data off of MSU's High Performace Computing Cluster

## Reference
The tag-based linear genetic programming system used in this work is the same as previous work, and can be found [here](https://github.com/amlalejini/GECCO-2019-cohort-lexicase/blob/master/docs/gp-system.md). (Note that we used a larger population size of 1,000 candidate solutions.)

All diversity maintenance techniques come from the paper ["Quantifying the Tape of Life: Ancestry-based Metrics Provide Insights and Intuition about Evolutionary Dynamics"](https://www.mitpressjournals.org/doi/abs/10.1162/isal_a_00020) from ALife 2018. 

## Setup
There are two dependecies for this repository to run: 
1. **Empirical** - A [branch](https://github.com/emilydolson/Empirical/tree/memic_model) of the [Empirical](https://github.com/devosoft/Empirical) library. 
 ```
 git clone git@github.com:emilydolson/Empirical.git
 git checkout memic_model
 ```
2. [**csv-parser**](https://github.com/AriaFallah/csv-parser)
```
git clone git@github.com:AriaFallah/csv-parser.git
```

Once both dependencies are downloaded, the makefile (in the repo's root) needs be edited (should be the first two lines) so the compiler can find them:
```
EMP_DIR := PATH_TO_YOUR_EMPIRICAL_DIR/source
PARSER_DIR := PATH_TO_YOUR_CSV_PARSER
```

After that the makefile should do the trick!

```
make
./gptp2019
```
