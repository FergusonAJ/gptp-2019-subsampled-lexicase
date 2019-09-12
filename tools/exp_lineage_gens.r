# Generate the plot showing the expected number of generations until a lineage sees a given fraction, T, of test cases
rm(list = ls())
library(ggplot2)
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/output/')

lineage_gen_func = function(D, G){
  return(((D - 1)/ D)^G)
}

res_2  = 1 - lineage_gen_func(2, 1:100)
res_4  = 1 - lineage_gen_func(4, 1:100)
res_10 = 1 - lineage_gen_func(10, 1:100)
res_20 = 1 - lineage_gen_func(20, 1:100)

vals = c(res_2, res_4, res_10, res_20)
d_vals = c(rep(2, 100), rep(4, 100), rep(10, 100), rep(20, 100))
subsample_rates = c(rep('50%', 100), rep('25%', 100), rep('10%', 100), rep('5%', 100))
line_types = c(rep('solid', 100), rep('dotted', 100), rep('dashed', 100), rep('dotdash', 100))
df = data.frame(frac = vals, D = d_vals, subsample_rate = subsample_rates, gens = rep(1:100, 4), line_type = line_types)
df$D = as.factor(df$D)
df$subsample_rate = factor(df$subsample_rate, levels = c('50%', '25%', '10%', '5%'))

ggplot(df, aes(x = gens, y = frac, col = subsample_rate, linetype = subsample_rate)) +  
  geom_line(size = 1.5) + 
  xlab('Generations') +
  ylab('Fraction of Training Cases Encountered by a Lineage')+
  theme(panel.grid.minor.x = element_blank()) +
  #scale_linetype_identity() +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(color=guide_legend(title="Subsample Rate", title.theme = element_text(size = 18))) +
  guides(linetype=guide_legend(title="Subsample Rate", title.theme = element_text(size = 18))) +  
  theme(axis.title  = element_text(size=18)) +
  theme(axis.text   = element_text(size=18)) +
  theme(legend.text = element_text(size=18), legend.position="bottom") +
  theme(legend.key.width = unit(5, 'line')) +
  scale_linetype_manual(values = c('solid', 'dotted', 'dashed', 'dotdash')) +
  scale_y_continuous(limits = c(0,1), breaks = c(0, 0.25, 0.5, 0.75, 1.0)) +
  ggsave(filename = './plots/exp_lineage_gens_new.pdf', units = 'in', width = 14, height = 8)
