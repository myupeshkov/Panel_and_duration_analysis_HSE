
clear all // cleans memory from data
set more off // cancel pauses 
capture log close 

cd /Users/mypeshkov/Desktop/seminars_panel/seminar5
use ht2015.dta

set mem 500000

tsset pid wave
xtdes
xtsum

// Test of relevancy
xtreg pnjuwks pur punflow pvacflow age agesq sex, fe

//pur punflow pvacflow - инструменты

test pur punflow pvacflow
test punflow pvacflow

findit xtoverid
findit xtivreg2
findit ranktest
findit ivreg2

ssc install xtoverid
ssc install xtivreg2
ssc install ranktest
ssc install ivreg2 //лучшая из них, много чего может

xtivreg logpay age agesq sex (pnjuwks=pur punflow pvacflow), fe 
xtoverid

xtivreg logpay age agesq sex (pnjuwks=pur punflow pvacflow), re
xtoverid //он работает только после re
//p-value большой - инструменты валидные

xtivreg2 logpay age agesq sex (pnjuwks=pur punflow pvacflow), fe
//test sargan - инструменты валидные 

//инструменты валидные, значит можем доверять оценкам

//(1) FE
xtivreg logpay age agesq sex (pnjuwks=pur punflow pvacflow), fe
est store fe_iv
xtreg logpay age agesq sex pnjuwks, fe
est store fe
hausman fe_iv fe
//p-value маленький, модели неэквивалентны, поэтому берем с инструментами


//(2) RE
xtivreg logpay age agesq sex (pnjuwks=pur punflow pvacflow), re
est store re_iv
xtreg logpay age agesq sex pnjuwks, re
est store re
hausman re_iv re
//тестируем чувствительности теста хаусмана на учет индивид эффектов
//стало меньше, поэтому точно берем с инструментми

hausman fe_iv re_iv
//берем fe_iv, но это неприятно, мы же хотим образование чекнуть, а при фикс мы не можем поменять (оно не имзеняется)

ssc install outreg2

outreg2[re fe re_iv fe_iv] using test.doc, replace

*******************************

//процедура хаусмана-тейлора

qui by pid: gen hieduc=hiqual[_N]

//состоятельное, но неэффективное оценивание

xtreg logpay age agesq sex pahgs hieduc pnjuwks, fe
predict residfe, ue
xtreg residfe sex pahgs hieduc, be
est store be
//на 40% перед (коэф перед hieduc) диплом увеличивал зп


//это все в statistics->panel data ->endogeneous ->hausman

//исследуем чувствительности теста хаусмана тейлора к набору инструментов
//переберем варианты и посмотрим как меняются результаты

xthtaylor logpay age agesq sex pahgs hieduc pnjuwks, ///
endog(pnjuwks hieduc)
//u_i - iid, то есть это re c разрешением корреляции регрессора с ошибкой
xtoverid
est store ht1
//невалидные инструменты - p-value маленький

xthtaylor logpay age agesq sex pur pahgs hieduc pnjuwks, ///
endog(pnjuwks hieduc)
xtoverid
est store ht2
//теперь по-лучше, добавление сильного и релевантного инструмента помогает

xthtaylor logpay age agesq sex pur punflow pvacflow pahgs hieduc pnjuwks, ///
endog(pnjuwks hieduc)
xtoverid
est store ht3
//еще лучше, инструменты валидные по тесту, хотя и есть слабые инструменты из них
//добавление слабых инструментов к дальнейшему улучшению не приводит, так еще и эффективность падает

xtreg logpay age agesq sex pahgs hieduc pnjuwks, re
est store re

est tab re ht3 ht2 ht1 be, b(%7.4f) star
est tab re ht3 ht2 ht1 be, b(%7.4f) se

outreg2[re ht3 ht2 ht1 be] using test.doc, append






