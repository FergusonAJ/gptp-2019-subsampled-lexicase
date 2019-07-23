from shared import *

# Problems 
problems = [prob_smallest, prob_median, prob_cmp_str_lens, prob_grade, prob_for_loop]

# Treatments
treatments = [trt_cohort, trt_reduced, trt_downsampled]

# Cohort (or equiv.) size
sizes = [size_10, size_100, size_25, size_50, size_5]

# Dilution rates
dilutions = [dil_0_0, dil_0_5, dil_0_75, dil_0_9, dil_0_95]

start_seed = 17000
num_replicates = 50

print('Creating make_dirs.sh...')
with open('./matrix/make_matrix_dirs.sh', 'w') as fp:
    fp.write('#! /bin/bash\n')
    for prob in problems:
        fp.write('mkdir ./' \
                + prob.name
                + '\n')
        for trt in treatments:
            fp.write('mkdir ./' \
                    + prob.name \
                    + '/' \
                    + trt.name \
                    + '\n')
            for size in sizes:
                fp.write('mkdir ./' \
                        + prob.name \
                        + '/' \
                        + trt.name \
                        + '/' \
                        + str(size.num_tests) \
                        + '\n')
                for dil in dilutions:
                    fp.write('mkdir ./' \
                            + prob.name \
                            + '/' \
                            + trt.name \
                            + '/' \
                            + str(size.num_tests) \
                            + '/' \
                            + dil.get_name() \
                            + '\n')
                    # Get the seed for each individual run
                    config_seed = start_seed \
                            + prob.seed_offset \
                            + trt.seed_offset \
                            + size.seed_offset \
                            + dil.seed_offset
                    for replicate in range(0, num_replicates):
                        seed = config_seed + replicate
                        fp.write('mkdir ./' \
                                + prob.name \
                                + '/' \
                                + trt.name \
                                + '/' \
                                + str(size.num_tests) \
                                + '/' \
                                + dil.get_name() \
                                + '/' \
                                + str(seed) \
                                + '\n')
print('./matrix/make_dirs.sh finished!')
