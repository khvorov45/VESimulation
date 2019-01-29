#------------------------------------------------------------------------------
# Takes a dataframe with all the group values for a population
# Returns VE estimates and sample size for that population
#------------------------------------------------------------------------------

sim_pop <- function(pop_est) {
  
  n_groups <- ncol(pop_est)
  
  pop_calcs <- data.frame() # For the output
  pop_summary <- data.frame() # For combining groups 
  for(i in 1:n_groups) {
    
    group_name <- names(pop_est[i])
    
    # Get the parameters for that population group:
    parameters <- get_group_parameters(pop_est, group_name)
    
    # Simulate that group:
    group_summary <- sim_pop_group(parameters) %>% 
      su_pop_group(group_name)
    # Add to overall:
    pop_summary <- rbind(pop_summary, group_summary)
  }
  
  if(n_groups != 1) {
    pop_summary <- add_overall(pop_summary) 
  }
  
  pop_calc <- calc_useful(pop_summary)
  
  return(pop_calc)
}

