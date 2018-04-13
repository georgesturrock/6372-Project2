*Import Data Set;
%web_drop_table(WORK.kobe);
*FILENAME REFFILE '/home/gsturrock0/STAT2/Project 2/KobeDataProj2.csv';
FILENAME REFFILE '/home/bmanry0/sasuser.v94/MSDS 6372/final project/KobeDataProj2.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.kobe;
	GETNAMES=YES;
RUN;
%web_open_table(WORK.kobe);

/*=== DATA ENRICHMENT ===*/
*Create additional columns for analysis in data set;
data kobe;
	set kobe;
	*Total time remaining;
	total_sec_remaining = seconds_remaining + (minutes_remaining*60);
	*Convert shot made flag to numeric;
	if shot_made_flag = "NA" then shot_made_flag = .;
	num_shot_made_flag = input(shot_made_flag, 1.);
	drop shot_made_flag;
	rename num_shot_made_flag = shot_made_flag;
	*Create Home/Away indicator;
	if index(matchup, '@') > 0 then home_away = "AWAY";
	else home_away = "HOME";
	*Create Achilles Injury Flag;
	achilles = 0;
	if game_date > '07Dec2013'd then achilles = 1;
	*Create Shaq indicator for period where Kobe and Shaq both played for the Lakers;
	shaq=0;
	if game_date < '01Oct2004'd then shaq = 1;
	/* Shot Angle*/
	if loc_x = 0 then shot_angle = 90;
	else shot_angle = round(atan(loc_y/loc_x)*(180/3.1459),30);

run;

/* Shot Seqence by Game */
proc sort data=kobe;
	by game_id descending total_sec_remaining  ;
run;
 
data kobe;
  set kobe;
  shot_seq+1;
  by game_id;
  if first.game_id then shot_seq=1; 
  game_shot_id = put(catx("_", game_id, shot_seq),12.);
run;

/* Previous Shot Lag */
proc expand data=kobe out=temp_lag1;
	by game_id;
	convert shot_made_flag = last_5_shot   / transout=(movave 5);
	convert shot_made_flag = last_5_shot_weighted   / transout=(movave(1 2 3 4 5));
	convert shot_made_flag = last_shots_exp   / transout=(ewma 0.3);
run;

/* Previous Game Lag */
proc means data = kobe noprint;
	by game_id;
	var shot_made_flag;
	output out = temp_lag2 mean=game_pct;
run;

proc expand data=temp_lag2 out=temp_lag2;
	convert game_pct = last_5_game   / transout=(movave 5);
	convert game_pct = last_5_game_weighted   / transout=(movave(1 2 3 4 5));
	convert game_pct = last_games_exp   / transout=(ewma 0.3);
run;

data kobe;
	merge kobe 
		temp_lag1(keep=game_id last_5_shot last_5_shot_weighted last_shots_exp)
		temp_lag2(keep=game_id last_5_game last_5_game_weighted last_games_exp);
run;

proc datasets library=work nolist nodetails;
   delete temp_lag1 temp_lag2;
run;

/* === Calculate Per X Shooting Percentage Columns ===*/
%macro meanPct(group_cols, table_name, var_name = pct_made);
	%let grp_vars = %sysfunc(tranwrd(&group_cols,%str( ),%str(,)));
	proc sql;
		create table tmp_mean_data as
		select *, mean(shot_made_flag) as &var_name
		from kobe
		group by &grp_vars;
	quit;
	
	data &table_name;
		set tmp_mean_data;
	run;
	proc datasets library=work nolist nodetails;
   		delete tmp_mean_data;
	run;
%mend;
	
%meanPct(game_id, kobe, var_name = game_pct);

/* Separate Kaggle test from remaining data */
data kobe kaggle_test;
	set kobe;
	if missing(shot_made_flag) then output kaggle_test;
	else output kobe;
run;

/*=== DATA EXPLORATION ===*/
*sort data prior to running proc sgscatter;
proc sort data=kobe;
by shot_made_flag;
run;

proc sgscatter data=kobe;
by shot_made_flag;
matrix attendance arena_temp avgnoisedb game_pct total_sec_remaining / ellipse=(type=mean alpha=.05) diagonal=(histogram kernel);
run;

/* === PROC CORR Test for multicolinearity and covariance === */
proc corr data=work.kobe;
var shot_made_flag minutes_remaining period seconds_remaining shot_distance game_date attendance arena_temp avgnoisedb game_pct total_sec_remaining;
run;


/* Character variable freq checks */
data kobe_explore;
	set kobe;
	drop game_shot_id;
run;

