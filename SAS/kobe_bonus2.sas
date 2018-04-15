/* === Bonus Question 2 === */
/*
Model Kobe’s shooting percentage over time.  Does he appear to get better over time?  
Use your knowledge of the methods we have studied so far to answer this question the 
best way possible.
 */
proc means data=kobe mean;
class season;
var game_pct;
output out=seasonshotpct mean=shoot_pct;
run;

data seasonshotpct;
set seasonshotpct;
if _type_ = 1;
career_pct = 0.4462;
year = season;
substr(year,5,6)='';
put year;
num_year = input(year, 4.);
drop year;
run;

proc sgplot data = seasonshotpct;
title 'Shooting Percentage Per Season';
title2 'Kobe Bryant';
scatter x = season y = shoot_pct / datalabel=shoot_pct;
series x = season y = shoot_pct;
series x = season y = career_pct / lineattrs = (color = black);
run;
title;
title2;

proc glm data=seasonshotpct plots=all;
model shoot_pct = num_year / solution clparm;
run;

proc means data=kobe mean;
class season game_id;
var game_pct;
output out=sgshotpct mean=shoot_pct;
run;

data sgshotpct;
set sgshotpct;
if _type_ = 3;
year = season;
substr(year,5,6)='';
put year;
num_year = input(year, 4.);
drop year;
run;

proc glm data=sgshotpct plots=all;
model shoot_pct = num_year / solution clparm;
run;
