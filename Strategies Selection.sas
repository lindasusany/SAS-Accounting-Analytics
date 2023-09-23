libname a "C:\Users\zzhang436\Downloads"; 
option obs=max;
* Check for data summary stats: accuracy;
proc means data=a.Crsp_mth nway mean median min max p1 p5 p10 q1 q3 p99 std n;	run;

%macro MOM(J, K);

/* Step 3. Formation period: Create Momentum Port. Based on Past (J) Month Compounded Returns */
proc sort data=a.Crsp_mth  nodupkey out=crsp; 
	by CUSIP date; 	
*	where 2000>year(date)>=1990 ;	
run;	 *;

proc expand data=crsp (keep=CUSIP date ret) out=umd method=none;
	by CUSIP;
	id date;
	convert ret = movsum_return / 			       transformout=(MOVSUM  &J);
	convert ret = cum_return2    / transformin=(+1) transformout=(MOVPROD &J -1);
	convert ret = cum_return    / transformin=(+1) transformout=(MOVPROD &J -1 trimleft &J);
	label cum_return1 = "cum_return1";
	label cum_return2 = "cum_return2";
	label cum_return = "cum_return";
	label movsum_return = "movsum_return";
quit;  
 
PROC Export data= umd
             OUTFILE= "C:\Users\zzhang436\Downloads\umd.xls"     DBMS=xls REPLACE;	 	run;

proc sort data=umd; by date; run;

/* Formation of 10 Portfolios Every Month based on the cumulative returns in the past J period */
proc rank data=umd out=umd1 group=40;   ***You may need to change the # of groups to manipulate the # of stocks in each portfolio; 
  	by date;
    var cum_return;
    ranks momr;
run;
 
/* MOMR is the portfolio rank variable taking values between 1 and 10 or 100 depending on how many groups you've assigned earlier: */
/*          1 - the lowest  momentum group: Losers   */
/*         10 (or 9 or 99 or 100) - the highest momentum group: Winners  */
data umd;	 format BDATE date9. EDATE date9. form_date date9.;
	set umd1 ;
	where momr>=0;
	momr=momr+1;
	form_date = date;
*	form_date = lag(date);
	BDATE = intnx("MONTH",date, 1,"B");
	EDATE = intnx("MONTH",date,&K,"E");
	label momr = "Momentum Portfolio";
	label form_date = "Formation Date";
	label BDATE= "First Holding Date";
	label EDATE= "Last Holding Date";
	keep CUSIP date BDATE EDATE cum_return momr form_date;
run;  *362,248;
 
/* Step 4. Merge stock returns during the Next (K) Months After Portfolio Formation */
proc sql;
    create table umd2
    as select distinct a.*, b.date, b.ret
    from umd(drop=date) as a,    crsp as b
    where a.CUSIP=b.CUSIP   and a.BDATE<=b.date<=a.EDATE;
quit; *2,085,167;
 
/* Step 5. Calculate cumulative holding period return for each stock for each portfolio formation month*/
/* Every date, each MOM group has J portfolios identified by momr*/
proc means data = umd2 nway noprint;
 	class cusip form_date ;
	id momr;
    var ret;
    output out = umd3 sum=ret_c;
run; *362,336;
 
/* Portfolio average monthly returns */
/* Create average return per MOMR group every month across stocks. _FREQ_ indicates the # of stocks in each group*/
proc means data = umd3 nway noprint;
  	class form_date momr;
    var ret_c;
    output out = temp mean= car;
run; 
 
 
/* Step 6. Tranpose the data, and calculate Long-Short Portfolio Returns */
*Depending on your number of groups you have set up, then WINNER group may be reset to _9 or _99;
*You may also drop the other groups such as _3 _4 since you do not need them in the later analysis;

proc sort data=temp; by form_date momr; run;

proc transpose data=temp out=ewretdat2
     (rename = (_1=LOSERS  _40=WINNERS)
       		   drop=_NAME_ _LABEL_);
 	by form_date;
 	id momr;
 	var car;
run;


/* To Compute monthly Long-Short and Cumulative Returns, name the trading strategy */
data s&j&k;	format strategy 5.;
	set ewretdat2;
	strategy= 100*&j+&k;
	LONG_SHORT=WINNERS-LOSERS;
	Loser_WINNERS=LOSERS-WINNERS;
	decade = floor(year(form_date)/10) * 10 ;
