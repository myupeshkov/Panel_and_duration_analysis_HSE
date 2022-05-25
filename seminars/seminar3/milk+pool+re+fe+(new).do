/* Models and tests Pool, FE, RE */
// 17/09/2019 

gen lmilk=ln(milk)
gen lgdp_ppc=ln(gdp_ppc)

xtset country t
/* Alternative declaration */
iis country
tis t

/* Models without time effect */
reg lmilk lgdp_ppc
est store pool
xtreg lmilk lgdp_ppc, fe
est store fe
xtreg lmilk lgdp_ppc, re
xttest0
est store re
est tab pool fe re, b(%7.4f) stats (N r2) se
est tab pool fe re, b(%7.4f) stats (N r2) star
findit outreg2
outreg2 [pool fe re] using test.doc, replace
hausman fe re
* Alternative Hausman test
egen mlgdp_ppc = mean(lgdp_ppc), by(country)
xtreg lmilk lgdp_ppc mlgdp_ppc, re
test mlgdp_ppc

reg lmilk lgdp_ppc i.t
/* Models with time effect */
quietly tabulate t, generate(year_)
*tabulate t, generate(year_)
reg lmilk lgdp_ppc year_2-year_16
est store pool_t
testparm year_*
xtreg lmilk lgdp_ppc year_2-year_16, fe
est store fe_t
testparm year_*
vif, uncentered
xtreg lmilk lgdp_ppc year_2-year_16, re
xttest0
testparm year_*
est store re_t
est tab pool_t fe_t re_t, b(%7.4f) stats (N r2) se
est tab pool_t fe_t re_t, b(%7.4f) stats (N r2) star
hausman fe_t re_t
outreg2 [pool fe re pool_t fe_t re_t] using test.doc, replace

* Alternative Hausman test
egen mlgdp_ppc = mean(lgdp_ppc), by(country)
xtreg lmilk lgdp_ppc mlgdp_ppc year_2-year_16, re
test mlgdp_ppc
drop mlgdp_ppc

global LIST "lgdp_ppc year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11 year_12 year_13 year_14 year_15 year_16"
foreach var of global LIST{
egen m`var' = mean(`var'), by(country)
}

xtreg lmilk lgdp_ppc year_2-year_16 m*, re
test mlgdp_ppc
drop mlgdp_ppc
