class TreatmentInfo:
    def __init__(self, name, config_id):
        self.name = name
        self.config_id = config_id
        self.initial = name[0]
class SizeInfo:
    def __init__(self, prog_cohort_size, num_tests, gens):
        self.prog_cohort_size = prog_cohort_size
        self.num_tests = num_tests
        self.gens = gens 
class DilutionInfo:
    def __init__(self, val):
        self.val = val
    def get_name(self):
        return self.val.replace('.', '_')
#Treatments
trt_reduced = TreatmentInfo('reduced', 0)
trt_cohort = TreatmentInfo('cohort', 1)
trt_downsampled = TreatmentInfo('downsampled', 2)

# Cohort (or equiv.) size
size_100 = SizeInfo(1000, 100, 300)
size_50  = SizeInfo(500,  50,  600)
size_25  = SizeInfo(250,  25,  1200)
size_10  = SizeInfo(100,  10,  3000)
size_5   = SizeInfo(50,   5,   6000)

# Dilution rates
dil_0_0  = DilutionInfo('0.00000')
dil_0_5  = DilutionInfo('0.50000')
dil_0_75 = DilutionInfo('0.75000')
dil_0_9  = DilutionInfo('0.90000')
dil_0_95 = DilutionInfo('0.95000')


treatments = [trt_cohort, trt_reduced, trt_downsampled]
sizes = [size_10, size_100]
dilutions = [dil_0_0, dil_0_5, dil_0_9]

with open('sbatch_run.sh', 'w') as fp:
    fp.write('#! /bin/bash\n')
    count = 0
    for trt in treatments:
        for size in sizes:
            for dil in dilutions: 
                fp.write('sbatch ./jobs/' \
                        + trt.name + '__' \
                        + str(size.num_tests) \
                        + '_tests__' \
                        + dil.get_name() \
                        + '_dilution.sb' \
                        + '\n')
                count += 1
    print('Included', count, 'files!')
