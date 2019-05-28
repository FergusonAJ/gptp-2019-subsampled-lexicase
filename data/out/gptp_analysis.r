rm(list=ls())

library(ggplot2)
library(GGally)
library(tidyr)
library(plyr)
library(dplyr)
library(hash)

## CONFIG OPTIONS
IMG_WIDTH = 14
IMG_HEIGHT = 10

setwd('~/Research/lexicase/gptp-2019-cohort-lexicase/data/out')

## ORGINIAL RUNS
data = read.csv('all_hand.csv', stringsAsFactors = FALSE)

## LOOKUPS FOR FORMATTING
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

size_lookup = hash()
size_lookup[['100']] = 'No subsampling'
size_lookup[['50']] = '50% subsampling'
size_lookup[['25']] = '25% subsampling'
size_lookup[['10']] = '10% subsampling'
size_lookup[['5']] = '5% subsampling'

dil_lookup = hash()
dil_lookup[['0_00000']] = 'No dilution'
dil_lookup[['0_50000']] = '50% discriminatory'
dil_lookup[['0_75000']] = '25% discriminatory'
dil_lookup[['0_90000']] = '10% discriminatory'
dil_lookup[['0_95000']] = '5% discriminatory'

problems = unique(data$problem)
treatments = unique(data$treatment)
sizes = unique(data$num_tests)
dilutions = unique(data$dilution)


data$found = data$solution_found == 'True'

# Calculate solution counts
res = matrix(ncol=5, nrow=0) 
for(prob in problems){
  for(trt in treatments){
    for(size in sizes){
      for(dil in dilutions){
        tmp = data[data$problem == prob & data$treatment == trt & data$num_tests == size & data$dilution == dil & data$found,]
        res = rbind(res, c(prob, trt, size, dil, nrow(tmp)))
      }
    }
  }
}
res_df = data.frame(data=res)
colnames(res_df) = c('problem', 'treatment', 'num_tests', 'dilution', 'solutions_found')
res_df$solutions_found = as.numeric(as.character(res_df$solutions_found))
res_df$size = as.numeric(as.character(res_df$num_tests))
res_df$prob_name = 0
res_df$trt_name = 0
res_df$size_name = 0
res_df$dil_name = 0


