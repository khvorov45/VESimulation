#------------------------------------------------------------------------------
# Checks that an argument is in a list of allowed ones
#------------------------------------------------------------------------------

check_argument <- function(arg, args_allowed, req_length = 9999) {
  if(length(arg) > req_length) 
    stop(paste(arg,collapse=" "), " is too many, need ", req_length)
  for(el in arg) {
    if(!(el %in% args_allowed)) {
      error_msg <- paste0("argument '", el, "' not allowed\n",
                          "allowed arguments: ")
      for(arg in args_allowed) error_msg <- paste(error_msg, arg)
      stop(error_msg)
    }
  }
}

#------------------------------------------------------------------------------
# Gets all parameter estimated, group to choose and returns narrowed estimates
#------------------------------------------------------------------------------

narrow_group <- function(all_estimates, groups) {
  needed <- data.frame(parameter = all_estimates$parameter)
  for(group in groups) {
    narrowed <- all_estimates %>% 
      select(contains(group))
    needed <- cbind(needed,narrowed)
  }
  return(needed)
}

#------------------------------------------------------------------------------
# Summarises a population group
#------------------------------------------------------------------------------

su_pop_group <- function(df_group, group_name, parameters) {
  
  summary <- data.frame("type" = c("surveillance","administrative"))
  
  #----------------------------------------------------------------------------
  
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

  for(par_name in names(parameters)) {
    summary[ , par_name] <- parameters[par_name]
  }

  return(summary)
}

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


#------------------------------------------------------------------------------
# Caclulates VE and nsam for a group
#------------------------------------------------------------------------------

calc_useful <- function(summary) {
  calcs <- summary %>% 
    mutate(
      VE_est = 1 - (case_vac/case_unvac) / (cont_vac/cont_unvac),
      n_study = case_vac + cont_unvac + case_unvac + cont_vac
    )
  return(calcs)
}

#------------------------------------------------------------------------------
# Normalise proportions (set sum to 1)
#------------------------------------------------------------------------------

normalise_prop <- function(proportions) {
  
  if(length(proportions) == 1) return(1)
  
  for(i in 1:length(proportions)) {
    proportions[[i]] <- proportions[[i]] / sum(proportions)
  }
  
  return(proportions)
}

#------------------------------------------------------------------------------
# Finds the starting size of population groups
#------------------------------------------------------------------------------

find_start_size <- function(proportions, nsam) {
  
  if(sum(proportions) != 1) stop("proportions don't add to 1")
  
  n_groups <- length(proportions)
  
  if(n_groups == 1) return(nsam)
  
  nsams <- rep(0, n_groups)
  
  for(i in 1:n_groups) {
    
    nsams[i] <- proportions[[i]] * nsam
  }
  
  return(nsams)
}

#------------------------------------------------------------------------------
# Formats the estimates
#------------------------------------------------------------------------------

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
    pop_est["p_test_ari" , ] <- 1
    pop_est["prop" , ] <- 1
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

get_group_parameters <- function(pop_est, group_name) {
    parameters <- pop_est[[group_name]]
    names(parameters) <- rownames(pop_est)
    return(parameters)
}

standardise_names <- function(all_names) {
  st_names <- gsub("[.]|[[:digit:]]|[)]|[(]", '', all_names)
  st_names <- tolower(st_names)
  return(st_names)
}

#------------------------------------------------------------------------------
# Take averages from many runs of the same population
#------------------------------------------------------------------------------

take_averages <- function(pop_many) {
  
  pop_avg <- pop_many %>% 
    group_by(name, type) %>% 
    summarise(VE_est_mean = mean(VE_est), VE_est_sd = sd(VE_est), 
              n_study_mean = mean(n_study)) %>% 
    ungroup(name)
  
  return(pop_avg)
}

#------------------------------------------------------------------------------
# Returns true VE (average if multiple groups)
#------------------------------------------------------------------------------

get_true_VE <- function(pop_est) {
  VE_true <- sum(pop_est["prop" , ] * pop_est["VE" , ])
  return(VE_true)
}

