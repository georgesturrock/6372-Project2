proc prinqual data=kobe out=kobe_pq plots=all;
transform identity (shot_made_flag shot_distance attendance arena_temp avgnoisedb game_pct total_sec_remaining achilles shaq)
          opscore (action_type combined_shot_type minutes_remaining period season seconds_remaining shot_type shot_zone_area shot_zone_basic shot_zone_range game_date opponent home_away);
run;

data kobe_pq;
set kobe_pq;
if _type_ = 'CORR' then delete;
run;

proc princomp plots=all data=kobe_pq out=kobe_pca;
var taction_type tcombined_shot_type tminutes_remaining tperiod tseason tseconds_remaining total_sec_remaining shot_distance tshot_type tshot_zone_area tshot_zone_basic tshot_zone_range tgame_date topponent attendance arena_temp avgnoisedb game_pct thome_away tachilles tshaq;
id shot_made_flag;
run;

proc logistic data=kobe_pca plots=all;
*class action_type shot_zone_area shot_zone_basic shot_zone_range home_away achilles;
*model shot_made_flag = prin1-prin21 / scale=none ctable clparm=wald lackfit;
model shot_made_flag = prin1-prin3 prin5-prin8 prin10-prin19 prin21 / scale=none ctable clparm=wald lackfit;
output out=pca_pred predprobs=crossvalidate;
run;

/* === Calculate Objective Log Loss for PCA model === */
data pca_pred;
set pca_pred;
model='PCA';
log_loss = (shot_made_flag*log(XP_1) + (1 - shot_made_flag)* log(1 - XP_1));
run;

proc means data=pca_pred sum;
class model;
var log_loss;
output out=PCALogLoss sum=log_loss n=obs;
run;

data PCAlogloss;
set PCAlogloss;
obj_log_loss = (-1*(1/obs)*log_loss);
if _type_ = 1;
run;

proc print data=PCAlogloss;
title 'Objective Log Loss Summary';
title2 'PCA Regression Models';
run;
title;
title2;
