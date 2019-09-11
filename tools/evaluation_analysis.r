rm(list=ls())

# Load external libraries
library(ggplot2)

## CONFIG OPTIONS
IMG_WIDTH = 14 #inches
IMG_HEIGHT = 8 #inches
DODGE_AMOUNT = 1.0
RM_TRUNCATED = T
RM_100_SUBS = F
LUMP_FULL = T
SET_ALL_FULL_300 = T
RM_CMP_STR_LENS = T

# Set the working directory so RStudio looks at this folder...
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output')
# Load variables (e.g., colors) that are consistent across analyses
source('../tools/shared.r')

# Read the data!
data = read.csv('evaluation_data.csv', stringsAsFactors = FALSE)

# If config option set, remove subsampled variants(reduced, cohort, and down-sampled) at 100 tests
if(RM_100_SUBS){
  data = data[data$treatment == 'full' | data$num_tests != '100',]
}

# If config option set, remove truncated lexicase entries
if(RM_TRUNCATED){
  data = data[data$treatment != 'truncated',]
}
# If config option set, set all full runs as 100 tests (which they really are)
if(LUMP_FULL & sum(data$treatment == 'full') > 0){
  data[data$treatment == 'full', ]$num_tests = '100' 
}
# The way the code is written, many 'full' jobs show as incomplete as their max_gens were changed in a weird way
if(SET_ALL_FULL_300){
  data[data$treatment == 'full' & data$max_gen >= 300,]$finished = 'True'
}

if(RM_CMP_STR_LENS){
  data = data[data$problem != 'compare-string-lengths',]
}

# Grab the configuration variables straight from the data
problems = unique(data$problem)
treatments = unique(data$treatment)
sizes = unique(data$num_tests)
dilutions = unique(data$dilution)

# Convert some 'True/False' strings to R booleans
data$found = data$solution_found == 'True'

# Calculate solution counts for each configuration
res_df = data.frame(data = matrix(ncol=6, nrow=0))
colnames(res_df) = c('problem', 'treatment', 'num_tests', 'dilution', 'solutions_found', 'num_replicates')
for(prob in problems){
  for(trt in treatments){
    for(size in sizes){
      for(dil in dilutions){
        tmp = data[data$problem == prob & data$treatment == trt & data$num_tests == size & data$dilution == dil,]
        solution_count = sum(tmp$found)
        if(trt == 'full'){
          solution_count = sum(tmp$first_gen_found > 0 & tmp$first_gen_found <= 300)
        }
        res_df[nrow(res_df) + 1,] = c(prob, trt, size, dil, solution_count, nrow(tmp))
      }
    }
  }
}
res_df$solutions_found = as.numeric(res_df$solutions_found)
res_df$num_replicates = as.numeric(res_df$num_replicates)

# Give each row prettier names for the configuration variables
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

# Turn those names into factors
res_df$size_name = as.factor(res_df$size_name)
res_df$dil_name = as.factor(res_df$dil_name)
res_df$trt_name = as.factor(res_df$trt_name)
res_df$prob_name = as.factor(res_df$prob_name)

# Calculate solution percentages
res_df$solution_pct = (res_df$solutions_found / res_df$num_replicates)
res_df$solution_pct_str = sprintf('%.3f', res_df$solution_pct)
res_df[is.nan(res_df$solution_pct), ]$solution_pct_str = ''

# Create custom gridlines
major_gridlines = c(0.0, 0.25, 0.5, 0.75, 1.0)
minor_gridlines = c(0.125, 0.375, 0.625, 0.875)
gridlines_df = data.frame(data=matrix(nrow = 0, ncol = 3))
colnames(gridlines_df) = c('y', 'prob_name', 'line_width')
for(prob_name in unique(res_df$prob_name)){
  for(major_val in major_gridlines){
    gridlines_df[nrow(gridlines_df) + 1, ] = c(major_val, prob_name, 1)
  }
  for(minor_val in minor_gridlines){
    gridlines_df[nrow(gridlines_df) + 1, ] = c(minor_val, prob_name, 2)
  }
}
gridlines_df$y = as.numeric(gridlines_df$y)

