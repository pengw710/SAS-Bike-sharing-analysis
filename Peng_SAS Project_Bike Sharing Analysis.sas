* SAS PROJECT - BIKE SHARING RIDER MEMBERSHIP PREDICTION
By Peng Wang | Instructor Mr. Ar Kar Min
2021 July 24
Metro College of Technology
********************************************************

PROJECT SCOPE
=============

The dataset comes from 12 months of bike sharing records of the Washington City, 2018.
Total Observations: 	3,500,000+
Total Variables:		10
Total Filesize:			271MB

BUSINESS REQUIREMENT
====================

Rider is either a registered member, or a casual rider without membership.
Business needs a model to predict the rider's membership class based on the
historical (2018) ride sharing details.

1. PROGRAMMING LANGUAGE/TOOL
============================

SAS 9
TABLEAU PREP

2. DATA PRE-PROCESSING
======================

2.1 Obtaining Data
------------------

The original dataset contains 12 CSV files, all files have the same attributes and data format. 
Used Tableau Prep merged 12 files into a single dataset.
;

* Import dataset in SAS;
PROC IMPORT OUT= PW.BIKE_SHARING 
            DATAFILE= "C:\Users\paddy\Documents\00-OSAP\12 SAS Project\My Projects\BikeSharing\Data Files - final\Output.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

* A quick view of dataset;
proc print data=pw.bike_sharing (obs=5) noobs; 
run;

* Review Data Descriptions;
proc contents data=pw.bike_sharing; 
run;

* VARIABLES LIST:

Bike_number 			Char 
Duration 				Num
End_station_number 		Num
Member_type 			Char
Month 					Num
StartDate 				Num
StartTime 				Num
StartTimeSlot 			Char
Start_station_number 	Num 
Weekday 				Char

2.2 Data Cleaning
-----------------

This part was completed in Tebleau Prep.

Add/Remove Variables:

Start date: 					
	They are in date&time format. For the purpose of analysis, I need to convert (separate) it and 
	add to new columns: Month, StartDate, Weekday, StartTimeSlot, StartTime.
End date: 						
	Having the attribute of Duration and Start date, it’s not necessary to keep End date. So I dropped it.
Start station / End station: 	
	They are text values and each entry is accompanied by Start/End station number. 
	For my project scope, I only need Start/End station numbers. So I dropped the station names.

2.3 Handling Missing Data
-------------------------

* Make a copy;
data pw.bs(label='Copy of Original');
	set pw.bike_sharing;
run;

* Count Missing Value for all columns
https://blogs.sas.com/content/iml/2011/09/19/count-the-number-of-missing-values-for-each-variable.html

Create a format to group missing and nonmissing
https://www.analyticsvidhya.com/blog/2014/11/sas-proc-format-guide/;
proc format library=pw.miss_fmt;* Save UDF to the same library for future use;
	value $missfmt ' '='Missing' other='Not Missing';
	value  missfmt  . ='Missing' other='Not Missing';
run;
options fmtsearch=(pw.miss_fmt);

* List of missing/non-missing, by variable;
title "List of Missing/Non-Missing by Variable";
proc freq data=pw.bs; 
	format _CHAR_ $missfmt.; 
	tables _CHAR_ / missing missprint nocum /*nopercent*/;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum /*nopercent*/;
run;title;

* Result: NO MISSING VALUES.

2.4 Feature Engineering
-----------------------
;
data pw.bs1;
 set pw.bs;

  * Convert Start/End Station Number from numerical to categorical: PUT()
  https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lepg/n04koei84kuaodn1g21eyx4btome.htm