*	year=year(form_date);

*	Calculate cumlative returns for each month starting from the begining for the sample period to the current month;
	by form_date;
	retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT CUMRET_Loser_WINNERS 0;
	CUMRET_WINNERS     = CUMRET_WINNERS+WINNERS;
	CUMRET_LOSERS      = CUMRET_LOSERS+LOSERS;
	CUMRET_LONG_SHORT  = CUMRET_LONG_SHORT+LONG_SHORT;
	CUMRET_Loser_WINNERS  = CUMRET_Loser_WINNERS+Loser_WINNERS;
	*Compounded below;
	CUMRET_WINNERS1     = (CUMRET_WINNERS+1)*(WINNERS+1)-1;
	CUMRET_LOSERS1      = (CUMRET_LOSERS +1)*(LOSERS +1)-1;
	CUMRET_LONG_SHORT1 =  (CUMRET_LONG_SHORT+1)*(LONG_SHORT+1)-1;  
	format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: 8.4; * percentn12.1;
run;

** Mean returns for the trading strategy for each decade;
proc means data = s&j&k nway noprint;
	class strategy decade;
    var WINNERS LOSERS LONG_SHORT;
    output out = FF&j&k mean=WINNERS LOSERS LONG_SHORT;
run; 
%mend;

%mom(36,12); %mom(24, 12); %mom(12, 12); 
%mom(36,24); %mom(24, 24); %mom(12, 24);
data final;
	set ff3612 ff2412 ff612 ff3624 ff2424 ff1224;
run;

PROC Export data= final
             OUTFILE= "C:\Users\zzhang436\Downloads\momentum_contr.xls"     DBMS=xls REPLACE;	 	run;

PROC SGPLOT DATA = s3612;
	SERIES X = form_date Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = form_date Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;

PROC SGPLOT DATA = s3612;
	SERIES X = form_date Y = Loser_WINNERS / LEGENDLABEL = "Loser_WINNERS";
*	SERIES X = form_date Y = LONG_SHORT / LEGENDLABEL = "LONG_SHORT";
	SERIES X = form_date Y = CUMRET_Loser_WINNERS / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;




*For the selected sample period, based on monthly portfolio formation, what is the average return to the strategy in each month post the portfolio formation;
data temp;
	set umd2;
	where month(form_date)=12;*  and int(year(form_date)/4)=year(form_date)/4;
	Interval=intck("month", form_date, DATE);
run;

* Mean return across stocks for each group on each post formation month;  *for each formation month;
proc means data = temp nway noprint;
 	class Interval momr;*form_date;
	id momr;
    var ret;
    output out = c1 mean=ret;
run;  

proc transpose data=c1 
	out=c2  (Keep=form_date Interval _1 _100  rename = (_1=LOSERS  _100=WINNERS)
       		   drop=_NAME_ _LABEL_);
 	by Interval; *form_date;
 	id momr;
 	var ret;
run;

data WL;	format strategy 5.;
	set c2;
*	strategy= 100*&j+&k;
	LONG_SHORT=WINNERS-LOSERS;
	decade = floor(year(form_date)/10) * 10 ;

*	Calculate cumlative returns for each month starting from the begining for the sample period to the current month;
*	by form_date;
	retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT 0;
	CUMRET_WINNERS     = CUMRET_WINNERS+WINNERS;
	CUMRET_LOSERS      = CUMRET_LOSERS+LOSERS;
	CUMRET_LONG_SHORT  = CUMRET_LONG_SHORT+LONG_SHORT;
	format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: 8.4; * percentn12.1;
run;

*Momentum and Contrarian Trading Stratgies over time;
PROC SGPLOT DATA = WL;
	SERIES X = Interval Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = Interval Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = Interval Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;

PROC SGPLOT DATA = s2412;
	SERIES X = form_date Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = form_date Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;

PROC SGPLOT DATA = s2412;
	SERIES X = form_date Y = Loser_WINNERS / LEGENDLABEL = "Loser_WINNERS";
*	SERIES X = form_date Y = LONG_SHORT / LEGENDLABEL = "LONG_SHORT";
	SERIES X = form_date Y = CUMRET_Loser_WINNERS / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;




