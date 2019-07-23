from job_gen import *

output_dir = '../unfinished_jobs/'
if output_dir[-1] != '/':
    output_dir += '/'
scratch_dir = '/mnt/gs18/scratch/users/fergu358/gptp2019_redo/'
if scratch_dir[-1] != '/':
    scratch_dir += '/'

jobs_to_run = []
with open('../output/unfinished_gptp.csv', 'r') as fp:
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
    print(x[0], x[1], x[2], x[3], x[4])
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

for job in jobs_to_run:
    write_job_file(job[0], job[1], job[2], job[3], out_dir = output_dir, extra_seed = job[4], \
        array_size = 1, hours = (24 * 7) - 1)
 
print('Finished! Goodbye!')
