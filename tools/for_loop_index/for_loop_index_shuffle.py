import random
import sys

def get_res(L):
    res = []
    i = L[0]
    while(i < L[1]):
        res.append(i)
        i += L[2]
    return res

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
L4 = []

filename = ''
for x in sys.argv[1:]:
    if x[0] != '-':
        filename = x

verbose =  '-v' in sys.argv or '--verbose' in sys.argv

with open(filename, 'r') as in_fp:
    header = in_fp.readline() #strip the header
    for line in in_fp:
        num_cases += 1
        tmp = [int(x) for x in line.strip().split(',')[0:3]] # Remove output on the end
        res = get_res(tmp)
        len_res = len(res)
        if len_res >= 1 and  len_res <= 4:
            L0.append(tmp)
        elif len_res >= 5 and  len_res <= 8:
            L1.append(tmp)
        elif len_res >= 9 and  len_res <= 12:
            L2.append(tmp)
        elif len_res >= 13 and  len_res <= 16:
            L3.append(tmp)
        elif len_res >= 17 and  len_res <= 20:
            L4.append(tmp)

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

    print('L4:', len(L4))
    for x in L4:
        print('\t', x, min(x))

random.shuffle(L0)
random.shuffle(L1)
random.shuffle(L2)
random.shuffle(L3)
random.shuffle(L4)

L = [L0, L1, L2, L3, L4]
names = ['L0', 'L1', 'L2', 'L3', 'L4']

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
                res = get_res(test_case)
                out_fp.write('"')
                for i in range(len(res)):
                    if(i):
                        out_fp.write(',')
                    out_fp.write(str(res[i]))
                out_fp.write('"')
                out_fp.write('\n')
        round_num += 1 
if num_cases != num_added:
    print('Error! Original file had ' + str(num_cases) + ' cases, we saved ' + str(num_added) + '!')
    exit(-1)
print('Finished! File written to ' + out_filename) 

