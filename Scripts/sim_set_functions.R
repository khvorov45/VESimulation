#------------------------------------------------------------------------------
# Sets appropriate random functions to population parameter estimates
#------------------------------------------------------------------------------

sim_set_functions <- function(pop_est, settings) {

  func_dic <- list("beta" = rbeta)
  Npop <- settings$Npop

  get_rfun <- function(group) {
    # Hope everything has exactly 2 parameters
    fun_base <- func_dic[[group[1]]]
    par1 <- as.numeric(group[2])
    par2 <- as.numeric(group[3])
    mod_base <- function() {
      return(fun_base(Npop,par1,par2))
    }
    return(mod_base)
  }

  for(variant_name in names(settings$to_vary)) {
    for(group_name in settings$vary_in_group) {
      vary_info <- settings$to_vary[[variant_name]][[group_name]]
      if (is.na(vary_info[1])) 
        stop("no variantion specified for ", variant_name, " ", group_name)
      if(!is.numeric(vary_info[1])) {
        if(vary_info[1] %in% names(func_dic)) {
          pop_est[[variant_name]][[group_name]] <- get_rfun(vary_info)
          settings$to_vary[[variant_name]][[group_name]] <- NULL
        } else stop("don't know ", vary_info[1], " distribution")
      }
    }
    if(length(settings$to_vary[[variant_name]])==0) {
      settings$to_vary[[variant_name]] <- NULL
    }
  }

  data <- sim_cycle_parameter(pop_est, settings)

  return(data)
}