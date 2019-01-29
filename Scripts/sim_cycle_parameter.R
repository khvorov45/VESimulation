#------------------------------------------------------------------------------
# Cylcles through the variant values to generate data for all combinations
#------------------------------------------------------------------------------

sim_cycle_parameter <- function(pop_est, settings) {
  
  # Go here when there is nothing left to vary
  if(length(settings$to_vary) == 0) {
    
    pop_est <- format_estimates_final(pop_est, settings$nsam)
	  double_cat(
      "estimates sent (final format):\n", 
      file = settings$save_locs$full_log, FALSE
    )
    double_print(pop_est, file = settings$save_locs$full_log, FALSE)
    double_cat("\n", file = settings$save_locs$full_log, FALSE)
	
    data <- sim_repeat(pop_est, settings$Npop, settings$save_locs$parallel_log)
	
    return(data)
  }
  
  # Otherwise set one and call itself again:
  
  variant_used <- settings$to_vary[1]
  settings$to_vary <- settings$to_vary[-1]
  
  data_complete <- data.frame()
  
  for(val in variant_used[[1]]) {
    
    pop_est[names(variant_used) , settings$vary_in_group] <- val
	
    
	double_cat(paste("set", names(variant_used), "to", val, "\n"), 
	  file = settings$save_locs$full_log)
    data <- sim_cycle_parameter(pop_est, settings)
    
    data[names(variant_used)] <- val
    
    data_complete <- rbind(data_complete, data)
  }
  
  return(data_complete)
}
