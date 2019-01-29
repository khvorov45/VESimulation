#include <Rcpp.h>
#include <thread>
// [[Rcpp::plugins(cpp11)]]
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame sim_repeat(DataFrame estimates, int Npop, String par_log)
{
	Function take_averages("take_averages");
	Function get_true_VE("get_true_VE");
	Function rbind("rbind");
	
	Function sim_pop("sim_pop");
	Function sim_pop_copy("sim_pop");
	
	DataFrame pop_many_1;
	DataFrame pop_many_2;
	
	int it_num = Npop/2;
	
	std::thread t1([sim_pop, estimates, &pop_many_1, &it_num, rbind] {
		for (int i = 0; i < it_num; ++i) {
			DataFrame pop = sim_pop(estimates);
			IntegerVector run(pop.nrow(),i);
			pop["run"] = run;
			pop_many_1 = rbind(pop_many_1, pop);
			std::cout << "thread 1 " << i << std::endl;
		}
	});
	
	std::thread t2([sim_pop_copy, estimates, &pop_many_2, &it_num, rbind] {
		
		for (int i = 0; i < it_num; ++i) {
			
			DataFrame pop = sim_pop_copy(estimates);
			//IntegerVector run(pop.nrow(),i);
			//pop["run"] = run;
			//pop_many_2 = rbind(pop_many_2, pop);
			std::cout << "thread 2 " << i << std::endl;
		}
	});
	
	t1.join();
	t2.join();
	
	DataFrame pop_many = rbind(pop_many_1,pop_many_2);
	
	DataFrame pop_avg = take_averages(pop_many);
	
	NumericVector true_VE_SEXP = get_true_VE(estimates);
	double true_VE_dbl = true_VE_SEXP[0];
	NumericVector true_VE_vec(pop_avg.nrow(),true_VE_dbl);
	pop_avg["VE_true"] = true_VE_vec;
	DataFrame pop_avg_df = pop_avg;
	
	return pop_avg_df;
}