#------------------------------------------------------------------------------
# Figures out the varied parameters from the complete dataset
#------------------------------------------------------------------------------

get_varied <- function(df, possibilities) {
  nms <- names(df)
  nms <- nms[nms %in% possibilities]
  return(nms)
}

#------------------------------------------------------------------------------
# Builds the settings list for the simulation
#------------------------------------------------------------------------------

build_settings <- function(
  args_processed, sim_options, vary_table, allowed_groups, scripts_dir
) {
  #names(vary_table) <- tolower(names(vary_table))
  settings <- sim_options
  
  group <- args_processed$group
  folder <- args_processed$save_directory
  variant_names <- args_processed$variants
  if(args_processed$vary_in_group[1] == F) {
    vary_in_group <- args_processed$group
  } else {vary_in_group <- args_processed$vary_in_group}
  
  settings$group <- group
  settings$to_vary <- vary_table[variant_names]
  settings$vary_in_group <- vary_in_group
  settings$save_locs <- get_save_locs(
    folder, group, variant_names, settings$vary_in_group, scripts_dir
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

#------------------------------------------------------------------------------
# Verifies that the settings list is correct
#------------------------------------------------------------------------------

verify_settings <- function(settings, estimates) {
  names(estimates) <- tolower(names(estimates))
  
  test <- lapply(settings$group, grepl, names(estimates))
  test <- lapply(test, any)
  if(!all(unlist(test))) stop(
    "one (or more) of the groups not found in estimates"
  )
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
    "given control element(s): ",
    paste0(
      arguments[!(given %in% obtained) & grepl(control_ind, arguments)],
      collaplse = ' '
    ),
    " not recognised", sep = ""
  )
  
  return(args_processed)
}

#------------------------------------------------------------------------------
# Reads part of an argument
#------------------------------------------------------------------------------

read_arg <- function(control_indicator, control_el, args) {
  looking_for <- paste0(control_indicator, control_el)
  if(!(looking_for %in% args)) return(FALSE)
  all_control_inds <- get_control_inds(control_indicator, args)
  needed_ind <- match(looking_for, args)
  next_ind <- all_control_inds[match(needed_ind, all_control_inds) + 1]
  
  if((needed_ind) == (next_ind - 1)) return(TRUE)
  
  arg <-args[(needed_ind + 1) : (next_ind - 1)]
  #arg <- tolower(arg)
  
  return(arg)
}

#------------------------------------------------------------------------------
# Gets all the control element indeces in the arguments
#------------------------------------------------------------------------------

get_control_inds <- function(control_indicator, args) {
  control_inds <- c()
  for(i in length(args)) {
	control_els <- args[grepl(paste0('^',control_indicator), args)]
	control_inds <- match(control_els, args)
  }
  control_inds[length(control_inds)+1] <- length(args) + 1
  return(control_inds)
}

#------------------------------------------------------------------------------
# Gets save locations
#------------------------------------------------------------------------------

get_save_locs <- function(folder, group, to_vary_names,vary_in_group,scripts_dir) {
  save_locs <- list(folder = folder)
  filename <- get_save_filename(group,to_vary_names,vary_in_group)
  save_locs$data <- 
    paste0(folder,"/",filename,".csv")
  save_locs$settings <- 
    paste0(folder,"/","settings_used","/",filename,".txt")
  save_locs$parameters <- 
    paste0(folder,"/","parameters_used","/",filename,".txt")
  save_locs$full_log_perm <-
    paste0(folder,"/","full_log","/",filename,".log")
  save_locs$full_log <-
    file.path(scripts_dir, "_current.log")
  save_locs$parallel_log <-
    paste0(folder,"/","full_log","/","parallel.log")
  for(filepath in save_locs)
    ifelse(dir.exists(dirname(filepath)), F, dir.create(dirname(filepath)))
  return(save_locs)
}

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

clean_names <- function(names) {
  clean_names <- na.omit(names)
  clean_names <- clean_names[clean_names != ""]
  return(clean_names)
}

#------------------------------------------------------------------------------
# Prints to stdout and a file
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
# Determines if what's been passed is a file or a directory
#------------------------------------------------------------------------------

is_directory <- function(arg) {
  if(grepl(".*[.][[:alpha:]]{1,3}", arg)) { return(FALSE) }
  else { return(TRUE) }
}

#------------------------------------------------------------------------------
# Copies info folders (used for graphing)
#------------------------------------------------------------------------------

copy_info <- function(from, to) {
  to_copy <- c("full_log","parameters_used","settings_used")
  start_dirs <- file.path(from, to_copy)
  end_dirs <- file.path(to, to_copy)

  end_f <- function(dir) if(!(dir.exists(dir))) dir.create(dir)
  start_f <- function(dir) {
    if(!(dir.exists(dir))) stop("info folder(s) not found")
  }

  lapply(start_dirs, start_f)
  lapply(end_dirs, end_f)

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
    vals <- c(vals, df[ , var])
  }
  vals <- na.omit(vals)
  vals <- vals[vals > -1 & vals < 1]

  return(c(min(vals),max(vals)))
}

