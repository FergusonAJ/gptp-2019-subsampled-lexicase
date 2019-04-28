from shared import *

#Treatments
treatments = [trt_cohort, trt_reduced, trt_downsampled]

# Cohort (or equiv.) size
sizes = [size_10, size_100, size_25, size_50, size_5]

# Dilution rates
dilutions = [dil_0_0, dil_0_5, dil_0_75, dil_0_9, dil_0_95]

with open('make_dirs.sh', 'w') as fp:
    fp.write('!# /bin/bash\n')
    for trt in treatments:
        fp.write('mkdir ' \
                + base_dir \
                + trt.name \
                + '\n')
        for size in sizes:
            fp.write('mkdir ' \
                    + base_dir \
                    + trt.name \
                    + '/' \
                    + str(size.num_tests) \
                    + '\n')
            for dil in dilutions:
                fp.write('mkdir ' \
                        + base_dir \
                        + trt.name \
                        + '/' \
                        + str(size.num_tests) \
                        + '/' \
                        + dil.get_name() \
                        + '\n')
for trt in treatments:
     for size in sizes:
        for dil in dilutions:
            with open(output_dir + trt.name + '__' + str(size.num_tests) + '_tests__'\
                        + dil.get_name() + '_dilution.sb', 'w') as fp:
                fp.write('#!/bin/bash\n')
                fp.write('########## Define Resources Needed with SBATCH Lines ##########\n')
                fp.write('\n')
                fp.write('#SBATCH --time=12:00:00         # limit of wall clock time - how long the job will run (same as -t)\n')
                fp.write('#SBATCH --array=1-50\n')
                fp.write('#SBATCH --mem=4G                # memory required per node - amount of memory (in bytes)\n')
                fp.write('#SBATCH --job-name ls' + trt.initial + str(size.num_tests) + '_' + dil.get_name() +'     # you can give your job a name for easier identification (same as -J)\n')
                fp.write('#SBATCH --account=devolab\n')
                fp.write('\n')
                fp.write('########## Command Lines to Run ##########\n')
                fp.write('\n')
                fp.write('\n')
                fp.write('##################################\n')
                fp.write('# Setup random seed info\n')
                fp.write('PROBLEM_SEED_OFFSET=17000\n')
                fp.write('\n')
                fp.write('TREATMENT=' + str(trt.config_id) + '\n')
                fp.write('TREATMENT_NAME="' + trt.name + '"\n')
                fp.write('\n')
                fp.write('PROG_COHORT_SIZE=' + str(size.prog_cohort_size) + '\n')
                fp.write('NUM_TESTS=' + str(size.num_tests)  + ' #Used for TEST_COHORT_SIZE, NUM_TESTS, and DOWNSAMPLED_NUM_TESTS\n')
                fp.write('\n')
                fp.write('DILUTION_PCT="' + dil.val + '"\n')
                fp.write('DILUTION_NAME="' + dil.get_name() + '"\n')
                fp.write('GENERATIONS=' + str(size.gens)  + '\n')
                fp.write('\n')
                fp.write('SEED=$((SLURM_ARRAY_TASK_ID + PROBLEM_SEED_OFFSET))\n')
                fp.write('\n')
                fp.write('\n')
                fp.write('##################################\n')
                fp.write('# Setup relevant directories\n')
                fp.write('OUTPUT_DIR=/mnt/gs18/scratch/users/fergu358/lexicase/${TREATMENT_NAME}/${NUM_TESTS}/${DILUTION_NAME}/${SEED}\n')
                fp.write('\n')
                fp.write('echo "./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS}"\n')
                fp.write('\n')
                fp.write('./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS}\n')


