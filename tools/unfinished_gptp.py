from shared import *

output_dir = './unfinished_gptp/'
if output_dir[-1] != '/':
    output_dir += '/'

jobs_to_run = []
with open('./tools/unfinished_gptp.csv', 'r') as fp:
    header = fp.readline().strip().split(',')
    col_map = {}
    for i in range(len(header)):
        col_map[header[i]] = i
    for line in fp:
        line = line.strip()    
        L = line.split(',')
        prob = prob_lookup[L[col_map['problem']]]
        trt = trt_lookup[L[col_map['treatment']]]
        size = size_lookup[int(L[col_map['num_tests']])]
        dil = dil_lookup[L[col_map['dilution']]]
        replicate_id = int(L[col_map['replicate_id']])
        jobs_to_run.append((prob, trt, size, dil, replicate_id))
for x in jobs_to_run:
    print(x)
print(len(jobs_to_run))


def get_filename(prob, trt, size, dil, replicate_id):
    return output_dir + \
           prob.name + '__' + \
           trt.name +  '__' + \
           str(size.num_tests) + \
           '_tests__' + \
           dil.get_name() + \
           '_dilution__' + \
           str(replicate_id) + \
           '.sb'


seed_start_offset = 17000

def write_redo_file(prob, trt, size, dil, replicate_id):
    seed = seed_start_offset + \
           prob.seed_offset + \
           trt.seed_offset + \
           size.seed_offset + \
           dil.seed_offset + \
           replicate_id
    print(seed)
    filename = get_filename(prob, trt, size, dil, replicate_id)
    with open(filename, 'w') as fp:
        fp.write('#!/bin/bash\n')
        fp.write('########## Define Resources Needed with SBATCH Lines ##########\n')
        fp.write('\n')
        fp.write('#SBATCH --time=48:00:00         ' + \
                 '# limit of wall clock time - how long the job will run (same as -t)\n')
        fp.write('#SBATCH --array=1-1\n')
        fp.write('#SBATCH --mem=4G                ' + \
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
                 '/training-examples-' + prob.name + '-shuffled.csv' + '\"\n')
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
                 '#Used for TEST_COHORT_SIZE, NUM_TESTS, and DOWNSAMPLED_NUM_TESTS\n')
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
                '-DOWNSAMPLED_NUM_TESTS ${NUM_TESTS} ' + \
                '-DILUTION_PCT ${DILUTION_PCT} ' + \
                '-GENERATIONS ${GENERATIONS} ' + \
                '> ${OUTPUT_DIR}/slurm.out'
        fp.write('echo \"' + cmd + '\"\n')
        fp.write(cmd + '\n')
       
with open('./unfinished_run.sh', 'w') as fp:
    for job in jobs_to_run:
        fp.write('sbatch ' + get_filename(*job) + '\n')
        write_redo_file(*job)
 
print('Finished! Goodbye!')
