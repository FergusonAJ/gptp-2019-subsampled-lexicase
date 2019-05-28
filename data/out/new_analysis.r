# There's not much here, just looking at which replicates found solutions
library(ggplot2)
library(GGally)
library(tidyr)
library(plyr)
library(dplyr)
setwd('~/Research/lexicase/gptp-2019-cohort-lexicase/data/out')

## FAST RUNS
data = read.csv('coverage_fast.csv', stringsAsFactors = FALSE)
data$found = data$solved == 'True'

treatments = unique(data$treatment)
sizes = unique(data$size)
dilutions = unique(data$dilution)

data$found = data$solved == "True"

res = matrix(ncol=4, nrow=0)
for(trt in treatments){
  for(size in sizes){
    for(dil in dilutions){
      tmp = data[data$treatment == trt & data$size == size & data$dilution == dil,]
      res = rbind(res, c(trt, size, dil, nrow(tmp[tmp$found,])))
      print(paste(trt, size, dil, nrow(tmp[tmp$found,]), sum(tmp$found)))
    }
  }
}
res_df = data.frame(data=res)
colnames(res_df) = c('treatment', 'num_tests', 'dilution', 'solutions_found')
#ggpairs(res_df)
# Create a numeric column for the number of tests

res_df$num_tests = ordered(res_df$num_tests, c('5', '10', '25', '50', '100')) 
res_df$solutions_found = as.numeric(as.character(res_df$solutions_found))
#res_df$trt_x_sizes = paste(res_df$treatment, res_df$num_tests, sep='x')
#res_df$size_x_dilution = paste(res_df$num_tests, res_df$dilution, sep='x')
#res_df$solutions_found = as.numeric(res_df$solutions_found)
#ggplot(data=res_df, aes(x=trt_x_sizes, y = solutions_found, color=dilution)) + geom_boxplot()

fast_data = data
fast_res_df = res_df

#ggplot(data=res_df, aes(x=size_x_dilution, y = solutions_found, color=treatment)) + geom_boxplot()
ggplot(data=res_df, aes(x=num_tests, y = solutions_found, color=treatment, shape=dilution)) + geom_jitter(width=0.25, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)')
#ggsave(filename = 'early_results.png')
#ggplot(data=res_df, aes(x=size, y = solutions_found, color=dilution, shape=dilution)) + geom_jitter(width=0.9)

ggplot(data=res_df, aes(x=treatment, y = solutions_found, color=treatment)) + geom_boxplot()
ggplot(data=res_df, aes(x=dilution, y = solutions_found, color=dilution)) + geom_boxplot()
ggplot(data=res_df, aes(x=treatment, y = solutions_found, color=treatment)) + geom_boxplot()


## ORGINIAL RUNS
data = read.csv('coverage.csv', stringsAsFactors = FALSE)
data$found = data$solved == 'True'

treatments = unique(data$treatment)
sizes = unique(data$size)
dilutions = unique(data$dilution)

data$found = data$solved == "True"

res = matrix(ncol=4, nrow=0)
for(trt in treatments){
  for(size in sizes){
    for(dil in dilutions){
      tmp = data[data$treatment == trt & data$size == size & data$dilution == dil & data$found,]
      res = rbind(res, c(trt, size, dil, nrow(tmp)))
      print(tmp[tmp$found,])
    }
  }
}
res_df = data.frame(data=res)
colnames(res_df) = c('treatment', 'num_tests', 'dilution', 'solutions_found')


res_df$solutions_found = as.numeric(as.character(res_df$solutions_found))
res_df$num_tests = ordered(res_df$num_tests, c('5', '10', '25', '50', '100')) 
ggplot(data=res_df, aes(x=num_tests, y = solutions_found, color=treatment, shape=dilution)) + geom_jitter(width=0.2, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)')
# Create a numeric column for the number of tests
res_df$size = as.numeric(as.character(res_df$num_tests))
ggplot(data = res_df, mapping=aes(x=treatment, y=solutions_found, fill=treatment)) +
  geom_bar(stat="identity") +
  guides(fill=FALSE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(0, 50) +
  geom_text(aes(label=solutions_found), nudge_y=3) +
  facet_grid(dilution ~ num_tests, ) + ggtitle("~") 


#ggpairs(res_df)
#ggplot(data=res_df, aes(x=trt_x_sizes, y = solutions_found, color=dilution)) + geom_boxplot()

#ggplot(data=res_df, aes(x=size_x_dilution, y = solutions_found, color=treatment)) + geom_boxplot()
ggplot(data=res_df, aes(x=size, y = solutions_found, color=treatment, shape=dilution)) + geom_jitter(width=1.0, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)')
#ggsave(filename = 'early_results.png')
#ggplot(data=res_df, aes(x=size, y = solutions_found, color=dilution, shape=dilution)) + geom_jitter(width=0.9)

ggplot(data=res_df, aes(x=treatment, y = solutions_found, color=treatment)) + geom_boxplot()
ggplot(data=res_df, aes(x=dilution, y = solutions_found, color=dilution)) + geom_boxplot()
ggplot(data=res_df, aes(x=treatment, y = solutions_found, color=treatment)) + geom_boxplot()

ggplot(data=res_df[res_df$treatment == 'reduced',], aes(x=size, y = solutions_found, color=dilution)) + geom_jitter(width=1.0, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)') + 
  ggtitle('Reduced')

ggplot(data=res_df[res_df$treatment == 'cohort',], aes(x=size, y = solutions_found, color=dilution)) + geom_jitter(width=1.0, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)') + 
  ggtitle('Cohort')

ggplot(data=res_df[res_df$treatment == 'downsampled',], aes(x=size, y = solutions_found, color=dilution)) + geom_jitter(width=1.0, height=0) +
  xlab('Cohort size (For training cases, x10 for programs)') +
  ylab('Number of Solutions found (out of 50)') + 
  ggtitle('Downsampled')


