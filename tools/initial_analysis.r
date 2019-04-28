# There's not much here, just looking at which replicates found solutions

library(ggplot2)

setwd('~/Research/lexicase/gptp-2019-cohort-lexicase/tools')
data = read.csv('solution_found.csv', stringsAsFactors = FALSE)
data$found = data$solution_found == 'True'

treatments = unique(data$treatment)
sizes = unique(data$num_tests)
dilutions = unique(data$dilution)

res = matrix(ncol=4, nrow=0)
for(trt in treatments){
  for(size in sizes){
    for(dil in dilutions){
      tmp = data[data$treatment == trt & data$num_tests == size & data$dilution == dil,]
      res = rbind(res, c(trt, size, dil, sum(tmp$found)))
    }
  }
}
res_df = data.frame(data=res)
colnames(res_df) = c('treatment', 'num_tests', 'dilution', 'solutions_found')
res_df$trt_x_sizes = paste(res_df$treatment, res_df$num_tests, sep='x')
res_df$size_x_dilution = paste(res_df$num_tests, res_df$dilution, sep='x')
res_df$solutions_found = as.numeric(res_df$solutions_found)
ggplot(data=res_df, aes(x=trt_x_sizes, y = solutions_found, color=dilution)) + geom_boxplot()

ggplot(data=res_df, aes(x=size_x_dilution, y = solutions_found, color=treatment)) + geom_boxplot()
