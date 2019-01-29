init_user_profile <- function(filenames, profile_name) {
  
  configs <- paste0(
    filenames$default_ind,filenames$shared_config,'.',filenames$config_ext
  )
  data_f <- paste0(
    filenames$default_ind,filenames$shared_data,'.',filenames$data_ext
  )
  
  filelist <- c(configs, data_f)
  
  filepaths <- file.path(filenames$default_folder, filelist)
  
  cat("Copying files:\n")
  for(filepath in filepaths) {
    new_name <- gsub("^_","",basename(filepath))
    new_path <- file.path(filenames$user_folder, profile_name, new_name)
    if(!dir.exists(dirname(new_path))) dir.create(dirname(new_path))
    cat(filepath,"to",new_path,"\n")
    file.copy(filepath, new_path, overwrite = T)
  }
}

if(sys.nframe()==0) {
  library(jsonlite)
  
  full_cmds <- commandArgs(trailingOnly = F)
  scripts_dir <- dirname(gsub("--file=","",full_cmds[4]))
  setwd(scripts_dir)
  filenames <- fromJSON("_file_index.json")
  sapply(paste0(filenames$scripts,'.',filenames$script_ext), source)
  def_config <- read_config(filenames, default = TRUE)
  
  prossessed_args <- process_args(
    commandArgs(trailingOnly=TRUE), def_config$init_profile_usage
  )
  profile_name <-  prossessed_args$profile_name
  init_user_profile(filenames, profile_name)
}