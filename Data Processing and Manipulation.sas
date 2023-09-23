* Create a library;
libname HW "C:\Users\zzhang436\Downloads"; 
options obs=max;

*Check data properties;
proc contents data=HW.funda; 	run;
*1.Count how many distinct gvkey, trading symbols and 2-digit industries in the funda dataset each year;
proc sort data=HW.funda;
   by fyear;
run;

proc sql;
  create table distinct_counts as
  select fyear, count(distinct gvkey) as num_gvkey, 
                  count(distinct TIC) as num_symbols, 
                  count(distinct GSECTOR) as num_industries
  from HW.funda
  group by fyear;
*2. From Funda, keep relevant data items to calculate 5-step DuPont analysis for companies for the full sample, 
plus the following additional information for cusip, two-digit NAICS codes, and other firm characteristics (such as liquidity and solvency) 
that you believe would affect ROA. Create the ratios that are needed for your analysis below;

*Net Income(ni)/Pretax Income(pi) * Pretax Income/EBIT(ebit) * EBIT/Sales(sale) * Sales/Total Assets(at) * Total Assets/ Equity(teq);
*Tax Burden * Interest Burden * Operating Margin * Asset Turnover * Equity Multiplier;

data RATIO;
set HW.funda(keep=gvkey ni pi ebit sale at teq datadate cusip naicsh epspx prcc_f act lct invt cogs dt consol datafmt popsrc indfmt COMPST);
if sale^=0 then 
	ROE=100*ni/teq;
	fyear=year(datadate);
	naicsh_2 = int(naicsh/100);

	*liquidity ratios;
	cr = act/lct;
    qr= (act-invt)/lct;

	*Market Value Ratios;
	PE= prcc_f/epspx;
    MtB = prcc_f/bkvlps;

	*asset utilization turnover ratio;
	TAT=100*sale/at;	*Total asset turnover;
	IT=cogs/invt; *Inventory turnover

	*Long-term solvency;
	EM = at/teq;
	TD = (at-teq)/teq;

	*Profitability Ratio;
	ROA=100*ni/at;
	PM=100*ni/sale;

	TaxBurden = ni/pi;
    InterestBurden = pi/ebit;
    OperatingMargin = ebit/sale;
	FL = teq/dt;
	drop consol datafmt popsrc indfmt COMPST;

	if	(consol eq "C") and    						/*  Level of Consolidation Data - Consolidated     */
	(datafmt eq "STD") and 						/*  Data Format - Standardized, Exclude SUMM_STD (Domestic Annual Restated Data)    */
	(popsrc eq "D") and	(not missing(fyear)) and /*  Population Source - Domestic (USA, Canada and ADRs)      */
	(indfmt eq "INDL") and						/*  Industry Format - Financial Services                                       */
	(at notin(0,.)) and	(sale notin(0,.)) and	/*  Assets total: missing */
	(COMPST ne 'DB') ;							/*  Comparability Status - Company has undergone a fiscal year change.         */
run;

*3.Winsorize your sample at 5 and 95 percent levels; *show how to check whether you’ve winsorized your data;
filename m3 url 'https://gist.githubusercontent.com/JoostImpink/497d4852c49d26f164f5/raw/11efba42a13f24f67b5f037e884f4960560a2166/winsorize.sas';
%include m3;
%winsor(dsetin=ratio, dsetout=Q3, vars=ROE FL cr qr PE MtB TAT IT EM TD ROA PM TaxBurden InterestBurden OperatingMargin, type=winsor, pctl=5 95);
run;

proc means data=Q3 p95 max;
  var ROE FL cr qr PE MtB TAT IT EM TD ROA PM TaxBurden InterestBurden OperatingMargin;
run;

*4.Choose two financial ratios for each of the 5 categories. 
Show the median values for these ratios that you've computed for each of the following: by two-digit NAICS codes, by fiscal year. 
Briefly discuss your findings. Hint: use Proc print to print your table.;
proc means data=Q3 nway median;	 
	class fyear;
	var ROE FL cr qr PE MtB tat IT EM TD ROA PM TaxBurden InterestBurden OperatingMargin;
	TITLE 'The median of financial ratios';
	output out=Q4(rename=(_freq_=freq) drop=_type_)   median=ROE FL cr qr PE MtB tat IT EM TD ROA PM TaxBurden InterestBurden OperatingMargin ;Proc print Data=Q4; run;	

*5. Compute the median value of the DuPont 3-factors over any 5 years, and plot these 3 factors. 
	Make sure you plot these ratios nicely to show their variations over the years. What conclusion can you draw?;
data Q5;
   set HW.funda (keep = gvkey datadate tic naicsh sale at ni teq);
   fyear=year(datadate);
   where sale >0 and at > 0 and teq >0 ;
   Profit_Margin = ni / sale;
   Asset_Turnover = sale / at;
   Financial_Leverage = at / teq;
run;

proc sql;
   create table Q5_median as
   select fyear, median(Profit_Margin) as Profit_Margin_median,
   median(Asset_Turnover) as Asset_Turnover_median, median(Financial_Leverage) as Financial_Leverage_median
   from Q5
   where 2015<fyear<2020
   group by fyear;
quit;

/* Plot the median values of the DuPont 3-factors */
title 'Median Values of DuPont 3-Factors';
proc sgplot data=Q5_median;
   series x=fyear y= Profit_Margin_median / lineattrs=(thickness=2 color=red);
   series x=fyear y= Asset_Turnover_median / lineattrs=(thickness=2 color=blue);
   series x=fyear y= Financial_Leverage_median / lineattrs=(thickness=2 color=green);
   xaxis label='Fiscal Year';
   yaxis label='Ratio Value';
   xaxis type = discrete; 
   keylegend / location=inside position=topright;
run;
*6.Plot the revenue growth of Tesla (TIC: TSLA) over the years. Briefly discuss your findings (Using six years into the future).;
data Q6;
set HW.funda(keep = datadate revt tic);
fyear=year(datadate);
where TIC ='TSLA';
run;
PROC SGPLOT DATA = Q6;
SERIES X = fyear Y = revt / LEGENDLABEL = 'revenue_growth';
	XAXIS TYPE = DISCRETE;
	TITLE 'revenue_growth of Tesla';
RUN;

*7.Use a regression approach to show how is ROE related to some firm characteristics, with standard errors clustering at the two-digit NAIC industry levels. 
For your regression table, please show only the variable names, coefficients and t-stats. Briefly explain your regression results. 
Due to correlations among the independent variables, you may try different combination among them to yield some reasonable results as predicted by your Dupont decomposition.;
proc surveyreg data=Q3;  
	cluster naicsh_2;
	model ROE =TAT EM TaxBurden InterestBurden OperatingMargin;
	ods OUTPUT ParameterEstimates = MyParmEst;
	TITLE 'The determinants of ROE';
quit; 
