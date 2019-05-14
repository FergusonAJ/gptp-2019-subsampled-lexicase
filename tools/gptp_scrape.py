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
treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_100, size_50, size_25, size_10, size_5]
dilutions = [dil_0_0]


# Get ALL the relevant data
with open('replicate_data.csv', 'w') as fp:
    fp.write('treatment' \
             + ',' \
             + 'num_tests' \
             + ',' \
             + 'dilution' \
             + ',' \
             + 'finished' \
             + ',' \
             + 'solution_found' \
             + ',' \
             + 'max_gen' \
             + ',' \
             + 'max_score' \
             + ',' \
             + 'max_actual_score' \
             + ',' \
             + 'replicate_id' \
             + ',' \
             + 'seed' \
             + ',' \
             + 'directory' \
             + '\n')    
    for trt in treatments:
        for size in sizes:
            for dil in dilutions:
                config_seed = start_seed + trt.seed_offset + size.seed_offset + dil.seed_offset
                for replicate in range(1, num_replicates + 1):
                    seed = config_seed + replicate
                    solution_found = False
                    finished = False
                    replicate_dir = trt.name + '/' \
                               + str(size.num_tests) \
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
                    fp.write(trt.name \
                             + ',' \
                             + str(size.num_tests) \
                             + ',' \
                             + dil.get_name() \
                             + ',' \
                             + str(max_gen == size.gens) \
                             + ',' 
                             + str(solution_found) \
                             + ',' \
                             + str(max_gen) \
                             + ',' \
                             + str(max_score) \
                             + ',' \
                             + str(max_actual_score) \
                             + ',' \
                             + str(replicate) \
                             + ',' \
                             + str(seed) \
                             + ',' \
                             + replicate_dir \
                             + '\n')
                print(trt.name + " " + str(size.num_tests) + dil.get_name())                 
                                
            
                 