# Set our color order
color_vec = c(cohort_color, downsampled_color, reduced_color, full_color)

# Remove no subsampling runs for non-standard treatments
res_df_trimmed = res_df[res_df$num_tests != '100' | res_df$treatment == 'full',]

# Plot the perfect solution graphs (no overfitting)
ggplot(data = res_df_trimmed, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(data = res_df_trimmed, stat='identity', position = position_dodge(DODGE_AMOUNT)) +
  geom_text(aes(label=solution_pct_str, y = -0.15), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.25, 1)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(strip.text  = element_text(size = 18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size = 18)) +
  theme(axis.text   = element_text(size = 18)) +
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(legend.text = element_text(size = 18), legend.position="bottom") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size=16))) +
  guides(size=F) +
  ggsave(filename = './plots/solutions_found_evals.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)


# ##########################################################################
# ###############    Checking for overfit solutions    #####################
# ##########################################################################
# 
# Calculate the number of runs which perfectly solved the training cases
# (Also count the ones which solved all the test cases)
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

# Calculate the percentage of replicates that passed all training cases
res_df$training_pct = (res_df$training_solutions / res_df$num_replicates)
res_df$training_pct_str = sprintf('%.3f', res_df$training_pct)
res_df[is.nan(res_df$training_pct), ]$training_pct_str = ''

# Remove no subsampling runs for non-standard treatments
res_df_trimmed = res_df[res_df$num_tests != '100' | res_df$treatment == 'full',]

# Plot the overfit data
ggplot(data = res_df_trimmed, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(stat='identity', position = position_dodge(DODGE_AMOUNT)) +
  geom_text(aes(label=solution_pct_str, y = -0.2), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  geom_bar(mapping = aes(x=factor(size_name, levels = size_levels), y=training_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels)), alpha = 0.5, stat="identity", position=position_dodge(DODGE_AMOUNT), width=0.65) +
  geom_text(aes(label=training_pct_str, y=1.2), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.3, 1.3)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(strip.text  = element_text(size = 18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size = 18)) +
  theme(axis.text   = element_text(size = 18)) +
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(legend.text = element_text(size = 18), legend.position="bottom") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size=18))) +
  guides(size = F) +
  ggsave(filename = './plots/solutions_found_evals_overfit.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)



# ##########################################################################
# ########################    Miscellaneous   ##############################
# ##########################################################################
# 
# Calculate the number of unfinished runs!
unfinished = data[!data$found & data$finished != 'True',]
cat(paste0('Unfinished runs: ', nrow(unfinished), '!\n'))
if(nrow(unfinished) > 0){
  # If unfinished runs exist, see how close they were (as a percentage)!
  unfinished$target_gen = 30000 / as.numeric(unfinished$num_tests)
  unfinished$pct_gen = unfinished$max_gen / unfinished$target_gen
  unfinished = unfinished[order(unfinished$pct_gen),]
  # Print and write to a .csv!
  print(unfinished)
  write.csv(unfinished, 'unfinished_evaluations.csv', quote=FALSE)
}

##########################################################################
#########################     Statistics    ##############################
##########################################################################

stats_df = data.frame(data = matrix(nrow = 0, ncol = 13))
colnames(stats_df) = c('problem', 'treatment', 'num_tests', 'ctrl_solutions_found', 'ctrl_num_replicates', 'cond_solutions_found', 'cond_num_replicates', 'p_value', 'p_value_adj', 'significant_at_0_05', 'odds_ratio', 'lower_95_conf_int', 'upper_95_conf_int')
for(prob in problems){
  ctrl_data = res_df[res_df$problem == prob & res_df$treatment == 'full' & res_df$num_tests == '100',]
  for(trt in setdiff(treatments, 'full')){
    for(size in sizes){
      cond_data = res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size,]
      mat = matrix(nrow=2, ncol = 2)
      mat[1,1] = cond_data$solutions_found
      mat[1,2] = cond_data$num_replicates - cond_data$solutions_found
      mat[2,1] = ctrl_data$solutions_found
      mat[2,2] = ctrl_data$num_replicates - ctrl_data$solutions_found
      res = fisher.test(mat)
      stats_df[nrow(stats_df) + 1, ] = c(prob, trt, size, ctrl_data$solutions_found, ctrl_data$num_replicates, cond_data$solutions_found, cond_data$num_replicates, res$p.value, 1, F, res$estimate, res$conf.int[1], res$conf.int[2])
    }
  }
  stats_df$p_value = as.numeric(stats_df$p_value)
  stats_df$p_value_adj = as.numeric(stats_df$p_value_adj)
  stats_df[stats_df$problem == prob, ]$p_value_adj = p.adjust(stats_df[stats_df$problem == prob, ]$p_value, method = 'holm')
}
# Frustratingly, most numbers end up as strings, let's ensure that doesn't happen
stats_df$p_value              = as.numeric(stats_df$p_value)
stats_df$p_value_adj          = as.numeric(stats_df$p_value_adj)
stats_df$ctrl_solutions_found = as.numeric(stats_df$ctrl_solutions_found)
stats_df$ctrl_num_replicates  = as.numeric(stats_df$ctrl_num_replicates)
stats_df$cond_solutions_found = as.numeric(stats_df$cond_solutions_found)
stats_df$cond_num_replicates  = as.numeric(stats_df$cond_num_replicates)

