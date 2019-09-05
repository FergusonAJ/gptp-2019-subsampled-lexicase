rm(list=ls())
library(ggplot2)
library(stringr)

## CONFIG OPTIONS
IMG_WIDTH = 14 #inches

IMG_HEIGHT = 8 #inches
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output')

# Load in shared data (colors)
source('../tools/shared.r')

color_vec = c(cohort_color, downsampled_color, full_color)

# Load the data! (It's a large file!)
clean = read.csv('specialist_data.csv')

# Grab the specialist probability from the correct column (depends on pop_size unfortunately)
data = clean
pop_sizes = unique(data$pop_size)
data$specialist_prob = 0
for(pop_size in pop_sizes){
  data[data$pop_size == pop_size,]$specialist_prob = data[data$pop_size == pop_size, paste0('X', as.numeric(pop_size - 1))]
}

# Filter the data for plotting
data = data[is.element(data$pass_prob, c('1', '0_5', '0_2')),]
data = data[is.element(data$treatment, c('lexicase', 'downsampled_0_5', 'downsampled_0_1', 'cohort_0_5', 'cohort_0_1')),]
data = data[is.element(data$pop_size, c('20', '100')),]
data = data[is.element(data$num_tests, ('20')),]


# Grab the subsample rate from the treatment name (Sorry for the hardcode!)
data$subsample_rate = 1
#TODO: Automate this...
data[data$treatment == 'cohort_0_5' | data$treatment == 'downsampled_0_5', ]$subsample_rate = 0.5
data[data$treatment == 'cohort_0_1' | data$treatment == 'downsampled_0_1', ]$subsample_rate = 0.1

# Filter out some unwanted cases
# e.g., when cohort size = 1 (So everyone gets picked!)
data = data[data$subsample_rate * as.numeric(data$num_tests) >= 1,]
data = data[data$subsample_rate * as.numeric(data$pop_size) > 1,]
data = data[(data$subsample_rate * as.numeric(data$pop_size)) %% 1 == 0,]
data = data[(data$subsample_rate * as.numeric(data$num_tests)) %% 1 == 0,]
data = data[!is.na(data$specialist_prob),]


# Duplicate lexicase data for the plot (no stats here, so this should be okay!)
lex_data = data[data$treatment == 'lexicase',]
lex_data$subsample_rate = 0.1
data[data$treatment == 'lexicase',]$subsample_rate = 0.5
data = rbind(data, lex_data)

# Assign pretty names for plotting!
data$trt_name = ''
data[data$treatment == 'lexicase',]$trt_name = 'Standard'
data[str_count(data$treatment, 'cohort') >= 1,]$trt_name = 'Cohort'
data[str_count(data$treatment, 'downsampled') >= 1,]$trt_name = 'Down-sampled'
data$pass_prob_name = paste0(as.character(100 * as.numeric(str_replace(data$pass_prob, '_', '\\.'))), '% Non-focal Candidate\nSolution Pass Rate')
data$pass_prob_name = factor(data$pass_prob_name, levels = c('20% Non-focal Candidate\nSolution Pass Rate', '50% Non-focal Candidate\nSolution Pass Rate', '100% Non-focal Candidate\nSolution Pass Rate'))
data$subsample_name = paste0(as.character(round(data$subsample_rate * 100, 0)), '% Subsampling')

