#------------------------------------------------------------------------------
# Graphs 1 or 2 variants, the first one to appear in data on x, facet by second
# Indicators appear in data in the opposite order from what they are in the 
# command line call to begin.R
#------------------------------------------------------------------------------


make_conventional_graph <- function(args) {
  
  called_from <- getwd()
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  
  filenames <- fromJSON("_file_index.json")
  source("graphing_functions.R")
  source(filenames$helper_functions)
  estimates <- read.csv(file.path(filenames$user_folder, filenames$estimates))
  usage_options <- fromJSON(
    file.path(
      filenames$default_folder, 
      paste0(filenames$default_ind, filenames$graph_usage)
    )
  )
  vary_table <- fromJSON(
    file.path(
      filenames$default_folder, 
      paste0(filenames$default_ind, filenames$vary_table)
    )
  )
  setwd(called_from)
  
  args_processed <- process_args(args, usage_options)
  if(!(dir.exists(args_processed$save_directory))) 
    dir.create(args_processed$save_directory)
  
  # Add input checks?
  
  data_to_graph <- get_data(args_processed$data)
  
  amount_total <- length(data_to_graph)
  amount_done <- 0
  diffs <- c()
  for(df in data_to_graph) {
    start <- Sys.time()
    
    if("overall" %in% unique(df$name)) df <- df[df$name=="overall" , ]
    graph_filename <- unique(
      gsub("[.][[:alpha:]]{1,3}$",".png", basename(df$filename))
    )
    
    varied <- get_varied(df, names(vary_table))
    
    x_axis <- varied[1]
    
    if(length(varied)>1) {
      facet_variable <- varied[2]
    } else facet_variable <- NULL
    
    y_axis <- "VE_est_mean"
    
    save_units <- "in"
    cat("File:",unique(df$filename),"\n")
    cat("Graphing",x_axis,"on x;",y_axis,"on y")
    
    if (!is.null(facet_variable)) {
      cat("; faceting by", facet_variable,"\n")
    } else { cat("\n") }
    
    pl <- graph_base_1(
      df, estimates, args_processed$errors, args_processed$sample_size, 
      x = x_axis, y = y_axis)
    
    if (!is.null(facet_variable)) {
      pl <- add_facets(pl,facet_variable)
      save_dimensions = c(10,10)
    } else {
      save_dimensions <- c(7,4)
    }
    filename = file.path(args_processed$save_directory,graph_filename)
    ggsave(pl, 
           filename = filename, 
           units=save_units, 
           width = save_dimensions[1], height = save_dimensions[2])
    cat("saved to",filename,"\n")
  
  amount_done <- amount_done + 1
  end <- Sys.time()
	diff <- as.numeric(end - start)
	diffs <- c(diffs, diff)
  diff_short <- round(diff, 1)
	est_to_comp <- mean(diffs)*(amount_total - amount_done)
	cat("\nCompleted ", amount_done, "/", amount_total," in: ", diff_short, "s | ", 
	    "ETC: ", round(est_to_comp,1),"s ", 
	    "(",round(est_to_comp/60,1),"m) \n\n", sep = "")
  }
  
  cat("Done in ", round(sum(diffs),1), "s (", round(sum(diffs)/60,1), "m)\n",sep="")
}

if(sys.nframe()==0) {
  library(ggplot2)
  library(ggedit)
  library(jsonlite)
  library(tools)
  make_conventional_graph(commandArgs(trailingOnly = T))
}
