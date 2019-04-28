from shared import *

base_dir = '/mnt/gs18/scratch/users/fergu358/lexicase/'
start_seed = 17000
num_replicates = 50

if base_dir[-1] != '/':
        base_dir += '/'


treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_10, size_100]
dilutions = [dil_0_0, dil_0_5, dil_0_9]

with open('solution_found.csv', 'w') as fp:
    fp.write('treatment' \
             + ', ' \
             + 'num_tests' \
             + ', ' \
             + 'dilution' \
             + ', ' \
             + 'solution_found' \
             + ', ' \
             + 'filename' \
             + '\n')    
    for trt in treatments:
        for size in sizes:
            for dil in dilutions:
                for task in range(1, num_replicates + 1):
                    solution_found = False
                    filename = trt.name + '/' \
                               + str(size.num_tests) \
                               + '/' \
                               + dil.get_name() \
                               + '/' \
                               + str(start_seed + task) \
                               + '/solutions.csv'
                    print(base_dir + filename)
                    with open(base_dir + filename, 'r') as tmp_fp:
                        tmp_fp.readline()
                        for line in tmp_fp:
                            if line.strip() != '':
                                solution_found = True
                    fp.write(trt.name \
                             + ', ' \
                             + str(size.num_tests) \
                             + ', ' \
                             + dil.get_name() \
                             + ', ' \
                             + str(solution_found) \
                             + ', ' \
                             + filename \
                             + '\n')

                             
                                
            
                 
