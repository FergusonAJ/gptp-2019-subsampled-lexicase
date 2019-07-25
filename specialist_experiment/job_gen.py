# Constants
SA_PATH = '~/tools/empirical_work/Empirical/apps/SelectionAnalyze/SelectionAnalyze'
INPUT_DIR = './pop_data/'
OUTPUT_DIR = './selection_probs/'
JOB_DIR = './jobs/'
NUM_REPLICATES = 100
NUM_SAMPLES = 1000000

# Configuration variables
pop_size_L = [10,20,100]
num_tests_L = [10,20]
pass_prob_L = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
subsampling_level_L = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
tourney_size_L = [2, 7]



def get_pop_file(pop_size, num_tests, pass_prob, rep_id):
    return 'population' + \
            '__num_tests_' + str(pop_size) + \
            '__pop_size_' + str(num_tests) + \
            '__pass_prob_' + str(pass_prob).replace('.', '_') + \
            '__rep_id_' + str(rep_id) + \
            '.csv'

def get_lexicase_line(pop_size, num_tests, pass_prob, rep_id):
    s = ''
    s += SA_PATH + ' '
    pop_filename = get_pop_file(pop_size, num_tests, pass_prob, rep_id)
    # Shared
    s += '-INPUT_FILENAME ' + INPUT_DIR + pop_filename + ' ' 
    s += '-OUTPUT_FILENAME ' + OUTPUT_DIR + pop_filename.replace('population', 'lexicase') + ' '
    s += '-AGGREGATE_FIT_IDX ' + '1' + ' '
    s += '-LEXICASE_START_IDX ' + '2' + ' '
    # Specific
    s += '-SELECTION_SCHEME ' + '0' + ' '
    s += '-LEXICASE_DO_SUBSAMPLING ' + '0'
    s += '\n'
    return s

def get_cohort_lines(pop_size, num_tests, pass_prob, rep_id):
    s = ''
    for subsampling_level in subsampling_level_L:
        subsampling_str = str(subsampling_level).replace('.', '_')
        s += SA_PATH + ' '
        pop_filename = get_pop_file(pop_size, num_tests, pass_prob, rep_id)
        # Shared
        s += '-INPUT_FILENAME ' + INPUT_DIR + pop_filename + ' ' 
        s += '-AGGREGATE_FIT_IDX ' + '1' + ' '
        s += '-LEXICASE_START_IDX ' + '2' + ' '
        # Specific
        s += '-OUTPUT_FILENAME ' + OUTPUT_DIR + pop_filename.replace('population', 'cohort_' + subsampling_str) + ' '
        s += '-SELECTION_SCHEME ' + '0' + ' '
        s += '-LEXICASE_DO_SUBSAMPLING ' + '1' + ' '
        s += '-LEXICASE_SUBSAMPLING_GROUP_SIZE ' + str(int(pop_size * subsampling_level)) + ' ' 
        s += '-LEXICASE_SUBSAMPLING_TEST_COUNT ' + str(int(num_tests * subsampling_level)) + ' ' 
        s += '-LEXICASE_SUBSAMPLING_NUM_SAMPLES ' + str(NUM_SAMPLES) + ' '
        s += '\n' 
    s += '\n' 
    return s

def get_downsampled_lines(pop_size, num_tests, pass_prob, rep_id):
    s = ''
    for subsampling_level in subsampling_level_L:
        subsampling_str = str(subsampling_level).replace('.', '_')
        s += SA_PATH + ' '
        pop_filename = get_pop_file(pop_size, num_tests, pass_prob, rep_id)
        # Shared
        s += '-INPUT_FILENAME ' + INPUT_DIR + pop_filename + ' ' 
        s += '-OUTPUT_FILENAME ' + OUTPUT_DIR + pop_filename.replace('population', 'downsampled_' + subsampling_str) + ' '
        s += '-AGGREGATE_FIT_IDX ' + '1' + ' '
        s += '-LEXICASE_START_IDX ' + '2' + ' '
        # Specific
        s += '-SELECTION_SCHEME ' + '0' + ' '
        s += '-LEXICASE_DO_SUBSAMPLING ' + '1' + ' '
        s += '-LEXICASE_SUBSAMPLING_GROUP_SIZE ' + '0' + ' ' 
        s += '-LEXICASE_SUBSAMPLING_TEST_COUNT ' + str(int(num_tests * subsampling_level)) + ' ' 
        s += '-LEXICASE_SUBSAMPLING_NUM_SAMPLES ' + str(NUM_SAMPLES) + ' '
        s += '\n' 
    s += '\n' 
    return s

def get_roulette_line(pop_size, num_tests, pass_prob, rep_id):
    s = ''
    s += SA_PATH + ' '
    pop_filename = get_pop_file(pop_size, num_tests, pass_prob, rep_id)
    # Shared
    s += '-INPUT_FILENAME ' + INPUT_DIR + pop_filename + ' ' 
    s += '-OUTPUT_FILENAME ' + OUTPUT_DIR + pop_filename.replace('population', 'roulette') + ' '
    s += '-AGGREGATE_FIT_IDX ' + '1' + ' '
    s += '-LEXICASE_START_IDX ' + '2' + ' '
    # Specific
    s += '-SELECTION_SCHEME ' + '3' + ' '
    s += '\n\n'
    return s

def get_tournament_lines(pop_size, num_tests, pass_prob, rep_id):
    s = ''
    for tourney_size in tourney_size_L:
        s += SA_PATH + ' '
        pop_filename = get_pop_file(pop_size, num_tests, pass_prob, rep_id)
        # Shared
        s += '-INPUT_FILENAME ' + INPUT_DIR + pop_filename + ' ' 
        s += '-OUTPUT_FILENAME ' + OUTPUT_DIR + pop_filename.replace('population', 'tournament_' + str(tourney_size)) + ' '
        s += '-AGGREGATE_FIT_IDX ' + '1' + ' '
        s += '-LEXICASE_START_IDX ' + '2' + ' '
        # Specific
        s += '-SELECTION_SCHEME ' + '1' + ' '
        s += '-TOURNAMENT_SIZE ' + str(tourney_size) + ' '
        s += '-TOURNAMENT_SAMPLES ' + str(NUM_SAMPLES) + ' '
        s += '\n'
    s += '\n' 
    return s


if __name__ == '__main__':
    for rep_id in range(1, NUM_REPLICATES + 1):
        with open(JOB_DIR + 'run_replicate_' + str(rep_id) + '.sh', 'w') as fp:
            fp.write('#!/bin/bash\n\n') 
            for pop_size in pop_size_L:
                fp.write('echo "Starting pop size: ' + str(pop_size) + '"\n')    
                for num_tests in num_tests_L:
                    fp.write('echo "\tStarting test count: ' + str(num_tests) + '"\n')
                    for pass_prob in pass_prob_L:
                        pass_prob_str = str(pass_prob).replace('.', '_')
                        fp.write('echo "\t\tStarting pass prob: ' + pass_prob_str + '"\n')
                        fp.write(get_lexicase_line(pop_size, num_tests, pass_prob, rep_id))
                        fp.write(get_cohort_lines(pop_size, num_tests, pass_prob, rep_id))
                        fp.write(get_downsampled_lines(pop_size, num_tests, pass_prob, rep_id))
                        fp.write(get_roulette_line(pop_size, num_tests, pass_prob, rep_id))
                        fp.write(get_tournament_lines(pop_size, num_tests, pass_prob, rep_id))
                        fp.write('\n')                       
