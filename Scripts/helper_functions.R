#------------------------------------------------------------------------------
# Reads config files in the appropriate profile folder. 
# Assumes we are already in scripts.
#------------------------------------------------------------------------------

read_config <- function(
  filenames, default = !user, user = !default, profile_name = NA
) {
  if (default) {
    folder <- filenames$default_folder
    config_names <- c(
      filenames$shared_config,filenames$default_only_config
    )
    config_files <- paste0(
      filenames$default_ind, config_names, ".",filenames$config_ext
    )
    
  } else {
    folder <- file.path(filenames$user_folder, profile_name)
    if (!dir.exists(folder)) stop("no profile ", profile_name, " found")
    config_names <- filenames$shared_config
    config_files <- paste0(config_names, ".", filenames$config_ext)
  }
  config_filepaths <- file.path(folder, config_files)
  config <- lapply(config_filepaths, fromJSON)
  names(config) <- config_names
  return(config)
}

#------------------------------------------------------------------------------
# Processes command line argumetns
#------------------------------------------------------------------------------

process_args <- function(arguments, usage_options) {
  
  control_ind <- usage_options$control_ind
  usage_options$control_ind <- NULL
  args_to_find <- usage_options
  
  args_processed <- list()
  
  for(name in args_to_find) {
    args_processed[[name]] <- read_arg(control_ind, name, arguments) 
  }
  
  obtained <- tolower(c(names(args_processed), unlist(args_processed)))
  given <- tolower(gsub(control_ind, "", arguments))
  if(!all(given %in% obtained)) stop(
    "failed to process: ",
    paste0(arguments[!(given %in% obtained)], collaplse = ' '), 
    sep = ""
  )
  
  return(args_processed)
}

# Reads part of an argument
read_arg <- function(control_indicator, control_el, args) {
  
  looking_for <- paste0(control_indicator, control_el)
  
  if(!(looking_for %in% args)) return(FALSE)

  all_control_inds <- get_control_inds(control_indicator, args)
  needed_ind <- match(looking_for, args)
  next_ind <- all_control_inds[match(needed_ind, all_control_inds) + 1]
  
  if((needed_ind) == (next_ind - 1)) return(TRUE)
  
  arg <-args[(needed_ind + 1) : (next_ind - 1)]
  
  return(arg)
}

# Gets all the control element indeces in the arguments
get_control_inds <- function(control_indicator, args) {
  
  control_inds <- c()
  for(i in length(args)) {
	  control_els <- args[grepl(paste0('^',control_indicator), args)]
	  control_inds <- match(control_els, args)
  }
  
  # Non-existent last control for parsing purposes
  control_inds[length(control_inds)+1] <- length(args) + 1
  
  return(control_inds)
}

#------------------------------------------------------------------------------
# Registers parallel backend. Assumes we are in scripts
#------------------------------------------------------------------------------

register_par <- function(core_decrease) {
  n_cores <- detectCores() - core_decrease
  cat(paste("Registering parallel backend with", n_cores, "cores... "))
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)

  # Python compatability
  if (Sys.info()['sysname'] == 'Windows') {
    clusterEvalQ(cl, source("fix_lib_path.R"))
    clusterEvalQ(cl, fix_lib_path())
  }
  clusterEvalQ(cl, library(dplyr))
  clusterEvalQ(cl, source("helper_functions.R"))
  clusterEvalQ(cl, source("sim_pop.R"))
  clusterEvalQ(cl, source("sim_pop_group.R"))
  
  cat("Done\n")
}

#------------------------------------------------------------------------------
# Returns all possible variant combinations
#------------------------------------------------------------------------------

get_variant_combinations <- function(possibilities, rule) {
  
  n <- length(rule)
  
  # Initialise a list with all possibilities in their place
  placeholder <- list()
  for(i in 1:n) {
    placeholder[[i]] <- possibilities[grepl(rule[i],possibilities)]
    if(identical(placeholder[[i]],character(0))) stop(rule[i], " not found")
  }
  
  combos <- placeholder[[1]]
  placeholder <- placeholder[-1]
  combos <- cycle_through(placeholder, combos)

  combos <- remove_repeats(combos)
  
  return(combos)
}

