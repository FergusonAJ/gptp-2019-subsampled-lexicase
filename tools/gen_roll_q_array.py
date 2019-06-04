from shared import *

problems = [prob_grade]
treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_100, size_10]
dilutions = [dil_0_0, dil_0_5, dil_0_75, dil_0_9, dil_0_95]

with open('./tools/roll_q/roll_q_idx.txt', 'w') as fp:
    fp.write('0')

with open('./tools/roll_q/roll_q_job_array.txt', 'w') as fp:
    count = 0
    for prob in problems:
        for trt in treatments:
            for size in sizes:
                for dil in dilutions: 
                    fp.write('./jobs/' \
                            + prob.name + '__' \
                            + trt.name + '__' \
                            + str(size.num_tests) \
                            + '_tests__' \
                            + dil.get_name() \
                            + '_dilution.sb' \
                            + '\n')
                    count += 1
    print('Included', count, 'files!')
