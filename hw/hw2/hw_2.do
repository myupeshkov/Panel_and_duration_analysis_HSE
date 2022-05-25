


clear all // cleans memory from data
set more off // cancel pauses 
capture log close 
log using log_3.log, replace



set obs 1000
set seed 777

*1
gen t_star = (-ln((1-uniform()))/0.07)^(1/0.7)
*2
gen t_c = uniform()*80
*3
gen t = min(t_star, t_c)

*4 
gen delta = 1
replace delta=0 if t_c <= t_star

*5

stset t, fail(delta)
sts gen s_km = s
sts gen cumhaz = na


sts graph //KM
sts graph, na //NA

*6a

twoway  (line s_km _t, connect(stairstep) sort lcolor(black))||function True_S=exp(-0.07*(x)^(0.7)), range(0 80)

*6b

twoway  (line cumhaz _t, connect(stairstep) sort lcolor(black))||function True_H=0.07*(x)^(0.7), range(0 80)

*7
stsum //26.78968

display (-(ln(0.5)/0.07))^(1/0.7) //26.452562

*8
drop if delta < 1

*8.1
stset t, fail(delta)

sts graph //KM
sts graph, na //NA

*8.2
sts gen surv = s

twoway  (line surv _t, connect(stairstep) sort lcolor(black))||function True_S=exp(-0.07*(x)^(0.7)), range(0 80)


*8.3
sts gen haz_cum_2 = na

twoway  (line haz_cum_2 _t, connect(stairstep) sort lcolor(black))||function True_H=0.07*(x)^(0.7), range(0 80)

*8.4
stsum //8.687847

display (-(ln(0.5)/0.07))^(1/0.7) //26.452562

