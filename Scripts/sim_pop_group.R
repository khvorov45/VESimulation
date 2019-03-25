#------------------------------------------------------------------------------
# Simulates a dataframe representing one group in a population
# More generally, generates a population using one fixed parameter set
#------------------------------------------------------------------------------

sim_pop_group <- function(parameters) {
  
  nsam <- parameters["nsam"]
  
  empty_vec <- rep(0, nsam)
  vac_true <- empty_vec
  vac_mes <- empty_vec
  flu <- empty_vec
  nonflu <- empty_vec
  ari <- empty_vec
  sympt <- empty_vec
  clin <- empty_vec
  tested <- empty_vec
  testout <- rep(NA, nsam)
  
  vac_true <- rbinom(nsam, 1, parameters["p_vac"])
  
  vac_mes[vac_true == 1] <- rbinom(
    sum(vac_true == 1), 1, parameters["sens_vac"]
  )
  vac_mes[vac_true == 0] <- rbinom(
    sum(vac_true == 0), 1, 1 - parameters["spec_vac"]
  )
  
  #----------------------------------------------------------------------------
  
  vac_prof <- rmultinom(
    n = sum(vac_true == 1), 
    size = 1, 
    prob = c(
      parameters["IP_flu"] * (1 - parameters["VE"]),
      parameters["IP_nonflu"],
      1 - parameters["IP_flu"] * (1 - parameters["VE"]) - 
        parameters["IP_nonflu"]
    )
  )
  
  unvac_prof <- rmultinom(
    n = sum(vac_true == 0), 
    size = 1, 
    prob=c(
      parameters["IP_flu"],
      parameters["IP_nonflu"],
      1 - parameters["IP_flu"] - parameters["IP_nonflu"]
    )
  )
  
  flu[vac_true == 1] <- vac_prof[1, ]
  flu[vac_true == 0] <- unvac_prof[1, ]
  
  nonflu[vac_true == 1] <- vac_prof[2, ]
  nonflu[vac_true == 0] <- unvac_prof[2, ]
  
  ari <- flu + nonflu
  
  #----------------------------------------------------------------------------
  
  sympt[ari == 1] <- rbinom(sum(ari == 1), 1, parameters["p_sympt_ari"])
  
  clin[sympt == 1] <- rbinom(sum(sympt == 1), 1, parameters["p_clin_ari"])
  
  tested[clin == 1] <- rbinom(sum(clin == 1), 1, parameters["p_test_ari"]) 
  tested[clin == 0] <- rbinom(sum(clin == 0), 1, parameters["p_test_nonari"]) 
  
  testout[(tested == 1) & (flu == 1)] <- rbinom(
    sum((tested == 1) & (flu == 1)), 1, parameters["sens_flu"]
  )
  testout[(tested == 1) & (flu == 0)] <- rbinom(
    sum((tested == 1) & (flu == 0)), 1, 1 - parameters["spec_flu"]
  )
  
  pop <- data.frame(
    vac_true, vac_mes, flu, nonflu, ari, sympt, clin, tested, testout
  )
  
  return(pop)
}