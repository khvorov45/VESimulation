# This function starts data generation
# Arseniy Khvorov
# Created 2018/12/01
# Last edit 2019/06/04

sim_begin <- function(
  sim_args, user_profile, scripts_dir
) {

  settings <- build_settings(
    sim_args, user_profile$sim_options, 
    user_profile$vary_table, user_profile$allowed_groups, scripts_dir
  )
  
  # Log file create & clear:
  #cat(as.character(Sys.time()),"\n\n",file = settings$save_locs$full_log) 

  estimates <- user_profile$user_data
  
  # Log estimates read
  #cat("Read:\n", file = settings$save_locs$full_log, FALSE)
  #print(estimates, file=settings$save_locs$full_log, FALSE)
  #cat("\n", file = settings$save_locs$full_log, FALSE)
  
  # Print/log start message:
  start_msg <- paste0(
    "\n", paste0(rep("~",80),collapse=""),
    "\nStarting simulations on group(s): ", paste(settings$group,collapse=' '), 
    " |\n\t times: ", settings$Npop, 
		" | starting size: ", settings$nsam, 
		" |\n\t to vary: ", paste0(names(settings$to_vary),collapse=" "), 
		" |\n\t in group(s): ", paste0(settings$vary_in_group,collapse=' '),
		"\n", paste0(rep("~",80), collapse = ""),"\n\n"
  )
  cat(start_msg)

  data <- sim_main(estimates, settings)

  cat("\nSimulation done\n\n")
  
  # Log data
  #cat("Results:\n", file=settings$save_locs$full_log, FALSE)
  #print(data, file = settings$save_locs$full_log, FALSE)
  #cat("\n", file = settings$save_locs$full_log, FALSE)

  # Save data
  write.csv(data, settings$save_locs$data,row.names = F)
  cat("saved data to", settings$save_locs$data, "\n")
  
  # Save settings and parameters:
  #cat(toJSON(settings, pretty=T), file=settings$save_locs$settings)
  #cat(toJSON(estimates, pretty=T), file=settings$save_locs$parameters)

  # Move the log file to a permanent location
  #file.copy(
  #  settings$save_locs$full_log, settings$save_locs$full_log_perm, 
  #  overwrite = T
  #)
  
  # End messages
  #cat(
  #  paste("saved settings to",settings$save_locs$settings,"\n"),
  #  file = settings$save_locs$full_log
  #)
  #cat(
  #  paste("saved read estimates to",settings$save_locs$parameters,"\n"),
  #  file = settings$save_locs$full_log
  #)
  #cat(
  #  paste("full log is in",settings$save_locs$full_log_perm,"\n"),
  #  file = settings$save_locs$full_log
  #)
}