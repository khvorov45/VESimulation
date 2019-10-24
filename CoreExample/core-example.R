# Example of the core simulation
# Arseniy Khvorov
# Created 2019/25/10
# Last edit 2019/25/10

source("../Scripts/sim_pop_group.R") # Core simulation
source("../Scripts/helper_functions.R") # Summary functions

pars <- c(
  "nsam" = 1e5,
  "p_vac" = 0.5,
  "sens_vac" = 0.9,
  "spec_vac" = 0.9,
  "IP_flu" = 0.1,
  "VE" = 0.5,
  "IP_nonflu" = 0.1,
  "p_sympt_ari" = 0.4,
  "p_clin_ari" = 0.4,
  "p_test_ari" = 0.5,
  "p_test_nonari" = 0.5,
  "sens_flu" = 0.9,
  "spec_flu" = 0.9
)

pop <- sim_pop_group(pars) # A population

pop_sum <- su_pop_group(pop, group_name = "example_group", pars) # Study counts
