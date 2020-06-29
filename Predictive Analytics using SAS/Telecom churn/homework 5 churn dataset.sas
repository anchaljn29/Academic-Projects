PROC IMPORT OUT= WORK.CHURN 
            DATAFILE= "H:\churn\Churn_telecom.csv"
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

proc print data = work.churn (obs = 10); 
run;

* Splitting data into training and testing sets 70/30;
proc surveyselect data = churn out = churn_rand method = SRS samprate = 0.7 outall seed = 123 noprint;
run;

proc print data = churn_rand (obs = 10);
where selected = 0;
run;

* Create training; 
data training_sample;
set churn_rand ;
where selected = 1; 
run;

* Create testing;
data testing_sample;
set churn_rand ;
where selected = 0; 
run;


* Completed splitting into 70/30 ;


* Find the means of the churn and not churn ;
proc means data = work.churn;
class churn; 
output out = churn_mean; 
run;

* Save just the means; 
data churn_mean2;
set churn_mean;
if _stat_ = 'MEAN';
if _TYPE_ = 1;
run;


proc print data = churn_mean2;
run;

* Flip the table to vertical call it churn_mean2_T;
proc transpose data = churn_mean2
out = churn_mean2_T;
run;

proc print data = churn_mean2_T;
run;

* Calculate the difference and percent difference/variance;
data churn_diff; 
set churn_mean2_T;
diff = abs(COL1 - COL2);
mean = (COL1+COL2)/2;
var = (diff/mean)*100;
var_abs = abs(var);
run; 

* Sort by the highest variance; 
proc sort data = churn_diff; 
by descending var_abs ;
run;


proc print data = churn_diff; 
run;

proc means data = churn; 
run; 
/* Model */
proc corr data=training_sample;
var change_rev drop_vce_Mean hnd_price ccrndmou_Mean uniqsubs eqpdays mtrcycle iwylis_vce_mean totmrc_Mean avg3qty; run;
proc reg data = training_sample;
model churn= change_rev drop_vce_Mean hnd_price ccrndmou_Mean uniqsubs eqpdays mtrcycle iwylis_vce_mean totmrc_Mean avg3qty/vif collin;run;
proc logistic data = training_sample desc;
model churn = change_rev drop_vce_Mean hnd_price ccrndmou_Mean uniqsubs eqpdays mtrcycle iwylis_vce_mean totmrc_Mean avg3qty ;OUTPUT OUT=churn_out10 predprob=individual; run;

/*hit ratio for training sample */
proc freq data=churn_out10;
table churn* _INTO_ /out=CellCounts10;
run;
data CellCounts10;
set CellCounts10;
Match=0;
if churn=_INTO_ then Match=1;
run;
proc means data=CellCounts10 mean;
freq count;
var Match;
run;

proc logistic data = testing_sample desc;
model churn = change_rev drop_vce_Mean hnd_price ccrndmou_Mean uniqsubs eqpdays mtrcycle iwylis_vce_mean totmrc_Mean avg3qty ;OUTPUT OUT=churn_out11 predprob=individual; run;
/*hit ratio for testing sample */
proc freq data=churn_out11;
table churn* _INTO_ /out=CellCounts11;
run;
data CellCounts11;
set CellCounts11;
Match=0;
if churn=_INTO_ then Match=1;
run;
proc means data=CellCounts11 mean;
freq count;
var Match;
run;
