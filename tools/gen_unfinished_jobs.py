from shared import *

input_filename = './tools/unfinished.csv'
output_dir = './unfinished/'
if output_dir[-1] != '/':
    output_dir += '/'
start_seed = 17000

# Define some helpful index constants
IDX_ID = 0
IDX_TRT = 1
IDX_SIZE = 2
IDX_DIL = 3
IDX_SOL = 4
IDX_MAX_GEN = 5
IDX_SLURM_JOB = 6
IDX_SLURM_TASK = 7
IDX_FILENAME = 8
IDX_FOUND = 9


unfinished = []
with open(input_filename, 'r') as fp:
    _ = fp.readline() # Headers
    for line in fp:
        line = line.strip()
        if line == '':
            continue
        L = line.split(',')
        trt = L[IDX_TRT].strip('"') 
        size = int(L[IDX_SIZE]) 
        dil = L[IDX_DIL].strip('"') 
        task_id = int(L[IDX_SLURM_TASK]) 
        unfinished.append((trt_lookup[trt], size_lookup[size], dil_lookup[dil], task_id))

count = 0
for tup in unfinished:
    count += 1
    trt = tup[0]
    size = tup[1]
    dil = tup[2]
    task_id = tup[3]
    with open(output_dir + 'redo__' + trt.name + '__' + str(size.num_tests) + '_tests__'\
                + dil.get_name() + '_dilution__' + str(count) + '.sb', 'w') as fp:
        fp.write('#!/bin/bash\n')
        fp.write('########## Define Resources Needed with SBATCH Lines ##########\n')
        fp.write('\n')
        fp.write('#SBATCH --time=72:00:00         # limit of wall clock time - how long the job will run (same as -t)\n')
        fp.write('#SBATCH --array=1-1\n')
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
        fp.write('REDO_SEED_OFFSET=' + str(task_id) + '\n')
        fp.write('\n')
        fp.write('SEED=$((REDO_SEED_OFFSET + PROBLEM_SEED_OFFSET))\n')
        fp.write('\n')
        fp.write('\n')
        fp.write('##################################\n')
        fp.write('# Setup relevant directories\n')
        fp.write('OUTPUT_DIR=/mnt/gs18/scratch/users/fergu358/lexicase/${TREATMENT_NAME}/${NUM_TESTS}/${DILUTION_NAME}/${SEED}\n')
        fp.write('\n')
        fp.write('echo "./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS}"\n')
        fp.write('\n')
        fp.write('./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS}\n')


count = 0
with open('./run_unfinished.sh', 'w') as sbatch_fp:
    sbatch_fp.write('#!/bin/bash\n')
    for tup in unfinished:
        count += 1
        trt = tup[0]
        size = tup[1]
        dil = tup[2]
        task_id = tup[3]
        sbatch_fp.write('sbatch ' \
                        + output_dir\
                        + 'redo__' \
                        + trt.name \
                        + '__' \
                        + str(size.num_tests) \
                        + '_tests__'\
                        + dil.get_name() \
                        + '_dilution__' \
                        + str(count) \
                        + '.sb\n')


with open('clear_dirs.sh', 'w') as dir_fp:
    dir_fp.write('#! /bin/bash\n')
    for tup in unfinished:
        trt = tup[0]
        size = tup[1]
        dil = tup[2]
        task_id = tup[3]
        dir_fp.write('rm ' \
                    + base_dir \
                    + trt.name \
                    + '/' \
                    + str(size.num_tests) \
                    + '/' \
                    + dil.get_name() \
                    + '/' \
                    + str(start_seed + task_id)
                    + '/* -r' \
                    + '\n')
print('Generated', count, 'files + 2 aux scripts!')
