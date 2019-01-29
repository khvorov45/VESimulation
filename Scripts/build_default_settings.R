# Isn't ready

build_def_estimates <- function(filenames) {  
  
  estimates_filename <- paste0(filenames$default_ind, filenames$estimates)
  estimates_filepath <- file.path(filenames$default_folder, estimates_filename)
  
  cat("\nRefreshing estimates... ")
  estimates <- read_from_gs("Estimates","Table", skip = 1)
  write.csv(estimates, estimates_filepath, row.names = F)
  cat("Done\n")
  
  cat("Estimates table saved to:", estimates_filepath, "relative to main folder\n")
  setwd(called_from)
}

build_def_groups <- function(file_index_loc = "_file_index.json") {  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  source("build_scripts_utilities.R")
  
  set_wd_to_scripts()
  filenames <- fromJSON(file_index_loc)
  source(filenames$helper_functions)
  
  def_estimates_filename <- paste0(filenames$default_ind, filenames$estimates)
  def_estimates_path <- file.path(filenames$default_folder, def_estimates_filename)
  def_estimates <- read.csv(def_estimates_path)
  
  allowed_groups_filename <- paste0(filenames$default_ind, filenames$allowed_groups)
  allowed_groups_filepath <- file.path(filenames$default_folder, allowed_groups_filename)
  
  cat("\nRefreshing allowed groups list... ")
  allowed_groups <- get_clean_colnames(def_estimates)
  allowed_groups <- allowed_groups[!(allowed_groups %in% c("parameter","description"))]
  cat(toJSON(allowed_groups, pretty = T), file = allowed_groups_filepath)
  cat("Done\n")
  
  cat("Allowed groups saved to:", allowed_groups_filepath, "in scripts folder\n")
  
  setwd(called_from)
}

build_def_vary_table <- function(file_index_loc = "_file_index.json") {  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  source("build_scripts_utilities.R")
  
  set_wd_to_scripts()
  filenames <- fromJSON(file_index_loc)
  
  vary_table_filename <- paste0(filenames$default_ind, filenames$vary_table)
  vary_table_filepath <- file.path(filenames$default_folder, vary_table_filename)
  
  cat("\nRefreshing variation table... ")
  vary_table <- make_vary_table()
  cat(toJSON(vary_table, pretty = T), file = vary_table_filepath)
  cat("Done\n")
  
  cat("Variation table saved to:", vary_table_filename, "in scripts folder\n")
  
  setwd(called_from)
}

read_from_gs <- function(filename, sheetname, skip = 0) {
  suppressMessages(
    df <- gs_title(filename) %>% 
      gs_read(ws = sheetname, skip = skip) %>% 
      as.data.frame())
  return(df)
}

make_vary_table <- function() {
  
  cycle_0.1_to_0.9 <- seq(0,1,0.1)
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
    "sens" = cycle_test,
    "spec" = cycle_test)
  
  return(vary_table)
}

if(sys.nframe()==0) {
  library(jsonlite)
  library(googlesheets)
  suppressMessages(library(dplyr))
  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  source("build_scripts_utilities.R")
  
  set_wd_to_scripts()
  filenames <- fromJSON("_file_index.json")
  source(filenames$scripts['helper_functions'])
  
  build_def_estimates()
}

