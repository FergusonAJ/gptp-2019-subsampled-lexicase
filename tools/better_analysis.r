# There's not much here, just looking at which replicates found solutions

library(ggplot2)

setwd('~/Research/lexicase/gptp-2019-cohort-lexicase/tools')
data = read.csv('replicate_data.csv', stringsAsFactors = FALSE)
data$found = data$solution_found == 'True'

treatments = unique(data$treatment)
sizes = unique(data$num_tests)
dilutions = unique(data$dilution)

unfinished = data[ (data$max_gen != 6000 & data$num_tests == 5) 
                 | (data$max_gen != 3000 & data$num_tests == 10)
                 | (data$max_gen != 1200 & data$num_tests == 25)
                 | (data$max_gen != 600  & data$num_tests == 50)
                 | (data$max_gen != 300  & data$num_tests == 100)
                 ,]

write.csv('unfinished.csv', x = unfinished)

unfinished_10 = unfinished[unfinished$num_tests == 10,]
unfinished_10 = unfinished_10[order(unfinished_10$max_gen),]
unfinished_100 = unfinished[unfinished$num_tests == 100,]
unfinished_100 = unfinished_100[order(unfinished_100$max_gen),]

