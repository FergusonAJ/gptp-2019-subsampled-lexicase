rm(list=ls())
library(ggplot2)

## CONFIG OPTIONS
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output')
RM_CMP_STR_LENS = T
LUMP_FULL = T
SET_ALL_FULL_300 = T

# Load in shared vars (e.g., colors)
source('../tools/shared.r')

# Load in original run data
data = read.csv('diversity_data.csv', stringsAsFactors = FALSE)
data$solution_found = data$solution_found == 'True'
data$finished = data$finished == 'True'
data$genotypic_diversity = data$diversity

# Remove instances of the compare string lengths problem
if(RM_CMP_STR_LENS){
  data = data[data$problem != 'compare-string-lengths',]
}

# When scraping, not all full runs were marked as 100 tests and 300 generations. Fix that.
if(SET_ALL_FULL_300){
  data[data$treatment == 'full' & data$max_gen == '300', ]$finished = T
}

if(LUMP_FULL){
  data[data$treatment == 'full', ]$num_tests = '100'
}

found = data[data$solution_found,]

nrow(found[is.na(found$behavioral_diversity),])
nrow(found[is.na(found$unique_behavioral_diversity),])
nrow(found[is.na(found$ave_depth),])


# Give each row prettier names for the configuration variables
found$prob_name = 0
found$trt_name = 0
found$size_name = 0
found$dil_name = 0
for(prob in unique(found$problem)){
  for(trt in unique(found$treatment)){
    for(size in unique(found$num_tests)){
      for(dil in unique(found$dilution)){
        num_rows = nrow(found[found$problem == prob & found$treatment == trt & found$num_tests == size & found$dilution == dil,])
        if(num_rows > 0){
          found[found$problem == prob & found$treatment == trt & found$num_tests == size & found$dilution == dil,]$prob_name = prob_lookup[[prob]]
          found[found$problem == prob & found$treatment == trt & found$num_tests == size & found$dilution == dil,]$trt_name = trt_lookup[[toString(trt)]]
          found[found$problem == prob & found$treatment == trt & found$num_tests == size & found$dilution == dil,]$size_name = size_lookup[[toString(size)]]
          found[found$problem == prob & found$treatment == trt & found$num_tests == size & found$dilution == dil,]$dil_name = dil_lookup[[dil]]
        }
      }
    }
  }
}

# Turn those names into factors
found$size_name = as.factor(found$size_name)
found$dil_name = as.factor(found$dil_name)
found$trt_name = as.factor(found$trt_name)
found$prob_name = as.factor(found$prob_name)

color_vec = c(cohort_color, downsampled_color, full_color)

# Calculate statistics for the given column
diversity_stats = function(working_name){
  stats_df = data.frame(data = matrix(nrow = 0, ncol = 8))
  colnames(stats_df) = c('problem', 'num_tests', 'treatment_a', 'treatment_b', 'p_value', 'p_value_adj', 'a_solutions', 'b_solutions')
  for(prob in unique(found$problem)){
    prob_data = found[found$problem == prob,]
    ctrl_data = prob_data[prob_data$treatment == 'full', working_name]
    for(size in unique(found$num_tests)){
      cohort_data = prob_data[prob_data$treatment == 'cohort' & prob_data$num_tests == size, working_name]
      downsampled_data = prob_data[prob_data$treatment == 'downsampled' & prob_data$num_tests == size, working_name]
      mann_whitney_res_1 = wilcox.test(ctrl_data, downsampled_data, paired = F)
      stats_df[nrow(stats_df) + 1,] = c(prob, size, 'full', 'downsampled', mann_whitney_res_1$p.value, 1, length(ctrl_data), length(downsampled_data))
      mann_whitney_res_2 = wilcox.test(ctrl_data, cohort_data, paired = F)
      stats_df[nrow(stats_df) + 1,] = c(prob, size, 'full', 'cohort', mann_whitney_res_2$p.value, 1, length(ctrl_data), length(cohort_data))
      mann_whitney_res_3 = wilcox.test(cohort_data, downsampled_data, paired = F)
      stats_df[nrow(stats_df) + 1,] = c(prob, size, 'cohort', 'downsampled', mann_whitney_res_3$p.value, 1, length(cohort_data), length(downsampled_data))
    }
    stats_df$p_value = as.numeric(stats_df$p_value)
    stats_df[stats_df$problem == prob,]$p_value_adj = p.adjust(stats_df[stats_df$problem == prob,]$p_value, method = 'holm')
  }
  stats_df$p_value = as.numeric(stats_df$p_value)
  stats_df$p_value_adj = as.numeric(stats_df$p_value_adj)
  stats_df$significant_at_0_05 = stats_df$p_value_adj <= 0.05
  write.csv(stats_df, paste0('./stats/diversity_', working_name, '.csv'))
  return(stats_df)
}