*For the selected sample period, based on monthly portfolio formation, what is the average return to the strategy in each month post the portfolio formation;
data temp;
	set umd2;
	where month(form_date)=12;*  and int(year(form_date)/4)=year(form_date)/4;
	Interval=intck("month", form_date, DATE);
run;

* Mean return across stocks for each group on each post formation month;  *for each formation month;
proc means data = temp nway noprint;
 	class Interval momr;*form_date;
	id momr;
    var ret;
    output out = c1 mean=ret;
run;  

proc transpose data=c1 
	out=c2  (Keep=form_date Interval _1 _100  rename = (_1=LOSERS  _100=WINNERS)
       		   drop=_NAME_ _LABEL_);
 	by Interval; *form_date;
 	id momr;
 	var ret;
run;

data WL;	format strategy 5.;
	set c2;
*	strategy= 100*&j+&k;
	LONG_SHORT=WINNERS-LOSERS;
	decade = floor(year(form_date)/10) * 10 ;

*	Calculate cumlative returns for each month starting from the begining for the sample period to the current month;
*	by form_date;
	retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT 0;
	CUMRET_WINNERS     = CUMRET_WINNERS+WINNERS;
	CUMRET_LOSERS      = CUMRET_LOSERS+LOSERS;
	CUMRET_LONG_SHORT  = CUMRET_LONG_SHORT+LONG_SHORT;
	format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: 8.4; * percentn12.1;
run;

*Momentum and Contrarian Trading Stratgies over time;
PROC SGPLOT DATA = WL;
	SERIES X = Interval Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = Interval Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = Interval Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;

PROC SGPLOT DATA = s1212;
	SERIES X = form_date Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = form_date Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;

PROC SGPLOT DATA = s1212;
	SERIES X = form_date Y = Loser_WINNERS / LEGENDLABEL = "Loser_WINNERS";
*	SERIES X = form_date Y = LONG_SHORT / LEGENDLABEL = "LONG_SHORT";
	SERIES X = form_date Y = CUMRET_Loser_WINNERS / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
*	SERIES X = form_date Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_Loser_WINNERS" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;




*For the selected sample period, based on monthly portfolio formation, what is the average return to the strategy in each month post the portfolio formation;
data temp;
	set umd2;
	where month(form_date)=12;*  and int(year(form_date)/4)=year(form_date)/4;
	Interval=intck("month", form_date, DATE);
run;

* Mean return across stocks for each group on each post formation month;  *for each formation month;
proc means data = temp nway noprint;
 	class Interval momr;*form_date;
	id momr;
    var ret;
    output out = c1 mean=ret;
run;  

proc transpose data=c1 
	out=c2  (Keep=form_date Interval _1 _100  rename = (_1=LOSERS  _100=WINNERS)
       		   drop=_NAME_ _LABEL_);
 	by Interval; *form_date;
 	id momr;
 	var ret;
run;

data WL;	format strategy 5.;
	set c2;
*	strategy= 100*&j+&k;
	LONG_SHORT=WINNERS-LOSERS;
	decade = floor(year(form_date)/10) * 10 ;

*	Calculate cumlative returns for each month starting from the begining for the sample period to the current month;
*	by form_date;
	retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT 0;
	CUMRET_WINNERS     = CUMRET_WINNERS+WINNERS;
	CUMRET_LOSERS      = CUMRET_LOSERS+LOSERS;
	CUMRET_LONG_SHORT  = CUMRET_LONG_SHORT+LONG_SHORT;
	format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: 8.4; * percentn12.1;
run;

*Momentum and Contrarian Trading Stratgies over time;
PROC SGPLOT DATA = WL;
	SERIES X = Interval Y = CUMRET_WINNERS / LEGENDLABEL = "CUMRET_WINNERS";
	SERIES X = Interval Y = CUMRET_LOSERS / LEGENDLABEL = "CUMRET_LOSERS";
*	SERIES X = Interval Y = CUMRET_LONG_SHORT / LEGENDLABEL = "CUMRET_LONG_SHORT" Y2Axis ;  
	XAXIS interval = year;
*	XAXIS TYPE = DISCRETE;
    Title "Momentum and Contrarian Trading Stratgies";
RUN;
