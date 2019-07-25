rm(list=ls())
setwd('~/research/lexicase/gptp-2019-subsampled-lexicase/specialist_experiment')
library(stringr)


test_counts = c(10, 20)
pop_sizes = c(10, 20, 100)
pass_probs = seq(0, 1, 0.1)
replicate_ids = 1:100

for(num_tests in test_counts){
  for(pop_size in pop_sizes){
    num_non_focal_orgs = pop_size - 1
    num_focal_orgs = 1
    for(pass_prob in pass_probs){
      pass_prob_str = str_replace(as.character(pass_prob), '\\.', '_')
      for(rep_id in replicate_ids){
        data = data.frame(data = matrix(nrow = 0, ncol = num_tests + 1))
        # Non-Focal Orgs
        for(non_focal_id in 1:num_non_focal_orgs){
          tmp_vec = sample(c(0,1), prob = c(1 - pass_prob, pass_prob), size = num_tests - 1, replace = T)
          data = rbind(data, c(0, tmp_vec, 0)) # Don't forget the 0 for fitness and focal case!
        }
        # Focal Orgs
        tmp_vec = c(0, rep(0, num_tests - 1), 1) # Fitness, non-focal cases, focal case
        data = rbind(data, tmp_vec)
        colnames(data) = c('Fitness', paste('Test_',1:(num_tests-1)), 'Focal')
        data$Fitness <- rowSums(data,na.rm = F,dims = 1L)
        write.csv(data, file = paste("./pop_data/population__num_tests_", num_tests, "__pop_size_", pop_size, "__pass_prob_", pass_prob_str, "__rep_id_", rep_id,".csv",sep=""))
      }
    }
  }
}
