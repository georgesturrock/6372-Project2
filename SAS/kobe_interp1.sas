/*1.	The odds of Kobe making a shot decrease with respect to the distance he is from the hoop.  
If there is evidence of this, quantify this relationship.  (CIs, plots, etc.) */
proc format;
value madefmt 1='Made'
              0='Missed';
run;

proc means data=kobe n;
class shot_distance shot_made_flag;
var shot_made_flag;
output out=kobe_interp n=shots;
run;

*data kobe_interp;
*set kobe_interp;
*if _type_ = 3;
*drop _type_ _freq_;
*if shot_distance > 29 then shot_distance = 30;
*run;

data kobe_interp;
set kobe_interp;
if _type_ = 3;
drop _type_ _freq_;
if shot_distance > 21 then shot_distance_cat = 'Long Range ';
else shot_distance_cat = 'Short Range';
run;

proc sort data=kobe_interp out=kobe_interp;                                                                                                                  
   by descending shot_distance_cat descending shot_made_flag;
run;

proc freq data=kobe_interp order=data;
format shot_made_flag madefmt.;
tables shot_distance_cat*shot_made_flag / chisq  riskdiff(equal var=null) CMH relrisk cl;
exact pchi or fisher;
weight shots;
title 'Odds of Making a Shot with Respect to Distance';
title2 'Kobe Bryant';
run; 
title;
title2;