;
  Start_station = put(Start_station_number,best5.);
  End_station = put(End_station_number,best5.);
  drop Start_station_number End_station_number;

  * Convert Month from Numerical to categorical: IF...ELSE IF;
  if Month=1 then Months="Jan";
   else if Month=2 then Months="Feb";
   else if Month=3 then Months="Mar";
   else if Month=4 then Months="Apr";
   else if Month=5 then Months="May";
   else if Month=6 then Months="Jun";
   else if Month=7 then Months="Jul";
   else if Month=8 then Months="Aug";
   else if Month=9 then Months="Sep";
   else if Month=10 then Months="Oct";
   else if Month=11 then Months="Nov";
   else Months="Dec";   
  drop Month;
Run;
proc contents data=pw.bs1; run;
proc print data=pw.bs1 (obs=5) noobs; run; 

* 2.5 Feature Selection
-----------------------

Bike_number 	Char 
Duration 		Num 
End_station 	Char    
Member_type 	Char 
Months 			Char 
StartDate 		Num 
StartTime 		Num 
StartTimeSlot 	Char 
Start_station 	Char 
Weekday 		Char 

3.	Data Visualization (EDA)
============================

3.1.	Univariate Analysis
---------------------------
*CHECKING NL DISTRIBUTION;
PROC UNIVARIATE DATA = pw.bs1 ;
 VAR duration;
 HISTOGRAM /NORMAL ;
RUN;
QUIT;

PROC UNIVARIATE DATA = pw.bs3 ;
 VAR duration;
 HISTOGRAM /NORMAL ;
RUN;
QUIT;

PROC HPBIN DATA = pw.bs3 OUTPUT = bs3;
  INPUT duration/NUMBIN=10;
  
RUN;
PROC UNIVARIATE DATA = bs3;
 VAR BIN_Duration;
 HISTOGRAM /NORMAL ;
RUN;
QUIT;

PROC HPBIN DATA = pw.bs3 OUTPUT = bs3 QUANTILE;
  INPUT duration/NUMBIN=5;
  RUN;
proc contents data = bs3;run;


* CHECK IF SAS MACRO FACILITY IS ENABLE OR NOT;

PROC OPTIONS OPTION = MACRO;
RUN;

* https://support.sas.com/kb/36/898.html
Create a Macro procedure receives variable as parameter and return the unique values (levels)
of that variable;

%macro levels (var);
	ods select nlevels; *Use the NLEVELS option with the ODS SELECT statement to capture the
						number of levels for a variable;
	proc freq data=pw.bs1 nlevels;
   	tables &var;
	title "Number of unique level for &var"; 
	run; title;
%mend levels;

*Q1:How many bikes are available for sharing?;
%levels(Bike_number);
* ANSWER: 5387 BIKES ARE AVAILABLE FOR RIDE SHARING.

Q2: How nmay stations in the city?;
%levels(Start_station);
%levels(End_station);
* ANSWER: THERE ARE 528 BIKE SHARING STATIONS IN THE CITY. 

Q3: Which are top 50 most popular start station?
https://communities.sas.com/t5/Statistical-Procedures/How-to-find-3-most-frequently-occurring-values/td-p/204661
;
proc freq data=pw.bs1 order=freq;
tables Start_station / noprint out=station;
run; 
proc print data=station (obs=50) noobs; 
title "The top 50 popular stations";
run; title;
* ANSWER: Top 50 popular start stations are found. Interestingly, if look at their percentages, these stations 
are not significantly above others. For example, the most popular station only has 1.79%.
In another word, there's no a single station is significantly busy or popular than others.

Moreover, if look at top 50 quietest stations:
;
proc freq data=pw.bs1;
tables Start_station / noprint out=station;
run; 
proc sort data=station;
by count;
run;
proc print data=station (obs=50) noobs; 
title "The top 50 quietest stations - Do we really need them?";
run; title; 
* we found out that for the whole year of 2018, these stations had been visited from 
the minimum 3 times per 1 million visits to 
the maximum 40 times per 1 million visits. 
For such less usage, the business question might be: DO WE REALLY NEED TO KEEP MAINTAINING THESE STATIONS?

Further more, I listed start stations with count < 365, i.e., all stations had less than 1 visit per day during 2018;

