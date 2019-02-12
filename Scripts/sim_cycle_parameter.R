#------------------------------------------------------------------------------
# Cylcles through the variant values to generate data for all combinations
#------------------------------------------------------------------------------

sim_cycle_parameter <- function(pop_est, settings) {

  # Go here when there is nothing left to vary
  if(length(settings$to_vary) == 0) {
    
    # Do another format pass and log it
    pop_est <- format_estimates_final(pop_est, settings$nsam)
	  double_cat(
      "estimates sent (final format):\n", 
      file = settings$save_locs$full_log, FALSE
    )
    double_print(pop_est, file = settings$save_locs$full_log, FALSE)
    double_cat("\n", file = settings$save_locs$full_log, FALSE)
	
    data <- sim_repeat(
      pop_est, settings$Npop, settings$save_locs$parallel_log, 
      settings$scripts_dir
    )

    return(data)
  }
  
  # Otherwise set one and call itself again:
  
  variant_used <- settings$to_vary[1]
  settings$to_vary <- settings$to_vary[-1]

  par_name <- names(variant_used)
  group_names <- names(variant_used[[par_name]])
  
  # Hope every group has the same length of values
  value_count <- length(variant_used[[par_name]][[group_names[1]]])
  
  data_complete <- data.frame()
  
  for(ind_par in 1:value_count) {
    
    for(group_name in group_names) {
      pop_est[[par_name]][[group_name]] <- 
        variant_used[[par_name]][[group_name]][ind_par]
      double_cat(
        paste(
          "set", par_name, "in group", group_name, "to", 
          variant_used[[par_name]][[group_name]][ind_par], 
          "\n"
        ), 
	      file = settings$save_locs$full_log
      )
    }

    data <- sim_cycle_parameter(pop_est, settings)

    data_complete <- rbind(data_complete, data)
  }
  
  return(data_complete)
}