#------------------------------------------------------------------------------
# Cleans the column names of a dataframe
#------------------------------------------------------------------------------

get_clean_colnames <- function(df) {
  cur_names <- names(df)
  clean_names <- tolower(cur_names)
  clean_names <- gsub("[.]|[[:digit:]]", '', clean_names)
  return(clean_names)
}

#------------------------------------------------------------------------------
# Reads a given setting from a given folder
#------------------------------------------------------------------------------

read_setting <- function(folder, setting_name) {
  path <- file.path(folder, setting_name)
  if(grepl(".csv", setting_name)) setting <- read.csv(path)
  else if(grepl(".json", setting_name)) setting <- fromJSON(path)
  else stop("unrecognised extension in ", setting_name)
  return(setting)
}

#------------------------------------------------------------------------------
# Registers parallel backend
#------------------------------------------------------------------------------

register_par <- function() {
  n_cores <- detectCores()
  cat(paste("Registering parallel backend with", n_cores, "cores... "))
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)

  clusterEvalQ(cl, source("fix_lib_path.R"))
  clusterEvalQ(cl, fix_lib_path())
  cat("Done\n")
}

#------------------------------------------------------------------------------
# Reads config files in the appropriate profile folder. 
# Assumes we are already in scripts.
#------------------------------------------------------------------------------

read_config <- function(
  filenames, default = !user, user = !default, profile_name = NA
) {
  if(default) {
    folder <- filenames$default_folder
    config_names <- c(
      filenames$shared_config,filenames$default_only_config
    )
    config_files <- paste0(
      filenames$default_ind, config_names, ".",filenames$config_ext
    )
    
  } else {
    folder <- file.path(filenames$user_folder, profile_name)
    if(!dir.exists(folder)) stop("no profile ", profile_name, " found")
    config_names <- filenames$shared_config
    config_files <- paste0(config_names, ".",filenames$config_ext)
  }
  config_filepaths <- file.path(folder,config_files)
  config <- lapply(config_filepaths, fromJSON)
  names(config) <- config_names
  return(config)
}

#------------------------------------------------------------------------------
# Returns all possible variant combinations
#------------------------------------------------------------------------------

get_variant_combinations <- function(possibilities, rule) {
  
  #possibilities <- tolower(possibilities)
  #rule <- tolower(rule)
  
  n <- length(rule)
  
  placeholder <- list()
  for(i in 1:n) {
    placeholder[[i]] <- possibilities[grepl(rule[i],possibilities)]
    if(identical(placeholder[[i]],character(0))) stop(rule[i], " not found")
  } 
  
  combos <- placeholder[[1]]
  placeholder <- placeholder[-1]
  combos <- cycle_through(placeholder, combos)
  
  return(combos)
}

cycle_through <- function(iterable, combos) {
  if(length(iterable)==0) {
    log_vec <- sapply(combos, contains_duplicates)
    combos <- combos[!log_vec]
    return(combos)
  }
  
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