proc print data=station; 
	where count < 365;
	title "Stations less than 1 visit per day - Do we really need them?";
run; title; 

* Bar Charts;
%vbar(start_station);

* Q4: What is the minimum and maximum duration? How long is the average duration?;
proc means data = pw.bs1 n nmiss min mean median std max maxdec=2;
 var Duration;
run;
* Analysis Variable : Duration  
N       N Miss Minimum Mean    Median Std Dev Maximum 
3542684 0      60.00   1143.42 698.00 2204.50 86372.00 ;

PROC UNIVARIATE DATA = pw.bs1;
 VAR duration;
RUN;
* Quantiles (Definition 5) 
Level 		Quantile 
100% Max 	86372 
99% 		8144 
95% 		3394 
90% 		1976 
75% Q3 		1210 
50% Median 	698 
25% Q1 		402 
10% 		252 
5% 			194 
1% 			118 
0% Min 		60 

* For the rest analysis, I created a Macro to extract the 'most' count for a value.
;
%MACRO THE_MOST (VAR);
	proc freq data=pw.bs1 order=freq;
	tables &VAR / noprint out=&VAR;
	run; 

	proc print data=&VAR; 
	title "The rank of &VAR";
	run; title;
%MEND;

* Q5: What day is the busiest day during a week?;
%THE_MOST(Weekday);
* ANSWER: THURSDAY IS THE BUSIEST DAY AND SUNDAY IS THE QUIETEST.
The rank of Weekday 
Obs 	Weekday 	COUNT 	PERCENT 
1 		Thursday 	536119 	15.1331 
2 		Wednesday 	534591 	15.0900 
3 		Friday 		526133 	14.8513 
4 		Tuesday 	511839 	14.4478 
5 		Saturday 	502401 	14.1814 
6 		Monday 		495089 	13.9750 
7 		Sunday 		436512 	12.3215 

* Bar Charts;
%vbar(weekday);

* Q6: What time slot is the busiest during a day?;
%THE_MOST(StartTimeSlot);
* ANSWER: Rush Hour IS THE BUSIEST TIME AND EARLY MORNING IS THE QUIETEST.
The rank of StartTimeSlot 
Obs 	StartTimeSlot 	COUNT 	PERCENT 
1 		Rush Hour 		1187641 33.5238 
2 		Afternoon 		1090856 30.7918 
3 		Evening 		599419 	16.9199 
4 		Morning 		495148 	13.9766 
5 		Early Mor 		169620 	4.7879 

* Bar Charts;
%vbar(StartTimeSlot);

* Q7: Which month is the busiest or most quiet month?;
%THE_MOST(Months);
* ANSWER: JULY IS THE BUSIEST MONTH AND JANURARY IS THE QUIETEST.
The rank of Months 
Obs Months 	COUNT 	PERCENT 
1 	Jul 	404761 11.4253 
2 	Aug 	403866 11.4000 
3 	Jun 	392338 11.0746 
4 	May 	374115 10.5602 
5 	Oct 	343021 9.6825 
6 	Apr 	328907 9.2841 
7 	Sep 	325800 9.1964 
8 	Mar 	238998 6.7462 
9 	Nov 	202376 5.7125 
10 	Feb 	182378 5.1480 
11 	Dec 	177534 5.0113 
12 	Jan 	168590 4.7588 

* Bar Charts;
%vbar(months);

* Q8: What is ratio of riders membership?;
proc freq data=pw.bs1;
tables member_type / noprint out=members;
run; 
proc print data=members noobs; 
title "The ratio of memberships";
run; title;
* ANSWER: 78% OF RIDERS ARE MEMBERS AND 21% ARE CASUAL CLIENTS.
The ratio of memberships 
Member_type COUNT 	PERCENT 
Casual 		750115 	21.1736 
Member 		2792569 78.8264 

