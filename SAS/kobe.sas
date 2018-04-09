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

proc sgscatter data=kobetrain;
matrix attendance arena_temp avgnoisedb game_pct / ellipse=(type=mean alpha=.05) diagonal=(histogram kernel);
run;