cycle_through <- function(iterable, combos) {
  
  # Go here when there is nothing left to add
  if(length(iterable)==0) {
    
    # Get rid of entries with duplicates 
    log_vec <- sapply(combos, contains_duplicates)
    combos <- combos[!log_vec]

    return(combos)
  }
  
  # Add the second entry in the possibilities
  combos <- sapply(combos, paste, iterable[[1]])
  names(combos) <- NULL
  
  iterable <- iterable[-1]
  
  combos <- cycle_through(iterable, combos)
  
  return(combos)
}

contains_duplicates <- function(string) {
  char_vec <- unlist(strsplit(string, split = ' '))
  if(anyDuplicated(char_vec)) { return(TRUE) }
  else { return(FALSE) }
}

remove_repeats <- function(vecs) {
  vecs_clean <- c()
  vec_els <- list()
  ind <- 0
  for (vec in vecs) {
    is_repeated <- FALSE
    all_vec_elements <- unlist(strsplit(vec, split = ' '))
    for (vec_el_set in vec_els) {
      if (all(all_vec_elements %in% vec_el_set)) {
        is_repeated <- TRUE
        break
      }
    }
    if (is_repeated) next
    ind <- ind + 1
    vecs_clean[ind] <- vec
    vec_els[[ind]] <- all_vec_elements
  }

  return(vecs_clean)
}

#------------------------------------------------------------------------------
# Builds the settings list for the simulation
#------------------------------------------------------------------------------

build_settings <- function(
  args_processed, sim_options, vary_table, allowed_groups, scripts_dir
) {
  settings <- sim_options
  
  settings$group <- args_processed$group
  
  folder <- args_processed$save_directory
  variant_names <- args_processed$variants
  
  # Set the vary_in_group setting with group as default
  if (length(args_processed$vary_in_group[1]) == 0) {
    settings$vary_in_group <- settings$group
  } else {settings$vary_in_group <- args_processed$vary_in_group}
  
  if (any(!(variant_names %in% names(vary_table)))) 
    stop("vary_table does not have variation for one or more variants")
  settings$to_vary <- vary_table[variant_names]
  
  settings$save_locs <- get_save_locs(
    folder, settings$group, variant_names, settings$vary_in_group, scripts_dir
  )

  # Reduce the vary table further:
  for(variant_name in names(settings$to_vary)) {
    for(group_name in names(settings$to_vary[[variant_name]])) {
      if (!(group_name %in% settings$vary_in_group)) {
        settings$to_vary[[variant_name]][[group_name]] <- NULL
      }
    }
  }

  settings$scripts_dir <- scripts_dir
  
  return(settings)
}

# Gets save locations
get_save_locs <- function(
  folder, group, to_vary_names, vary_in_group, scripts_dir
) {
  
  # Initialise the list
  save_locs <- list(folder = folder)
  
  filename <- get_save_filename(group, to_vary_names, vary_in_group)
  
  data_filename <- paste0(filename,".csv")
  save_locs$data <- file.path(folder, data_filename)

  text_filename <- paste0(filename, ".txt")
  save_locs$settings <- file.path(folder, "settings_used", text_filename)
  save_locs$parameters <- file.path(folder,"parameters_used",text_filename)

  log_filename <- paste0(filename,".log")
  save_locs$full_log_perm <- file.path(folder,"full_log",log_filename)
  save_locs$full_log <- file.path(scripts_dir, "_current.log")
  save_locs$parallel_log <- file.path(folder, "full_log", "parallel_log.txt")

  # Create all the directories and files
  create_dir <- function(filepath) {
    if (!dir.exists(dirname(filepath))) dir.create(dirname(filepath))
  }
  create_files <- function(filepath) {
    if (!file.exists(filepath)) file.create(filepath)
  }

  lapply(save_locs, create_dir)
  lapply(save_locs, create_files)

  save_locs <- lapply(save_locs, normalizePath)
  
  return(save_locs)
}

# Makes a filename
get_save_filename <- function(group, to_vary_names, vary_in_group) {
  group <- clean_names(group)
  to_vary_names <- clean_names(to_vary_names)
  filename <- paste0(
    paste0(group,collapse="-"),"--", 
    paste0(to_vary_names,collapse="-"))
  if(all(group %in% vary_in_group)) return(filename)
  filename <- paste0(filename,"--",paste0(vary_in_group,collapse='-'))
  return(filename)
}

# Omits missing and empty entries
clean_names <- function(names) {
  clean_names <- na.omit(names)
  clean_names <- clean_names[clean_names != ""]
  return(clean_names)
}

#------------------------------------------------------------------------------
# Estimates formatting
#------------------------------------------------------------------------------

