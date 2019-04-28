from shared import *

treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_10, size_100]
dilutions = [dil_0_0, dil_0_5, dil_0_9]

with open('sbatch_run.sh', 'w') as fp:
    fp.write('#! /bin/bash\n')
    count = 0
    for trt in treatments:
        for size in sizes:
            for dil in dilutions: 
                fp.write('sbatch ./jobs/' \
                        + trt.name + '__' \
                        + str(size.num_tests) \
                        + '_tests__' \
                        + dil.get_name() \
                        + '_dilution.sb' \
                        + '\n')
                count += 1
    print('Included', count, 'files!')
