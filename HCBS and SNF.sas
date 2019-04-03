/*************************************************************************************************************************************

This project is adding in aspects of the PQI program provided by the AHRQ to determine preventable SNF admissions. This will be turned 
into an academic article. Increased efficiency of programming adapted into this iteration of the project. 

@author: Robert F Schuldt
@email: rschuldt@uams.edu

**************************************************************************************************************************************/
libname cms '*****************';
libname poster '*****************';
libname zip '*****************';


/*Calling in my macro program for sorting*/
%include '*****************';


	data selected_variables (compress = yes);
		set poster.data_dementiasubset;
		drop nh_stay hosp_stay any_hosp_stay;
			where dementia = 1 or alzheimer = 1;
/* remove those patients with no cognitive difficulties*/
			if m1700_cog_function = "00" then delete;
		
/*Correct Medicare payment amount */
			if MDCR_PMT_AMT lt 0 then MDCR_PMT_AMT = 0;

/*Mark our SNF and Long term stays*/
	if SS_LS_SNF_IND_CD = "L" then long_stay = 1;
				else long_stay = 0;
	if SS_LS_SNF_IND_CD = "N" then snf_stay = 1;
				else snf_stay = 0;

			run;

	proc freq;
	table m1700_cog_function snf_stay long_stay;
	run;

	proc univariate;
	var MDCR_PMT_AMT;
	run;

	proc sql;
	create table sum_pats as
	select * ,
	sum(snf_stay) as total_pat_snf,
	sum(CASE WHEN snf_stay=1 THEN MDCR_PMT_AMT  ELSE 0 END) as total_snf_pay,
	sum(long_stay) as total_pat_long,
	sum(CASE WHEN long_stay=1 THEN MDCR_PMT_AMT  ELSE 0 END) as total_long_pay,
	from selected_variables
	group by m1700_cog_function
	order by m1700_cog_function;
	quit;

data per_pat;
	set sum_pats;

	per_pat_snf = total_pat_snf/total_snf_pay;
	per_pat_long =total_pat_long/total_long_pay;
run;

proc freq;
table per_pat_long per_pat_snf ;
by m1700_cog_function;
run; 

