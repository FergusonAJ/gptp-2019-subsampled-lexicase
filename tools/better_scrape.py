import os
import re
from shared import *

# Variables to be set
scratch_dir = '/mnt/gs18/scratch/users/fergu358/lexicase/'
slurm_dir = '/mnt/home/fergu358/lexicase/gptp-2019-cohort-lexicase/slurm/batch_1'
start_seed = 17000
num_replicates = 50

# Format paths
if scratch_dir[-1] != '/':
        scratch_dir += '/'
if slurm_dir[-1] != '/':
        slurm_dir += '/'

# Grab the parameter sets we care about
treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_10, size_100]
dilutions = [dil_0_0, dil_0_5, dil_0_9]

# Scrape all the slurm job ids
slurm_id_map = {}
rex = re.compile('slurm-(\d+)_(\d+)')
for s in os.listdir(slurm_dir):
    res = rex.match(s)
    if res.group(1) not in slurm_id_map.keys():
        slurm_id_map[res.group(1)] = 0
    slurm_id_map[res.group(1)] += 1
# Make sure each task at least started (though it may not have finished)
for k in slurm_id_map.keys():
    if slurm_id_map[k] != num_replicates:
        print('Expected', num_replicates, 'tasks for job id', k, 'but found', slurm_id_map[k])


# Create map of params -> slurm id
slurm_lookup = {}
for slurm_id in slurm_id_map.keys():
    slurm_trt = None
    slurm_size = None
    slurm_dil = None
    with open(slurm_dir + 'slurm-' + str(slurm_id) + '_1.out', 'r') as slurm_fp:
       for line in slurm_fp:
           L = line.strip().split()
           if(len(L) == 0):
                continue
           # Get the relevant data 
           if L[0] == 'set':
                if L[1] == 'TREATMENT':
                    #This is gross, I apologize
                    if L[2] == '0':
                        slurm_trt = 'reduced'
                    elif L[2] == '1':
                        slurm_trt = 'cohort'
                    elif L[2] == '2':
                        slurm_trt = 'downsampled'
                    else: 
                        print('Unknown treatment:', L[2])
                        exit()
                elif L[1] == 'NUM_TESTS':
                    slurm_size = int(L[2])
                elif L[1] == 'DILUTION_PCT':
                    slurm_dil = L[2].replace('.', '_')[0:7] #Off by one decimal point...
    slurm_lookup[(slurm_trt, slurm_size, slurm_dil)] = slurm_id

for k in slurm_lookup.keys():
    print(k, slurm_lookup[k])

# Get ALL the relevant data
with open('replicate_data.csv', 'w') as fp:
    fp.write('treatment' \
             + ',' \
             + 'num_tests' \
             + ',' \
             + 'dilution' \
             + ',' \
             + 'solution_found' \
             + ',' \
             + 'max_gen' \
             + ',' \
             + 'slurm_job_id' \
             + ',' \
             + 'slurm_task_id' \
             + ',' \
             + 'directory' \
             + '\n')    
    for trt in treatments:
        for size in sizes:
            for dil in dilutions:
                slurm_id = slurm_lookup[(trt.name, size.num_tests, dil.get_name())]
                print(slurm_id) 
                for replicate in range(1, num_replicates + 1):
                    solution_found = False
                    replicate_dir = trt.name + '/' \
                               + str(size.num_tests) \
                               + '/' \
                               + dil.get_name() \
                               + '/' \
                               + str(start_seed + replicate)
                    # Check if a solution was found
                    solution_filename = replicate_dir +  '/solutions.csv'
                    with open(scratch_dir + solution_filename, 'r') as tmp_fp:
                        tmp_fp.readline()
                        for line in tmp_fp:
                            if line.strip() != '':
                                solution_found = True
                    # Look for maximum number of generations
                    fitness_filename = replicate_dir +  '/fitness.csv'
                    max_gen = 0
                    with open(scratch_dir + fitness_filename, 'r') as tmp_fp:
                        tmp_fp.readline()
                        for line in tmp_fp:
                            if line.strip() != '':
                                L = line.split(',')
                                if len(L) > 0 and int(L[0]) > max_gen:
                                    max_gen = int(L[0])
                    
                    fp.write(trt.name \
                             + ',' \
                             + str(size.num_tests) \
                             + ',' \
                             + dil.get_name() \
                             + ',' \
                             + str(solution_found) \
                             + ',' \
                             + str(max_gen) \
                             + ',' \
                             + str(slurm_id) \
                             + ',' \
                             + str(replicate) \
                             + ',' \
                             + replicate_dir \
                             + '\n')

                             
                                
            
                 
