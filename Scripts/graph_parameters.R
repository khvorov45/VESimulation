#------------------------------------------------------------------------------
# Graphs paramter patterns
#------------------------------------------------------------------------------

graph_parameters <- function(args, usage_options, descriptions) {
  
  args_processed <- process_args(args, usage_options)
  if (!(dir.exists(args_processed$save_directory)))
    dir.create(args_processed$save_directory)

  all_data_paths <- list_files_with_exts(
    args_processed$data, exts=c("csv","tsv")
  )
  copy_info(args_processed$data, args_processed$save_directory)
  all_data_names <- basename(all_data_paths)

  all_groups <- unique(strsplit(all_data_names, "--"))
  all_groups <- unique(sapply(
    strsplit(all_data_names, "--"), 
    function(el) return(el[1])
  ))
  all_parameters <- unique(sapply(
    strsplit(all_data_names, "--"), 
    function(el) return(el[2])
  ))
  all_parameters <- gsub(".csv", "", all_parameters)
  
  for (parameter in all_parameters) {
    cat("Graphing", parameter, "\n")
    x_name <- descriptions[parameter]
    paths <- all_data_paths[grepl(parameter, all_data_paths)]
    dfs <- data.frame()
    for (path in paths) {
      df <- read.csv(path)
      
      df <- calc_useful(df) %>% take_averages(all_parameters)
      
      # Deal how I express p_test_nonari (recover original probability ratio)
      df[, "p_test_nonari"] <- df[, "p_test_nonari"] / df[ , "p_test_ari"]
      
      dfs <- rbind(dfs, df)
    }
    pl <- ggplot(dfs, aes_string(x = parameter, y = "VE_est_mean")) + theme_bw()
    
    if (parameter == "VE") {
      pl <- pl + geom_abline(intercept = 0, slope = 1, linetype = 5, lwd = 1)
    } else {
      pl <- pl + geom_hline(aes(yintercept = VE_true), linetype = 5, lwd = 1)
    }
    
    pl <- pl +
      geom_line(aes(col = type, linetype = type), lwd = 1.2, na.rm = T) +
      scale_x_continuous(name = x_name) +
      scale_y_continuous(name = "Estimated VE") + 
      scale_color_manual(
        name = "Data type", values = c(4,2),
        labels = c("Administrative","Surveillance")
      ) + 
      scale_fill_manual(
        name = "Data type", values = c(4,2), 
        labels = c("Administrative","Surveillance")
      ) +
      scale_shape_manual(
        name = "Data type", values = c(21,24),
        labels = c("Administrative","Surveillance")
      ) +
      scale_linetype_manual(
        name = "Data type", values = c("solid", "dotdash"),
        labels = c("Administrative","Surveillance")
      ) +
      facet_wrap(vars(name)) + 
      theme(
        legend.position = "bottom", 
        panel.grid.minor = element_blank(),
        panel.spacing = unit(0,"lines"),
        axis.text.x = element_text(angle = 90, hjust = 1)
      )
    gr_name <- paste0(parameter, "--fixed_alone", ".png")
    grp_path <- file.path("FixedParameterGraphs", gr_name)
    ggsave(
      pl, device = "png", filename = grp_path, 
      width = 15, height = 10, units = "cm"
    )
    cat("Done\n")
  }
  cat("Done with all\n")
}

if (sys.nframe() == 0) {
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
  
  graph_parameters(
    commandArgs(trailingOnly = T), usage_options, descriptions 
  )
}
