#include <Rcpp.h>
// [[Rcpp::plugins(cpp11)]]
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame sim_pop(DataFrame estimates_final)
{
	Function rbind("rbind");
	Function su_pop_group("su_pop_group");
	Function sim_pop_group("sim_pop_group");
	Function get_group_parameters("get_group_parameters");
	Function add_overall("add_overall");
	Function calc_useful("calc_useful");
	
	int n_groups = estimates_final.ncol();
	StringVector group_names = estimates_final.names();
	DataFrame pop_summary;
	
	for (int i = 0; i < n_groups; ++i) {
		String group_name = group_names[i];
		
		NumericVector parameters = get_group_parameters(
			estimates_final, group_name
		);
		
		DataFrame group_simulated = sim_pop_group(parameters);
		
		DataFrame group_summary = su_pop_group(group_simulated,group_name);
		
		pop_summary = rbind(pop_summary, group_summary);
	}
	
	if (n_groups != 1) { pop_summary = add_overall(pop_summary); }
	
	DataFrame pop_calc = calc_useful(pop_summary);
	
	return pop_calc;
}