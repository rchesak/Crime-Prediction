*import data from file, define new variables and labels;
data crime_original; 
infile 'Crimerates_data.txt' DELIMITER = '09'x MISSOVER FIRSTOBS=2; 
input ID county$ State$ Land total_Pop Pop18_34 Pop65plus DOCS BEDS CRIMES Hsgrads Bgrads poverty unemp Pcincome Pers_income region; 
dRegion1 = (Region = 1); *Create dummy variables;
dRegion2 = (Region = 2);
dRegion3 = (Region = 3);
logCRIMES = log(CRIMES); *transformations of the dependent variable to see if normality can be improved;
sqrtCRIMES = sqrt(CRIMES);
squaredCRIMES = (CRIMES)**2;
cubeCRIMES = (CRIMES)**3;
invCRIMES = 1/(CRIMES);
LABEL county= 'County Name' State='State Abbreviation' Land='Land Area (sq. mi.)' logLand='Log of Land Area (sq. mi.)' total_Pop='Est. Pop.' Pop18_34='Pop. Age 18-34 (%)' invPop18_34='Inverse of Pop. Age 18-34 (%)' Pop65plus='Pop. Age 65+ (%)' DOCS='Drs per 1000 Pop.' logDOCS='Log of Drs per 1000 Pop.' BEDS='Approximate Avg Household Size' CRIMES='Serious Crimes per 1000 Pop.' sqrtCRIMES='Square Root of Serious Crimes per 1000 Pop.'
 Hsgrads='High School Attainment (%)' Bgrads='Bachelor Attainment (%)' poverty='Poverty Rate (%)' sqrtpoverty='Square Root of Poverty Rate (%)'  unemp='Unemployment Rate (%)' Pcincome='Per Capita Income ($)' invPcincome='Inverse of Per Capita Income ($)' Pers_income='Total Personal Income (Mil $)' dRegion1='North East' dRegion2='North Central' dRegion3='South';
run;

proc print data= crime_original; 
run;



*-----------Split data into training and testing set--------------;
*Creates a next dataset - adds a column splitting train and test sets;
title "Test and Train Sets for Crime";
proc surveyselect data=crime_original out=crime_xv seed=227
samprate=0.75 outall; *outall - show all the data selected (1)and not selected (0) for training;
run;
proc print data=crime_xv;
run;
* create new variable new_y = Debt for training set, and new_y = NA for testing set;
data crime; *create blank dataset;
set crime_xv; *add the xv data do it;
if selected then new_y=sqrtCRIMES; *create a field "new_y" where the response variable will only appear if it was selected as part of the training set;
run;
proc print data=crime;
run;



*----------------Data exploration--------------------;
/* look at distributions of different transformations of the response variable to find the best one (creates histogram with normal density plotted on top of histogram);*/
TITLE2 "Histogram - Crimes";
proc univariate normal; 
var CRIMES logCRIMES sqrtCRIMES squaredCRIMES cubeCRIMES invCRIMES; 
histogram / normal(mu=est sigma=est);
run;

TITLE2 "Descriptive Statistics";
proc means min max mean std stderr clm p25 p50 p75 data=crime; 
var CRIMES sqrtCRIMES Land Pop18_34 Pop65plus DOCS BEDS Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3; 
run;

TITLE2 "Histogram - Suspicious Predictors";
proc univariate normal; 
var beds Pcincome Pers_income; 
histogram / normal(mu=est sigma=est);
run;

* creates scatterplot matrix;
proc sgscatter data=crime;
title2 "Scatterplot Matrix for Crime Data";
matrix CRIMES sqrtCRIMES Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3;
run;

*computes correlation coefficient for all y and x-variables;
proc corr;
var CRIMES sqrtCRIMES Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3;
run;

* creates scatterplot matrix for suspicious x-variables;
proc sgscatter data=crime;
title2 "Scatterplot Matrix for Suspicious Crime Data";
matrix total_Pop Pcincome Pers_income;
run;
*computes correlation coefficient for suspicious x-variables;
proc corr;
var total_Pop Pcincome Pers_income;
run;

*looking at residuals;
proc reg data=crime;
model sqrtCRIMES = Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3;
run; 
*looking at residuals;
proc reg data=crime;
model CRIMES = Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3;
run; 

