from shared import *

problems = [prob_for_loop]
treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_100, size_50, size_25, size_10, size_5]
dilutions = [dil_0_0, dil_0_5, dil_0_75, dil_0_9, dil_0_95]

with open('sbatch_run.sh', 'w') as fp:
    fp.write('#!/bin/bash\n')
    count = 0
    for prob in problems:
        for trt in treatments:
            for size in sizes:
                for dil in dilutions: 
                    fp.write('sbatch ./jobs/' \
                            + prob.name + '__' \
                            + trt.name + '__' \
                            + str(size.num_tests) \
                            + '_tests__' \
                            + dil.get_name() \
                            + '_dilution.sb' \
                            + '\n')
                    count += 1
    print('Included', count, 'files!')
