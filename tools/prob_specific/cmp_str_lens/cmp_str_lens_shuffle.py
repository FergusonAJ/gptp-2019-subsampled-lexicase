import random
import sys

def get_res(L):
    if len(L) != 3:
        print('Error! Expected 3 strings, received', len(L))
        exit(-1)
    l0 = len(L[0])
    l1 = len(L[1])
    l2 = len(L[2])
    if l0 < l1:
        if l1 < l2:
            return (True, 0)
        else:
            return (False, 1)
    else:
        if l1 < l2:
            return (False, 2)
        else:
            return (False, 3)

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

filename = ''
for x in sys.argv[1:]:
    if x[0] != '-':
        filename = x

verbose =  '-v' in sys.argv or '--verbose' in sys.argv

with open(filename, 'r') as in_fp:
    header = in_fp.readline() #Strip away header
    tmp = []
    while True:
        L = []
        for i in range(4):
            S = ''
            in_quotes = False
            buff = in_fp.read(1)
            while buff and (in_quotes or buff != ',') and (in_quotes or buff != '\n'):
                if buff == '"':
                    in_quotes = not in_quotes
                S += buff
                buff = in_fp.read(1)
            if (i + 1) % 4 == 0:
                if S != 'true' and S != 'false':
                    exit(0)
            L.append(S)
        tmp.append(L[:-1]) # shave off the output
        num_cases += 1
        if not buff: #EOF
            break
    print('total:', len(tmp))
    for test_case in tmp:
        res = get_res(test_case) 
        if res[1] == 0:
            L0.append(test_case)
        elif res[1] == 1:
            L1.append(test_case)
        elif res[1] == 2:
            L2.append(test_case)
        elif res[1] == 3:
            L3.append(test_case)

if verbose:
    print('L0:', len(L0))
    for x in L0:
        print('\t', x)

    print('L1:', len(L1))
    for x in L1:
        print('\t', x)

    print('L2:', len(L2))
    for x in L2:
        print('\t', x)

    print('L3:', len(L3))
    for x in L3:
        print('\t', x)

random.shuffle(L0)
random.shuffle(L1)
random.shuffle(L2)
random.shuffle(L3)

L = [L0, L1, L2, L3]
names = ['L0', 'L1', 'L2', 'L3']

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
                if get_res(test_case)[0]:
                    out_fp.write('true')
                else:
                    out_fp.write('false')
                out_fp.write('\n')
        round_num += 1 
if num_cases != num_added:
    print('Error! Original file had ' + str(num_cases) + ' cases, we saved ' + str(num_added) + '!')
    exit(-1)
print('Finished! File written to ' + out_filename) 

