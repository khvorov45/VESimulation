#------------------------------------------------------------------------------
# Main graphing control function
#------------------------------------------------------------------------------

make_graph <- function(
  args, usage_options, all_variants, descriptions
) {
  
  args_processed <- process_args(args, usage_options)
  if(!(dir.exists(args_processed$save_directory))) 
    dir.create(args_processed$save_directory)
  
  data_filepaths <- list_files_with_exts(
    args_processed$data, exts=c("csv","tsv")
  )
  copy_info(args_processed$data, args_processed$save_directory)
  
  # Check y fix
  if(args_processed$fix_y) {
    stop("unimplemented y fixation")
    cat("Fixing y at ")
    ylims <- get_minmax(data_filepaths, "VE_est_mean")
    cat("min", ylims[1],"max",ylims[2],"\n\n")
  } 
  else {
    cat("Not fixing y\n\n")
    ylims <- c(NA,NA)
  } 

  # Cycle through dfs
  amount_total <- length(data_filepaths)
  amount_done <- 0
  diffs <- c()
  for(data_file in data_filepaths) {
    start <- Sys.time()

    cat("File:",data_file,"\n")
   
    df <- read.csv(data_file)

    # Do not graph multiple groups
    if("overall" %in% unique(df$name)) {
      cat("Multiple groups found, skipping\n\n")
      amount_done <- amount_done + 1
      next
    }
    
    varied <- get_varied(df, all_variants)
    
    fixed_var <- is_fixed_var(df, varied)

    df <- calc_useful(df) %>% take_averages(varied)

    graph_filename <- unique(
      gsub("[.][[:alpha:]]{1,3}$","", basename(data_file))
    )
    graph_device <- "png"
    graph_save_dir <- file.path(args_processed$save_directory, graph_filename)

    # Choose what graph to make
    if (fixed_var) graph_fixed_var(
      df, varied, descriptions, args_processed$errors, 
      args_processed$sample_size,
      ylims, graph_save_dir, graph_device
    )
    else {
      graph_prob_var(df, varied, descriptions, graph_save_dir, graph_device)
    }
    
    # End message stuff
    amount_done <- amount_done + 1
    end <- Sys.time()
    diff <- as.numeric(end - start)
    diffs <- c(diffs, diff)
    diff_short <- round(diff, 1)
    est_to_comp <- mean(diffs)*(amount_total - amount_done)
    cat(
      "\nCompleted ", amount_done, "/", amount_total," in: ", 
      diff_short, "s | ", 
      "ETC: ", round(est_to_comp,1),"s ", 
      "(",round(est_to_comp/60,1),"m) \n\n", sep = ""
      )
  }

  dev.off()
  if(file.exists("Rplots.pdf")) file.remove("Rplots.pdf")

  cat(
    "Done in ", round(sum(diffs),1), "s (", round(sum(diffs)/60,1), "m)\n",
    sep=""
  )
}

if(sys.nframe()==0) {
  library(ggplot2)
  library(ggedit)
  library(jsonlite)
  library(tools)
  suppressMessages(library(ggpubr))
  suppressMessages(library(dplyr))

  #----------------------------------------------------------------------------
  # Temporary directory change

  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  
  filenames <- fromJSON("_file_index.json")

  # File sourcing
  script_names <- paste0(
    filenames$scripts, ".", filenames$script_ext
  )
  sapply(script_names, source)

  # For argument parsing
  default_config <- read_config(filenames, default = TRUE)
  usage_options <- default_config$graph_usage

  # Variants and descriptions for graphing
  all_variants <- names(default_config$vary_table)
  estimates_data_name <- paste0( 
    filenames$default_ind, filenames$shared_data, ".", filenames$data_ext
  )
  default_data <- read.csv(
    file.path(filenames$default_folder, estimates_data_name)
  )
  descriptions <- as.character(default_data[ , "Description"])
  names(descriptions) <- default_data[ , "Parameter"]

  setwd(called_from)
  #----------------------------------------------------------------------------
  
  make_graph(
    commandArgs(trailingOnly = T), usage_options, all_variants, descriptions
  )
}
