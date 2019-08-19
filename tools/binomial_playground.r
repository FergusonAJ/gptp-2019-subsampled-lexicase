rm(list = ls())
library(ggplot2)

prob_mass_func = function(n, k, p = 0.5){
  return(choose(n, k) * p^k * (1-p)^(n-k))
}

cum_dist_func = function(n, k, p = 0.5){
  total = 0
  for(i in 0:k){
    total = total + choose(n, i) * p^i * (1-p)^(n-i)
  }
  return(total)
}

n = 1000
p = 0.5
trials = 10000

mu = n * p
var = n * p * (1-p)
std_dev = var ^ 0.5
cat0 = function(...){
  cat(..., sep = '')
}
cat0('mean: ', mu, '\n')
cat0('std. dev.: ', std_dev, '\n')
cat0('1 std. dev.: (', mu - 1 * std_dev, ', ', mu + 1 * std_dev, ')', '\n')
cat0('1 std. dev.: (', mu - 2 * std_dev, ', ', mu + 2 * std_dev, ')', '\n')
cat0('1 std. dev.: (', mu - 3 * std_dev, ', ', mu + 3 * std_dev, ')', '\n')

print(1 - 2 * cum_dist_func(n, mu - 1 * std_dev))
print(1 - 2 * cum_dist_func(n, mu - 2 * std_dev))
print(1 - 2 * cum_dist_func(n, mu - 3 * std_dev))


flips = rbinom(n = trials,  size = n, prob = p)
data = data.frame(data = matrix(data = c(1:trials, flips), nrow = trials, ncol = 2))
colnames(data) = c('x', 'heads')

ggp = ggplot(data, aes(x = heads))
ggp = ggp + geom_histogram(binwidth = 1)
ggp = ggp + scale_x_continuous(limits = c(0, n))
ggp = ggp + geom_vline(xintercept = mu, color='red')
ggp = ggp + geom_vline(xintercept = mu - 1 * std_dev, color='orange')
ggp = ggp + geom_vline(xintercept = mu + 1 * std_dev, color='orange')
ggp = ggp + geom_vline(xintercept = mu - 2 * std_dev, color='orange')
ggp = ggp + geom_vline(xintercept = mu + 2 * std_dev, color='orange')
ggp = ggp + geom_vline(xintercept = mu - 3 * std_dev, color='yellow')
ggp = ggp + geom_vline(xintercept = mu + 3 * std_dev, color='yellow')
ggp

print(nrow(data[data$heads >= mu - 1 * std_dev & data$heads <= mu + 1 * std_dev,]) / trials)
print(nrow(data[data$heads >= mu - 2 * std_dev & data$heads <= mu + 2 * std_dev,]) / trials)
print(nrow(data[data$heads >= mu - 3 * std_dev & data$heads <= mu + 3 * std_dev,]) / trials)