* Bar Charts;
%vbar(member_type);
* Pie Charts
https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/n0ejmrdm6ov3ton1gx1tsuuxd1ca.htm;
goptions reset=all border;
title "Riders Membership Ratio";
proc gchart data=pw.bs1;
pie member_type / other=0
midpoints="Member" "Casual"
value=none
percent=arrow
slice=arrow
noheading;
run;
quit;

* 3.1.1.	Charts	
https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/odsproc/p0kroq43yu0lspn16hk1u4c65lti.htm;
%macro vbar(var);
	ods graphics on / OBSMAX=3600000;
	proc sgplot data=pw.bs1;
	vbar &var;
run;
quit;
%mend;

* 3.2 Handling Outliers
---------------------
;
PROC SGPLOT DATA = pw.bs1;
 VBOX duration/DATALABEL = duration;
RUN;
QUIT;

data pw.bs2;
 set pw.bs1;
run;

*https://www.listendata.com/2014/10/identify-and-remove-outliers-with-sas.html;
%macro outliers(input=, var=, output= );

	%let Q1=;
	%let Q3=;
	%let varL=;
	%let varH=;

	%let n = %sysfunc(countw(&var));
	%do i = 1 %to &n;
		%let val = %scan(&var,&i);
		%let Q1 = &Q1 &val._P25;
		%let Q3 = &Q3 &val._P75;
		%let varL = &varL &val.L;
		%let varH = &varH &val.H;
	%end;

/* Calculate the quartiles and inter-quartile range using proc univariate */
	proc means data = &input nway noprint;
		var &var;
		output out = temp P25= P75= / autoname;
	run;

/* Extract the upper and lower limits into macro variables */
	data temp;
		set temp;

		ID = 1;

		array varb(&n) &Q1;
		array varc(&n) &Q3;
		array lower(&n) &varL;
		array upper(&n) &varH;

		do i = 1 to dim(varb);
			lower(i) = varb(i) - 3 * (varc(i) - varb(i));
			upper(i) = varc(i) + 3 * (varc(i) - varb(i));
		end;

		drop i _type_ _freq_;
	run;

	data temp1;
		set &input;
		ID = 1;
	run;

	data &output;
		merge temp1 temp;
		by ID;

		array var(&n) &var;
		array lower(&n) &varL;
		array upper(&n) &varH;

		do i = 1 to dim(var);
			if not missing(var(i)) then do;
				if var(i) >= lower(i) and var(i) <= upper(i);
			end;
		end;

		drop &Q1 &Q3 &varL &varH ID i;
	run;
%mend;

%outliers(input=pw.bs2, var=Duration, output=pw.bs3);
* Total 160,638 observations (4.5%) had been removed.;

PROC UNIVARIATE DATA = pw.bs3;
 VAR duration;
RUN;

PROC SGPLOT DATA = pw.bs3;
 VBOX duration/DATALABEL = duration;
RUN;
QUIT;
*
4.	Statistics (Hypothesis)
===========================

4.1.	Bivariate Analysis
--------------------------

HYPOTHESIS TESTING:
H0 : NULL HYPOTHEISIS- NO RELATIONSHIP/ASSOCIATION
HA : ALTERNATIVE HYPOTHESIS- RELATIONSHIP/ASSOCIATION
ALPHA /SIGNIFICANT LEVEL = 5% (0.05)
DECISION : REJECT H0 OR FAILED TO REJCT H0
P-VALUE : LE 0.05

4.1.1.	Chi-square Test;

%macro chi_sq(varA, varB);
proc freq data = pw.bs3;
	table &varA * &varB/chisq;
run;
%mend;

proc univariate normal plot data=pw.bs3 /*noprint*/; * noprint will avoid showing up discription tables;
var age sales;
histogram age sales/normal(color=red w=5);
run; title;

