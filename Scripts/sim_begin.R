#------------------------------------------------------------------------------
# The script that will start all data generation
#------------------------------------------------------------------------------

sim_begin <- function(
  sim_args, user_profile, default_config, scripts_dir
) {

  # Get settings:
  args_processed <- process_args(sim_args, default_config$sim_usage)
  
  settings <- build_settings(
    args_processed, user_profile$sim_options, 
    user_profile$vary_table, user_profile$allowed_groups, scripts_dir
  )
  
  verify_settings(settings, user_profile$user_data)
  
  cat("",file = settings$save_locs$full_log) # Log file create & clear
  
  #----------------------------------------------------------------------------
  
  estimates <- user_profile$user_data
  
  # Print/log estimates read:
  double_cat("Read:\n", file = settings$save_locs$full_log, FALSE)
  double_print(estimates, file=settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)
  
  #----------------------------------------------------------------------------
  
  # Simulate:
  
  data <- sim_main(estimates, settings)
  
  #----------------------------------------------------------------------------
  
  # Save the data:
  write.csv(data, settings$save_locs$data,row.names = F)
  double_cat(paste("saved data to",settings$save_locs$data,"\n"),
      file = settings$save_locs$full_log)
  
  #----------------------------------------------------------------------------
  
  # Save settings and parameters:
  cat(toJSON(settings,pretty=T), file=settings$save_locs$settings)
  cat(toJSON(estimates,pretty=T), file=settings$save_locs$parameters)
  
  double_cat(paste("saved settings to",settings$save_locs$settings,"\n"),
             file = settings$save_locs$full_log)
  double_cat(paste("saved read estimates to",settings$save_locs$parameters,"\n"),
             file = settings$save_locs$full_log)
  file.copy(settings$save_locs$full_log, settings$save_locs$full_log_perm, 
            overwrite = T)
  double_cat(paste("full log is in",settings$save_locs$full_log_perm,"\n"),
             file = settings$save_locs$full_log)
  
  #----------------------------------------------------------------------------
}

if(sys.nframe()==0) {
  options("scipen"=100) # For printing in non-scientific
  
  suppressMessages(library(dplyr))
  suppressMessages(library(doParallel))
  suppressMessages(library(jsonlite))
  
  #----------------------------------------------------------------------------
  # Temporarily switch directory to scripts, source everything and read config
  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  
  filenames <- fromJSON("_file_index.json")
  script_names <- paste0(
    filenames$scripts, ".", filenames$script_ext
  )
  sapply(script_names, source)
  
  default_config <- read_config(filenames, default = TRUE)
  user_profile <- default_config
  
  estimates_data_name <- paste0(
    filenames$default_ind, filenames$shared_data, ".",filenames$data_ext
  )
  user_profile$user_data <- read.csv(
    file.path(
      filenames$default_folder, 
      estimates_data_name
    )
  )
  
  sim_args <- commandArgs(trailingOnly = TRUE)
  
  setwd(called_from)
  
  #----------------------------------------------------------------------------
  
  register_par()
  
  sim_begin(sim_args, user_profile, default_config, scripts_dir)
}
