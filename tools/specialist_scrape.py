SCRATCH_DIR = '/mnt/gs18/scratch/users/fergu358/gptp2019_specialists/'
MAX_POP_SIZE = 100

with open('specialist_data.csv', 'w') as out_fp:
    out_fp.write('treatment,num_tests,pop_size,pass_prob,rep_id')
    for i in range(MAX_POP_SIZE):
        out_fp.write(',' + str(i))
    out_fp.write('\n')
    with open('specialist_files.txt', 'r') as filename_fp:
        count = 0
        for line in filename_fp:
            print(count)
            count += 1
            filename = line.strip()
            L = filename.split('__')
            trt = L[0]
            num_tests = L[1].split('_')[2]
            pop_size = L[2].split('_')[2]
            pass_prob = L[3][10:]
            rep_id = L[4].split('_')[2].split('.')[0]
            out_fp.write(trt + ',' +\
                num_tests + ',' + \
                pop_size  + ',' + \
                pass_prob + ',' + \
                rep_id    + ',')
            with open(SCRATCH_DIR + filename, 'r') as tmp_fp:
                line = tmp_fp.readline()
                line = line.strip()
                out_fp.write(line)
                if int(pop_size) < MAX_POP_SIZE:
                    out_fp.write(',NA' * (MAX_POP_SIZE - int(pop_size)))
            out_fp.write('\n')
            
