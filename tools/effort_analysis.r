rm(list=ls())
library(ggplot2)

## CONFIG OPTIONS
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output')

# Load in shared data
source('../tools/shared.r')


# Load data, convert string 'True'/'False' to R booleans
data = read.csv('effort_data.csv')
data$solution_found = data$solution_found == 'True'

# Filter out runs with no results
data = data[data$solution_found,]


# Grab all configuration variables present
problems = as.character(unique(data$problem))
sizes = as.character(unique(data$num_tests))
treatments = as.character(unique(data$treatment))


# Create and fill data frame to show how many successful runs were present in each configuration
count_df = data.frame(data=matrix(nrow=0, ncol=4))
for(prob in problems){
 for(size in sizes){
   for(trt in treatments){
     trt_df = data[data$problem == prob & data$num_tests == size & data$treatment == trt,]
     count_df = rbind(count_df, c(prob, size, trt, sum(trt_df$solution_found)), stringsAsFactors=F)
   }
 }
}
colnames(count_df) = c('problem', 'num_tests', 'treatment', 'solution_count')

# We only have full runs at 0% subsampling and subsampled at 10% subsampling
#   So filter accordingly to remove any unneccesary zeros!
count_df = count_df[count_df$treatment == 'full' | count_df$num_tests != '100',]
count_df = count_df[count_df$treatment != 'full' | count_df$num_tests == '100',]

# Check to make sure enough runs finished!
min_count = min(count_df$solution_count)
if(min_count < 25){
  print(paste0('Error! Not enough runs! Wanted 25, min = ', min_count))
}

# No we need to filter down the main data set so all treatments in a problem x size combo
#   have the same number of solution counts
filtered_data = data.frame(data = matrix(nrow = 0, ncol = ncol(data)))
desired_count = 25
for(prob in problems){
  for(size in sizes){
    for(trt in treatments){
      trt_df = data[data$problem == prob & data$num_tests == size & data$treatment == trt,]
      if(nrow(trt_df) > 0){
        trt_df = trt_df[order(trt_df$evals),]
        filtered_data = rbind(filtered_data, trt_df[1:desired_count, ])
      }
    }
  }
}

# We ended up rerunning this experiment to only show the 10% level, so we let's modify our legend
trt_lookup[['downsampled']] = 'Down-sampled (10%)'
trt_lookup[['cohort']] = 'Cohort  (10%)'
trt_lookup[['truncated']] = 'Truncated  (10%)'

# Give each row prettier names for the configuration variables
filtered_data$prob_name = 0
filtered_data$trt_name = 0
filtered_data$size_name = 0
filtered_data$dil_name = 0
for(prob in unique(filtered_data$problem)){
  for(trt in unique(filtered_data$treatment)){
    for(size in unique(filtered_data$num_tests)){
      for(dil in unique(filtered_data$dilution)){
        if(nrow(filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt & filtered_data$num_tests == size & filtered_data$dilution == dil,]) > 0){
          #cat(prob, ' ', trt, ' ', size, ' ', dil, '\n')
          filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt & filtered_data$num_tests == size & filtered_data$dilution == dil,]$prob_name = prob_lookup[[prob]]
          filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt & filtered_data$num_tests == size & filtered_data$dilution == dil,]$trt_name = trt_lookup[[toString(trt)]]
          filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt & filtered_data$num_tests == size & filtered_data$dilution == dil,]$size_name = size_lookup[[toString(size)]]
          filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt & filtered_data$num_tests == size & filtered_data$dilution == dil,]$dil_name = dil_lookup[[dil]]
        }
      }
    }
  }
}


# Change full to "Standard Lexicase"
filtered_data[filtered_data$treatment == 'full',]$trt_name = 'Standard'
# And modify the order to match
trt_levels = c(trt_lookup[['truncated']], trt_lookup[['cohort']], trt_lookup[['downsampled']], 'Standard')
# Set our color order
color_vec = c(truncated_color, cohort_color, downsampled_color, full_color)


# Turn those names into factors
filtered_data$size_name = as.factor(filtered_data$size_name)
filtered_data$dil_name = as.factor(filtered_data$dil_name)
filtered_data$trt_name = as.factor(filtered_data$trt_name)
filtered_data$prob_name = as.factor(filtered_data$prob_name)

# (gg)Plot! 
x_scale_size = 0.8
ggplot(filtered_data, aes(x = 0, y = evals, fill=factor(trt_name, levels=trt_levels))) +
  geom_boxplot(position = position_dodge(1.5), width=1) +
  facet_grid(cols = vars(factor(prob_name, levels=prob_levels))) +
  ggtitle('Computational Effort') +
  scale_y_log10() +
  scale_x_continuous(limits = c(-x_scale_size, x_scale_size)) +
  scale_fill_manual(values = color_vec) +
  ylab('Number of Evaluations') +
  ggtitle('Computational Effort') +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill=guide_legend(title="Lexicase Selection Variant", reverse=T)) +
  theme(strip.text = element_text(size=10.5, face = 'bold')) + # For the facet labels
  theme(axis.title = element_text(size=12)) +
  theme(axis.text =  element_text(size=10.5)) +
  theme(axis.ticks.y= element_blank()) +
  theme(axis.title.y = element_blank()) +
  theme(axis.text.y = element_blank()) +
  theme(panel.grid.minor.y = element_blank()) +
  theme(panel.grid.major.y =  element_blank()) +
  theme(legend.position="bottom", legend.text = element_text(size=10.5)) +
  coord_flip() +
  ggsave('./plots/computational_effort.pdf', units = 'in', width = 14, height = 4)


# Run the stats
# Kruskal-wallis to test for any effect across all treatments (hint: they all have one)
# Then do a Mann-Whitney comparison (i.e., unpaired Wilcox) between standard and each treatment
# Holm correction is used for multiple comparisons
stats_df = data.frame(data = matrix(nrow = 0, ncol = 5))
colnames(stats_df) = c('problem', 'treatment', 'kruskal_p_value', 'p_value', 'p_value_adj')
for(prob in unique(filtered_data$problem)){
  prob_name = prob_lookup[[prob]]
  cat('Problem: ', prob_name, '\n')
  kruskal_res = kruskal.test(evals ~ treatment, data = filtered_data[filtered_data$problem == prob,])
  cat('p-value:', kruskal_res$p.value, '\n\n')
  if(kruskal_res$p.value < 0.05){
    ctrl_data = filtered_data[filtered_data$problem == prob & filtered_data$treatment == 'full',]
    for(trt in setdiff(treatments, c('full'))){
      trt_data = filtered_data[filtered_data$problem == prob & filtered_data$treatment == trt,]
      wilcox_res = wilcox.test(ctrl_data$evals, trt_data$evals, paired=F)
      stats_df[nrow(stats_df) + 1,] = c(prob, trt, kruskal_res$p.value, wilcox_res$p.value, 0)
    }
    stats_df$p_value = as.numeric(stats_df$p_value)
    stats_df[stats_df$problem == prob,]$p_value_adj = p.adjust(stats_df[stats_df$problem == prob,]$p_value, method = 'holm')
  }
  else{
    stats_df[nrow(stats_df) + 1,] = c(prob, trt, kruskal_res$p.value, 'NA', 'NA')
  }
}
stats_df$kruskal_p_value = as.numeric(stats_df$kruskal_p_value)
stats_df$p_value = as.numeric(stats_df$p_value)
stats_df$p_value_adj = as.numeric(stats_df$p_value_adj)
stats_df$significant_at_0_05 = stats_df$p_value_adj <= 0.05
print(stats_df)
write.csv(stats_df, './stats/effort_stats.csv')
print('Finished!')