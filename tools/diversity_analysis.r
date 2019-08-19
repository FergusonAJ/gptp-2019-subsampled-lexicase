rm(list=ls())
library(ggplot2)

## CONFIG OPTIONS
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output')

# Load in shared vars (e.g., colors)
source('../tools/shared.r')

# Load in original run data
data = read.csv('diversity_data.csv', stringsAsFactors = FALSE)
data$solution_found = data$solution_found == 'True'
data$finished = data$finished == 'True'

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

# trt_levels = c('reduced', 'downsampled', 'cohort')
# 
# ggplot(found, aes(x = factor(num_tests, levels = c('100', '50', '25', '10', '5')), y = behavioral_diversity, fill = factor(treatment, levels=trt_levels))) + 
#   geom_boxplot(position=position_dodge(0.6), width = 0.5) + 
#   scale_fill_manual(values = color_vec) +
#   scale_x_discrete() + 
#   facet_grid(rows = vars(problem))#, cols = vars(factor(num_tests, levels = c('100', '50', '25', '10', '5'))))

color_vec = c(cohort_color, downsampled_color, reduced_color)

plot_diversity = function(working_name, pretty_name, log_scale = F){
  ggp = ggplot(data = found, mapping=aes_string(x="factor(size_name, levels = size_levels)", y=working_name, fill="factor(trt_name, levels = trt_levels)")) +
      geom_boxplot(position = position_dodge(0.6), width = 0.5, notch=F) +
      scale_fill_manual(values=color_vec) +
      coord_flip() +
      facet_grid(. ~ factor(prob_name, levels = prob_levels)) + 
      theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
      ggtitle(pretty_name) +
      theme(plot.title = element_text(hjust = 0.5)) +
      ylab(pretty_name) +
      xlab('Subsampling Level') +
      theme(axis.title = element_text(size=12)) +
      theme(axis.text =  element_text(size=10.5)) +
      theme(panel.grid.major.y = element_blank()) +
      guides(fill=guide_legend(title="Selection Scheme", reverse = T)) +
      theme(legend.position="bottom", legend.text = element_text(size=10.5))
  if(log_scale){
    ggp = ggp + scale_y_log10()
  }
  ggp = ggp + ggsave(filename = paste0('./plots/diversity_', working_name, '.pdf'), units = 'in', width = 14, height = 6)
  ggp
}

plot_diversity('behavioral_diversity', 'Behavioral Diversity')
plot_diversity('unique_behavioral_diversity', 'Unique Behavioral Diversity')
plot_diversity('mean_pairwise_distance', 'Mean Pairwise Distance')
plot_diversity('diversity', 'Genotypic Diversity')
plot_diversity('num_taxa', 'Number of Taxa')
plot_diversity('current_phylogenetic_diversity', 'Phylogenetic Diversity')
plot_diversity('mean_evolutionary_distinctiveness', 'Mean Evolutionary Distinctiveness')
plot_diversity('mrca_depth', 'MRCA Depth')
plot_diversity('mrca_changes', 'MRCA Changes', T)
plot_diversity('variance_pairwise_distance', 'Variance of Pairwise Distances', T)
plot_diversity('mean_sparse_pairwise_distances', 'Mean pf Sparse Pairwise Distances')
plot_diversity('variance_sparse_pairwise_distances', 'Variance of Sparse Pairwise Distances')
plot_diversity('sum_sparse_pairwise_distances', 'Sum of Sparse Pairwise Distances')
found$mrca_norm = found$mrca_depth / found$first_gen_found 
plot_diversity('mrca_norm', 'MRCA Depth (Normalized)')

plot_diversity('first_gen_found', 'First Generation a Solution Appeared', T)
