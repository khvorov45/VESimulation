#----------------------------------------------------------------------------
# Graphs tornados in each of the groups
#----------------------------------------------------------------------------

graph_tornado_groups <- function(args, usage_options) {
  
  args_processed <- process_args(args, usage_options)
  if (!(dir.exists(args_processed$save_directory)))
    dir.create(args_processed$save_directory)

  all_data_paths <- list_files_with_exts(
    args_processed$data, exts=c("csv","tsv")
  )
  copy_info(args_processed$data, args_processed$save_directory)
  
  coeffs_all <- list()
  for (data_path in all_data_paths) {
    df <- read.csv(data_path)
    varied <- unlist(strsplit(basename(data_path), "--"))[2]
    varied <- gsub(".csv", "", varied)
    varied <- unlist(strsplit(varied, "-"))
    df <- df %>% calc_useful() %>% take_averages(varied)
    coeffs <- get_coeffs(df, varied)
    group_name <- unlist(strsplit(basename(data_path), "--"))[1]
    if (length(coeffs_all) == 0) {
      for (set_name in names(coeffs)) {
        coeffs[[set_name]][, "group_name"] <- group_name
      }
      coeffs_all <- coeffs
      next
    }
    for (coeff_type in names(coeffs)) {
      coeffs[[coeff_type]][, "group_name"] <- group_name
      
      coeffs_all[[coeff_type]] <- rbind(
        coeffs_all[[coeff_type]], coeffs[[coeff_type]]
      )
    }
  }
  
  ind <- 0
  for (coeffs_name in names(coeffs_all)) {
    ind <- ind + 1 
    coeffs <- coeffs_all[[coeffs_name]]
    write.csv(coeffs, file = "temp.csv")
    gr <- ggplot(coeffs, aes(x = parameter, y = lin_coef_est)) + theme_bw() +
      geom_bar(position = "identity", stat = "identity") + 
      ylab(coeffs_name) + xlab("Parameter") +
      coord_flip() +
      facet_grid(rows = vars(group_name), cols = vars(type))   
    graph_filename <- paste0("tornados_bygroup", "--", ind, ".png")
    ggsave(
      gr, filename = file.path(args_processed$save_directory, graph_filename), 
      width = 20, height = 20, units = "cm"
    )
  }  
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

  setwd(called_from)
  #----------------------------------------------------------------------------
  
  graph_tornado_groups(
    commandArgs(trailingOnly = T), usage_options 
  )
  cat("Done.\n")
}