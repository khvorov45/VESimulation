#------------------------------------------------------------------------------
# Will repeatedly simulate a population and return averages
#------------------------------------------------------------------------------

sim_repeat <- function(pop_est, Npop, par_log, scripts_dir) {
  
  cat("Parallel execution log:\n\n", file = par_log)
  
  called_from <- getwd()

  # Generate the numbers for probabilistic variation
  gen_num <- function(el) {
    # Should be a closure if not numeric
    if(is.numeric(el)) return(el)
    else return(el())
  }
  gen_num_par <- function(par_entry) {
    par_entry_new <- lapply(par_entry, gen_num)
    return(par_entry_new)
  }
  pop_est <- lapply(pop_est, gen_num_par)
  
  # Simulate many populations
  pop_many <- foreach(i = 1:Npop, .combine = rbind) %dopar% {
    
    library(dplyr)
	
    setwd(scripts_dir)
    source("helper_functions.R")
    source("sim_pop.R")
    source("sim_pop_group.R")
    setwd(called_from)
    
    # Pick one of the randomly genrated numbers
    pop_est_partial <- pop_est
    for(par_name in names(pop_est)) {
      for(group_name in names(pop_est[[par_name]])) {
        element <- pop_est[[par_name]][[group_name]]
        if(length(element) > 1) {
          pop_est_partial[[par_name]][[group_name]] <- element[i]
        }
      }
    }
    
    pop <- sim_pop(pop_est_partial)
    
    pop$run <- i
    
    cat(i, " ", sep="", file = par_log, append = T)
    
    return(pop)
  }
  return(pop_many)
}