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
source('shared.r')

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
  guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
  guides(size=F) +
  theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
  ggsave(filename = 'solutions_found_evals.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)


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

# # Plot the perfect + overfit solution graphs
# ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=solutions_found, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
#   geom_bar(stat='identity', position = 'dodge') +
#   geom_text(aes(label=solutions_found, y = -5), position=position_dodge(0.9)) +
#   geom_bar(mapping = aes(x=factor(size_name, levels = size_levels), y=training_solutions, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels)), alpha = 0.5, stat="identity", position=position_dodge(0.9), width=0.65) +
#   geom_text(aes(label=training_solutions, y=training_solutions + 5), position=position_dodge(0.9)) +
#   scale_y_continuous(breaks = c(0, 25, 50), limits = c(-7 ,57)) +
#   scale_fill_manual(values=color_vec) +
#   coord_flip() +
#   facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
#   theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
#   ggtitle('Perfect and Overfit Solutions - Constant Evaluations') +
#   theme(plot.title = element_text(hjust = 0.5)) +
#   ylab('Number of Perfect Solutions Found') +
#   xlab('Subsampling Level') +
#   theme(axis.title = element_text(size=12)) +
#   theme(axis.text =  element_text(size=10.5)) +
#   theme(panel.grid.major.y = element_blank()) +
#   guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
#   theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
#   ggsave(filename = 'solutions_found_evals_overfit.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

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
  guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
  guides(size = F) +
  theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
  ggsave(filename = 'solutions_found_evals_overfit.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

# # 
# # 
# # ##########################################################################
# # ###############    Checking for gen 300 solutions    #####################
# # ##########################################################################
# # 
# # Calculate the number of replicates for each configuration that solved all the test
# #   cases at a measly 300 generations
# res_df$const_time_solutions = 0
# for(prob in problems){
#   for(trt in treatments){
#     for(size in sizes){
#       for(dil in dilutions){
#         tmp = data[data$problem == prob & data$treatment == trt & data$num_tests == size & data$dilution == dil & data$found & data$first_gen_found <= 300,]
#         res_df[res_df$problem == prob & res_df$treatment == trt & res_df$num_tests == size & res_df$dilution == dil,]$const_time_solutions = nrow(tmp)
#       }
#     }
#   }
# }
# 
# # Plot the number of replicates that solved the problem in <= 300 generations
# ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=const_time_solutions, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
#   geom_bar(stat='identity', position = 'dodge') +
#   geom_text(aes(label=const_time_solutions, y = -5), position=position_dodge(0.9)) +
#   scale_y_continuous(breaks = c(0, 25, 50), limits = c(-7 ,57)) +
#   scale_fill_manual(values=color_vec) +
#   coord_flip() +
#   facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
#   theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
#   ggtitle('Perfect Solutions Found - Constant Generations') +
#   theme(plot.title = element_text(hjust = 0.5)) +
#   ylab('Number of Perfect Solutions Found') +
#   xlab('Subsampling Level') +
#   theme(axis.title = element_text(size=12)) +
#   theme(axis.text =  element_text(size=10.5)) +
#   theme(panel.grid.major.y = element_blank()) +
#   guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
#   theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
#   ggsave(filename = 'solutions_found_gens.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
# 
# # Plot the number of <= 300 gen solutions with the constant eval bars (the first plot) as shadows
# ggplot(data = res_df, mapping=aes(x=factor(size_name, levels = size_levels), y=const_time_solutions, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels))) +
#   geom_bar(stat='identity', position = 'dodge') +
#   geom_text(aes(label=const_time_solutions, y = -5), position=position_dodge(0.9)) +
#   geom_bar(mapping = aes(x=factor(size_name, levels = size_levels), y=solutions_found, fill=factor(trt_name, levels = trt_levels), group=factor(trt_name, levels = trt_levels)), alpha = 0.5, stat="identity", position=position_dodge(0.9), width=0.65) +
#   geom_text(aes(label=solutions_found, y=solutions_found + 5), position=position_dodge(0.9)) +
#   scale_y_continuous(breaks = c(0, 25, 50), limits = c(-7 ,57)) +
#   scale_fill_manual(values=color_vec) +
#   coord_flip() +
#   facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
#   theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
#   ggtitle('Perfect Solutions Found - Constant Generations vs Constant Evaluations') +
#   theme(plot.title = element_text(hjust = 0.5)) +
#   ylab('Number of Perfect Solutions Found') +
#   xlab('Subsampling Level') +
#   theme(axis.title = element_text(size=12)) +
#   theme(axis.text =  element_text(size=10.5)) +
#   theme(panel.grid.major.y = element_blank()) +
#   guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
#   theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
#   ggsave(filename = 'solutions_found_gens_vs_evals.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)



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
  write.csv(unfinished, 'unfinished_gptp.csv', quote=FALSE)
}
# 
# # Check which configurations did not hit the 50% solve rate in the allotted time (in evals)
# res_df[res_df$solutions_found < 25 & (res_df$treatment != 'reduced' | res_df$size == 100),]
# 
# # Finish! :^)
# cat('Done!\n')
# 
# # For the plots that Charles requested for the GPTP conference, see data_analysis.r
# #   Warning: Do so at your own risk. That file contains awful code with no comments written
# #   at around 2 am...
# 
# prob = 'smallest'
# ggplot(data = res_df[res_df$problem == prob,], mapping=aes(x=factor(trt_name, levels = trt_levels), y=const_time_solutions, fill=trt_name)) +
#   geom_bar(stat="identity") +
#   guides(fill=FALSE) +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1, size=10)) + ylim(-5, 55) +
#   geom_text(aes(label=const_time_solutions, y = -5)) +
#   geom_bar(mapping = aes(x=trt_name, y=solutions_found), alpha = 0.5, stat="identity") +
#   geom_text(aes(label=solutions_found, y=solutions_found), nudge_y=3) +
#   scale_fill_manual(values=color_vec) +
#   ylab('Number of Perfect Solutions Found') +
#   xlab('Lexicase Variant') +
#   facet_grid(. ~ factor(size_name, levels=size_levels)) + ggtitle(paste(prob_lookup[[prob]], ' - Perfect Solutions at 300 generations')) + 
#   ggsave(filename = paste('test-', prob, '.pdf', sep=''), units = 'in', width = 10, height = 6)
# 


# pairwise_fisher = function(data, adjust_method = 'bonferroni'){
#   nrows = nrow(data)
#   res = matrix(
#     ncol = nrows, 
#     nrow = nrows, 
#     dimnames = list(
#       rownames(data),
#       rownames(data)
#     ))
#   
#   for(i in 1:(nrows - 1)){
#     for(j in (i+1):nrows){
#       #cat(i, ' ', j, '\n')
#       tmp = fisher.test(data[c(i,j),])
#       res[i,j] = tmp$p.value
#     }
#   }
#   as.numeric(res)
#   adjusted_vals = p.adjust(as.numeric(res), method = adjust_method)  
#   adjusted_res = matrix(
#     data = adjusted_vals,
#     ncol = nrows, 
#     nrow = nrows, 
#     dimnames = list(
#       rownames(data),
#       rownames(data)
#     ))
#   for(i in 1:(nrows - 1)){
#     for(j in (i+1):nrows){
#       adjusted_res[j,i] = adjusted_res[i,j]
#     }
#   }
#   return(adjusted_res)
# }
# 
# # Do stats on problem solving rates (Constant evaluations)
# stats_df = res_df[, c('prob_name', 'trt_name', 'size_name', 'solutions_found')]
# stats_df$config = paste(stats_df$trt_name, stats_df$size_name, sep = '_')
# for(prob in unique(res_df$problem)){
#   prob_name = prob_lookup[[prob]]
#   print(stats_df[stats_df$prob_name == prob_name,])
#   cat('Problem: ', prob_name, '\n')
#   prob_stats_df = stats_df[stats_df$prob_name == prob_name, c('config', 'solutions_found')]
#   prob_stats_df$solutions_not_found = 50 - prob_stats_df$solutions_found
#   rownames(prob_stats_df) = prob_stats_df$config
#   prob_stats_matrix = matrix(
#       data = c(as.numeric(prob_stats_df$solutions_found), as.numeric(prob_stats_df$solutions_not_found)),
#       nrow = nrow(prob_stats_df),
#       ncol = 2, 
#       dimnames = list(prob_stats_df$config, c('Successes', 'Failures'))
#   )
#   print(prob_stats_matrix)
#   stats_res = pairwise_fisher(prob_stats_matrix, adjust_method='holm')
#   print(stats_res)
#   write.csv(stats_res, paste0('eval_stats_', prob, '.csv'))
#   write.csv(stats_res <= 0.05, paste0('eval_stats_boolean_', prob, '.csv'))
# }
# 
# rm('stats_df') # So I can reuse the variable...
# 
# # Do stats on problem solving rates (Constant generations)
# stats_df = res_df[, c('prob_name', 'trt_name', 'size_name', 'const_time_solutions')]
# stats_df$config = paste(stats_df$trt_name, stats_df$size_name, sep = '_')
# for(prob in unique(res_df$problem)){
#   prob_name = prob_lookup[[prob]]
#   print(stats_df[stats_df$prob_name == prob_name,])
#   cat('Problem: ', prob_name, '\n')
#   prob_stats_df = stats_df[stats_df$prob_name == prob_name, c('config', 'const_time_solutions')]
#   prob_stats_df$solutions_not_found = 50 - prob_stats_df$const_time_solutions
#   rownames(prob_stats_df) = prob_stats_df$config
#   prob_stats_matrix = matrix(
#     data = c(as.numeric(prob_stats_df$const_time_solutions), as.numeric(prob_stats_df$solutions_not_found)),
#     nrow = nrow(prob_stats_df),
#     ncol = 2, 
#     dimnames = list(prob_stats_df$config, c('Successes', 'Failures'))
#   )
#   print(prob_stats_matrix)
#   stats_res = pairwise_fisher(prob_stats_matrix, adjust_method='holm')
#   print(stats_res)
#   write.csv(stats_res, paste0('gen_stats_', prob, '.csv'))
#   write.csv(stats_res <= 0.05, paste0('gen_stats_boolean_', prob, '.csv'))
# }
# 
# 
# # Do stats on the effect of the added generations
# stats_res_df = data.frame(data=matrix(nrow = 0, ncol = 5))
# stats_against_
# for(prob in unique(res_df$problem)){
#   for(size in unique(res_df$num_tests)){
#     for(trt in unique(res_df$treatment)){
#       tmp_df = res_df[res_df$problem == prob & res_df$num_tests == size & res_df$treatment == trt,]
#       mat = matrix(ncol = 2, nrow = 2)
#       colnames(mat) = c('Y', 'N')
#       rownames(mat) = c('gens', 'evals')
#       num_solutions_gens = tmp_df$const_time_solutions
#       num_solutions = tmp_df$solutions_found
#       mat[1,1] = num_solutions_gens
#       mat[1,2] = 50 - num_solutions_gens
#       mat[2,1] = num_solutions
#       mat[2,2] = 50 - num_solutions
#       print(mat)
#       fisher_res = fisher.test(mat)
#       print(fisher_res$p.value)
#       print(fisher_res$p.value <= 0.05)
#       stats_res_df = rbind(stats_res_df, c(prob, size, trt, num_solutions, num_solutions_gens, fisher_res$p.value), stringsAsFactors = F)
#     } 
#   } 
# }
# colnames(stats_res_df) = c('problem', 'num_tests', 'treatment', 'solutions_found', 'const_time_solutions_found', 'p_value')
# stats_res_df$p_value = as.numeric(stats_res_df$p_value)
# stats_res_df$significant = stats_res_df$p_value <= 0.05
# write.csv(stats_res_df, 'gens_stats_all.csv')
# 
# # Whittle down some of the things we know will not be significant
# stats_trimmed = stats_res_df
# stats_trimmed = stats_trimmed[stats_trimmed$num_tests != '100',]
# write.csv(stats_res_df, 'gens_stats_trimmed.csv')
