fix_lib_path <- function() {
  lib_path <- Sys.getenv("R_LIBS_USER")
  lib_version <- basename(lib_path)
  lib_platform <- basename(dirname(lib_path))
  lib_R <- basename(dirname(dirname(lib_path)))
  lib_path_unique <- file.path(lib_R, lib_platform, lib_version)
  user_path <- Sys.getenv("R_USER")
  if(!grepl("[D|d]ocuments", user_path) & grepl("[U|u]sers", user_path)) {
    user_path <- file.path(user_path, "Documents")
  }
  lib_path <- file.path(user_path, lib_path_unique)
  .libPaths(lib_path)
}