# Initial format
format_estimates_init <- function(estimates_og, group) {
  
  pop_est <- estimates_og

  names(pop_est) <- standardise_names(names(pop_est))

  pop_est <- narrow_group(pop_est, group)
  
  # Move parameter names to row names:
  rownames(pop_est) <- pop_est[ , "parameter"]
  pop_est <- select(pop_est, -parameter)
  
  # Format p_test_ari and prop:
  n_groups <- ncol(pop_est)
  if(n_groups == 1) {
    pop_est["prop", ] <- 1 # Only relevant when multiple groups are present
    pop_est["p_clin_ari", ] <- 1 # No absolute estimates
  } 

  # Convert to list:
  pop_est_list <- list()
  for(par_name in rownames(pop_est)) {
    pop_est_list[[par_name]] <- list()
    for(group_name in names(pop_est)) {
      pop_est_list[[par_name]][[group_name]] <- pop_est[par_name, group_name]
    }
  }
  return(pop_est_list)
}


# Gets all parameter estimated, group to choose and returns narrowed estimates
narrow_group <- function(all_estimates, groups) {

  needed <- data.frame(parameter = all_estimates$parameter)
  for(group in groups) {
    narrowed <- all_estimates %>% 
      select(contains(group))
    needed <- cbind(needed,narrowed)
  }
  return(needed)
}

# Final format - add nsam
format_estimates_final <- function(pop_est, nsam) {

  # Add nsam here:
  pop_est[["nsam"]] <- list()
  # Hope prop attribute isn't wierd
  groups <- names(pop_est[["prop"]])
  for(group in groups) {
    pop_est[["nsam"]][[group]] <- pop_est[["prop"]][[group]]*nsam
  }
  
  return(pop_est)
}

standardise_names <- function(all_names) {
  st_names <- gsub("[.]|[[:digit:]]|[)]|[(]", '', all_names)
  st_names <- tolower(st_names)
  return(st_names)
}

#------------------------------------------------------------------------------
# Population summaries
#------------------------------------------------------------------------------

su_pop_group <- function(df_group, group_name, parameters) {
  
  summary <- data.frame("type" = c("surveillance","administrative"))
  
  # Count cases and controls

  #----------------------------------------------------------------------------
  # Surveillance

  summary$case_vac[summary$type == "surveillance"] <- sum(
    df_group$vac_mes == 1 & df_group$testout == 1 & 
    df_group$clin == 1, na.rm = T
  )
  summary$case_unvac[summary$type == "surveillance"] <- sum(
    df_group$vac_mes == 0 & df_group$testout == 1 & 
    df_group$clin == 1, na.rm = T
  )
  
  summary$cont_vac[summary$type == "surveillance"] <- sum(
    df_group$vac_mes == 1 & df_group$testout == 0 & 
    df_group$clin == 1, na.rm = T
  )
  summary$cont_unvac[summary$type == "surveillance"] <- sum(
    df_group$vac_mes == 0 & df_group$testout == 0 & 
    df_group$clin == 1, na.rm = T
  )
  
  #----------------------------------------------------------------------------
  # Administrative

  summary$case_vac[summary$type == "administrative"] <- 
    sum(df_group$vac_mes == 1 & df_group$testout == 1, na.rm = T)
  summary$case_unvac[summary$type == "administrative"] <- 
    sum(df_group$vac_mes == 0 & df_group$testout == 1, na.rm = T)
  
  summary$cont_vac[summary$type == "administrative"] <- 
    sum(df_group$vac_mes == 1 & df_group$testout == 0, na.rm = T)
  summary$cont_unvac[summary$type == "administrative"] <- 
    sum(df_group$vac_mes == 0 & df_group$testout == 0, na.rm = T)
  
  #----------------------------------------------------------------------------

  summary$name <- group_name

  # Add parameter values used
  for(par_name in names(parameters)) {
    summary[ , par_name] <- parameters[par_name]
  }

  return(summary)
}

# Adds population averages
add_overall <- function(pop_summary, par_names) {
  to_sum <- c("case_vac","case_unvac","cont_vac","cont_unvac","prop","nsam")
  to_av <- par_names[!(par_names %in% c("prop","nsam"))]
  pop_summary_overall <- pop_summary %>% 
    mutate_at(vars(to_av),funs(.*prop)) %>%
    group_by(type) %>% 
    summarise_at(vars(to_sum, to_av),funs(sum)) %>% 
    mutate(name = "overall")
  pop_summary_overall <- rbind(pop_summary, pop_summary_overall)
  return(pop_summary_overall)
}