stats_df$significant_at_0_05 = stats_df$p_value_adj <= 0.05
stats_df$ctrl_pct = stats_df$ctrl_solutions_found / stats_df$ctrl_num_replicates
stats_df$cond_pct = stats_df$cond_solutions_found / stats_df$cond_num_replicates
write.csv(stats_df, './stats/evals_stats.csv')

# Combine stats into res_df for plotting significance stars
res_df$significant_at_0_05 = F
res_df$stats_str = ' '
for(row in 1:nrow(res_df)){
  if(res_df[row,]$num_replicates > 0 & res_df[row,]$treatment != 'full'){
    prob = res_df[row,]$problem
    trt = res_df[row,]$treatment
    num_tests = res_df[row,]$num_tests
    res_df[row,]$significant_at_0_05 = stats_df[stats_df$problem == prob & stats_df$treatment == trt & stats_df$num_tests == num_tests,]$significant_at_0_05
    if(res_df[row,]$significant_at_0_05){
      res_df[row,]$stats_str = '*'
    }
  }
}


# Remove no subsampling runs for non-standard treatments
res_df_trimmed = res_df[res_df$num_tests != '100' | res_df$treatment == 'full',]

# Plot the non-overfit data with significance symbols
ggplot(data = res_df_trimmed, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(stat='identity', position = position_dodge(DODGE_AMOUNT)) +
  geom_text(aes(label=solution_pct_str, y = -0.25), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  geom_text(aes(label=stats_str, y = -0.05), position=position_dodge(DODGE_AMOUNT), vjust=0.8, size = (5/14) * 30) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.35, 1)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(strip.text  = element_text(size = 18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size = 18)) +
  theme(axis.text   = element_text(size = 18)) +
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(legend.text = element_text(size = 18), legend.position="bottom") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size=18))) +
  guides(size = F) +
  ggsave(filename = './plots/solutions_found_evals_stats.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)


# Plot the overfit data with significance symbols
ggplot(data = res_df_trimmed, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(stat='identity', position = position_dodge(DODGE_AMOUNT)) +
  geom_text(aes(label=solution_pct_str, y = -0.3), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  geom_text(aes(label=stats_str, y = -0.05), position=position_dodge(DODGE_AMOUNT), vjust=0.8, size = (5/14) * 30) +
  geom_bar(mapping = aes(x=factor(size_name, levels = size_levels), y=training_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels)), alpha = 0.5, stat="identity", position=position_dodge(DODGE_AMOUNT), width=0.65) +
  geom_text(aes(label=training_pct_str, y=1.22), position=position_dodge(DODGE_AMOUNT), size = (5/14) * 18) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.45, 1.35)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(strip.text  = element_text(size = 18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size = 18)) +
  theme(axis.text   = element_text(size = 18)) +
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(legend.text = element_text(size = 18), legend.position="bottom") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size=18))) +
  guides(size = F) +
  ggsave(filename = './plots/solutions_found_evals_overfit_stats.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)


