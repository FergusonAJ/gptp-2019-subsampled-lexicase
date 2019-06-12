# Characterizing the Effects of Random Subsampling on Lexicase Selection
This repository holds the code behind our work for the 2019 Genetic Programming Theory and Practice (GPTP) conference.

All code is modified and simplified from GECCO 2019 code by Alexander Lalejini and Jose Hernandez here:
[https://github.com/amlalejini/GECCO-2019-cohort-lexicase](https://github.com/amlalejini/GECCO-2019-cohort-lexicase)

## Background
Previous work (CITE) has shown that by applying random subsampling to lexicase selection, we can reduce the number of evaluations needed to acheive satisfactory results. However, while the theoretical differences between subsampled methods (e.g., cohort and downsampled lexicase) are obvious, in practice they seem to perform similarly. The aim of this work is to characterize the differences of these selection techniques to help guide when they should be used.

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

More detailed descriptions to come!
