import random
import sys

A_STR = 'Student has a A grade.'
B_STR = 'Student has a B grade.'
C_STR = 'Student has a C grade.'
D_STR = 'Student has a D grade.'
F_STR = 'Student has a F grade.'

def get_grade(L):
    if(len(L) != 5):
        print('I cannot do anything with this, length of 5 needed, received', len(L))
        exit(-1)
    score = L[4]
    if score >= L[0]:
        return (A_STR, 'A')
    elif score >= L[1]:
        return (B_STR, 'B')
    elif score >= L[2]:
        return (C_STR, 'C')
    elif score >= L[3]:
        return (D_STR, 'D')
    return (F_STR, 'F')

if '--help' in sys.argv:
    print('Takes in one argument: the .csv with training cases to order')

if len(sys.argv) < 2:
    print('Error! You must pass the filename to sort!')
    exit(-1)

num_cases = 0
header = ''

LA = []
LB = []
LC = []
LD = []
LF = []

filename = ''
for x in sys.argv[1:]:
    if x[0] != '-':
        filename = x

verbose =  '-v' in sys.argv or '--verbose' in sys.argv

with open(filename, 'r') as in_fp:
    header = in_fp.readline() #
    for line in in_fp:
        tmp = [int(x) for x in line.strip().split(',')[0:5]] # Remove output on the end
        res = get_grade(tmp)
        num_cases += 1
        if res[1] == 'A':
            LA.append(tmp)
        elif res[1] == 'B':
            LB.append(tmp)
        elif res[1] == 'C':
            LC.append(tmp)
        elif res[1] == 'D':
            LD.append(tmp)
        elif res[1] == 'F':
            LF.append(tmp)

if verbose:
    print('LA:', len(LA))
    for x in LA:
        print('\t', x, get_grade(x)[1])
    print('LB:', len(LB))
    for x in LB:
        print('\t', x, get_grade(x)[1])
    print('LC:', len(LC))
    for x in LC:
        print('\t', x, get_grade(x)[1])
    print('LD:', len(LD))
    for x in LD:
        print('\t', x, get_grade(x)[1])
    print('LF:', len(LF))
    for x in LF:
        print('\t', x, get_grade(x)[1])

random.shuffle(LA)
random.shuffle(LB)
random.shuffle(LC)
random.shuffle(LD)
random.shuffle(LF)

L = [LA, LB, LC, LD, LF]
names = ['LA', 'LB', 'LC', 'LD', 'LF']

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
                out_fp.write(str(test_case[4]))
                out_fp.write(',')
                out_fp.write(str(get_grade(test_case)[0]))
                out_fp.write('\n')
        round_num += 1 
if num_cases != num_added:
    print('Error! Original file had ' + str(num_cases) + ' cases, we saved ' + str(num_added) + '!')
    exit(-1)
print('Finished! File written to ' + out_filename) 