for(prob in problems){
  for(trt in treatments){
    for(size in sizes){
      for(dil in dilutions){
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$prob_name = prob_lookup[[prob]]
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$trt_name = trt_lookup[[toString(trt)]]
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$size_name = size_lookup[[toString(size)]]
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$dil_name = dil_lookup[[dil]]
      }
    }
  }
}
res_df$size_name = as.factor(res_df$size_name)
res_df$dil_name = as.factor(res_df$dil_name)
res_df$trt_name = as.factor(res_df$trt_name)
res_df$prob_name = as.factor(res_df$prob_name)
res_df$size_name = ordered(res_df$size_name, c(size_lookup[['100']], size_lookup[['50']], size_lookup[['25']], size_lookup[['10']], size_lookup[['5']])) 
res_df$dil_name = ordered(res_df$dil_name, c(dil_lookup[['0_00000']], dil_lookup[['0_50000']], dil_lookup[['0_75000']], dil_lookup[['0_90000']], dil_lookup[['0_95000']])) 
res_df$trt_name = ordered(res_df$trt_name, c(trt_lookup[['reduced']], trt_lookup[['downsampled']], trt_lookup[['cohort']]))
res_df$prob_name = ordered(res_df$prob_name, c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']]))

for(prob in problems){
  ggplot(data = res_df[res_df$problem == prob,], mapping=aes(x=trt_name, y=solutions_found, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=solutions_found, y = -5)) +
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    facet_grid(dil_name ~ size_name ) + ggtitle(paste(prob_lookup[[prob]], ' - Perfect Solutions Found')) +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') +
    ggsave(filename = paste('solutions_found_', prob, '.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}


##########################################################################
###############    Checking for overfit solutions    #####################
##########################################################################
res_df$training_solutions = 0

for(prob in problems){
  for(trt in treatments){
    for(size in sizes){
      for(dil in dilutions){
        tmp = data[data$problem == prob & data$treatment == trt & data$num_tests == size & data$dilution == dil & data$solved_all_training == 'True',]
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$training_solutions = nrow(tmp)
      }
    }
  }
}

for(prob in problems){
  ggplot(data = res_df[res_df$problem == prob,], mapping=aes(x=trt_name, y=solutions_found, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=solutions_found, y = -5)) +
    geom_bar(mapping = aes(x=trt_name, y=training_solutions), alpha = 0.5, stat="identity") +
    geom_text(aes(label=training_solutions, y=training_solutions), nudge_y=3) +     
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    ylab('Number of Perfect / Overfit Solutions Found') +
    xlab('Lexicase Variant') +
    facet_grid(dil_name ~ size_name ) + ggtitle(paste(prob_lookup[[prob]], ' - Perfect and Overfit Solutions'))
    ggsave(filename = paste('overfit_solutions_', prob, '.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}

##########################################################################
###############    Checking for gen 300 solutions    #####################
##########################################################################
res_df$const_time_solutions = 0

for(prob in problems){
  for(trt in treatments){
    for(size in sizes){
      for(dil in dilutions){
        tmp = data[data$problem == prob & data$treatment == trt & data$num_tests == size & data$dilution == dil & data$found & data$first_gen_found <= 300,]
        res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$const_time_solutions = nrow(tmp)
      }
    }
  }
}


for(prob in problems){
  ggplot(data = res_df[res_df$problem == prob,], mapping=aes(x=trt_name, y=const_time_solutions, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=const_time_solutions, y = -5)) +     
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') +
    facet_grid(dil_name ~ size_name ) + ggtitle(paste(prob_lookup[[prob]], ' - Perfect Solutions at 300 generations'))
  ggsave(filename = paste('const_time_', prob, '.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}


##########################################################################
##################    Charles' Requested Plots    ########################
##########################################################################
plot_dil_size = function(dil_val, size_val){
  ggplot(res_df[res_df$num_tests == size_val & res_df$dilution == dil_val,], mapping=aes(x=trt_name, y=solutions_found, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=solutions_found, y = -5)) + 
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    facet_wrap(~prob_name ) + 
    ggtitle(paste(dil_lookup[[dil_val]], ', ', size_lookup[[size_val]], sep = '')) +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') +
    ggsave(filename = paste('dil_', dil_val, '__size_', size_val,'.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}

plot_dil_size_sum = function(dil_val, size_val){
  tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val,]
  tmp_mat = matrix(ncol=3, nrow=0)
  for(prob in problems){
    tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem == prob,]
    tmp_mat = rbind(tmp_mat, c(prob, prob_lookup[[prob]], sum(tmp$solutions_found)))
  }
  tmp_df = data.frame(data=tmp_mat)
  colnames(tmp_df) = c('problem', 'prob_name', 'solutions_found')
  tmp_df$solutions_found = as.numeric(as.character(tmp_df$solutions_found))
  tmp_df$prob_name = ordered(tmp_df$prob_name, c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']]))
    ggplot(tmp_df, mapping=aes(x=prob_name, y=solutions_found)) +
    geom_bar(stat="identity", fill="#E69F00") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(hjust = NULL)) + 
    ylim(-5, 155) +
    geom_text(aes(label=solutions_found, y = -5)) + 
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    ggtitle('Total Solution Counts (No subsampling, no dilution)') +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') 
    ggsave(filename = paste('sum_dil_', dil_val, '__size_', size_val,'.png', sep=''), units = 'in', width = IMG_WIDTH/2, height = IMG_HEIGHT/2)
}

plot_dil_size_sum_overfit = function(dil_val, size_val){
  tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val,]
  tmp_mat = matrix(ncol=4, nrow=0)
  for(prob in problems){
    tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem == prob,]
    tmp_mat = rbind(tmp_mat, c(prob, prob_lookup[[prob]], sum(tmp$solutions_found), sum(tmp$training_solutions)))
  }
  tmp_df = data.frame(data=tmp_mat)
  colnames(tmp_df) = c('problem', 'prob_name', 'solutions_found', 'training_solutions')
  tmp_df$solutions_found = as.numeric(as.character(tmp_df$solutions_found))
  tmp_df$training_solutions = as.numeric(as.character(tmp_df$training_solutions))
  tmp_df$prob_name = ordered(tmp_df$prob_name, c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']], prob_lookup[['grade']]))
  ggplot(tmp_df, mapping=aes(x=prob_name, y=solutions_found)) +
    geom_bar(stat="identity", fill="#E69F00") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(hjust = NULL)) + 
    ylim(-5, 155) +
    geom_text(aes(label=solutions_found, y = -5)) + 
    geom_bar(mapping = aes(x=prob_name, y=training_solutions), alpha = 0.5, stat="identity", fill="#E69F00") +
    geom_text(aes(label=training_solutions, y=training_solutions), nudge_y=3) +     
    scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
    ggtitle('Total Solution Counts + Overfitting (No subsampling, no dilution)') +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') 
  ggsave(filename = paste('sum_overfit_dil_', dil_val, '__size_', size_val,'.png', sep=''), units = 'in', width = IMG_WIDTH/2, height = IMG_HEIGHT/2)
}

plot_dil_size_var = function(dil_val, size_val){
  tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem != 'grade',]
  tmp_mat = matrix(ncol=4, nrow=0)
  tmp$size_name = as.character(tmp$size_name)
  tmp$dil_name = as.character(tmp$dil_name)
  tmp$trt_name = as.character(tmp$trt_name)
  tmp$prob_name = as.character(tmp$prob_name)
  tmp$num_tests = as.character(tmp$num_tests)
  tmp$dilution = as.character(tmp$dilution)
  tmp$treatment = as.character(tmp$treatment)
  tmp$problem = as.character(tmp$problem)
  for(prob in problems){
    if(prob != 'grade'){
      ctrl = round(mean(res_df[res_df$num_tests == '100' & res_df$dilution == '0_00000' & res_df$problem == prob,]$solutions_found))
      tmp = rbind(tmp, c(prob, 'control', size_val, dil_val, ctrl, 10, prob_lookup[[prob]], 'Control', size_lookup[[size_val]], dil_lookup[[dil_val]], 0, 0))
      #tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem == prob,]
      #tmp_mat = rbind(tmp-_mat, c(prob, prob_lookup[[prob]], sum(tmp$solutions_found), sum(tmp$training_solutions)))
    }
  }
  tmp$size_name = as.factor(tmp$size_name)
  tmp$dil_name = as.factor(tmp$dil_name)
  tmp$trt_name = as.factor(tmp$trt_name)
  tmp$prob_name = as.factor(tmp$prob_name)
  tmp$size_name = ordered(tmp$size_name, c(size_lookup[['100']], size_lookup[['50']], size_lookup[['25']], size_lookup[['10']], size_lookup[['5']])) 
  tmp$dil_name = ordered(tmp$dil_name, c(dil_lookup[['0_00000']], dil_lookup[['0_50000']], dil_lookup[['0_75000']], dil_lookup[['0_90000']], dil_lookup[['0_95000']])) 
  tmp$trt_name = ordered(tmp$trt_name, c('Control', trt_lookup[['reduced']], trt_lookup[['downsampled']], trt_lookup[['cohort']]))
  tmp$prob_name = ordered(tmp$prob_name, c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']]))
  tmp$solutions_found = as.numeric(tmp$solutions_found)
  ggplot(tmp, mapping=aes(x=trt_name, y=solutions_found, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=solutions_found, y = -5)) + 
    scale_fill_manual(values=c("#000000", "#999999", "#E69F00", "#56B4E9")) +
    facet_wrap(~prob_name ) + 
    ggtitle(paste(dil_lookup[[dil_val]], ', ', size_lookup[[size_val]], sep = '')) +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') +
    ggsave(filename = paste('dil_', dil_val, '__size_', size_val,'.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}

plot_dil_size_var_overfit = function(dil_val, size_val){
  tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem != 'grade',]
  tmp_mat = matrix(ncol=4, nrow=0)
  tmp$size_name = as.character(tmp$size_name)
  tmp$dil_name = as.character(tmp$dil_name)
  tmp$trt_name = as.character(tmp$trt_name)
  tmp$prob_name = as.character(tmp$prob_name)
  tmp$num_tests = as.character(tmp$num_tests)
  tmp$dilution = as.character(tmp$dilution)
  tmp$treatment = as.character(tmp$treatment)
  tmp$problem = as.character(tmp$problem)
  for(prob in problems){
    if(prob != 'grade'){
      ctrl = round(mean(res_df[res_df$num_tests == '100' & res_df$dilution == '0_00000' & res_df$problem == prob,]$solutions_found))
      ctrl_overfit = round(mean(res_df[res_df$num_tests == '100' & res_df$dilution == '0_00000' & res_df$problem == prob,]$training_solutions))
      tmp = rbind(tmp, c(prob, 'control', size_val, dil_val, ctrl, 10, prob_lookup[[prob]], 'Control', size_lookup[[size_val]], dil_lookup[[dil_val]], ctrl_overfit, 0))
      #tmp = res_df[res_df$num_tests == size_val & res_df$dilution == dil_val & res_df$problem == prob,]
      #tmp_mat = rbind(tmp-_mat, c(prob, prob_lookup[[prob]], sum(tmp$solutions_found), sum(tmp$training_solutions)))
    }
  }
  tmp$size_name = as.factor(tmp$size_name)
  tmp$dil_name = as.factor(tmp$dil_name)
  tmp$trt_name = as.factor(tmp$trt_name)
  tmp$prob_name = as.factor(tmp$prob_name)
  tmp$size_name = ordered(tmp$size_name, c(size_lookup[['100']], size_lookup[['50']], size_lookup[['25']], size_lookup[['10']], size_lookup[['5']])) 
  tmp$dil_name = ordered(tmp$dil_name, c(dil_lookup[['0_00000']], dil_lookup[['0_50000']], dil_lookup[['0_75000']], dil_lookup[['0_90000']], dil_lookup[['0_95000']])) 
  tmp$trt_name = ordered(tmp$trt_name, c('Control', trt_lookup[['reduced']], trt_lookup[['downsampled']], trt_lookup[['cohort']]))
  tmp$prob_name = ordered(tmp$prob_name, c(prob_lookup[['smallest']], prob_lookup[['median']], prob_lookup[['for-loop-index']]))
  tmp$solutions_found = as.numeric(tmp$solutions_found)
  ggplot(tmp, mapping=aes(x=trt_name, y=solutions_found, fill=trt_name)) +
    geom_bar(stat="identity") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ylim(-5, 55) +
    geom_text(aes(label=solutions_found, y = -5)) + 
    geom_bar(mapping = aes(x=trt_name, y=training_solutions), alpha = 0.5, stat="identity", fill=trt_name) +
    geom_text(aes(label=training_solutions, y=training_solutions), nudge_y=3) +     
    scale_fill_manual(values=c("#000000", "#999999", "#E69F00", "#56B4E9")) +
    facet_wrap(~prob_name ) + 
    ggtitle(paste(dil_lookup[[dil_val]], ', ', size_lookup[[size_val]], sep = '')) +
    ylab('Number of Perfect Solutions Found') +
    xlab('Lexicase Variant') +
    ggsave(filename = paste('dil_', dil_val, '__size_', size_val,'.png', sep=''), units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
}


# 1: 10% discriminatory and no sub-sampling. (edited) 
# 2: 10% subsampling and no dilution.
# 3: Both turned off... (so the controls)


plot_dil_size('0_00000', '10')
plot_dil_size('0_90000', '100')
plot_dil_size('0_00000', '100')

plot_dil_size_sum('0_00000', '100')

plot_dil_size_sum_overfit('0_00000', '100')

plot_dil_size_var('0_00000', '10')
plot_dil_size_var('0_90000', '100')

plot_dil_size_var_overfit('0_00000', '10')
plot_dil_size_var_overfit('0_90000', '100')


## PLAYGROUND
## Just some helpful tidbits

# Unfinished runs
nrow(data[!data$found & data$finished != 'True',])
unfinished = data[!data$found & data$finished != 'True',]
unfinished
write.csv(unfinished, 'unfinished_gptp.csv', quote=FALSE)
