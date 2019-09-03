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
plot_diversity = function(working_name, pretty_name, x_axis = pretty_name, log_scale = F){
  ggp = ggplot(data = found, mapping=aes_string(x="factor(size_name, levels = size_levels)", y=working_name, fill="factor(trt_name, levels = trt_levels)")) +
      geom_boxplot(position = position_dodge(1, preserve = 'single'), width = 0.9, notch=F) +
      #geom_violin(position = position_dodge(1, preserve = 'single')) +
      scale_fill_manual(values=color_vec) +
      coord_flip() +
      facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
      theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
      ggtitle(pretty_name) +
      theme(plot.title = element_text(hjust = 0.5)) +
      ylab(x_axis) +
      xlab('Subsampling Level') +
      theme(axis.title = element_text(size=12)) +
      theme(axis.text =  element_text(size=10.5)) +
      theme(panel.grid.major.y = element_blank()) +
      guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T)) +
      theme(legend.position="bottom", legend.text = element_text(size=10.5))
  if(log_scale){
    ggp = ggp + scale_y_log10()
  }
  ggp = ggp + ggsave(filename = paste0('./plots/diversity_', working_name, '.pdf'), units = 'in', width = 14, height = 6)
  ggp
  
  ggp_stats = ggplot(data = found, mapping=aes_string(x="factor(size_name, levels = size_levels)", y=working_name, fill="factor(trt_name, levels = trt_levels)")) +
    geom_boxplot(position = position_dodge(1, preserve = 'single'), width = 0.9, notch=F) +
    #geom_violin(position = position_dodge(1, preserve = 'single')) +
    scale_fill_manual(values=color_vec) +
    facet_grid(factor(prob_name, levels = prob_levels) ~ .) + 
    theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
    ggtitle(pretty_name) +
    theme(plot.title = element_text(hjust = 0.5)) +
    ylab(x_axis) +
    xlab('Subsampling Level') +
    theme(axis.title = element_text(size=12)) +
    theme(axis.text =  element_text(size=10.5)) +
    theme(panel.grid.major.y = element_blank()) +
    guides(fill=guide_legend(title="Lexicase Selection Variant", reverse = T)) +
    theme(legend.position="bottom", legend.text = element_text(size=10.5))
  if(log_scale){
    ggp_stats = ggp_stats + scale_y_log10()
  }
  ggp_stats = ggp_stats + ggsave(filename = paste0('./plots/diversity_', working_name, '_stats.pdf'), units = 'in', width = 14, height = 6)
  print(ggp_stats)
  return(diversity_stats(working_name))
}

# Plot and run stats
# Set each result = stats_df to make analysis easier

# Genotypic
stats_df = plot_diversity('genotypic_diversity', 'Genotypic Diversity', 'Shannon Diversity')

# Phenotypic
stats_df = plot_diversity('behavioral_diversity', 'Phenotypic Diversity', 'Shannon Diversity')
stats_df = plot_diversity('unique_behavioral_diversity', 'Unique Phenotypic Diversity', 'Number of Unique Phenotypes')

# Phylogenetic
stats_df = plot_diversity('num_taxa', 'Number of Taxa')
stats_df = plot_diversity('current_phylogenetic_diversity', 'Phylogenetic Diversity', 'Phylogenetic Diversity')
stats_df = plot_diversity('mrca_depth', 'MRCA Depth', 'Generation')
stats_df = plot_diversity('mrca_changes', 'MRCA Changes', 'Number of Changes', T)

# Phylogenetic Richness
stats_df = plot_diversity('sum_sparse_pairwise_distances', 'Sum of Sparse Pairwise Distances')

# Phylogenetic Divergence
stats_df = plot_diversity('mean_pairwise_distance', 'Mean Pairwise Distance', 'Mean Pairwise Distance', T)
stats_df = plot_diversity('mean_sparse_pairwise_distances', 'Mean of Sparse Pairwise Distances')
stats_df = plot_diversity('mean_evolutionary_distinctiveness', 'Mean Evolutionary Distinctiveness')

# Phylogenetic Regularity
stats_df = plot_diversity('variance_pairwise_distance', 'Variance of Pairwise Distances', 'Variance of Pairwise Distances', T)
stats_df = plot_diversity('variance_sparse_pairwise_distances', 'Variance of Sparse Pairwise Distances')
stats_df = plot_diversity('variance_evolutionary_distinctiveness', 'Variance of Evolutionary Distinctiveness')

#found$mrca_norm = found$mrca_depth / found$first_gen_found 
#plot_diversity('mrca_norm', 'MRCA Depth (Normalized)', 'Percentage of Evolutionary Run')

stats_df = plot_diversity('first_gen_found', 'First Generation a Solution Appeared', 'Generation', T)
