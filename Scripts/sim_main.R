#------------------------------------------------------------------------------
# Starts off data simulations
#------------------------------------------------------------------------------

sim_main <- function(estimates, settings) {

  # Print start message:
  start_msg <- paste0(
    "\n", paste0(rep("~",80),collapse=""),
    "\nStarting simulations on group(s): ", paste(settings$group,collapse=' '), 
    " | times: ", settings$Npop, 
		" | starting size: ", settings$nsam, 
		" |\n\t to vary: ", paste0(names(settings$to_vary),collapse=" "), 
		" | in group(s): ", paste0(settings$vary_in_group,collapse=' '),
		"\n",paste0(rep("~",80),collapse=""),"\n\n")
  double_cat(start_msg, settings$save_locs$full_log)
  
  # Format estimates:
  pop_est <- format_estimates_init(estimates, settings$group)
  check_argument(settings$vary_in_group, names(pop_est))
  double_cat("Estimates initial format:\n", 
    file = settings$save_locs$full_log, FALSE)
  double_print(pop_est, file = settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)
  
  # Simulate:
  data <- sim_set_functions(pop_est, settings)
  double_cat("\nSimulation done\n\n", file = settings$save_locs$full_log)
  
  # Print results:
  double_cat("Results:\n", file=settings$save_locs$full_log, FALSE)
  double_print(data, file = settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)
  
  return(data)
}
