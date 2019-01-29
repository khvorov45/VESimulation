# Structure

# Profile-based usage

A profile is a folder inside `user_settings` with files: `allowed_groups.json estimates.csv sim_options.json vary_table.json`

- Profile structure

  - `estimates.csv` holds the parameter values to be passed to the simulation function. Columns correspond to different parameter sets. Which columns (sets) will be passed is controlled by `allowed_groups.json`

  - `allowed_groups.json` defines a list of groups (parameter sets) that will be used for the simulation. 

    Example 1: `["special_no"]` will result in only the parameter set in column `special_no` being passed. This will result in simulations of populations where every individual is created using parameter values specified in `special_no` column in `estimates.csv` 

    Example 2: `["special_no", "special_sens"]` will result in the parameter set in column `special_no` being passed leading to the corresponding population simulations. Then the parameter set in column  `special_sens` will be passed leading to another set of simulations.

    - Defining multiple groups for one simulation set is possible as a nested list:

      Example: `["special_no", ["children", "adults", "elderly"]]` will result in one simulation set with the populations consisting of one group defined by the `special_no` column and another simulation set with the populations consisting of multiple groups defined by `children adults elderly` columns. Proportions of groups are controlled by `prop` parameter in `estimates.csv` (`prop` parameter is ignored when only one group is present in a population)

      When multiple groups are defined, the ones where parameters are to be varied should be marked with *. If no such symbols are present, parameters will be varied in all groups.

      Example:  `["special_no", ["children*", "adults", "elderly"]]` will result in variation only occurring in the `children` group.

  - `sim_options.json` defines `nsam Npop vary_rule `

    - `nsam` - starting population size

    - `Npop` - amount of populations to simulate for any one parameter set

    - `vary_rule` - controls variation. Is a list of elements, each one will be treated as a regular expression when looking for parameters to vary in `vary_table.json` 

      Example: `[".", "p_test_nonari"]` means that all the parameters will be varied as per `vary_table.json` as well as `p_test_nonari`. Resulting data will have all combinations of possible `p_test_nonari` values with the possible values of every other parameter that appears in `vary_table.json`

  -  `vary_table.json` contains all values of the parameters to be used in simulations.

- Defining a profile

  - Initialization: easiest way is to copy `default` folder inside `user_settings` and rename it
  - Definition: edit the appropriate files

- Running profile: have R execute `run_user_profile.R` script (located in the scripts folder) with the following arguments: 

  `--save_directory` `path_to_some_directory` `--profile_name` `some_profile_name`

  - Example on Windows:

   	`Rscript run_user_profile.R --save_directory my_directory --profile_name my_profile`

  ​	Assuming `Rscript` is defined in `PATH` system environment variable. If not, either define it or specify full path to `Rscript.exe`, example:

  ​	`C:\Program Files\R\R-3.5.2\bin\Rscript.exe run_user_profile.R --save_directory my_directory --profile_name my_profile`