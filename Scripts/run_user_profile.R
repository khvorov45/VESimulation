#------------------------------------------------------------------------------
# The script that will run the simulation for all the possible combinations
# as per user settings
#------------------------------------------------------------------------------

run_user_profile <- function(
  save_directory, user_profile, default_config, scripts_dir
) {
  
  if(length(save_directory) != 1) stop("Too many arguments in save_directory")
  if(save_directory==F) stop("save_directory missing")
  
  vary_table <- user_profile$vary_table
  
  variants <- names(vary_table)
  
  groups <- user_profile$allowed_groups
  if(is.matrix(groups)) groups <- list(groups[1,]) # Only if one nested list
  
  variant_combinations <- get_variant_combinations(
    names(vary_table), user_profile$sim_options$vary_rule
  )
  
  amount_total <- length(groups) * length(variant_combinations)
  amount_done <- 0
  diffs <- c()
  for(group in groups) {
    for(variant_combo in variant_combinations) {
      start <- Sys.time()
      arg_set <- c(
          paste0(
            default_config$sim_usage$control_ind, 
            default_config$sim_usage$save_directory_ind
          ), 
          save_directory
      ) %>% c(
        paste0(
          default_config$sim_usage$control_ind, 
          default_config$sim_usage$group_ind
        ), 
        paste(gsub("[*]","",group))
      ) %>% c(
        paste0(
          default_config$sim_usage$control_ind, 
          default_config$sim_usage$variants_ind
        ), 
        paste(unlist(strsplit(variant_combo,split = ' ')))
      )
      if(any(grepl('[*]',group))) arg_set <- c(
        arg_set,
        paste0(
          default_config$sim_usage$control_ind, 
          default_config$sim_usage$vary_in_group_ind
        ), 
        paste(gsub('[*]','',group[grepl('[*]',group)]))
      )
      
      sim_begin(
        arg_set, user_profile, default_config, scripts_dir
      )
      
      amount_done <- amount_done + 1
      end <- Sys.time()
      diff <- as.numeric(end - start)
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
  
  processed_args <- process_args(
    commandArgs(trailingOnly=T), default_config$run_profile_usage
  )
  
  user_profile <- read_config(
    filenames, user = TRUE, profile_name = processed_args$profile_name
  )
  
  estimates_data_name <- paste0(filenames$shared_data, ".",filenames$data_ext)
  user_profile$user_data <- read.csv(
    file.path(
      filenames$user_folder, processed_args$profile_name, 
      estimates_data_name
    )
  )
  
  setwd(called_from)
  
  #----------------------------------------------------------------------------
  
  register_par()
  
  run_user_profile(
    processed_args$save_directory, user_profile, default_config, scripts_dir
  )
}