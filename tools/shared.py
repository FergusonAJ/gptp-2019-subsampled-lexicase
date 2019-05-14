#Classes and instances to be used in several scripts

class TreatmentInfo:
    def __init__(self, name, config_id, seed_offset):
        self.name = name
        self.config_id = config_id
        self.initial = name[0]
        self.seed_offset = seed_offset
class SizeInfo:
    def __init__(self, prog_cohort_size, num_tests, gens, seed_offset):
        self.prog_cohort_size = prog_cohort_size
        self.num_tests = num_tests
        self.gens = gens 
        self.seed_offset = seed_offset
class DilutionInfo:
    def __init__(self, val, seed_offset):
        self.val = val
        self.seed_offset = seed_offset
    def get_name(self):
        return self.val.replace('.', '_')

base_dir = "/mnt/gs18/scratch/users/fergu358/gptp2019/"        
if base_dir[-1] != '/':
    base_dir += '/'
output_dir = "../"        
if output_dir[-1] != '/':
    output_dir += '/'

#Treatments
trt_reduced = TreatmentInfo('reduced', 0, 10000)
trt_cohort = TreatmentInfo('cohort', 1, 20000)
trt_downsampled = TreatmentInfo('downsampled', 2, 30000)

# Cohort (or equiv.) size
size_100 = SizeInfo(1000, 100, 300,  1000)
size_50  = SizeInfo(500,  50,  600,  2000)
size_25  = SizeInfo(250,  25,  1200, 3000)
size_10  = SizeInfo(100,  10,  3000, 4000)
size_5   = SizeInfo(50,   5,   6000, 5000)

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
