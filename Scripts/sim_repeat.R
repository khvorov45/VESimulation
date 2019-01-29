#------------------------------------------------------------------------------
# Will repeatedly simulate a population and return averages
#------------------------------------------------------------------------------

sim_repeat <- function(estimates, Npop, par_log) {
  
  cat("Parallel execution log:\n\n", file = par_log)
  
  # To deal with dopar's nonsense:
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  
  pop_many <- foreach(i = 1:Npop, .combine = rbind) %dopar% {
    
    library(dplyr)
	
    setwd(scripts_dir)
    source("helper_functions.R")
    source("sim_pop.R")
    source("sim_pop_group.R")
    setwd(called_from)
	
    pop <- sim_pop(estimates)
    
    pop$run <- i
    
    cat(i, "\n", file = par_log, append = T)
    
    return(pop)
  }
  
  pop_avg <- take_averages(pop_many)
  pop_avg$VE_true <- get_true_VE(estimates)
  
  return(pop_avg)
}