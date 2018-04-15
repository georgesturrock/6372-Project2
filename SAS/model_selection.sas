libname sasdata '/home/bmanry0/sasuser.v94/MSDS 6372/final project/sasdata/';

/*---- SET VARIABLES ----*/
/* Set the variable name we want for the models */

data analysis_data;
	set sasdata.kobe;
	drop game_event_id game_id team_id team_name season ;
run;

proc sql;
select name into :xvars_num separated by ' '
from dictionary.columns
where libname eq 'WORK'     
  and memname eq 'ANALYSIS_DATA'
  and type = "num"
  and name    not in("shot_made_flag", "shot_id");;
  
select name into :xvars_char separated by ' '
from dictionary.columns
where libname eq 'WORK'     
  and memname eq 'ANALYSIS_DATA'
  and type = "char"
  and name    not in('game_shot_id', 'action_type', 'CLUSTGRP400', 'CLUSTGRP150', 'CLUSTGRP100', 'CLUSTGRP20');;
quit;

/*-- Create Test and Train Data --*/
proc surveyselect data=analysis_data out=analysis_data method=srs samprate=0.70 outall noprint;
run;
/*
data train test;
	set analysis_data;
	if missing(shot_made_flag) then delete;
	if selected = 1 then output train;
	else output test;
	
run;
*/
/* RUN MODELS*/
ods graphics on; 
/* Top vars for interaction terms. Determined after running several models */
/* SAS studio limits memory so only a select set of vars could be used with interaction*/
%let interact_vars = combined_shot_type|minutes_remaining|seconds_remaining|total_seconds_remaining|shot_distance|game_date|last_5_shot|last_5_shot_weighted|last_shots_exp|game_pct; 

/* Interact Selected Vars */
%macro runLogSelect(select_type, additionalArgs = link=proit);
	proc logistic data=analysis_data  outmodel=sasdata.&select_type._model plots=(oddsratio phat roc);
		class &xvars_char ;
		model shot_made_flag(event='1') = &interact_vars  @3 &xvars_char &xvars_num / selection=&select_type NODUMMYPRINT nodesignprint &additionalArgs ctable;
		output out=&select_type._Pred predprobs=crossvalidate;
	run;
	
	/* RUN MODEL ON TEST SET */
	/*proc logistic inmodel=sasdata.&select_type._model;
	      score data=test out=test_&select_type._score;
	run;*/
	
	/* LOG LOSS */
	data &select_type._Pred;
		set &select_type._Pred;
		model='forward and stepwise';
		log_loss = (shot_made_flag*log(XP_1) + (1 - shot_made_flag)* log(1 - XP_1));
	run;
	
	proc means data=&select_type._Pred sum;
		class model;
		var log_loss;
		output out=LogLoss sum=log_loss n=obs;
	run;
	
	data logloss;
		set logloss;
		obj_log_loss = (-1*(1/obs)*log_loss);
		if _TYPE_ = 1;
	run;
	
	
	/* RUN MODEL ON KAGGLE DATA */
	proc logistic inmodel=sasdata.&select_type._model;
	      score data=sasdata.KAGGLE_TEST out=&select_type.results;
	run;
	
	data &select_type.results;
		set &select_type.results;
		shot_made_flag = P_1;
		keep shot_id shot_made_flag;
	run;
	
	proc export data=&select_type.results
   		outfile= "/home/bmanry0/sasuser.v94/MSDS 6372/final project/results/&select_type.results..csv"
   		dbms=csv
   		replace;
	run;
	
	
%mend;

%runLogSelect(forward);
%runLogSelect(stepwise);









