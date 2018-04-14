/* === Interpretation Question #1 ===
 The odds of Kobe making a shot decrease with respect to the distance he is from the hoop.

 If there is evidence of this, quantify this relationship.  (CIs, plots, etc.)
 */

proc format;
value madefmt 1='Made'
              0='Missed';
value playofffmt 1='Playoffs'
                 0='Regular Season';
run;

proc means data=kobe n;
class shot_distance shot_made_flag;
var shot_made_flag;
output out=kobe_interp n=shots;
run;

data kobe_interp;
set kobe_interp;
if _type_ = 3;
drop _type_ _freq_;
if shot_distance > 16 then shot_distance_cat = 'Long Range ';
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

/* === Interpretation Question #3 ===
The relationship between the distance Kobe is from the hoop and the odds of him making the shot is 
different if they are in the playoffs.  Quantify your findings with statistical evidence one way or the other.
*/
proc means data=kobe n;
class playoffs shot_distance shot_made_flag;
var shot_made_flag;
output out=kobe_interp3 n=shots;
run;

data kobe_interp3;
set kobe_interp3;
if _type_ = 7;
drop _type_ _freq_;
if shot_distance > 16 then shot_distance_cat = 'Long Range ';
else shot_distance_cat = 'Short Range';
run;

proc sort data=kobe_interp3 out=kobe_interp3;                                                                                                                  
   by descending shot_distance_cat descending shot_made_flag;
run;

proc freq data=kobe_interp3 order=data;
format shot_made_flag madefmt.;
format playoffs playofffmt.;
tables playoffs*shot_distance_cat*shot_made_flag / chisq  riskdiff(equal var=null) CMH relrisk cl;
exact pchi or fisher EQOR;
weight shots;
title 'Odds of Making a Shot with Respect to Distance';
title2 'Accounting for Playoffs';
title3 'Kobe Bryant';
run; 
title;
title2;
title3;