xtset Comp_ID Year

global LIST "DtE l_RD lEmp"

xi i.Year
qui reg lQ_Tobin $LIST _IYear*
testparm _IYear*
est store pool
qui xtreg lQ_Tobin $LIST _IYear*
testparm _IYear*
xttest0
est store re
qui xtreg lQ_Tobin $LIST _IYear*, fe
testparm _IYear*
est store fe
vif, uncentered
hausman fe re
outreg2 [pool fe re]  using models.doc,  replace 

// Time autocorrelation test
findit xttest1
// ssc install xttest1
qui xtreg lQ_Tobin $LIST _IYear*, re
xttest1

// Time autocorrelation test (Wooldrige test)
findit xtserial
// ssc install xtserial
xtserial lQ_Tobin $LIST _IYear*

// Spatial autocorrelation test
findit xttest2
// ssc install xttest2
qui xtreg lQ_Tobin $LIST _IYear*, fe
xttest2

// Spatial autocorrelation test (Pesaran test)
findit xtcsd
// ssc install xtcsd

* Spatial autocorrelation test (Pesaran test) in FE-model
qui xtreg lQ_Tobin $LIST _IYear*, fe
xtcsd, pesaran

* Spatial autocorrelation test (Pesaran test) in RE-model
qui xtreg lQ_Tobin $LIST i.Year i.Country_ID i.Sector_ID
xtcsd, pesaran
xi i.Year i.Sector_ID i.Country_ID 
qui xtreg lQ_Tobin $LIST _IYear* _ISector_ID* _ICountry_I*
testparm _IYear*
testparm _ISector_ID*
testparm _ICountry_I*
xtcsd, pesaran

// Heteroscedastisity test (Wald adjusted test)
findit xttest3
// ssc install xttest3
qui xtreg lQ_Tobin $LIST _IYear*, fe
xttest3
qui xtreg lQ_Tobin $LIST _IYear* _ISector_ID* _ICountry_I*
xttest3


// Model correction

* Heteroscedastisity correction
xtreg lQ_Tobin $LIST _IYear*, fe robust
est store fe_rob
xtreg lQ_Tobin $LIST _IYear*, fe cluster(Comp_ID)
est store fe_cl

* Time autocorrelation correction
xtregar lQ_Tobin $LIST i.Year, fe
xtregar lQ_Tobin $LIST _IYear*, fe
est store regar 
xtpcse lQ_Tobin $LIST _IYear*, fe correlation(ar1) 
xtpcse lQ_Tobin $LIST _IYear*,  correlation(ar1) 
est store pcar
xtpcse lQ_Tobin $LIST _IYear*, correlation(psar1) 
est store pcpsar

* Heteroscedastisity,  Time autocorrelation, Spatial autocorrelation correction
findit xtscc
xtscc lQ_Tobin $LIST i.Year, fe
xtscc lQ_Tobin $LIST _IYear*, fe
est store scc_fe

// Comparison models

outreg2 [fe fe_rob fe_cl] using models.doc, replace 
outreg2 [fe fe_rob regar pcar pcpsar] using models.doc, replace 
outreg2 [pool re fe fe_rob regar pcpsar scc_fe] using models.doc, replace 



