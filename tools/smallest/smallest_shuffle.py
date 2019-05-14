import random
import sys

if '--help' in sys.argv:
    print('Takes in one argument: the .csv with training cases to order')

if len(sys.argv) < 2:
    print('Error! You must pass the filename to sort!')
    exit(-1)

num_cases = 0
header = ''

L0 = []
L1 = []
L2 = []
L3 = []
LS = []

filename = ''
for x in sys.argv[1:]:
    if x[0] != '-':
        filename = x

verbose =  '-v' in sys.argv or '--verbose' in sys.argv

with open(filename, 'r') as in_fp:
    header = in_fp.readline() #
    for line in in_fp:
        tmp = [int(x) for x in line.strip().split(',')[0:4]] # Remove output on the end
        res = min(tmp)
        res_count = 0
        num_cases += 1 
        for x in tmp:
            if res == x:
                res_count += 1
        if res_count > 1:
            LS.append(tmp)
            continue
        if res == tmp[0]:
            L0.append(tmp)
        elif res == tmp[1]:
            L1.append(tmp)
        elif res == tmp[2]:
            L2.append(tmp)
        elif res == tmp[3]:
            L3.append(tmp)

if verbose:
    print('L0:', len(L0))
    for x in L0:
        print('\t', x, min(x))

    print('L1:', len(L1))
    for x in L1:
        print('\t', x, min(x))

    print('L2:', len(L2))
    for x in L2:
        print('\t', x, min(x))

    print('L3:', len(L3))
    for x in L3:
        print('\t', x, min(x))

    print('LS:', len(LS))
    for x in LS:
        print('\t', x, min(x))

random.shuffle(L0)
random.shuffle(L1)
random.shuffle(L2)
random.shuffle(L3)
random.shuffle(LS)

L = [L0, L1, L2, L3, LS]
names = ['L0', 'L1', 'L2', 'L3', 'LS']

out_filename = 'shuffled.csv'
with open(out_filename, 'w') as out_fp:
    out_fp.write(header) # Keep the same header
    progress_made = True
    round_num = 0
    num_added = 0
    while progress_made:
        progress_made = False
        for list_id in range(len(L)):
            cur_list = L[list_id] 
            if round_num < len(cur_list):
                progress_made = True
                num_added += 1
                test_case = cur_list[round_num]
                if verbose:
                    print(names[list_id])
                out_fp.write(str(test_case[0]))
                out_fp.write(',')
                out_fp.write(str(test_case[1]))
                out_fp.write(',')
                out_fp.write(str(test_case[2]))
                out_fp.write(',')
                out_fp.write(str(test_case[3]))
                out_fp.write(',')
                out_fp.write(str(min(test_case)))
                out_fp.write('\n')
        round_num += 1 
if num_cases != num_added:
    print('Error! Original file had ' + str(num_cases) + ' cases, we saved ' + str(num_added) + '!')
    exit(-1)
print('Finished! File written to ' + out_filename) 

