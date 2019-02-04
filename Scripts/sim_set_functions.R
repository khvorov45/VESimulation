#------------------------------------------------------------------------------
# Sets appropriate random functions to population parameter estimates
#------------------------------------------------------------------------------

sim_set_functions <- function(pop_est, settings) {

  func_dic <- list("beta" = rbeta)

  get_rfun <- function(group) {
    # Hope everything has exactly 2 parameters for now
    fun_base <- func_dic[[group[1]]]
    par1 <- as.numeric(group[2])
    par2 <- as.numeric(group[3])
    mod_base <- function() {
      return(fun_base(1,par1,par2))
    }
    return(mod_base)
  }

  assign_rfun <- function(pop_est_row) {
    #print(pop_est_row)
    print(rownames(pop_est_row))
    return(pop_est_row)
  }

  #print(settings$to_vary)

  # CONVERT TO LIST
  par_names <- rownames(pop_est)
  print(par_names)

  pop_est <- as.list(pop_est)
  print(pop_est)
  stop("enough")

  for(variant_name in names(settings$to_vary)) {
    for(group_name in names(settings$to_vary[[variant_name]])) {
      if (
        settings$to_vary[[variant_name]][[group_name]][1] %in% names(func_dic)
      ) {
        pop_est[variant_name , group_name] <- get_rfun(
          settings$to_vary[[variant_name]][[group_name]]
        )
      }
    }
  }

  print(pop_est)
  stop("enough")

  pop_est[ , ]

  assign_rfun_group <- function(group) {
    if(!is.numeric(group[1])) {
      if(group[1] %in% names(func_dic)) {
        return(get_rfun(group))
      }
      stop("don't know ",group[1])
    }
    return(group)
  }

  assign_rfun_var <- function(variant) {
    variant <- lapply(variant, assign_rfun_group)
    return(variant)
  }

  settings$to_vary <- lapply(settings$to_vary, assign_rfun_var)

  print(pop_est)
  stop("enough")

  data <- sim_cycle_parameter(pop_est, settings)

  return(data)
}