 #------------------------------------------------------------------------------
# The script that will run the simulation for all the possible combinations
# as per user settings profile
#------------------------------------------------------------------------------

run_user_profile <- function(
  save_directory, user_profile, scripts_dir
) {

  if(length(save_directory) != 1) stop("Too many arguments in save_directory")
  if(save_directory==F) stop("save_directory missing")
  
  vary_table <- user_profile$vary_table
  
  if (identical(vary_table, NULL)) stop("no vary table in user profile")
  
  variants <- names(vary_table)
  
  groups <- user_profile$allowed_groups
  if(is.matrix(groups)) groups <- list(groups[1,]) # Only if one nested list
  
  variant_combinations <- get_variant_combinations(
    names(vary_table), user_profile$sim_options$vary_rule
  )
  
  # For duration caclulations
  amount_total <- length(groups) * length(variant_combinations)
  amount_done <- 0
  diffs <- c()

  # Cycle through possible calls
  for(group in groups) {
    for(variant_combo in variant_combinations) {
      start <- Sys.time()

      arg_set <- list()
      arg_set$save_directory <- save_directory
      arg_set$group <- paste(gsub("[*]","",group))
      arg_set$variants <- paste(unlist(strsplit(variant_combo,split = ' ')))
      if(any(grepl('[*]',group))) {
        arg_set$vary_in_group <- paste(gsub('[*]','',group[grepl('[*]',group)]))
      }

      sim_begin(
        arg_set, user_profile, scripts_dir
      )
      
      # End message stuff
      amount_done <- amount_done + 1
      end <- Sys.time()
      diff <- as.numeric(difftime(end, start, units = "secs"))
      diffs <- c(diffs, diff)
      diff_short <- round(diff, 1)
      est_to_comp <- mean(diffs)*(amount_total - amount_done)
      cat(
        "\nCompleted ", amount_done, "/", 
        amount_total," in: ", diff_short, "s | ", 
        "ETC: ", round(est_to_comp,1),"s ", 
        "(",round(est_to_comp/60,1),"m) \n", sep = ""
      )
    }
  }
  cat(
    "\nDone in ", round(sum(diffs),1), "s (", 
    round(sum(diffs)/60,1), "m)\n",sep=""
  )
}

if(sys.nframe()==0) {  
  options("scipen"=100) # For printing in non-scientific

  #----------------------------------------------------------------------------
  # Temporarily switch directory
  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)

  # Deal with python compatability
  if (Sys.info()['sysname'] == 'Windows') {
    source("fix_lib_path.R")
    fix_lib_path()
  }

  suppressMessages(library(dplyr))
  suppressMessages(library(doParallel))
  suppressMessages(library(jsonlite))
  
  # Source script files
  filenames <- fromJSON("_file_index.json")
  script_names <- paste0(
    filenames$scripts, ".", filenames$script_ext
  )
  sapply(script_names, source)

  default_config <- read_config(filenames, default = TRUE) # For usage options
  
  processed_args <- process_args(
    commandArgs(trailingOnly=T), default_config$run_profile_usage
  )
  
  user_profile <- read_config(
    filenames, user = TRUE, profile_name = processed_args$profile_name
  )
  
  # Add estimates to user profile
  estimates_data_name <- paste0(filenames$shared_data, ".",filenames$data_ext)
  user_profile$user_data <- read.csv(
    file.path(
      filenames$user_folder, processed_args$profile_name, 
      estimates_data_name
    )
  )
  register_par()
  setwd(called_from)
  
  #----------------------------------------------------------------------------

  run_user_profile(
    processed_args$save_directory, user_profile, scripts_dir
  )
}