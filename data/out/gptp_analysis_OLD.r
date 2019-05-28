# Same as gptp analysis, but for older data
rm(list=ls())

library(ggplot2)
library(GGally)
library(tidyr)
library(plyr)
library(dplyr)
setwd('~/Research/lexicase/gptp-2019-cohort-lexicase/data/out')

## ORGINIAL RUNS
data = read.csv('replicate_data_3.csv', stringsAsFactors = FALSE)

treatments = unique(data$treatment)
sizes = unique(data$num_tests)
dilutions = unique(data$dilution)


data$found = data$solution_found == 'True'

res = matrix(ncol=4, nrow=0)
for(trt in treatments){
  for(size in sizes){
    for(dil in dilutions){
      tmp = data[data$treatment == trt & data$num_tests == size & data$dilution == dil & data$found,]
      res = rbind(res, c(trt, size, dil, nrow(tmp)))
      print(tmp[tmp$found,])
    }
  }
}

res_df = data.frame(data=res)
colnames(res_df) = c('treatment', 'num_tests', 'dilution', 'solutions_found')
res_df$solutions_found = as.numeric(as.character(res_df$solutions_found))
res_df$num_tests = ordered(res_df$num_tests, c('5', '10', '25', '50', '100')) 
res_df$size = as.numeric(as.character(res_df$num_tests))
ggplot(data = res_df, mapping=aes(x=treatment, y=solutions_found, fill=treatment)) +
  geom_bar(stat="identity") +
  guides(fill=FALSE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(0, 55) +
  geom_text(aes(label=solutions_found), nudge_y=3) +
  facet_grid(dilution ~ num_tests ) + ggtitle('"Smallest" - Solutions Found') 



##########################################################################
###############    Checking for overfit solutions    #####################
##########################################################################
data$found_train = data$solution_found == 'True' | (data$max_actual_score == data$num_tests)

res_train = matrix(ncol=4, nrow=0)
for(trt in treatments){
  for(size in sizes){
    for(dil in dilutions){
      tmp = data[data$treatment == trt & data$num_tests == size & data$dilution == dil & data$found_train,]
      res_train = rbind(res_train, c(trt, size, dil, nrow(tmp)))
      print(tmp[tmp$found,])
    }
  }
}
res_train_df = data.frame(data=res_train)
colnames(res_train_df) = c('treatment', 'num_tests', 'dilution', 'train_solutions')

res_train_df$train_solutions = as.numeric(as.character(res_train_df$train_solutions))
res_train_df$num_tests = ordered(res_train_df$num_tests, c('5', '10', '25', '50', '100')) 
res_train_df$size = as.numeric(as.character(res_train_df$num_tests))

ggplot(data = res_train_df, mapping=aes(x=treatment, y=train_solutions, fill=treatment)) +
  geom_bar(stat="identity") +
  guides(fill=FALSE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(0, 55) +
  geom_text(aes(label=train_solutions), nudge_y=3) +
  facet_grid(dilution ~ num_tests ) + ggtitle('"Smallest" - Number of solutions to entire *training* set') 

all_res_df = full_join(res_df, res_train_df, by=c('treatment', 'num_tests', 'dilution', 'size'))

ggplot(data = all_res_df, mapping=aes(x=treatment, y=train_solutions - solutions_found, fill=treatment)) +
  geom_bar(stat="identity") +
  guides(fill=FALSE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(0, 55) +
  geom_text(aes(label=train_solutions - solutions_found), nudge_y=3) +
  facet_grid(dilution ~ num_tests ) + ggtitle('"Smallest" - Number of solutions for training but not test') 