# Plot the diversity boxplot for the given column
# Also set up to do statistics to make life easier
plot_diversity = function(working_name, pretty_name, x_axis = pretty_name, log_scale = F, x_axis_rot = 0, x_axis_hjust = 0.5, rm_non_full_100 = F, rm_full_100 = F){
  # If we remove lexicase, also remove the non-standard runs at 100 tests
  if(rm_full_100){
    rm_non_full_100 = T
  }
  dodge_amount = 1.15
  cohort_offset = 1.8 
  downsampled_offset = -1
  sig_from_full_char = '†'
  sig_from_subsampled_char = '‡'
  sig_from_both_str = '† ‡'
  to_plot = found
  if(rm_non_full_100){
    cohort_offset = 0.6
    downsampled_offset = -3.2
    dodge_amount = 1
    to_plot = found[found$num_tests != '100' | found$treatment == 'full',]
  }
  if(rm_full_100){
    cohort_offset = 0.4
    downsampled_offset = -3.4
    dodge_amount = 0.8
    sig_from_full_char = ''
    sig_from_subsampled_char = '†'
    sig_from_both_str = '†'
    to_plot = to_plot[to_plot$treatment != 'full',]
  }
  ggp = ggplot(data = to_plot, mapping=aes_string(x="factor(size_name, levels = size_levels)", y=working_name, fill="factor(trt_name, levels = trt_levels)")) +
      #geom_boxplot(position = position_dodge(1, preserve = 'single'), width = 0.9, notch=F) +
      geom_boxplot(position = position_dodge(1), width = 0.9, notch=F) +
      scale_fill_manual(values=color_vec) +
      coord_flip() +
      facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
      theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
      ggtitle(pretty_name) +
      ylab(x_axis) +
      xlab('Subsampling Level') +
      theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
      theme(axis.title  = element_text(size=18)) +
      theme(axis.text   = element_text(size=18)) +
      theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
      theme(legend.text = element_text(size = 18), legend.position="bottom") +
      theme(axis.text.x = element_text(angle = x_axis_rot, hjust = x_axis_hjust)) +
      theme(panel.grid.major.y = element_blank()) +
      guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18)))
  if(log_scale){
    ggp = ggp + scale_y_log10()
  }
  ggp = ggp + ggsave(filename = paste0('./plots/diversity_', working_name, '.pdf'), units = 'in', width = 14, height = 6)
  print(ggp)
  stats_df = diversity_stats(working_name)
  plot_df = data.frame(data = matrix(nrow = 0, ncol = 7))
  found$stats_str = '   '
  found$median = 0
  colnames(plot_df) = c('treatment', 'num_tests', 'problem', 'median', 'significant_at_0_05', 'y_offset', 'str')
  for(prob in unique(found$problem)){
    for(num_tests in unique(found$num_tests)){
        level_df = stats_df[stats_df$problem == prob & stats_df$num_tests == num_tests,]
        # Cohort x Full
        cohort_full = level_df[level_df$treatment_a == 'full' & level_df$treatment_b == 'cohort',]
        cohort_median = median(found[found$problem == prob & found$num_tests == num_tests & found$treatment == 'cohort', working_name])
        cohort_row = nrow(plot_df) + 1
        plot_df[cohort_row, ] = c('cohort', num_tests, prob, cohort_median, cohort_full$significant_at_0_05, cohort_offset, ifelse(cohort_full$significant_at_0_05, sig_from_full_char, ' '))
        
        # Down-sampled x Full
        downsampled_full = level_df[level_df$treatment_a == 'full' & level_df$treatment_b == 'downsampled',]
        downsampled_median = median(found[found$problem == prob & found$num_tests == num_tests & found$treatment == 'downsampled', working_name])
        downsampled_row = nrow(plot_df) + 1
        plot_df[downsampled_row, ] = c('downsampled', num_tests, prob, downsampled_median, downsampled_full$significant_at_0_05, downsampled_offset, ifelse(downsampled_full$significant_at_0_05, sig_from_full_char, ' '))
        
        # Cohort x Downsampled
        cohort_downsampled = level_df[level_df$treatment_a == 'cohort' & level_df$treatment_b == 'downsampled',]
        if(cohort_downsampled$significant_at_0_05[1 == T]){
          if(plot_df[cohort_row,]$significant_at_0_05 == T){
            plot_df[cohort_row,]$str = sig_from_both_str
          }else{
            plot_df[cohort_row,]$str = sig_from_subsampled_char
          }
          if(plot_df[downsampled_row,]$significant_at_0_05 == T){
            plot_df[downsampled_row,]$str = sig_from_both_str
          }else{
            plot_df[downsampled_row,]$str = sig_from_subsampled_char
          }
        }
    }
  }
  found$median = as.numeric(found$median)
  plot_df$median = as.numeric(plot_df$median)
  plot_df$y_offset = as.numeric(plot_df$y_offset)
  #plot_df$str = ' '
  #plot_df[plot_df$significant_at_0_05 == T,]$str = '*'
  plot_df$trt_name = ' '
  plot_df$prob_name = ' '
  plot_df$size_name = ' '
  for(row in 1:nrow(plot_df)){
    plot_df[row,]$trt_name = trt_lookup[[plot_df[row,]$treatment]]
    plot_df[row,]$prob_name = prob_lookup[[plot_df[row,]$problem]]
    plot_df[row,]$size_name = size_lookup[[plot_df[row,]$num_tests]]
  }

  to_plot = found
  plot_df_trimmed = plot_df
  if(rm_non_full_100){
    to_plot = found[found$num_tests != '100' | found$treatment == 'full',]
    plot_df_trimmed = plot_df[plot_df$num_tests != 100 | plot_df$treatment != 'lexicase',]
  }
  if(rm_full_100){
    to_plot = to_plot[to_plot$treatment != 'full',]
    plot_df_trimmed = plot_df[plot_df$num_tests != 100,]
  }
  gpp_stats = NULL
  ggp_stats = ggplot(data = to_plot, mapping=aes_string(x="factor(size_name, levels = size_levels)", y=working_name, fill="factor(trt_name, levels = trt_levels)")) +
    #geom_boxplot(position = position_dodge(1.15, preserve = 'single'), width = 0.5, notch=F) +
    geom_boxplot(position = position_dodge(dodge_amount), width = 0.5, notch=F) +
    geom_text(
      data= plot_df_trimmed, 
      mapping=aes(
        x = factor(size_name, levels = size_levels),
        label = str, 
        group = interaction(factor(size_name, levels = size_levels),factor(prob_name, levels = prob_levels)),
        y= median,
        vjust = y_offset), 
      size = (5/14) * 14
      ) +
    scale_fill_manual(values=color_vec) +
    coord_flip() +
    facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
    theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
    ggtitle(pretty_name) +
    ylab(x_axis) +
    xlab('Subsampling Level') +
    theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
    theme(axis.title  = element_text(size=18)) +
    theme(axis.text   = element_text(size=18)) +
    theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
    theme(legend.text = element_text(size = 18), legend.position="bottom") +
    theme(axis.text.x = element_text(angle = x_axis_rot, hjust = x_axis_hjust)) +
    theme(panel.grid.major.y = element_blank()) +
    guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18)))
  if(log_scale){
    ggp_stats = ggp_stats + scale_y_log10()
  }
  ggp_stats = ggp_stats + ggsave(filename = paste0('./plots/diversity_', working_name, '_stats.pdf'), units = 'in', width = 14, height = 8, device = cairo_pdf)
  print(ggp_stats)
  return(stats_df)
}

