import os
import re
from evals_shared import *

# Variables to be set
scratch_dir = '/mnt/gs18/scratch/users/fergu358/gptp2019_out/'
start_seed = 117000
num_replicates = 50

# Format paths
if scratch_dir[-1] != '/':
        scratch_dir += '/'

# Grab the parameter sets we care about
problems = [prob_smallest, prob_median, prob_grade, prob_cmp_str_lens, prob_for_loop]
treatments = [trt_full, trt_cohort, trt_reduced, trt_downsampled]#, trt_truncated]
sizes = [size_100, size_50, size_25, size_10, size_5]
dilutions = [dil_0_0]

# Regex for seperating strings on a comma, but ignoring commas in quotes
#       source : Duncan at https://stackoverflow.com/questions/2785755/how-to-split-but-ignore-separators-in-quoted-strings-in-python
rex = re.compile(r'''((?:[^,"']|"[^"]*"|'[^']*')+)''')

def get_overfit(filename):
    with open(filename, 'r') as in_fp:
        header = in_fp.readline()
        cols = header.strip().split(',')
        col_map = {}
        for i in range(0, len(cols)):
             col_map[cols[i]] = i
        first_line = in_fp.readline()
        L = rex.split(first_line.strip())[1::2]
        num_all_tests = int(L[col_map['num_tests__validation_eval']])
# TODO: Make this more robust!
        num_training = num_all_tests // 11
        num_validation = num_all_tests - num_training
        # Reset the file pointer to get the first line in the for loop below
        in_fp.seek(0)
        header = in_fp.readline()
        for line in in_fp: 
            L = rex.split(line.strip())[1::2]
            all_results = L[col_map['passes_by_test__validation_eval']]
            all_results = all_results[2:-2] # remove "[ and ]" from ends
            training_results = [x for x in \
                    all_results.split(',')[num_validation: len(all_results)]]
            if '0' in training_results:
                continue
            return (True, int(L[col_map['program_id']]))
        return (False, -1)

# Get ALL the relevant data
with open('evaluation_data.csv', 'w') as fp:
    fp.write('problem' \
             + ',' \
             + 'treatment' \
             + ',' \
             + 'num_tests' \
             + ',' \
             + 'dilution' \
             + ',' \
             + 'finished' \
             + ',' \
             + 'solution_found' \
             + ',' \
             + 'first_gen_found' \
             + ',' \
             + 'max_gen' \
             + ',' \
             + 'max_score' \
             + ',' \
             + 'max_actual_score' \
             + ',' \
             + 'solved_all_training' \
             + ',' \
             + 'overfit_prog_id' \
             + ',' \
             + 'replicate_id' \
             + ',' \
             + 'seed' \
             + ',' \
             + 'directory' \
             + '\n')
    for prob in problems: 
        for trt in treatments:
            for size in sizes:
                for dil in dilutions:
                    config_seed = start_seed \
                            + prob.seed_offset \
                            + trt.seed_offset \
                            + size.seed_offset \
                            + dil.seed_offset
                    for replicate in range(0, num_replicates):
                        seed = config_seed + replicate
                        solution_found = False
                        first_gen_found = -1
                        finished = False
                        num_tests = size.num_tests
                        if trt.name == 'full':
                            num_tests = 100
                        replicate_dir = prob.name + '/' \
                                   + trt.name + '/' \
                                   + str(num_tests * prob.test_case_factor) \
                                   + '/' \
                                   + dil.get_name() \
                                   + '/' \
                                   + str(seed) \
                                   + '/'
                        # Check if a solution was found
                        solution_filename = replicate_dir +  '/solutions.csv'
                        with open(scratch_dir + solution_filename, 'r') as tmp_fp:
                            tmp_fp.readline()
                            for line in tmp_fp:
                                if line.strip() != '':
                                    solution_found = True
                                    first_gen_found = int(line.strip().split(',')[0])
                        
                        # Look for maximum number of generations
                        slurm_filename = replicate_dir +  '/slurm.out'
                        max_gen = 0
                        max_score = 0
                        max_actual_score = 0
                        with open(scratch_dir + slurm_filename, 'r') as tmp_fp:
                            for line in tmp_fp:
                                if line.strip() != '':
                                    L = line.split()
                                    if len(L) > 0 and L[0] == 'Update:':
                                        max_gen = int(L[1][:-1])
                                        score = int(L[4][:-1])
                                        actual_score = int(L[8][:-1])
                                        max_score = max(max_score, score)
                                        max_actual_score = max(max_actual_score, actual_score)
                        solved_all_training = solution_found
                        overfit_prog_id = -1
                        if not solution_found:
                            max_snapshot_gen = max_gen - (max_gen % 100)
                            pop_file_name = 'pop_' + str(max_snapshot_gen)
                            if  pop_file_name not in  os.listdir(scratch_dir + replicate_dir):
                                print('Error! No valid last snapshot!')
                                exit(-1)
                            pop_file_path = scratch_dir + replicate_dir + pop_file_name
                            solved_all_training, overfit_prog_id = get_overfit(pop_file_path \
                                  + '/program_pop_' + str(max_snapshot_gen) + '.csv') 
                        fp.write(prob.name \
                                 + ',' \
                                 + trt.name \
                                 + ',' \
                                 + str(size.num_tests) \
                                 + ',' \
                                 + dil.get_name() \
                                 + ',' \
                                 + str(max_gen == size.gens) \
                                 + ',' 
                                 + str(solution_found) \
                                 + ',' \
                                 + str(first_gen_found) \
                                 + ',' \
                                 + str(max_gen) \
                                 + ',' \
                                 + str(max_score) \
                                 + ',' \
                                 + str(max_actual_score) \
                                 + ',' \
                                 + str(solved_all_training) \
                                 + ',' \
                                 + str(overfit_prog_id) \
                                 + ',' \
                                 + str(replicate) \
                                 + ',' \
                                 + str(seed) \
                                 + ',' \
                                 + replicate_dir \
                                 + '\n')
                    print(prob.name + ' ' \
                          + trt.name + ' ' \
                          + str(size.num_tests) + ' ' \
                          + dil.get_name())                 
                                    
                
                     