proc freq data=kobe_explore order=freq page;
  tables (_CHARACTER_ period minutes_remaining shaq achilles)*shot_made_flag/ nocum nocol nopercent chisq;
run;

/*=== Time Series Analsis ===*/
%macro seriesPlot(xvar, grp_var = NONE);
	%if &grp_var = NONE %then %let all_vars = &xvar;	
	%else %let all_vars = &grp_var &xvar;
	proc sort data=kobe out=tmp_plot_data;
		by &all_vars;
	run;
	proc means data = tmp_plot_data noprint;
		by  &all_vars;
		var shot_made_flag;
		output out = tmp_plot_data mean=mean_pct lclm=lower uclm=upper;
	run;
	%if &grp_var = NONE %then 
		%do;
			proc sgplot data=tmp_plot_data;
				*band x = &xvar lower = lower upper = upper;
				series x = &xvar y = mean_pct;
			run;
		%end;
	%else
		%do;
			proc sgplot data=tmp_plot_data;
				*band x = &xvar lower = lower upper = upper / group=&grp_var transparency=.6;
				series x = &xvar y = mean_pct / group=&grp_var;
			run;
		%end;
%mend;
%seriesPlot(minutes_remaining);
%seriesPlot(minutes_remaining, grp_var = home_away);
%seriesPlot(period, grp_var = home_away);
%seriesPlot(game_date);


/*=== Macro for zoned heat map scatter plot ===*/
%macro make_heat_scatter(cat_vars);
	ods graphics on / width=6in height=6in noscale;
	%meanPct(&cat_vars., tmp_plot_data, var_name = pct_made);
	proc sgplot data=tmp_plot_data;
		scatter x = loc_x y = loc_y /colorresponse=pct_made colormodel=(cxD05B5B cxFBFAEF cx667FA2) transparency=0.6 
										MARKERATTRS=(SYMBOL=CircleFilled size = 4);
	run;
	proc datasets library=work nolist nodetails;
   		delete tmp_plot_data;
	run;
%mend;
%make_heat_scatter(shot_angle);
%make_heat_scatter(shot_zone_range);
%make_heat_scatter(shot_zone_range shot_angle);


/*=== Shot Clustering ===*/
/* Shot Clustering */
proc cluster data = kobe method=complete outtree=clust1 plots=all NOID PRINT=500 pseudo ccc;                                                                       
  var loc_x loc_y shot_made_flag;                                                                                                        
  id game_shot_id;                                                                                                                                 
run;  

proc sort data = kobe;                                                                                                               
  by game_shot_id;                                                                                                                               
run; 

%macro addCluster(nclust);
	proc tree data = clust1 nclusters=&nclust  out=clust&nclust. dock=5 noprint;                                                                              
	  id game_shot_id;   
	run; 
	data clust&nclust.;
		set clust&nclust.;
		if missing(CLUSNAME) then CLUSNAME = "OTHER";
		rename CLUSNAME = CLUSTGRP&nclust;
		drop CLUSTER;
	run;
	proc sort data = clust&nclust.;                                                                                                                 
  		by game_shot_id;                                                                                                                               
 	run;  
	data kobe;                                                                                                                            
  		merge kobe clust&nclust.;                                                                                                                 
 		by game_shot_id;                                                                                                                               
	run; 
	
	proc freq data=kobe;
		tables CLUSTGRP&nclust / chisq;
	run;
	%make_heat_scatter(CLUSTGRP&nclust);
	
	proc datasets library=work nolist nodetails;
   		delete clust&nclust.;
	run;
%mend;

%addCluster(20);
%addCluster(50);
%addCluster(100);
%addCluster(150);
%addCluster(400);

/* heatmap testing */
proc sgpanel data=kobe;
	panelby combined_shot_type;
	heatmap  x = loc_x y = loc_y / colorresponse=shot_made_flag colorstat=mean transparency=.4 colormodel=(RGBAFF000015 a00FF0066) xbinsize=20 ybinsize=30;
run;

proc sgpanel data=kobe;
	panelby shot_zone_range;
	heatmap  x = loc_x y = loc_y / colorresponse=shot_made_flag colorstat=mean transparency=.4 colormodel=(RGBAFF000015 a00FF0066) xbinsize=20 ybinsize=30;
run;

proc sgpanel data=kobe;
	panelby shot_zone_range shot_angle;
	heatmap  x = loc_x y = loc_y / colorresponse=shot_made_flag colorstat=mean transparency=.4 colormodel=(RGBAFF000015 a00FF0066) xbinsize=30 ybinsize=30;
run;

proc sql;
	select distinct game_id, game_date
	from kobe
	order by game_id;
quit;


