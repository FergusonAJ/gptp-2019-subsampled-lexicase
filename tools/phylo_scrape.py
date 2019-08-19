import os
import re
from diversity_shared import *

# Variables to be set
scratch_dir = '/mnt/gs18/scratch/users/fergu358/gptp2019_diversity/'
start_seed = 0
num_replicates = 50

# Format paths
if scratch_dir[-1] != '/':
        scratch_dir += '/'

# Grab the parameter sets we care about
problems = [prob_smallest]#, prob_median, prob_cmp_str_lens, prob_for_loop]#prob_grade
treatments = [trt_cohort, trt_reduced, trt_downsampled]#, trt_truncated]
sizes = [size_100, size_50, size_25, size_10, size_5]
dilutions = [dil_0_0]

with open('phylo_gens.csv', 'w') as fp:
    fp.write('problem, treatment, num_tests, dilution, gen_solution_found\n')
    for prob in problems: 
        print(prob.name)
        for trt in treatments:
            print('\t' + trt.name)
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
                        replicate_dir = prob.name + '/' \
                                   + trt.name + '/' \
                                   + str(size.num_tests * prob.test_case_factor) \
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
                        if solution_found:
                            cp_src = scratch_dir + replicate_dir + 'pop_' + str(first_gen_found) + \
                                '/' + 'program_phylogeny_' + str(first_gen_found) + '.csv'
                            cp_dest = './phylos/' + prob.name + '_' + trt.name + '_' + \
                                str(size.num_tests) + '_' + str(seed) + '_phylo.txt'
                            os.system('cp ' + cp_src + ' ' + cp_dest)
                            os.system(r'sed -i -E "s/(^[[:digit:]]+.+),\".+\"$/\1/g" ' + cp_dest)
                            #os.system('vim ' + cp_dest + ' '  + \
                            #    r'-c ":%s/\(^\d\+.\+\),\".\+\"$/\1/g" -c "wq"')
                        #if not solution_found:
                        #    max_snapshot_gen = max_gen - (max_gen % 100)
                        #    pop_file_name = 'pop_' + str(max_snapshot_gen)
                        #    if  pop_file_name not in  os.listdir(scratch_dir + replicate_dir):
                        #        print('Error! No valid last snapshot!')
                        #        exit(-1)
                        #    pop_file_path = scratch_dir + replicate_dir + pop_file_name
                        #    solved_all_training, overfit_prog_id = get_overfit(pop_file_path \
                        #          + '/program_pop_' + str(max_snapshot_gen) + '.csv')
                                    
                
                     
