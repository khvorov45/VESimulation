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

  par_name <- names(variant_used)
  par_group_values <- variant_used[[1]]
  par_group_values <- par_group_values[
    names(par_group_values) %in% settings$vary_in_group
  ]

  # SET FUNCTIONS??? Probably do so beforehand

  par_group_values <- as.data.frame(par_group_values)
  value_count <- nrow(par_group_values)
  
  data_complete <- data.frame()
  
  for(ind in 1:value_count) {
    
    pop_est[par_name , settings$vary_in_group] <- par_group_values[ind , ]
    
	  double_cat(
      paste(
        "set", names(variant_used), "to", 
        paste0(par_group_values[ind , ],collapse=' '), 
        "\n"
      ), 
	    file = settings$save_locs$full_log
    ) 
    data <- sim_cycle_parameter(pop_est, settings)

    data[
      data$name %in% settings$vary_in_group, par_name
    ] <- par_group_values[ind , ]
    
    data_complete <- rbind(data_complete, data)
  }
  
  return(data_complete)
}
