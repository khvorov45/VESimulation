

test_sim_repeat <- function() {
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  filenames <- fromJSON("_file_index.json")
  source(filenames$helper_functions)
  
  
  source(filenames$sim_pop)
  sim_pop_R <- sim_pop
  source(filenames$sim_repeat)
  sim_repeat_R <- sim_repeat
  
  cat("Compiling C++ code... ")
  sourceCpp("sim_pop_group.cpp")
  sim_pop_group_cpp <- sim_pop_group
  sourceCpp("sim_pop.cpp")
  sim_pop_cpp <- sim_pop
  cat("Done.\n")
  
  source(filenames$sim_pop_group)
  sim_pop_group_R <- sim_pop_group
  
  estimates <- read_setting(filenames$user_folder, filenames$estimates) # As read
  estimates_init <- format_estimates_init(estimates, c("adults","children","elderly")) # Cleaned up
  estimates_final <- format_estimates_final(estimates_init,100000) # To be sent
  parameters <- get_group_parameters(estimates_final,"children") # Extr & sent
  
  print(microbenchmark(sim_pop_R(estimates_final), sim_pop_cpp(estimates_final),times = 10))
  
  cat("end\n")
  
  setwd(called_from)
}

if(sys.nframe()==0) {
  library(Rcpp)
  library(jsonlite)
  library(gmodels)
  library(microbenchmark)
  suppressMessages(library(doParallel))
  suppressMessages(library(dplyr))
  
  options(scipen=999)
  
  test_sim_repeat()
}