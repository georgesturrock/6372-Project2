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

proc discrim data=train_kobe pool=test crossvalidate testdata=test_kobe testout = testout;
class shot_made_flag;
var shot_distance attendance arena_temp loc_x loc_y;
run;

data results;
set testout;
keep shot_made_flag _into_;
run;

proc print data=results;
run;