*full model 1;
proc reg data=crime;
model new_y = Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3 /vif tol influence r;
plot student.*(Land Pop18_34 Pop65plus DOCS BEDS  Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 



*------------------ testing transformations --------------------;
*transform variables to improve residuals;
data crime1;
set crime;
logLand = log(Land); 
sqrtLand = sqrt(Land);
squaredLand = (Land)**2;
cubeLand = (Land)**3;
invLand = 1/(Land);
 
logPop18_34 = log(Pop18_34);
sqrtPop18_34 = sqrt(Pop18_34);
squaredPop18_34 = (Pop18_34)**2;
cubePop18_34 = (Pop18_34)**3;
invPop18_34 = 1/(Pop18_34);

logDOCS = log(DOCS);
sqrtDOCS = sqrt(DOCS);
squaredDOCS = (DOCS)**2;
cubeDOCS = (DOCS)**3;
invDOCS = 1/(DOCS);

logpoverty = log(poverty);
sqrtpoverty = sqrt(poverty);
squaredpoverty = (poverty)**2;
cubepoverty = (poverty)**3;
invpoverty = 1/(poverty);

logPcincome = log(Pcincome);
sqrtPcincome = sqrt(Pcincome);
squaredPcincome = (Pcincome)**2;
cubePcincome = (Pcincome)**3;
invPcincome = 1/(Pcincome);

run;
proc print data= crime1; 
run;

*full model testing log-transformed predictors;
proc reg data=crime1;
model new_y = logLand logPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads logpoverty unemp logPcincome dRegion1 dRegion2 dRegion3;
plot student.*(logLand logPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads logpoverty unemp logPcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model testing sqrt-transformed predictors;
proc reg data=crime1;
model new_y = sqrtLand sqrtPop18_34 Pop65plus sqrtDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp sqrtPcincome dRegion1 dRegion2 dRegion3;
plot student.*(sqrtLand sqrtPop18_34 Pop65plus sqrtDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp sqrtPcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model testing squared-transformed predictors;
proc reg data=crime1;
model new_y = squaredLand squaredPop18_34 Pop65plus squaredDOCS BEDS Hsgrads Bgrads squaredpoverty unemp squaredPcincome dRegion1 dRegion2 dRegion3;
plot student.*(squaredLand squaredPop18_34 Pop65plus squaredDOCS BEDS Hsgrads Bgrads squaredpoverty unemp squaredPcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model testing cube-transformed predictors;
proc reg data=crime1;
model new_y = cubeLand cubePop18_34 Pop65plus cubeDOCS BEDS Hsgrads Bgrads cubepoverty unemp cubePcincome dRegion1 dRegion2 dRegion3;
plot student.*(cubeLand cubePop18_34 Pop65plus cubeDOCS BEDS Hsgrads Bgrads cubepoverty unemp cubePcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model testing inv-transformed predictors;
proc reg data=crime1;
model new_y = invLand invPop18_34 Pop65plus invDOCS BEDS Hsgrads Bgrads invpoverty unemp invPcincome dRegion1 dRegion2 dRegion3;
plot student.*(invLand invPop18_34 Pop65plus invDOCS BEDS Hsgrads Bgrads invpoverty unemp invPcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model 1 (for residual comparison);
proc reg data=crime1;
model new_y = Land Pop18_34 Pop65plus DOCS BEDS Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3 /vif tol influence r;
plot student.*(Land Pop18_34 Pop65plus DOCS BEDS Hsgrads Bgrads poverty unemp Pcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 
*full model with BEST transformations;
proc reg data=crime1;
model new_y = logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3 /vif tol influence r;
plot student.*(logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.; *plots the studentized residuals (combined for all variables) against a theoretical probability of normality, shows if the residuals (of all variables overall) are normally distributed;
run; 



*----------------------Data Exploration for Transformed Variables------------------;
TITLE2 "Descriptive Statistics";
proc means min max mean std stderr clm p25 p50 p75 data=crime1; 
var sqrtCRIMES logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3; 
run;

* creates scatterplot matrix;
proc sgscatter data=crime1;
title2 "Scatterplot Matrix for Crime Data";
matrix sqrtCRIMES logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3;
run;

*computes correlation coefficient for all y and x-variables;
proc corr data=crime1;
var sqrtCRIMES logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3;
run;

TITLE2 "Histogram - Suspicious Predictors";
proc univariate normal; 
var beds Pcincome Pers_income; 
histogram / normal(mu=est sigma=est);
run;



*-------------------Model Selection Methods----------------;
*STEPWISE variable selection;
proc reg data=crime1 alpha=0.05;
model new_y = logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3/selection=stepwise;
run;
*model selected from STEPWISE variable selection;
proc reg data=crime1 alpha=0.05;
model new_y = logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol stb;
run; 

* CP variable selection;
*Select the model that has the Cp ˜ p where p =k+1 (k = # of predictors);
proc reg data=crime1;
model new_y = logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3/selection=cp;
run;
*model selected from CP variable selection;
proc reg data=crime1;
model new_y = logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol stb;
run; 

* ADJ-R2 variable selection;
proc reg data=crime1 alpha=0.05;
model new_y = logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3/selection=adjrsq;
run;
*model selected from ADJ-R2 variable selection. NOTE: all had 0.54 adj-r2, so I chose the one with the fewest predictors and took out insig. predictors;
proc reg data=crime1;
model new_y = logLand sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol stb;
run; 

* BACKWARD variable selection;
proc reg data=crime1 alpha=0.05;
model new_y = logLand invPop18_34 Pop65plus logDOCS BEDS Hsgrads Bgrads sqrtpoverty unemp invPcincome dRegion1 dRegion2 dRegion3/selection=backward;
run;
*model selected from BACKWARD variable selection;
proc reg data=crime1;
model new_y = logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol stb;
run; 

*full SECOND-ORDER INTERACTION model;
proc glmselect data=crime1;
model new_y = logLand|invPop18_34|Pop65plus|logDOCS|BEDS|Hsgrads|Bgrads|sqrtpoverty|unemp|invPcincome|dRegion1|dRegion2|dRegion3 @2/ selection=none;
/*shorthand notation uses | to include interaction terms. @2 indicates that only second order interaction terms will be included in the model;*/
run;
*SECOND-ORDER INTERACTION model selection using STEPWISE selection;
proc glmselect data=crime1;
model new_y = logLand|invPop18_34|Pop65plus|logDOCS|BEDS|Hsgrads|Bgrads|sqrtpoverty|unemp|invPcincome|dRegion1|dRegion2|dRegion3 @2/selection=stepwise;
/*shorthand notation uses | to include interaction terms. @2 indicates that only second order interaction terms will be included in the model;*/
run;
*create interaction variables for the model selected from the above process;
data crime2;
set crime1;
BEDS__sqrtpoverty = BEDS*sqrtpoverty;
logDOCS__unemp = logDOCS*unemp;
logLand__dRegion1 = logLand*dRegion1;
sqrtpoverty__dRegion1 = sqrtpoverty*dRegion1;
BEDS__dRegion2 = BEDS*dRegion2;
unemp__dRegion2 = unemp*dRegion2;
invPcincome__dRegion2 = invPcincome*dRegion2;
Hsgrads__dRegion3 = Hsgrads*dRegion3;
run;
*model selected from SECOND-ORDER INTERACTION variable selection;
proc reg data=crime2;
model new_y = sqrtpoverty BEDS__sqrtpoverty logDOCS__unemp invPcincome logLand__dRegion1 sqrtpoverty__dRegion1 BEDS__dRegion2 unemp__dRegion2 invPcincome__dRegion2 Hsgrads__dRegion3 /vif tol stb;
run; 
*CORRECTED model selected from SECOND-ORDER INTERACTION variable selection (removing collinear and insig. predictors);
proc reg data=crime2;
model new_y = sqrtpoverty logDOCS__unemp invPcincome sqrtpoverty__dRegion1 Hsgrads__dRegion3 /vif tol stb;
run; 



*-----------Models Selected for Validation----------;
*Model 1 - selected from ADJ-R2 variable selection;
proc reg data=crime1;
Title "Model 1";
model new_y = logLand sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol influence r;
plot student.*(logLand sqrtpoverty invPcincome dRegion1 dRegion2 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.;
run; 
*Model 2 - selected from SECOND-ORDER INTERACTION variable selection;
proc reg data=crime2;
Title "Model 2";
model new_y = invPop18_43__Hsgrads Hsgrads__sqrtpoverty BEDS__unemp invPcincome Hsgrads__invPers_income Pop65plus__dRegion1 invPers_income__dRegion2 dRegion3 /vif tol influence r;
plot student.*(invPop18_43__Hsgrads Hsgrads__sqrtpoverty BEDS__unemp invPcincome Hsgrads__invPers_income Pop65plus__dRegion1 invPers_income__dRegion2 dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.;
run; 
*Model 3 - selected from CP variable selection;
proc reg data=crime2;
Title "Model 2";
model new_y = logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol influence r;
plot student.*(logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.;
run; 


*--------------Testing Influential Points-----------;
data crime3; * write to a different dataset;
set crime2; * merge with old dataset;
*remove 123rd observation;
if _n_=123 then delete;
run;
*Model 1 - selected from ADJ-R2 variable selection;
proc reg data=crime3;
Title "Model 1";
model new_y = logLand sqrtpoverty invPcincome dRegion1 dRegion2 /vif tol influence r;
plot student.*(logLand sqrtpoverty invPcincome dRegion1 dRegion2 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.;
run; 
*Model 2 - selected from SECOND-ORDER INTERACTION variable selection;
proc reg data=crime3;
Title "Model 2";
model new_y = sqrtpoverty logDOCS__unemp invPcincome sqrtpoverty__dRegion1 Hsgrads__dRegion3 /vif tol influence r;
plot student.*(sqrtpoverty logDOCS__unemp invPcincome sqrtpoverty__dRegion1 Hsgrads__dRegion3 predicted.); *plots studentized residuals against their original value, numbers more extreme than +-3 are outliers;
plot npp.*student.;
run; 




*--------------------Predictions Using the Training Set of Model 1------------;
*new dataset containing values for predictions; 
data pred; 
input logLand sqrtpoverty invPcincome dRegion1 dRegion2; 
datalines; 
6.8 3.2 0.000047617 0.0000257 1 0
7 2.28 0.000040984 0.000017 0 1
; 
*join datasets; 
data predict; 
set pred crime2;
*computes prediction; 
proc reg; 
model new_y = logLand sqrtpoverty invPcincome dRegion1 dRegion2/p clm cli alpha=0.05; 
run;




*------------------------Model Validation------------------------;
/* get predicted values for the missing new_y (test set rows) for 3 competing models*/
title "Validation - Test Set";
proc reg data=crime2;
* Model 1;
model new_y = logLand sqrtpoverty invPcincome dRegion1 dRegion2;
output out=M1(where=(new_y=.)) p=yhat; *out=M1 defines dataset containing Model 1's predicted values for test set;
* Model 2;
model new_y = sqrtpoverty logDOCS__unemp invPcincome sqrtpoverty__dRegion1 Hsgrads__dRegion3;
output out=M2(where=(new_y=.)) p=yhat; *out=M2 defines dataset containing Model 2's predicted values for test set;
* Model 3;
model new_y = logLand invPop18_34 logDOCS Bgrads sqrtpoverty invPcincome dRegion1 dRegion2;
output out=M3(where=(new_y=.)) p=yhat; *out=M3 defines dataset containing Model 3's predicted values for test set;
run;
/* summarize the results of the cross-validations for Model 1*/
title "Difference between Observed and Predicted in Test Set";
data M1_Summ;
set M1;
dif=sqrtCRIMES-yhat; *dif = difference between observed and predicted values in test set;
abs_dif=abs(dif); *define the absolute value of the difference;
run;
/* computes predictive statistics: root mean square error (RMSE)and mean absolute error (MAE)*/
proc summary data=M1_Summ;
var dif abs_dif;
output out=M1_Stats std(dif)=RMSE mean(abs_dif)=MAE ;
run;
proc print data=M1_Stats;
title 'Validation Statistics for Model 1';
run;
*computes correlation of observed and predicted values in test set;
proc corr data=M1;
var sqrtCRIMES yhat;
run;

/* summarize the results of the cross-validations for Model 2*/
title "Difference between Observed and Predicted in Test Set";
data M2_Summ;
set M2;
dif=sqrtCRIMES-yhat; *dif = difference between observed and predicted values in test set;
abs_dif=abs(dif); *define the absolute value of the difference;
run;
/* computes predictive statistics: root mean square error (RMSE)and mean absolute error (MAE)*/
proc summary data=M2_Summ;
var dif abs_dif;
output out=M2_Stats std(dif)=RMSE mean(abs_dif)=MAE ;
run;
proc print data=M2_Stats;
title 'Validation Statistics for Model 2';
run;
*computes correlation of observed and predicted values in test set;
proc corr data=M2;
var sqrtCRIMES yhat;
run;

/* summarize the results of the cross-validations for Model 3*/
title "Difference between Observed and Predicted in Test Set";
data M3_Summ;
set M3;
dif=sqrtCRIMES-yhat; *dif = difference between observed and predicted values in test set;
abs_dif=abs(dif); *define the absolute value of the difference;
run;
/* computes predictive statistics: root mean square error (RMSE)and mean absolute error (MAE)*/
proc summary data=M3_Summ;
var dif abs_dif;
output out=M3_Stats std(dif)=RMSE mean(abs_dif)=MAE ;
run;
proc print data=M3_Stats;
title 'Validation Statistics for Model 3';
run;
*computes correlation of observed and predicted values in test set;
proc corr data=M3;
var sqrtCRIMES yhat;
run;





