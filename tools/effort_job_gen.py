from effort_shared import *

# Problems 
problems = [prob_smallest, prob_median, prob_cmp_str_lens, prob_for_loop]

# Treatments
treatments = [trt_cohort, trt_reduced, trt_downsampled, trt_truncated]

# Cohort (or equiv.) size
sizes = [size_100, size_50, size_25, size_10, size_5]

# Dilution rates
dilutions = [dil_0_0]

seed_start_offset = 52000


def write_job_file(prob, trt, size, dil, out_dir = None, extra_seed = None, \
        array_size = 50, hours = 24):
    seed = seed_start_offset + \
           prob.seed_offset + \
           trt.seed_offset + \
           size.seed_offset + \
           dil.seed_offset
    if out_dir == None:
        out_dir = output_dir
    filename = ''
    if extra_seed == None:
        filename = out_dir + \
                prob.name + '__' + \
                trt.name +  '__' + \
                str(size.num_tests) + \
                '_tests__'\
                + dil.get_name() + \
                '_dilution.sb'
    else:
        seed += extra_seed
        filename = out_dir + \
                prob.name + '__' + \
                trt.name +  '__' + \
                str(size.num_tests) + \
                '_tests__' + \
                dil.get_name() + \
                '_dilution__' + \
                str(extra_seed) + \
                '.sb'
    
    with open(filename, 'w') as fp:
        fp.write('#!/bin/bash\n')
        fp.write('########## Define Resources Needed with SBATCH Lines ##########\n')
        fp.write('\n')
        fp.write('#SBATCH --time=' + str(hours) + ':00:00         ' + \
                 '# limit of wall clock time - how long the job will run (same as -t)\n')
        fp.write('#SBATCH --array=1-' + str(array_size) + '\n')
        fp.write('#SBATCH --mem=8G                ' + \
                 '# memory required per node - amount of memory (in bytes)\n')
        fp.write('#SBATCH --job-name ls' + prob.initial + '_' + trt.initial + \
                 str(size.num_tests) + '_' + dil.get_name() + '     '\
                 '# you can give your job a name for easier identification (same as -J)\n')
        fp.write('#SBATCH --account=devolab\n')
        fp.write('\n')
        fp.write('########## Command Lines to Run ##########\n')
        fp.write('\n')
        fp.write('\n')
        fp.write('##################################\n')
        fp.write('PROBLEM_NAME=\"' + prob.name + '\"\n')
        fp.write('PROBLEM_ID=' + str(prob.prob_id) + '\n')
        fp.write('TRAINING_FILENAME=\"' + data_dir + prob.name + \
                 '/training-examples-' + prob.name + '.csv' + '\"\n')
        fp.write('TESTING_FILENAME=\"' + data_dir + prob.name + \
                 '/testing-examples-' + prob.name + '.csv' + '\"\n')
        fp.write('MAX_PROG_SIZE=' + str(prob.max_size) + '\n')
        fp.write('MAX_EVAL_TIME=' + str(prob.eval_time) + '\n')
        fp.write('\n')
        
        fp.write('# Setup random seed info\n')
        fp.write('PROBLEM_SEED_OFFSET=' + str(seed - 1) + '\n')
        fp.write('\n')
        
        fp.write('TREATMENT=' + str(trt.config_id) + '\n')
        fp.write('TREATMENT_NAME="' + trt.name + '"\n')
        fp.write('\n')
        
        fp.write('PROG_COHORT_SIZE=' + str(size.prog_cohort_size) + '\n')
        fp.write('NUM_TESTS=' + str(int(prob.test_case_factor * size.num_tests))  + ' ' + \
                 '#Used for TEST_COHORT_SIZE, NUM_TESTS, TRUNCATED_MAX_FUNCS and DOWNSAMPLED_NUM_TESTS\n')
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
        fp.write('OUTPUT_DIR=' + scratch_dir + \
                 '${PROBLEM_NAME}/${TREATMENT_NAME}/${NUM_TESTS}/${DILUTION_NAME}/${SEED}\n')
        fp.write('\n')
        fp.write('rm ${OUTPUT_DIR}/* -r  #If this is a redo, clear the dir\n') 
        fp.write('cd ' + exec_dir + '\n') 
        fp.write('\n')
        fp.write('echo \"mkdir ${OUTPUT_DIR}\"\n')
        fp.write('mkdir ${OUTPUT_DIR}\n')
        cmd = './gptp2019 ' + \
                '-SEED ${SEED} ' + \
                '-PROBLEM_ID ${PROBLEM_ID} ' + \
                '-TRAINING_SET_FILENAME ${TRAINING_FILENAME} ' \
                '-TEST_SET_FILENAME ${TESTING_FILENAME} ' \
                '-MAX_PROG_SIZE ${MAX_PROG_SIZE} ' \
                '-PROG_EVAL_TIME ${MAX_EVAL_TIME} ' \
                '-TREATMENT ${TREATMENT} ' + \
                '-OUTPUT_DIR ${OUTPUT_DIR} ' + \
                '-PROG_COHORT_SIZE ${PROG_COHORT_SIZE} ' + \
                '-TEST_COHORT_SIZE ${NUM_TESTS} ' + \
                '-NUM_TESTS ${NUM_TESTS} ' + \
                '-TRUNCATED_MAX_FUNCS ${NUM_TESTS} ' + \
                '-DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} ' + \
                '-DILUTION_PCT ${DILUTION_PCT} ' + \
                '-GENERATIONS ${GENERATIONS} ' + \
                '> ${OUTPUT_DIR}/slurm.out'
        fp.write('echo \"' + cmd + '\"\n')
        fp.write(cmd + '\n')
        #fp.write('echo "./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS} > /mnt/gs18/scratch/users/fergu358/gptp2019/${TREATMENT_NAME}/${NUM_TESTS}/${DILUTION_NAME}/${SEED}/slurm.out\"\n')
        #fp.write('\n')
        #fp.write('./gptp2019 -SEED ${SEED} -TREATMENT ${TREATMENT} -OUTPUT_DIR ${OUTPUT_DIR} -PROG_COHORT_SIZE ${PROG_COHORT_SIZE} -TEST_COHORT_SIZE ${NUM_TESTS} -NUM_TESTS ${NUM_TESTS} -DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} -DILUTION_PCT ${DILUTION_PCT} -GENERATIONS ${GENERATIONS} > /mnt/gs18/scratch/users/fergu358/gptp2019/${TREATMENT_NAME}/${NUM_TESTS}/${DILUTION_NAME}/${SEED}/slurm.out\n')

