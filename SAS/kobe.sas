*Import Data Set;
%web_drop_table(WORK.kobe);

FILENAME REFFILE '/home/gsturrock0/STAT2/Project 2/KobeDataProj2.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.kobe;
	GETNAMES=YES;
RUN;

*PROC CONTENTS DATA=WORK.kobe; 
*RUN;
%web_open_table(WORK.kobe);

*Create additional columns for analysis in data set;
data kobe;
set kobe;
*Concatenate minutes and seconds remaining;
min_sec_remain = catx(':', minutes_remaining, seconds_remaining);
*Convert shot made flag to numeric;
num_shot_made_flag = input(shot_made_flag, 1.);
drop shot_made_flag;
rename num_shot_made_flag = shot_made_flag;
*Create game_pct flag;
game_pct = 0;
*Create Home/Away indicator;
home_away = index(matchup, '@');
*Create Achilles Injury Flag;
achilles = 0;
if game_date > '07Dec2013'd then achilles = 1;
*Create Shaq indicator for period where Kobe and Shaq both played for the Lakers;
shaq=0;
if game_date < '01Oct2004'd then shaq = 1;
run;

*Subset Data to create train data set;
data kobetrain;
set kobe;
if shot_made_flag ='NA' then delete;
run;

*Calculate Per Game Shooting Percentage for known shots;
proc means data=kobetrain mean;
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
update kobetrain
set game_pct = 
(select shoot_pct from gameshotpct
where kobetrain.game_id = gameshotpct.game_id)
where kobetrain.game_id in (select game_id from gameshotpct);
quit;

*sort data prior to running proc sgscatter;
proc sort data=kobetrain;
*by shot_zone_range;
by shot_made_flag;
run;

proc sgscatter data=kobetrain;
*by shot_zone_range;
by shot_made_flag;
matrix attendance arena_temp avgnoisedb game_pct / ellipse=(type=mean alpha=.05) diagonal=(histogram kernel);
run;

/* 
**********************************
*** Logistic Regression Models ***
**********************************
*/

*kitchen sink logistic regression model;
proc logistic data=kobetrain plots=all;
class action_type combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
run;

*manual logistic regression model;
proc logistic data=kobetrain plots=all;
class action_type shot_zone_area shot_zone_basic shot_zone_range home_away achilles;
model shot_made_flag action_type minutes_remaining period seconds_remaining shot_zone_area shot_zone_basic shot_zone_range game_pct home_away achilles minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
run;

*Backward variable selection with Proc logistic;
proc logistic data=kobetrain plots=all;
class action_type combined_shot_type period season shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=backward;
run;

proc logistic data=kobetrain plots=all;
class action_type period shot_zone_area shot_zone_basic shot_zone_range;
model shot_made_flag = action_type minutes_remaining period seconds_remaining shot_zone_area shot_zone_basic shot_zone_range game_pct minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
run;

*Forward variable selection;
proc logistic data=kobetrain plots=all;
class action_type period combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=forward;
run;

*Stepwise variable selection;
proc logistic data=kobetrain plots=all;
class action_type period combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=stepwise;
run;

*Model selected by Forward and Stepwise is the same;
proc logistic data=kobetrain plots=all;
class action_type period shot_zone_area shot_zone_basic shot_zone_range;
model shot_made_flag = action_type minutes_remaining period seconds_remaining period shot_zone_area shot_zone_basic shot_zone_range game_date game_pct minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
run;
