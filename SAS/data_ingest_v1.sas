*Import Data Set;
PROC IMPORT DATAFILE='/home/bmanry0/sasuser.v94/MSDS 6372/final project/KobeDataProj2.csv'
	replace
	DBMS=CSV
	OUT=WORK.kobe;
	GETNAMES=YES;
RUN;

*Create additional columns for analysis in data set;
data kobe;
	set kobe;
	*Concatenate minutes and seconds remaining;
	/*min_sec_remain = catx(':', minutes_remaining, seconds_remaining);*/
	*Total time remaining;
	total_sec_remaining = seconds_remaining + (minutes_remaining*60);
	*Convert shot made flag to numeric;
	if shot_made_flag = "NA" then shot_made_flag = .;
	num_shot_made_flag = input(shot_made_flag, 1.);
	drop shot_made_flag;
	rename num_shot_made_flag = shot_made_flag;
	*Create game_pct flag;
	game_pct = 0;
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

/* Separate Kaggle test from remaining data */
data kobe kaggle_test;
	set kobe;
	if missing(shot_made_flag) then output kaggle_test;
	else output kobe;
run;

/* === Calculate Per Game Shooting Percentage Columns in Kobe and Kaggle_test ===*/
*Calculate Per Game Shooting Percentage for known shots;
proc means data=kobe mean;
class game_id;
var shot_made_flag;
output out=gameshotpct mean=shoot_pct;
run;

*Join per game shooting percentage back to kobe;
proc sql;
update kobe
set game_pct = 
(select shoot_pct from gameshotpct
where kobe.game_id = gameshotpct.game_id)
where kobe.game_id in (select game_id from gameshotpct);
quit;

*Join per game shooting percentage back to kobetrain;
proc sql;
update kaggle_test
set game_pct = 
(select shoot_pct from gameshotpct
where kaggle_test.game_id = gameshotpct.game_id)
where kaggle_test.game_id in (select game_id from gameshotpct);
quit;

*sort data prior to running proc sgscatter;
proc sort data=kobe;
by shot_made_flag;
run;

proc sgscatter data=kobe;
by shot_made_flag;
matrix attendance arena_temp avgnoisedb game_pct / ellipse=(type=mean alpha=.05) diagonal=(histogram kernel);
run;

/*=== DATA EXPLORATION ===*/
/* Character variable freq checks */
proc freq data=kobe order=freq page;
  tables _CHARACTER_*shot_made_flag / nocum ;
run;

/* Plot testing */
proc sgpanel data=kobe;
	panelby shot_made_flag;
	styleattrs  
     datacontrastcolors=(RGBAFF000015 ADDA0DD66 AFFDAB999 ADB7093CC AB0E0E6FF) ;
	scatter x = loc_x y = loc_y /group=shot_zone_basic ;
run;

/* Macro for zoned heat map scatter plot */
%macro make_heat_scatter(cat_vars);
	%let grp_vars = %sysfunc(tranwrd(&cat_vars,%str( ),%str(,)));

	proc sql;
	create table tmp_plot_data as
	select *, mean(shot_made_flag) as pct_made
	from kobe
	group by &grp_vars;
quit;

proc sgplot data=tmp_plot_data;
	scatter x = loc_x y = loc_y /colorresponse=pct_made colormodel=(cxD05B5B cxFAFBFE cx667FA2);
run;
%mend;
%make_heat_scatter(shot_angle);
%make_heat_scatter(shot_zone_range);
%make_heat_scatter(shot_zone_range shot_angle);

/* heatmap testing */
proc sgpanel data=kobe;
	panelby combined_shot_type;
	heatmap  x = loc_x y = loc_y / colorresponse=shot_made_flag colorstat=mean transparency=.4 colormodel=(RGBAFF000015 a00FF0066) xbinsize=20 ybinsize=30;
run;

proc sgpanel data=kobe;
	panelby shot_zone_range shot_angle;
	heatmap  x = loc_x y = loc_y / colorresponse=shot_made_flag colorstat=mean transparency=.4 colormodel=(RGBAFF000015 a00FF0066) xbinsize=30 ybinsize=30;
run;


