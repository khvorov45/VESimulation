#------------------------------------------------------------------------------
# Takes a dataframe with all the group values for a population
# Returns VE estimates and sample size for that population
#------------------------------------------------------------------------------

sim_pop <- function(pop_est) {

  # Convert to df
  pop_est_li <- pop_est
  pop_est <- data.frame()

  for(par_name in names(pop_est_li)) {
    par_entry <- as.data.frame(pop_est_li[[par_name]])
    rownames(par_entry) <- par_name
    pop_est <- rbind(pop_est, par_entry)
  }
  
  # Format p_test_nonari
  pop_est["p_test_nonari",] <- 
    pop_est["p_test_nonari",] * pop_est["p_test_ari",]

  n_groups <- ncol(pop_est)
  
  pop_calcs <- data.frame() # For the output
  pop_summary <- data.frame() # For combining groups 
  for(i in 1:n_groups) {
    
    group_name <- names(pop_est[i])
    
    # Get the parameters for that population group:
    parameters <- pop_est[[group_name]]
    names(parameters) <- rownames(pop_est)
    
    # Simulate that group:
    group_summary <- sim_pop_group(parameters) %>% 
      su_pop_group(group_name, parameters)
    # Add to overall:
    pop_summary <- rbind(pop_summary, group_summary)
  }
  
  if(n_groups != 1) {
    pop_summary <- add_overall(pop_summary, names(parameters)) 
  }
  
  return(pop_summary)
}

