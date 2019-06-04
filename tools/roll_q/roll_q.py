import sys

#### CONFIG OPTIONS
replicates = 50    
roll_q_dir = './tools/roll_q'
if roll_q_dir[-1] != '/':
    roll_q_dir += '/'

if len(sys.argv) < 2:
    print('Must pass one argument, the number of jobs in the queue!')
    exit(-1)
jobs_in_queue = int(sys.argv[1])
open_slots = 1000 - jobs_in_queue
print(open_slots, 'slots available in queue.')
num_jobs_to_run = open_slots // replicates 

cur_idx = 0
with open(roll_q_dir + 'roll_q_idx.txt', 'r') as fp:
    cur_idx = int(fp.readline().strip())
print('Current index in job array:', cur_idx)


jobs_to_run = []
with open(roll_q_dir + 'roll_q_job_array.txt', 'r') as fp:
    all_jobs_finished = False
    for i in range(0, cur_idx):
        line = fp.readline().strip()
        if line == '':
            all_jobs_finished = True
            break
        print('Skipping:', line)
    if all_jobs_finished:
        print('All jobs already running or done, there\'s nothing to queue!')
        exit(0)
    for i in range(0, num_jobs_to_run):
        line = fp.readline().strip()
        if line == '':
            print('We hit the end of the queue! Submitting the last few jobs...')
            break
        jobs_to_run.append(line)

with open(roll_q_dir + 'roll_q_submit.sh', 'w') as out_fp:
    out_fp.write('#!/bin/bash\n')
    for job in jobs_to_run:
        out_fp.write('sbatch ' + job + '\n')

with open(roll_q_dir + 'roll_q_idx.txt', 'w') as idx_fp:
    idx_fp.write(str(cur_idx + len(jobs_to_run)))

print('Prepared', len(jobs_to_run), 'jobs to run!')