if __name__ == '__main__':        
    print('Creating make_dirs.sh...')
    with open('make_dirs.sh', 'w') as fp:
        fp.write('#! /bin/bash\n')
        for prob in problems:
            fp.write('mkdir ' \
                    + scratch_dir \
                    + prob.name
                    + '\n')
            for trt in treatments:
                fp.write('mkdir ' \
                        + scratch_dir \
                        + prob.name \
                        + '/' \
                        + trt.name \
                        + '\n')
                for size in sizes:
                    fp.write('mkdir ' \
                            + scratch_dir \
                            + prob.name \
                            + '/' \
                            + trt.name \
                            + '/' \
                            + str(size.num_tests * prob.test_case_factor) \
                            + '\n')
                    for dil in dilutions:
                        fp.write('mkdir ' \
                                + scratch_dir \
                                + prob.name \
                                + '/' \
                                + trt.name \
                                + '/' \
                                + str(size.num_tests * prob.test_case_factor) \
                                + '/' \
                                + dil.get_name() \
                                + '\n')
    print('make_dirs.sh finished!')
    
    ####### STANDARD LEXICASE CONTROL
    # Problems 
    problems = [prob_smallest, prob_median, prob_cmp_str_lens, prob_for_loop]
    # Treatments
    treatments = [trt_reduced]
    # Cohort (or equiv.) size
    sizes = [size_100]
    
    print('Writing all standard lexicase job files!')
    for prob in problems:
        print('Preparing files for ' + prob.name + ' jobs.')
        for trt in treatments:
            for size in sizes:
                for dil in dilutions:
                    write_job_file(prob, trt, size, dil, None, None, 50, (24 * 7) - 1)
        print(prob.name + ' job files created!')
    

    ####### SUBSAMPLING EXPERIMENTS
    # Problems 
    problems = [prob_smallest, prob_median, prob_cmp_str_lens, prob_for_loop]
    # Treatments
    treatments = [trt_cohort, trt_downsampled, trt_truncated]
    # Cohort (or equiv.) size
    sizes = [size_50, size_25, size_10, size_5]
    
    print('Writing all subsampling job files!')
    for prob in problems:
        print('Preparing files for ' + prob.name + ' jobs.')
        for trt in treatments:
            for size in sizes:
                for dil in dilutions:
                    write_job_file(prob, trt, size, dil, None, None, 50, (24 * 7) - 1)
        print(prob.name + ' job files created!')
    

