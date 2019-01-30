#------------------------------------------------------------------------------
# Graphs 1 or 2 variants, the first one to appear in data on x, facet by second
# Indicators appear in data in the opposite order from what they are in the 
# command line call to begin.R
#------------------------------------------------------------------------------


make_conventional_graph <- function(
  args, usage_options, all_variants, descriptions
) {
  
  args_processed <- process_args(args, usage_options)
  if(!(dir.exists(args_processed$save_directory))) 
    dir.create(args_processed$save_directory)
  
  # Add input checks?
  
  data_filepaths <- list_files_with_type(args_processed$data, type="data")
  copy_info(args_processed$data, args_processed$save_directory)
  
  if(args_processed$fix_y) {
    cat("Fixing y at ")
    ylims <- get_minmax(data_filepaths, "VE_est_mean")
    cat("min", ylims[1],"max",ylims[2],"\n\n")
  } 
  else {
    cat("Not fixing y\n\n")
    ylims <- c(NA,NA)
  } 

  amount_total <- length(data_filepaths)
  amount_done <- 0
  diffs <- c()
  for(data_file in data_filepaths) {
    start <- Sys.time()
    df <- read.csv(data_file)
    if("overall" %in% unique(df$name)) df <- df[df$name=="overall" , ]
    graph_filename <- unique(
      gsub("[.][[:alpha:]]{1,3}$",".png", basename(data_file))
    )
    
    varied <- get_varied(df, all_variants)
    
    x_axis <- varied[1]
    
    if(length(varied)>1) {
      facet_variable <- varied[2]
    } else facet_variable <- NULL
    
    y_axis <- "VE_est_mean"
    
    save_units <- "in"
    cat("File:",data_file,"\n")
    cat("Graphing",x_axis,"on x;",y_axis,"on y")
    
    if (!is.null(facet_variable)) {
      cat("; faceting by", facet_variable,"\n")
    } else { cat("\n") }
    
    pl <- graph_base_1(
      df, descriptions, args_processed$errors, args_processed$sample_size, 
      x = x_axis, y = y_axis, ylims = ylims)
    
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
  usage_options <- default_config$graph_usage
  all_variants <- names(default_config$vary_table)

  estimates_data_name <- paste0( 
    filenames$default_ind, filenames$shared_data, ".", filenames$data_ext
  )
  default_data <- read.csv(
    file.path(
      filenames$default_folder, 
      estimates_data_name
    )
  )

  descriptions <- as.character(default_data[ , "Description"])
  names(descriptions) <- default_data[ , "Parameter"]

  setwd(called_from)
  
  make_conventional_graph(
    commandArgs(trailingOnly = T), 
    usage_options, 
    all_variants,
    descriptions
  )
}