# Plot and run stats
# Set each result = stats_df to make analysis easier

# Genotypic
stats_df = plot_diversity('genotypic_diversity', 'Genotypic Diversity', 'Shannon Diversity', rm_non_full_100 = T)

# Phenotypic
stats_df = plot_diversity('behavioral_diversity', 'Phenotypic Diversity', 'Shannon Diversity', rm_non_full_100 = T)
stats_df = plot_diversity('unique_behavioral_diversity', 'Unique Phenotypic Diversity', 'Number of Unique Phenotypes', rm_non_full_100 = T)

# Phylogenetic
stats_df = plot_diversity('num_taxa', 'Number of Taxa', rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('num_sparse_taxa', 'Number of Sparse Taxa', rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('current_phylogenetic_diversity', 'Phylogenetic Diversity', 'Nodes in Minimum Spanning Tree', rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('mrca_depth', 'MRCA Depth', 'Generation', rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('mrca_changes', 'Most Recent Common Ancestor (MRCA) Changes', 'Number of Changes', T, rm_non_full_100 = T, rm_full_100 = T)

# Phylogenetic Richness
stats_df = plot_diversity('sum_sparse_pairwise_distances', 'Sum of Sparse Pairwise Distances', 'Sum', x_axis_rot = 45, x_axis_hjust = 1, rm_non_full_100 = T, rm_full_100 = T)

# Phylogenetic Divergence
stats_df = plot_diversity('mean_pairwise_distance', 'Mean Pairwise Distance', 'Mean Distance', T, rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('mean_sparse_pairwise_distances', 'Mean Sparse Pairwise Distance', 'Mean of Distance', x_axis_rot = 0, x_axis_hjust = 0.5, rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('mean_evolutionary_distinctiveness', 'Mean Evolutionary Distinctiveness', rm_non_full_100 = T, rm_full_100 = T)

# Phylogenetic Regularity
stats_df = plot_diversity('variance_pairwise_distance', 'Variance of Pairwise Distances', 'Variance of Pairwise Distances', T, x_axis_rot = 45, x_axis_hjust = 1, rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('variance_sparse_pairwise_distances', 'Variance of Sparse Pairwise Distances', 'Variance of Distances', rm_non_full_100 = T, rm_full_100 = T)
stats_df = plot_diversity('variance_evolutionary_distinctiveness', 'Variance of Evolutionary Distinctiveness', rm_non_full_100 = T, rm_full_100 = T)
# 
# #found$mrca_norm = found$mrca_depth / found$first_gen_found
# #stats_df = plot_diversity('mrca_norm', 'MRCA Depth (Normalized)', 'Percentage of Evolutionary Run')
# 
# stats_df = plot_diversity('first_gen_found', 'First Generation a Solution Appeared', 'Generation', T)
