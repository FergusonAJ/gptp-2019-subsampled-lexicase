import os
import re
from shared import *

# Variables to be set
scratch_dir = '/mnt/gs18/scratch/users/fergu358/gptp2019/'
start_seed = 17000
num_replicates = 50

# Format paths
if scratch_dir[-1] != '/':
        scratch_dir += '/'

# Grab the parameter sets we care about
problems = [prob_smallest]
treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_100, size_50, size_25, size_10, size_5]
dilutions = [dil_0_0, dil_0_5]


# Regex for seperating strings on a comma, but ignoring commas in quotes
#       source : Duncan at https://stackoverflow.com/questions/2785755/how-to-split-but-ignore-separators-in-quoted-strings-in-python
rex = re.compile(r'''((?:[^,"']|"[^"]*"|'[^']*')+)''')

def log_replicate(prob, trt, size, dil, replicate, seed):
    replicate_dir = prob.name + '/' \
               + trt.name + '/' \
               + str(size.num_tests * prob.test_case_factor) \
               + '/' \
               + dil.get_name() \
               + '/' \
               + str(seed) \
               + '/'
    for filename in os.listdir(scratch_dir + replicate_dir):
        if 'pop' in filename:
            #program_pop_{gen}.csv
            gen = filename.strip().split('_')[-1] # as str
            csv_filename = '/program_pop_' + gen + '.csv'
            with open(scratch_dir + replicate_dir + filename + csv_filename, 'r') as in_fp:
                header = in_fp.readline()
                cols = header.strip().split(',')
                col_map = {}
                for i in range(0, len(cols)):
                     col_map[cols[i]] = i
                first_line = in_fp.readline()
                L = rex.split(first_line.strip())[1::2]
                num_all_tests = int(L[col_map['num_tests__validation_eval']])
                num_training = num_all_tests // 11
                num_validation = num_all_tests - num_training
                # Reset the file pointer to get the first line in the for loop below
                in_fp.seek(0)
                header = in_fp.readline()
                with open('./matrix/' + replicate_dir + 'gen_' + gen + '.csv', 'w') as out_fp:
                    print('./matrix/' + replicate_dir + 'gen_' + gen + '.csv')
                    out_fp.write('prog_id')
                    for i in range(num_training):
                        out_fp.write(',case_' + str(i))
                    out_fp.write('\n')
                    for line in in_fp: 
                        L = rex.split(line.strip())[1::2]
                        #print(L[col_map['program_id']])
                        #print(L[col_map['num_tests__validation_eval']])
                        #print(L[col_map['passes_by_test__validation_eval']])
                        all_results = L[col_map['passes_by_test__validation_eval']]
                        all_results = all_results[2:-2] # remove "[ and ]" from ends
                        training_results = [x for x in \
                                all_results.split(',')[num_validation: len(all_results)]]
                        #print('Found', len(training_results), 'training results.')
                        #print(training_results)
                        out_fp.write(L[col_map['program_id']])
                        for res in training_results:
                            out_fp.write(',' + res)
                        out_fp.write('\n')
                
            

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
                    log_replicate(prob, trt, size, dil, replicate, seed)
                                
            
                 