* Q9:  Does Weekday has any impact on Membership?;
%chi_sq(weekday,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN WEEKDAY AND MEMBERSHIP.

Q10: Does Timeslot has any impact on Membership?;
%chi_sq(StartTimeSlot,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN start time slot AND MEMBERSHIP.

Q11: Does Start Station has any relationship with Membership?;
%chi_sq(start_station,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN start station AND MEMBERSHIP.

Q12: Does End Station has any relationship with Membership?;
%chi_sq(end_station,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN end station AND MEMBERSHIP.

Q13: Does Month has any impact on Membership?;
%chi_sq(months,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN month AND MEMBERSHIP.

4.1.2.	T-Test;
%macro ttest(var, target);
	proc ttest data=pw.bs3 plots(unpack)=summary;  
	class &target;   
	var &var;
	run;
	quit;
%mend;

* Q14: Does duration has any relationship with Membership?;
%ttest(duration,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN DURATION AND MEMBERSHIP.

* Q15: Does startDate has any relationship with Membership?;
%ttest(startDate,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN StartTime AND MEMBERSHIP.

* Q16: Does startTime has any relationship with Membership?;
%ttest(startTime,member_type);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN StartTime AND MEMBERSHIP.

* Q17: What is the duration total among member_types;
proc means data=pw.bs3 maxdec=2;
var duration;
class member_type;
run;
ods graphics on / OBSMAX=3600000;
proc sgplot data=pw.bs3;
vbox duration / category=member_type;
run;
TITLE 'Summary of Weight Variable (in pounds) - added a CLASS statement';  
PROC UNIVARIATE DATA = pw.bs3 NOPRINT; 
 CLASS member_type; 
 HISTOGRAM duration / NORMAL (COLOR = red)                               
	CFILL = ltgray  
	CTEXT = blue;   
RUN;

4.1.3.	ANOVA Test;
*ANOVA : ANALYSIS OF VARIANCE;
%macro anova(var);
	PROC ANOVA DATA = pw.bs3 PLOTS(MAXPOINTS=NONE);
 		CLASS &var;
 		MODEL duration = &var;
 		MEANS &var/SCHEFFE;
	RUN;
	quit;
%mend;

*Q17: Does duration has any relationship with Weekday?;
%anova(weekday);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN DURATION AND weekday.

Q18: Does duration has any relationship with Timeslot?;
%anova(StartTimeSlot);
* CONCLUSION: P VALUE IS LESS THAN 5%, THEREFORE REJECT H0 - THERE IS
SIGNIFICANT STATISTIC RELATIONSHIP BETWEEN DURATION AND StartTimeSlot.

4.1.3.	Correlation

The dataset has just one continuous variable - Duration. The rest two numerical
variables are date and time accross the whole year, which is not related with my analysis 
scope.

The categorical variables are MemberType(target, binary), Month, Weekday, DayTimeSlot, Station ID and Bike ID, 
for which I don't see any necessarities of converting them into numerical variables for 
the correlation test because I already figured out the relationship between them.

5.	Machine Learning (Modeling);

proc logistic data = pw.bs3 desc;
class months weekday starttimeslot start_station;
model member_type = duration months weekday starttimeslot start_station;
output out = model1 p = pred_prob lower = low upper = upp;
run;
quit;

proc logistic data = pw.bs3 desc;
class weekday starttimeslot ;
model member_type = duration weekday starttimeslot;
output out = model2 p = pred_prob;
run;
quit;

PROC LOGISTIC DATA = pw.bs3;
 CLASS starttimeslot;
 MODEL member_type (EVENT="Member") = starttimeslot /CLODDS =PL;
RUN;

PROC LOGISTIC DATA = pw.bs3;
 CLASS starttimeslot weekday;
 MODEL member_type (EVENT="Member") = duration weekday starttimeslot /CLODDS =PL;
RUN;



proc sql;
create table duration_pct as
SELECT member_type,
       sum(duration) as Total_Duration
  FROM pw.bs3
 GROUP BY member_type;
quit;

proc print data = duration_pct;
run;

PROC UNIVARIATE DATA = pw.bs3 NOPRINT;
HISTOGRAM duration/NORMAL;
RUN;
