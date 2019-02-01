#------------------------------------------------------------------------------
# Sets appropriate random functions to population parameter estimates
#------------------------------------------------------------------------------

sim_set_functions <- function(pop_est, settings) {

    data <- sim_cycle_parameter(pop_est, settings)

    return(data)
}