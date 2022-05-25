// Dinamic model estimation
/* declaration of panel */
clear all // cleans memory from data
set more off // cancel pauses 
capture log close 

cd /Users/mypeshkov/Desktop/seminars_panel/seminar6
use Firms+panel+2007_2012.dta

xtset Comp_ID Year

global LIST "DtE l_RD lEmp"

qui xtreg lQ_Tobin $LIST, fe
est store fe
xtabond lQ_Tobin $LIST, nocons twostep 
est store ab
xtdpdsys lQ_Tobin $LIST, nocons twostep 
// Comments:
// dgmmiv(varlist) ñ list of variables in level - instruments for equation in differences 
// lgmmiv (varlist) - list of variables in differences  - instruments for equation in level‚   
// div(varlist) ñ list of add standart instruments in differences for equation in differences 

est store bb
est tab fe ab bb, b(%7.4f) star
findit outreg2
outreg2 [fe ab bb] using dinamic.doc,replace

quietly tabulate Sector_ID, generate(Sec_)
cor  lEmp l_RD DtE Sec_*
// lEmp may be endog because correlation with Sector_ID

xtabond lQ_Tobin $LIST, nocons twostep endog(lEmp)
est store ivab
hausman ivab ab
qui xtdpdsys lQ_Tobin $LIST, nocons twostep endog(lEmp)
est store ivbb
hausman ivbb bb
qui xtabond lQ_Tobin $LIST, nocons twostep endog(lEmp) vce(robust)
est store ivabr
qui xtdpdsys lQ_Tobin $LIST, nocons twostep endog(lEmp) vce(robust)
est store ivbbr
est tab fe ab ivab bb ivbb ivabr ivbbr, b(%7.4f) star
// with lEmp endog estimations have improve

quietly tabulate Year, generate(Year_)
cor  lEmp l_RD DtE Year_*
cor lQ_Tobin Year_*
// lQ_Tobin corr with year

xtreg lQ_Tobin $LIST Year_2-Year_6, fe
testparm Year_2-Year_6
// May be linear trend should be included to model
qui xtreg lQ_Tobin $LIST Year, fe
est store fe
qui xtabond lQ_Tobin $LIST Year,  twostep 
est store ab
qui xtabond lQ_Tobin $LIST Year,  twostep endog(lEmp)
est store ivab
hausman ivab ab
qui xtdpdsys lQ_Tobin $LIST Year,  twostep 
est store bb
qui xtdpdsys lQ_Tobin $LIST Year, twostep endog(lEmp)
est store ivbb
hausman ivbb bb
qui xtabond lQ_Tobin $LIST Year,  twostep endog(lEmp) vce(robust)
est store ivabr
qui xtdpdsys lQ_Tobin $LIST Year, twostep endog(lEmp) vce(robust)
est store ivbbr
est tab fe ab ivab bb ivbb ivabr ivbbr, b(%7.4f) star
// ivab and ivbb are the best, but do opposit estimation of time effects

xtabond lQ_Tobin $LIST Year, nocons twostep endog(lEmp)
estat sargan
xtabond lQ_Tobin $LIST Year, nocons twostep endog(lEmp) vce(robust)
estat abond

qui xtdpdsys lQ_Tobin $LIST Year, nocons twostep endog(lEmp)
estat sargan
qui xtdpdsys lQ_Tobin $LIST Year, nocons twostep endog(lEmp) vce(robust)
estat abond
// ivbb has  unvalid instruments 

// ivab is the best
// stationarity test for ivab

xtabond lQ_Tobin $LIST Year, nocons twostep endog(lEmp)
predict de, e difference
predict e, e

/* unit root tests */
/* LLC test, using the AIC to choose the number of lags for regressions and 
   using an HAC variance estimator based on the Bartlett kernel and the number
   of lags chosen using Newey and West's method */

xtunitroot llc de, demean lags(aic 1) kernel(bartlett nwest)
xtunitroot llc e, demean lags(aic 1) kernel(bartlett nwest)

/* demean requests that xtunitroot first subtract the cross-sectional averages
        from the series.  When specified, for each time period xtunitroot
        computes the mean of the series across panels and subtracts this mean
        from the series.  Levin, Lin, and Chu suggest this procedure to mitigate
        the impact of cross-sectional dependence */
		
/* kernel(kernel_spec) requests a variant of the test statistic that is robust
        to serially correlated errors.  kernel_spec specifies the method used to
        estimate the long-run variance of each panel's series.  kernel_spec
        takes the form kernel [#].  Three kernels are supported: bartlett,
        parzen, and quadraticspectral */

/* HT test, removing cross-sectional means from data */

xtunitroot ht de, demean
xtunitroot ht e, demean

/* Robust version of the Breitung test on a subset of OECD countries, using 1
    lags for the prewhitening step  (robust version of the Breitung test is impossible) */

xtunitroot breitung de, lags(1) 
xtunitroot breitung e, lags(1) 

/* Hadri LM test of stationarity, using an HAC variance estimator based on the
    Parzen kernel with 5 lags */

xtunitroot hadri de, kernel(parzen 5)
xtunitroot hadri e, kernel(parzen 5)

/* IPS test, using the AIC to choose the number of lags for regressions */

xtunitroot ips de, lags(aic 1)
xtunitroot ips e, lags(aic 1)

/* Fisher-type test based on ADF tests with 1 lag1, allowing for a drift term
    in each panel */

xtunitroot fisher de, dfuller lags(1) drift
xtunitroot fisher de, dfuller lags(1) trend

xtunitroot fisher e, dfuller lags(1) drift
xtunitroot fisher e, dfuller lags(1) trend


//Panel cointegration

xtcointtest kao lQ_Tobin l_RD lEmp DtE