# Caclulates VE and nsam for a group
calc_useful <- function(df_cc) {
  calcs <- df_cc %>% 
    mutate(
      VE_est = 1 - (case_vac/case_unvac) / (cont_vac/cont_unvac),
      n_study = case_vac + cont_unvac + case_unvac + cont_vac
    )
  return(calcs)
}

# Take averages from many runs of the same population
take_averages <- function(pop_many, variants) {
  
  pop_avg <- pop_many %>% 
    mutate(VE_true = VE) %>%
    group_by_at(vars(c(variants, "name", "type", "VE_true"))) %>%
    summarise(
      VE_est_mean = mean(VE_est), VE_est_sd = sd(VE_est), 
      n_study_mean = mean(n_study)
    ) %>% 
    ungroup()
  
  return(pop_avg)
}

#------------------------------------------------------------------------------
# Logging funtions - optionally print to stdout and a file
#------------------------------------------------------------------------------

double_cat <- function(msg, file, verbose = TRUE) {
  if(verbose) cat(msg)
  cat(msg, file = file, append = T)
}

double_print <- function(printdata, file, verbose = TRUE) {
  if(verbose) print(printdata)
  capture.output(print(printdata), file = file, append = T)
}

#------------------------------------------------------------------------------
# Copies info folders
#------------------------------------------------------------------------------

copy_info <- function(from, to) {

  # Set up directories
  to_copy <- c("full_log","parameters_used","settings_used")
  start_dirs <- file.path(from, to_copy)
  end_dirs <- file.path(to, to_copy)

  # Create directories
  end_f <- function(dir) if(!(dir.exists(dir))) dir.create(dir)
  start_f <- function(dir) {
    if(!(dir.exists(dir))) cat("info folder", dir, "not found\n")
  }
  lapply(start_dirs, start_f)
  lapply(end_dirs, end_f)

  # Copy files
  ind <- 0
  for(dir in start_dirs) {
    ind <- ind+1
    files <- list.files(dir)
    paths <- file.path(dir, files)
    lapply(paths, file.copy, end_dirs[ind], overwrite=TRUE)
  }
}

#------------------------------------------------------------------------------
# Returns min and max of the specified variable in dfs
#------------------------------------------------------------------------------

get_minmax <- function(data_filepaths, var) {
  vals <- c()
  for(data_file in data_filepaths) {
    df <- read.csv(data_file)
    df <- calc_useful(df) %>% take_averages(all_variants)
    vals <- c(vals, unlist(df[ , var]))
  }
  vals <- na.omit(vals)
  vals <- vals[vals > -1 & vals < 1]

  return(c(min(vals),max(vals)))
}

#------------------------------------------------------------------------------
# Figures out the varied parameters from the complete dataset
#------------------------------------------------------------------------------

get_varied <- function(df, possibilities) {
  nms_all <- names(df)
  nms_all <- nms_all[nms_all %in% possibilities]
  is_varied <- function(col) {
    if (length(unique(na.omit(col))) > 1) return(TRUE)
    else return(FALSE)
  }
  varied <- sapply(df[ , nms_all], is_varied)

  varied <- names(varied)[varied]

  return(varied)
}

#------------------------------------------------------------------------------
# Figures out whether the data represents fixed variation or not
#------------------------------------------------------------------------------

is_fixed_var <- function(df, varied) {
  len_un <- function(vec) length(unique(na.omit(vec)))>1
  vec <- df %>% 
    mutate(call = cumsum(run - lag(run, default=0) < 0) + 1) %>%
    select_at(vars(c(varied,"call"))) %>%
    group_by(call) %>%
    summarise_all(funs(len_un)) %>%
    select(-call) %>%
    summarise_all(funs(any)) %>%
    slice(1) %>%
    unlist()
  return(!any(vec))
}

#------------------------------------------------------------------------------
# Reads all csv files in a folder and aggregates them for graphing
#------------------------------------------------------------------------------

read_all_csv <- function(datapath, parameter_names) {
  dfs <- data.frame()
  for (filename in list_files_with_exts(datapath, "csv")) {
    df <- read.csv(filename)
    df$p_test_nonari <- df$p_test_nonari / df$p_test_ari # Recover prob rat
    df <- calc_useful(df) %>% take_averages(parameter_names)
    df$filename <- basename(filename)
    dfs <- rbind(dfs, df)
  }
  return(dfs)
}