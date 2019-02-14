 #------------------------------------------------------------------------------
# THis function starts data generation
#------------------------------------------------------------------------------

sim_begin <- function(
  sim_args, user_profile, scripts_dir
) {

  settings <- build_settings(
    sim_args, user_profile$sim_options, 
    user_profile$vary_table, user_profile$allowed_groups, scripts_dir
  )
  
  # Log file create & clear:
  cat(as.character(Sys.time()),"\n\n",file = settings$save_locs$full_log) 

  estimates <- user_profile$user_data
  
  # Log estimates read
  double_cat("Read:\n", file = settings$save_locs$full_log, FALSE)
  double_print(estimates, file=settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)
  
  # Print/log start message:
  start_msg <- paste0(
    "\n", paste0(rep("~",80),collapse=""),
    "\nStarting simulations on group(s): ", paste(settings$group,collapse=' '), 
    " |\n\t times: ", settings$Npop, 
		" | starting size: ", settings$nsam, 
		" |\n\t to vary: ", paste0(names(settings$to_vary),collapse=" "), 
		" |\n\t in group(s): ", paste0(settings$vary_in_group,collapse=' '),
		"\n",paste0(rep("~",80),collapse=""),"\n\n"
  )
  double_cat(start_msg, settings$save_locs$full_log)

  data <- sim_main(estimates, settings)

  double_cat("\nSimulation done\n\n", file = settings$save_locs$full_log)
  
  # Log data
  double_cat("Results:\n", file=settings$save_locs$full_log, FALSE)
  double_print(data, file = settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)

  # Save data
  write.csv(data, settings$save_locs$data,row.names = F)
  double_cat(
    paste("saved data to",settings$save_locs$data,"\n"),
    file = settings$save_locs$full_log
  )
  
  # Save settings and parameters:
  cat(toJSON(settings, pretty=T), file=settings$save_locs$settings)
  cat(toJSON(estimates, pretty=T), file=settings$save_locs$parameters)

  # Move the log file to a permanent location
  file.copy(
    settings$save_locs$full_log, settings$save_locs$full_log_perm, 
    overwrite = T
  )
  
  # End messages
  double_cat(
    paste("saved settings to",settings$save_locs$settings,"\n"),
    file = settings$save_locs$full_log
  )
  double_cat(
    paste("saved read estimates to",settings$save_locs$parameters,"\n"),
    file = settings$save_locs$full_log
  )
  double_cat(
    paste("full log is in",settings$save_locs$full_log_perm,"\n"),
    file = settings$save_locs$full_log
  )
}