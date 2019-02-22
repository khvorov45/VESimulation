#------------------------------------------------------------------------------
# Builds the default settings found in default folder. 
# Will place the files wherever it is called from.
#------------------------------------------------------------------------------

build_def_estimates <- function(filenames) {
  
  estimates_filename <- paste0(
    filenames$default_ind, filenames$shared_data, '.', filenames$data_ext
  )
  
  cat("\nRefreshing estimates... ")
  estimates <- read_from_gs("Estimates","Table", skip = 1)
  write.csv(estimates, estimates_filename, row.names = F)
  cat("Done\n")
  
  cat("Estimates table saved to:", estimates_filename, "\n")
}

build_def_groups <- function(filenames) { 
  def_data <- read_def_est(filenames)
  
  allowed_groups_filename <- paste0(
    filenames$default_ind, "allowed_groups", '.', filenames$config_ext
  )

  cat("\nRefreshing allowed groups list... ")
  groups <- names(select(def_data, -Parameter, -Description))
  allowed_groups <- standardise_names(groups)
  cat(toJSON(allowed_groups, pretty = T), file = allowed_groups_filename)
  cat("Done\n")
  
  cat("Allowed groups saved to:", allowed_groups_filename, "\n")
}

read_from_gs <- function(filename, sheetname, skip = 0) {
  suppressMessages(
    df <- gs_title(filename) %>% 
      gs_read(ws = sheetname, skip = skip) %>% 
      as.data.frame())
  return(df)
}

build_def_vary_table <- function(filenames) {

  def_data <- read_def_est(filenames)
  group_names <- names(select(def_data, -Description, -Parameter))
  par_names <- def_data[["Parameter"]]
  par_names <- par_names[par_names != "prop"]
  
  group_names <- standardise_names(group_names)
  
  vary_table_filename <- paste0(
    filenames$default_ind, "vary_table", ".", filenames$config_ext
  )
  
  constrained_vary_table_filename <- paste0(
    filenames$default_ind, "const_vary_table", ".", filenames$config_ext
  )
  
  cat("\nRefreshing variation table... ")
  
  create_entry <- function(par_name) return(list())
  full_table <- lapply(par_names, create_entry)
  names(full_table) <- par_names
  
  ref_table <- ref_vary_table()
  
  for(par_name in par_names) {
    for(group_name in group_names) {
      full_table[[par_name]][[group_name]] = ref_table[[par_name]]
    }
  }
  
  cat(toJSON(full_table, pretty = T), file = vary_table_filename)
  
  cat("Done\n")
  
  cat("Variation table saved to:", vary_table_filename, "\n")
}

ref_vary_table_full <- function() {
  
  cycle_0.1_to_0.9 <- seq(0.1,0.9,0.1)
  cycle_disease <- seq(0.1,0.6,0.1)
  cycle_test <- seq(0.6,1,0.05)
  
  vary_table <- list(
    "p_vac" = cycle_0.1_to_0.9,
    "sens_vac" = cycle_test,
    "spec_vac" = cycle_test,
    "VE" = cycle_0.1_to_0.9,
    "IP_flu" = cycle_disease,
    "IP_nonflu" = cycle_disease,
    "p_sympt_ari" = cycle_0.1_to_0.9,
    "p_clin_ari" = cycle_0.1_to_0.9,
    "p_test_ari" = cycle_0.1_to_0.9,
    "p_test_nonari" = cycle_0.1_to_0.9,
    "sens_flu" = cycle_test,
    "spec_flu" = cycle_test
  )
  
  return(vary_table)
}

ref_vary_table_const <- function() {
  cycle_0.1_to_0.9 <- seq(0.1,0.9,0.1)
  cycle_disease <- seq(0.1,0.6,0.1)
  cycle_test <- seq(0.6,1,0.05)
  
  vary_table <- list(
    "p_vac" = cycle_0.1_to_0.9,
    "sens_vac" = cycle_test,
    "spec_vac" = cycle_test,
    "VE" = cycle_0.1_to_0.9,
    "IP_flu" = cycle_disease,
    "IP_nonflu" = cycle_disease,
    "p_sympt_ari" = cycle_0.1_to_0.9,
    "p_clin_ari" = cycle_0.1_to_0.9,
    "p_test_ari" = cycle_0.1_to_0.9,
    "p_test_nonari" = cycle_0.1_to_0.9,
    "sens_flu" = cycle_test,
    "spec_flu" = cycle_test
  )
  
  return(vary_table)
}

read_def_est <- function(filenames) {
  estimates_data_name <- paste0(
    filenames$default_ind, filenames$shared_data, ".",filenames$data_ext
  )
  def_data <- read.csv(estimates_data_name)
  return(def_data)
}

if(sys.nframe()==0) {

  library(googlesheets)
  library(jsonlite)
  suppressMessages(library(dplyr))

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
  
  setwd(called_from)
  
  #----------------------------------------------------------------------------
  
  build_def_estimates(filenames)
  build_def_groups(filenames)
  build_def_vary_table(filenames)
  
  cat("\nDone\n")
}