/* */
proc surveyselect data=kobe method=srs samprate=.7 out=train_kobe;
run;

proc sort data=kobe;
by shot_id;
run;

proc sort data=train_kobe;
by shot_id;
run;

data test_kobe;
merge train_kobe(in=a) kobe(in=b);
by shot_id;
if not a and b;
run;

proc discrim data=train_kobe pool=test crossvalidate testdata=test_kobe testout = shotRes;
class shot_made_flag;
var shot_distance attendance arena_temp loc_x loc_y;
run;

data results;
set shotRes;
keep shot_made_flag _1;  /*I have tried everything to get that column '1' */
run;

proc print data=results;
run;

/* === Calculate Objective Log Loss for PCA model === */
data results;
set results;
model='LDA';
log_loss = (shot_made_flag*log(	_1) + (1 - shot_made_flag)* log(1 - _1));
run;

proc means data=results sum;
class model;
var log_loss;
output out=LogLoss sum=log_loss n=obs;
run;

data logloss;
set logloss;
obj_log_loss = (-1*(1/obs)*log_loss);
if _type_ = 1;
run;

proc print data=logloss;
title 'Log Loss Summary';
title2 'LDA Regression Models';
run;
title;
title2;