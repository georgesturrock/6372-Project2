/* === Logistic Regression Models === */

**kitchen sink logistic regression model;
*proc logistic data=kobe plots=all;
*class action_type combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range opponent home_away achilles shaq;
*model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
*output out=kitchensink_pred predprobs=crossvalidate;
*run;

*manual logistic regression model;
proc logistic data=kobe plots=all;
class action_type shot_zone_area shot_zone_basic shot_zone_range home_away achilles;
model shot_made_flag = action_type minutes_remaining period seconds_remaining /*total_sec_remaining*/ shot_zone_area shot_zone_basic shot_zone_range game_pct home_away achilles minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
output out=manual_pred predprobs=crossvalidate;
run;

*Backward variable selection with Proc logistic;
proc logistic data=kobe plots=all;
class action_type combined_shot_type /*season*/ shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period /*season*/ seconds_remaining total_sec_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=backward;
run;

proc logistic data=kobe plots=all;
class action_type shot_zone_area shot_zone_basic shot_zone_range;
model shot_made_flag = action_type minutes_remaining period seconds_remaining shot_zone_area shot_zone_basic shot_zone_range game_pct minutes_remaining*seconds_remaining / scale=none ctable clparm=wald lackfit;
output out=Backward_Pred predprobs=crossvalidate;
run;

*Forward variable selection;
title 'Forward Selection';
proc logistic data=kobe plots=all;
class action_type combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining total_sec_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=forward;
run;

*Stepwise variable selection;
title 'Stepwise Selection';
proc logistic data=kobe plots=all;
class action_type combined_shot_type season shot_type shot_zone_area shot_zone_basic shot_zone_range team_name opponent home_away achilles shaq;
model shot_made_flag = action_type combined_shot_type minutes_remaining period season seconds_remaining total_sec_remaining shot_distance shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent attendance arena_temp avgnoisedb game_pct home_away achilles shaq minutes_remaining*seconds_remaining / selection=stepwise;
run;
title;

*Model selected by Forward and Stepwise is the same;
proc logistic data=kobe plots=all;
class action_type period shot_zone_area shot_zone_basic shot_zone_range;
model shot_made_flag = action_type period seconds_remaining total_sec_remaining shot_zone_area shot_zone_basic shot_zone_range game_date game_pct / scale=none ctable clparm=wald lackfit;
output out=FwdandStep_Pred predprobs=crossvalidate;
run;

/* === Calculate Objective Log Loss for all models === */
data fwdandstep_pred;
set fwdandstep_pred;
model='forward and stepwise';
log_loss = (shot_made_flag*log(XP_1) + (1 - shot_made_flag)* log(1 - XP_1));
run;

data manual_pred;
set manual_pred;
model='manual';
log_loss = (shot_made_flag*log(XP_1) + (1 - shot_made_flag)* log(1 - XP_1));
run;

data backward_pred;
set backward_pred;
model='backward';
log_loss = (shot_made_flag*log(XP_1) + (1 - shot_made_flag)* log(1 - XP_1));
run;

data concat;
set fwdandstep_pred manual_pred backward_pred;
keep model log_loss;
run;

proc means data=concat sum;
class model;
var log_loss;
output out=LogLoss sum=log_loss n=obs;
run;

data logloss;
set logloss;
obj_log_loss = (-1*(1/obs)*log_loss);
if _TYPE_ = 1;
run;

proc print data=logloss;
title 'Objective Log Loss Summary';
title2 'Logistic Regression Models';
run;
title;
title2;

/* === Create Influence Plots for logistic regression === */
proc logistic data=kobe /*descending*/ plots(maxpoints=none label only)=(leverage dpc);
class action_type shot_zone_area shot_zone_basic shot_zone_range home_away achilles;
model shot_made_flag = action_type minutes_remaining period seconds_remaining /*total_sec_remaining*/ shot_zone_area shot_zone_basic shot_zone_range game_pct home_away achilles minutes_remaining*seconds_remaining;
run;

*examine observations 3521 and 22118;
proc print data=kobe (firstobs=22118 obs=22118);
run;
