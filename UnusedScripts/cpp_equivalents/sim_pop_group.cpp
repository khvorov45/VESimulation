#include <Rcpp.h>
// [[Rcpp::plugins(cpp11)]]
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame sim_pop_group(NumericVector parameters)
{
	
	int nsam = parameters["nsam"];
	
	NumericVector vac_true(nsam);
	NumericVector vac_mes(nsam);
	NumericVector flu(nsam);
	NumericVector nonflu(nsam);
	NumericVector ari(nsam);
	NumericVector sympt(nsam);
	NumericVector clin(nsam);
	NumericVector tested(nsam);
	NumericVector testout(nsam,NA_REAL);
	
	vac_true = rbinom(nsam, 1, parameters["p_vac"]);
	
	vac_mes[vac_true==1] = rbinom(sum(vac_true==1), 1, parameters["sens_vac"]);
	vac_mes[vac_true==0] = rbinom(sum(vac_true==0), 1, 1-parameters["spec_vac"]);
	
	//---------------------------------------------------------------------------
	
	NumericVector disease_vac{
		parameters["IP_flu"]*(1-parameters["VE"]),
		parameters["IP_nonflu"],
		1-parameters["IP_flu"]*(1-parameters["VE"])-parameters["IP_nonflu"]
	};
	
	NumericVector disease_unvac{
		parameters["IP_flu"],
		parameters["IP_nonflu"],
		1-parameters["IP_flu"]-parameters["IP_nonflu"]
	};
	
	IntegerVector result(3);
	
	for(int i = 0; i < nsam; ++i) {
		if (vac_true[i]==1) {
			rmultinom(1,disease_vac.begin(),3,result.begin());
		}
		else {
			rmultinom(1,disease_unvac.begin(),3,result.begin());
		}
		flu[i] = result[0];
		nonflu[i] = result[1];
	}
	
	ari = flu + nonflu;
	
	//---------------------------------------------------------------------------
	
	sympt[ari==1] = rbinom(sum(ari==1),1,parameters["p_sympt_ari"]);
	
	clin[sympt==1] = rbinom(sum(sympt==1),1,parameters["p_clin_ari"]);
	
	tested[clin==1] = rbinom(sum(clin==1),1,parameters["p_test_ari"]);
	tested[clin==0] = rbinom(sum(clin==0),1,parameters["p_test_nonari"]);
	
	testout[(tested==1) & (flu==1)] = rbinom(sum((tested==1) & (flu==1)),1,parameters["sens"]);
	testout[(tested==1) & (flu==0)] = rbinom(sum((tested==1) & (flu==0)),1,1-parameters["spec"]);
	
	DataFrame pop = DataFrame::create(
		_["vac_true"] = vac_true,
		_["vac_mes"] = vac_mes,
		_["flu"] = flu,
		_["nonflu"] = nonflu,
		_["ari"] = ari,
		_["sympt"] = sympt,
		_["clin"] = clin,
		_["tested"] = tested,
		_["testout"] = testout
	);
	
	return pop;
}