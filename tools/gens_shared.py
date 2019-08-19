#Classes and instances to be used in several scripts

class Problem:
    def __init__(self, name, prob_id, initial, max_size, eval_time, test_case_factor, seed_offset):
        self.name = name
        self.prob_id = prob_id
        self.initial = initial
        self.max_size = max_size
        self.eval_time = eval_time
        self.test_case_factor = test_case_factor
        self.seed_offset = seed_offset
    def __str__(self):
        return self.name
class TreatmentInfo:
    def __init__(self, name, config_id, seed_offset):
        self.name = name
        self.config_id = config_id
        self.initial = name[0]
        self.seed_offset = seed_offset
    def __str__(self):
        return self.name
class SizeInfo:
    def __init__(self, prog_cohort_size, num_tests, gens, seed_offset):
        self.prog_cohort_size = prog_cohort_size
        self.num_tests = num_tests
        self.gens = gens 
        self.seed_offset = seed_offset
    def __str__(self):
        return str(self.num_tests)
class DilutionInfo:
    def __init__(self, val, seed_offset):
        self.val = val
        self.seed_offset = seed_offset
    def get_name(self):
        return self.val.replace('.', '_')
    def __str__(self):
        return self.get_name()

#Define our directories
exec_dir = '/mnt/home/fergu358/lexicase/gens/gptp-2019-subsampled-lexicase'
scratch_dir = '/mnt/gs18/scratch/users/fergu358/gptp2019_gens/'
if scratch_dir[-1] != '/':
    scratch_dir += '/'
output_dir = './jobs'        
if output_dir[-1] != '/':
    output_dir += '/'
data_dir = './data'
if data_dir[-1] != '/':
    data_dir += '/'

# Problems
prob_smallest =     Problem('smallest',               0, 'S',    64,  64, 1, 100000)
prob_for_loop =     Problem('for-loop-index',         1, 'FL',  128, 256, 1, 200000)
prob_median =       Problem('median',                 2, 'M',    64,  64, 1, 300000)
prob_cmp_str_lens = Problem('compare-string-lengths', 3, 'CSL',  64,  64, 1, 400000)
prob_grade =        Problem('grade',                  4, 'G',    64,  64, 2, 500000)

#Treatments
trt_reduced =     TreatmentInfo('reduced',     0, 10000)
trt_cohort =      TreatmentInfo('cohort',      1, 20000)
trt_downsampled = TreatmentInfo('downsampled', 2, 30000)
trt_truncated =   TreatmentInfo('truncated',   3, 40000)
trt_full =        TreatmentInfo('full',        0, 50000)

# Cohort (or equiv.) size
size_100 = SizeInfo(1000, 100, 300,  1000)
size_50  = SizeInfo(500,  50,  600,  2000)
size_25  = SizeInfo(250,  25,  1200, 3000)
size_10  = SizeInfo(100,  10,  3000, 4000)
size_5   = SizeInfo(50,   5,   6000, 5000)
size_100_300 = SizeInfo(1000, 100, 300, 1050)
size_50_300  = SizeInfo(500,  50,  300, 2050)
size_25_300  = SizeInfo(250,  25,  300, 3050)
size_10_300  = SizeInfo(100,  10,  300, 4050)
size_5_300   = SizeInfo(50,   5,   300, 5050)

# Dilution rates
dil_0_0  = DilutionInfo('0.00000', 100)
dil_0_5  = DilutionInfo('0.50000', 200)
dil_0_75 = DilutionInfo('0.75000', 300)
dil_0_9  = DilutionInfo('0.90000', 400)
dil_0_95 = DilutionInfo('0.95000', 500)

# Create reverse lookups
trt_lookup = {}
trt_lookup['reduced'] = trt_reduced
trt_lookup['cohort'] = trt_cohort
trt_lookup['downsampled'] = trt_downsampled
trt_lookup['truncated'] = trt_truncated

size_lookup = {}
size_lookup[100] = size_100
size_lookup[50] = size_50
size_lookup[25] = size_25
size_lookup[10] = size_10
size_lookup[5] = size_5

dil_lookup = {}
dil_lookup['0_00000'] = dil_0_0
dil_lookup['0_50000'] = dil_0_5
dil_lookup['0_75000'] = dil_0_75
dil_lookup['0_90000'] = dil_0_9
dil_lookup['0_95000'] = dil_0_95

prob_lookup = {}
prob_lookup['smallest'] = prob_smallest
prob_lookup['for-loop-index'] = prob_for_loop
prob_lookup['median'] = prob_median
prob_lookup['compare-string-lengths'] = prob_cmp_str_lens
prob_lookup['grade'] = prob_grade
