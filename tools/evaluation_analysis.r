rm(list=ls())

# Load external libraries
library(ggplot2)

## CONFIG OPTIONS
IMG_WIDTH = 14 #inches
IMG_HEIGHT = 6 #inches
RM_TRUNCATED = T
RM_100_SUBS = F
LUMP_FULL = T
SET_ALL_FULL_300 = T

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

#res_df = res_df[res_df$treatment == 'full' | res_df$num_tests != '100', ]

# Plot the perfect solution graphs (no overfitting)
# ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=solutions_found, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
#   geom_bar(stat='identity', position = 'dodge') +
#   geom_text(aes(label=solutions_found, y = -5), position=position_dodge(0.9)) +
#   scale_y_continuous(breaks = c(0, 25, 50), limits = c(-7 ,57)) +
#   scale_fill_manual(values=color_vec) +
#   coord_flip() +
#   facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
#   theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
#   ggtitle('Perfect Solutions Found - Constant Evaluations') +
#   theme(plot.title = element_text(hjust = 0.5)) +
#   ylab('Number of Perfect Solutions Found') +
#   xlab('Subsampling Level') +
#   theme(axis.title = element_text(size=12)) +
#   theme(axis.text =  element_text(size=10.5)) +
#   theme(panel.grid.major.y = element_blank()) +
#   guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
#   theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
#   ggsave(filename = 'solutions_found_evals.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

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

# Plot the perfect solution graphs (no overfitting)
ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(data = res_df, stat='identity', position = 'dodge') +
  geom_text(aes(label=solution_pct_str, y = -0.15), position=position_dodge(0.9)) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.25, 1)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  theme(plot.title = element_text(hjust = 0.5)) +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(axis.title = element_text(size=12)) +
  theme(axis.text =  element_text(size=10.5)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T)) +
  guides(size=F) +
  theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
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

# # Plot the overfit data
ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=solution_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
  geom_hline(data = gridlines_df, aes(yintercept=y, size = factor(line_width)), color ='white') +
  scale_size_manual(values = c(1, 0.5)) +
  geom_bar(stat='identity', position = 'dodge') +
  geom_text(aes(label=solution_pct_str, y = -0.15), position=position_dodge(0.9)) +
  geom_bar(mapping = aes(x=factor(size_name, levels = size_levels), y=training_pct, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels)), alpha = 0.5, stat="identity", position=position_dodge(0.9), width=0.65) +
  #geom_text(aes(label=training_pct_str, y=training_pct + 0.15), position=position_dodge(0.9)) +
  geom_text(aes(label=training_pct_str, y=1.15), position=position_dodge(0.9)) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits = c(-0.25, 1.25)) +
  scale_fill_manual(values=color_vec) +
  coord_flip() +
  facet_grid(. ~ factor(prob_name, levels = prob_levels)) +
  theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
  ggtitle('Perfect Solutions Found - Constant Evaluations') +
  theme(plot.title = element_text(hjust = 0.5)) +
  ylab('Percentage of Runs that Found Perfect Solutions') +
  xlab('Subsampling Level') +
  theme(axis.title = element_text(size=12)) +
  theme(axis.text =  element_text(size=10.5)) +
  theme(panel.grid.major.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.x = element_blank()) +
  theme(panel.grid.minor.x = element_blank()) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T)) +
  guides(size = F) +
  theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
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

stats_df = data.frame(data = matrix(nrow = 0, ncol = 10))
colnames(stats_df) = c('problem', 'treatment', 'num_tests', 'ctrl_solutions_found', 'ctrl_num_replicates', 'cond_solutions_found', 'cond_num_replicates', 'p_value', 'p_value_adj', 'significant_at_0_05')
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
      stats_df[nrow(stats_df) + 1, ] = c(prob, trt, size, ctrl_data$solutions_found, ctrl_data$num_replicates, cond_data$solutions_found, cond_data$num_replicates, res$p.value, 0, F)
    }
  }
  stats_df$p_value = as.numeric(stats_df$p_value)
  stats_df$p_value_adj = as.numeric(stats_df$p_value_adj)
  stats_df[stats_df$problem == prob, ]$p_value_adj = p.adjust(stats_df[stats_df$problem == prob, ]$p_value, method = 'holm')
}
stats_df$significant_at_0_05 = stats_df$p_value_adj <= 0.05
write.csv(stats_df, './stats/evals_stats.csv')