# Plot the experimental data!
ggplot(data, aes(x = as.factor(pop_size), y = specialist_prob, color=trt_name)) +
  geom_boxplot(position = position_dodge(0.85), width = 0.8) +
  #geom_jitter(alpha = 0.1, position=position_jitterdodge(jitter.width = 0.15, dodge.width = 0.9)) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_discrete() +
  facet_grid(cols = vars(pass_prob_name), rows = vars(subsample_name)) +
  scale_color_manual(values = color_vec) +
  theme(panel.grid.minor.x = element_blank()) +
  xlab('Population Size') +
  ylab('Specialist Survival Chance') +
  ggtitle('Specialist Preservation Probability') +
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  ggsave(filename = './plots/specialist_experimental.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
  

# Gather data such that we can plot as a bar plot
bar_df = data.frame(data = matrix(nrow = 0, ncol = 13))
colnames(bar_df) = c('pop_size', 'pass_prob', 'subsample_rate', 'treatment', 'trt_name', 'pass_prob_name', 'subsample_name', 'prob_median', 'prob_min', 'prob_max', 'prob_var', 'prob_sd', 'prob_mean')
for(pop_size in unique(data$pop_size)){
  for(pass_prob in unique(data$pass_prob)){
    for(subsample_rate in unique(data$subsample_rate)){
      for(trt in unique(data$treatment)){
        tmp = data[data$pop_size == pop_size & data$pass_prob == pass_prob & data$subsample_rate == subsample_rate & data$treatment == trt,]
        if(nrow(tmp) > 0){
          specialist_probs = tmp$specialist_prob
          print(paste(pop_size, pass_prob, tmp$subsample_rate[1], trt, length(specialist_probs)))
          bar_df[nrow(bar_df) + 1, ] = c(pop_size, pass_prob, tmp$subsample_rate[1], trt, tmp$trt_name[1], as.character(tmp$pass_prob_name[1]), tmp$subsample_name[1], median(specialist_probs), min(specialist_probs), max(specialist_probs), var(specialist_probs), sd(specialist_probs), mean(specialist_probs))
        }
      }
    }
  }
}
bar_df$prob_median = as.numeric(bar_df$prob_median)
bar_df$prob_min = as.numeric(bar_df$prob_min)
bar_df$prob_max = as.numeric(bar_df$prob_max)
bar_df$prob_var = as.numeric(bar_df$prob_var)
bar_df$prob_sd = as.numeric(bar_df$prob_sd)
bar_df$prob_mean = as.numeric(bar_df$prob_mean)
bar_df$pass_prob_name = factor(bar_df$pass_prob_name, levels = c('20% Non-focal Candidate\nSolution Pass Rate', '50% Non-focal Candidate\nSolution Pass Rate', '100% Non-focal Candidate\nSolution Pass Rate'))

# Error bars for the standard deviation (median)
ggplot(bar_df,aes(x = factor(pop_size, levels=c(20, 100)), y = prob_median, fill=trt_name)) +
  geom_col(position = position_dodge(0.85), width = 0.8) + 
  geom_errorbar(aes(ymin = prob_median + prob_sd, ymax = prob_median - prob_sd), position = position_dodge(0.85), width = 0.4) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_discrete() +
  facet_grid(cols = vars(pass_prob_name), rows = vars(subsample_name)) +
  scale_fill_manual(values = color_vec) +
  scale_color_manual(values = color_vec) +
  theme(panel.grid.minor.x = element_blank()) +
  xlab('Population Size') +
  ylab('Specialist Survival Chance') +
  ggtitle('Specialist Preservation Probability') +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill =guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  ggsave(filename = './plots/specialist_experimental_bars_median_std_dev.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

# Error bars for the minimum and maximum (median)
ggplot(bar_df,aes(x = factor(pop_size, levels=c(20, 100)), y = prob_median, fill=trt_name)) +
  geom_col(position = position_dodge(0.85), width = 0.8) + 
  geom_errorbar(aes(ymin = prob_min, ymax = prob_max), position = position_dodge(0.85), width = 0.4) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_discrete() +
  facet_grid(cols = vars(pass_prob_name), rows = vars(subsample_name)) +
  scale_fill_manual(values = color_vec) +
  scale_color_manual(values = color_vec) +
  theme(panel.grid.minor.x = element_blank()) +
  xlab('Population Size') +
  ylab('Specialist Survival Chance') +
  ggtitle('Specialist Preservation Probability') +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill =guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  ggsave(filename = './plots/specialist_experimental_bars_median_min_max.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

# Error bars for the standard deviation (mean)
ggplot(bar_df,aes(x = factor(pop_size, levels=c(20, 100)), y = prob_mean, fill=trt_name)) +
  geom_col(position = position_dodge(0.85), width = 0.8) + 
  geom_errorbar(aes(ymin = prob_mean + prob_sd, ymax = prob_mean - prob_sd), position = position_dodge(0.85), width = 0.4) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_discrete() +
  facet_grid(cols = vars(pass_prob_name), rows = vars(subsample_name)) +
  scale_fill_manual(values = color_vec) +
  scale_color_manual(values = color_vec) +
  theme(panel.grid.minor.x = element_blank()) +
  xlab('Population Size') +
  ylab('Specialist Survival Chance') +
  ggtitle('Specialist Preservation Probability') +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill =guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  ggsave(filename = './plots/specialist_experimental_bars_mean_std_dev.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)

# Error bars for the minimum and maximum (mean)
ggplot(bar_df,aes(x = factor(pop_size, levels=c(20, 100)), y = prob_mean, fill=trt_name)) +
  geom_col(position = position_dodge(0.85), width = 0.8) + 
  geom_errorbar(aes(ymin = prob_min, ymax = prob_max), position = position_dodge(0.85), width = 0.4) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_discrete() +
  facet_grid(cols = vars(pass_prob_name), rows = vars(subsample_name)) +
  scale_fill_manual(values = color_vec) +
  scale_color_manual(values = color_vec) +
  theme(panel.grid.minor.x = element_blank()) +
  xlab('Population Size') +
  ylab('Specialist Survival Chance') +
  ggtitle('Specialist Preservation Probability') +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill =guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size = 18))) + 
  theme(plot.title  = element_text(size = 20, hjust = 0.5)) +
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  ggsave(filename = './plots/specialist_experimental_bars_mean_min_max.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)


######################################################################################
###################### Predicted Specialist Preservation #############################
######################################################################################

# Function to get the probability of selection in the next generation with:
#   p - probability of selection per selection event
#   n - population size
gen_prob = function(p, n){
  return(1 - (1 - p) ^ n)
}

#Function to get the probability of selection with lexicase, down-sampled lexicase, or cohort lexicase
#   Note: Arguments could definitely be cleaned up
#   groups = number of test case groups
#   N = total population size
#   n = group population size (N for lexicase and down-sampled, n / groups for cohort)
#   T_ = total number of test cases
#   t = test cases per group
run_test = function(groups, N = 10, n = N, T_ = N, t = T_ / groups){
  if(n == 1){ # Only member of your group? Guarantee selection!
    return(list(perfect = 1.0, upper = 1.0, lower = 1.0)) 
  }
  # Perfect mathematical prediction
  perfect_res = gen_prob(1/t, n) / groups
  # Trials var is used to emulate the Selection Analyze tool in Empirical
  # With this, we can calculate the range 99% of outputs from the Selection Analyze tool will fall in
  trials = 10000
  p = 1 / groups
  mean = p * trials # Emulating the Selection Analyze tool with a binomial distribution
  std_dev = sqrt(trials * p * (1 - p))
  lower_heads = mean - 3 * std_dev # Three standard deviations away from the true mean
  lower_probs = c(rep(1/t, lower_heads), rep(0, trials - lower_heads))
  lower_gen_probs = gen_prob(lower_probs, n)
  lower_res = mean(lower_gen_probs)
  upper_heads = mean + 3 * std_dev
  upper_probs = c(rep(1/t, upper_heads), rep(0, trials - upper_heads))
  upper_gen_probs = gen_prob(upper_probs, n)
  upper_res = mean(upper_gen_probs)
  return(list(perfect = perfect_res, lower = lower_res, upper = upper_res))
}

# Generate predicted data
pred_data = data.frame(data = matrix(nrow = 0, ncol = 6))
for(pop_size in seq(10, 1000, by=10)){
  for(num_tests in c(20, 100)){
    #Calculate lexicase prob once
    lexicase = run_test(groups = 1,  N = pop_size, n = pop_size,      T_ = num_tests, t = num_tests)
    for(sample_rate in c(0.1, 0.5)){
      # Calculate and append to data the probs for cohort and downsampled
      cohort =      run_test(groups = 1/sample_rate, N = pop_size, n = pop_size * sample_rate, T_ = num_tests, t = num_tests * sample_rate)
      downsampled = run_test(groups = 1/sample_rate, N = pop_size, n = pop_size,               T_ = num_tests, t = num_tests * sample_rate)
      tmp_str = str_replace(as.character(sample_rate), '\\.', '_')
      pred_data = rbind(pred_data, c(pop_size, paste0('cohort_', tmp_str),      num_tests, sample_rate, cohort$perfect,      cohort$lower,      cohort$upper),      stringsAsFactors = F) 
      pred_data = rbind(pred_data, c(pop_size, paste0('downsampled_', tmp_str), num_tests, sample_rate, downsampled$perfect, downsampled$lower, downsampled$upper), stringsAsFactors = F) 
      # Add lexicase with each sample rate to make plotting simpler
      pred_data = rbind(pred_data, c(pop_size, 'lexicase',                      num_tests, sample_rate, lexicase$perfect,    lexicase$lower,    lexicase$upper),    stringsAsFactors = F) 
    }
  }
}

#Pretty up the predicted data
colnames(pred_data) = c('pop_size', 'treatment', 'num_tests', 'subsample_rate', 'perfect', 'lower', 'upper')
pred_data$pop_size = as.numeric(pred_data$pop_size)
pred_data$perfect = as.numeric(pred_data$perfect)
pred_data$lower = as.numeric(pred_data$lower)
pred_data$upper = as.numeric(pred_data$upper)
pred_data$num_tests = as.numeric(pred_data$num_tests)
pred_data$subsample_rate = as.numeric(pred_data$subsample_rate)
# Add prettier names
pred_data$trt_name = ''
pred_data[pred_data$treatment == 'lexicase',]$trt_name = 'Standard'
pred_data[str_count(pred_data$treatment, 'cohort') >= 1,]$trt_name = 'Cohort'
pred_data[str_count(pred_data$treatment, 'downsampled') >= 1,]$trt_name = 'Down-sampled'
pred_data$subsample_name = paste0(as.character(round(pred_data$subsample_rate * 100, 0)), '% Subsampling')
pred_data$num_tests_name = paste0(pred_data$num_tests, ' Tests')
pred_data$num_tests_name = factor(pred_data$num_tests_name, levels = c('20 Tests', '100 Tests'))

#Plot the predicted data!
ggplot(pred_data, aes(x = pop_size, y = perfect, color = trt_name)) + 
  geom_line(size=2) +
  facet_grid(rows = vars(num_tests_name), cols = vars(subsample_name)) + 
  scale_color_manual(values = color_vec) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  xlab('Population Size') +
  ylab('Predicted Specialist Survival Chance') +
  ggtitle('Worst-case Specialist Preservation') +
  guides(color=guide_legend(title="Lexicase Selection Variant", reverse = T, title.theme = element_text(size=18))) +
  theme(plot.title  = element_text(size=20, hjust = 0.5)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") + 
  theme(strip.text  = element_text(size=18, face = 'bold')) + # For the facet labels
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  ggsave(filename = './plots/specialist_predicted.pdf', units = 'in', width = IMG_WIDTH, height = IMG_HEIGHT)
