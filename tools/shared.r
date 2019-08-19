#color_vec = c('#e66101', '#fdb863', '#5e3c99', '#b2abd2')
cohort_color = '#e66101'
downsampled_color = '#fdb863'
reduced_color = '#5e3c99'
full_color = '#b2abd2'
truncated_color = '#f7f7f7'
# Thanks colorbrewer! http://colorbrewer2.org/#type=diverging&scheme=PuOr&n=4

library(hash)
# Create hash table lookups to make formatting easy
prob_lookup = hash() 
prob_lookup[['smallest']] = 'Smallest'
prob_lookup[['median']] = 'Median'
prob_lookup[['for-loop-index']] = 'For Loop Index'
prob_lookup[['compare-string-lengths']] = 'Compare String Lengths'
prob_lookup[['grade']] = 'Grade'
trt_lookup = hash()
trt_lookup[['cohort']] = 'Cohort'
trt_lookup[['downsampled']] = 'Down-sampled'
trt_lookup[['reduced']] = 'Reduced'
trt_lookup[['control']] = 'Control'
trt_lookup[['truncated']] = 'Truncated'
trt_lookup[['full']] = 'Standard'
size_lookup = hash()
size_lookup[['100']] = '100%'#'No subsampling'
size_lookup[['50']] = '50%'#'50% subsampling'
size_lookup[['25']] = '25%'#'25% subsampling'
size_lookup[['10']] = '10%'#'10% subsampling'
size_lookup[['5']] = '5%'#'5% subsampling'
dil_lookup = hash()
dil_lookup[['0_00000']] = 'No dilution'
dil_lookup[['0_50000']] = '50% discriminatory'
dil_lookup[['0_75000']] = '25% discriminatory'
dil_lookup[['0_90000']] = '10% discriminatory'
dil_lookup[['0_95000']] = '5% discriminatory'

# Calculate the order in which factors will be plotted
#size_levels = c(size_lookup[['100']], size_lookup[['50']], size_lookup[['25']], size_lookup[['10']], size_lookup[['5']])
size_levels = c(size_lookup[['5']], size_lookup[['10']], size_lookup[['25']], size_lookup[['50']], size_lookup[['100']])
#trt_levels = c(trt_lookup[['reduced']], trt_lookup[['truncated']], trt_lookup[['downsampled']], trt_lookup[['cohort']])
trt_levels = c(trt_lookup[['cohort']], trt_lookup[['downsampled']], trt_lookup[['truncated']], trt_lookup[['reduced']], trt_lookup[['full']])
prob_levels = c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']], prob_lookup[['grade']], prob_lookup[['compare-string-lengths']])
