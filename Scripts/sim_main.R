#------------------------------------------------------------------------------
# Does an initial estimate format
#------------------------------------------------------------------------------

sim_main <- function(estimates, settings) {
  
  # Format estimates and log them:
  pop_est <- format_estimates_init(estimates, settings$group)
  double_cat(
    "Estimates initial format:\n", file = settings$save_locs$full_log, FALSE
  )
  double_print(pop_est, file = settings$save_locs$full_log, FALSE)
  double_cat("\n", file = settings$save_locs$full_log, FALSE)
  
  # Simulate:
  data <- sim_set_functions(pop_est, settings)
  
  return(data)
}
