
**СКАЧИВАНИЕ И ПОДГОТОВКА ДАННЫХ

clear all // cleans memory from data
set more off // cancel pauses 
capture log close 

cd /Users/mypeshkov/Desktop/hw_stata/
log using log_2.log, replace
insheet using data_stata.csv, clear

*говорим стате, что работаем с панельными данными
egen country_id = group(country_label) 
encode country_label, generate(country) //нужно чтобы он нас понимал

xtset country year //говорим, что работаем с панелькой

//создаем дамми-переменные на год
tab year, gen(year)
rename year# year#, addnumber(2014)

gen log_unemp =log(unemp)
gen log_startbus =log(startbusin)

browse

//смотрим на данные

xtdes 

//видим что все сбалансировано

**ОПИСАТЕЛЬНЫЕ СТАТИСТИКИ
xtsum growth_gdp rule_of_law schooling inflation startbusin urban log_popul unemp dummy_eu dummy_oecd covid_year

**ГРАФИКИ
//по странам много графиков
xtline growth_gdp, ytitle("Growth of GDP per capita")
//все страны вместе
xtline growth_gdp, overlay legend(off) ytitle("Growth of GDP per capita")
//смотрим на изменение среднего прироста
//по странам
bysort country: egen growth_gdp_mean=mean(growth_gdp)
 
twoway scatter growth_gdp country, msymbol(circle_hollow) || connected growth_gdp_mean country, msymbol(diamond) 
//по годам
bysort year: egen growth_gdp_mean1=mean(growth_gdp) 

twoway scatter growth_gdp year, msymbol(circle_hollow) || connected growth_gdp_mean1 year, msymbol(diamond) || , xlabel(2014(1)2020) ytitle("Growth of GDP per capita")
//смотрим на функцию плотности роста
kdensity growth_gdp 
//смотрим на распределения регрессеров в гистограммах
hist urban //norm distribution
hist log_popul //norm distribution
hist unemp //есть тяжелые хвосты, поэтому логарифмируем 
hist log_unemp //стало получше
hist inflation //norm distribution
hist startbusin //не нормальное, логарифмируем
hist log_startbus //не помогло, так как слишком много больших значений, поэтому оставим старый индекс, его проще интерпретировать

hist schooling //это качественная переменная, не будем логарфмировать
hist dummy_eu //они тоже качественные, просто для красоты пусть будут
hist dummy_oecd

//поищем среди индексов институтов с норм распределением, так как они коррелируют друг с другом, то достаточно одного из них взять, для лучших оценок ищем с нормальным распределением
hist rule_of_law
hist voice_account
hist pol_stability //norm distribution берем его
hist control_corrup
hist gov_effective
hist regulatory_qual

**ЗАВЕДЕМ СРЕДНИЕ И ОТКЛОНЕНИЯ ДЛЯ ТЕСТА ANCOVA
xtset country_id year

egen mean_growth_gdp =mean(growth_gdp), by(country_id)
egen mean_pol_stability =mean(pol_stability), by(country_id)
egen mean_rule_of_law =mean(rule_of_law), by(country_id)

egen mean_inflation =mean(inflation), by(country_id)
egen mean_urban =mean(urban), by(country_id)
egen mean_log_unemp =mean(log_unemp), by(country_id)
egen mean_startbusin =mean(startbusin), by(country_id)
egen mean_log_popul =mean(log_popul), by(country_id)

gen dif_growth_gdp = growth_gdp - mean_growth_gdp
gen dif_pol_stability = pol_stability - mean_pol_stability
gen dif_rule_of_law = rule_of_law - mean_rule_of_law

gen dif_inflation = inflation - mean_inflation
gen dif_urban = urban - mean_urban
gen dif_log_unemp = log_unemp - mean_log_unemp
gen dif_startbusin = startbusin - mean_startbusin
gen dif_log_popul = log_popul - mean_log_popul


***ТЕСТА ANCOVA


//в первой модели мы проверяем гипотезу о гетерогенными по времени коэффициентами наклона и свободным членом
//для этого нам нужно для каждой страны будет считать регрессию, но так как всего 7 лет, то придется убрать регрессоры  - мало меняющиеся во времени и мультиколлинеарные (население)

/* Estimation of model (0) without restriction */

//проверка на мультиколлинеарность
qui reg growth_gdp rule_of_law inflation startbusin urban log_unemp log_popul schooling dummy_eu dummy_oecd year2020

vif, uncentered
//видим что есть и надо убирать регрессии

scalar rss_ur=0
scalar n_ur=0
scalar df_ur=0

scalar list rss_ur n_ur df_ur
forvalue i=1/42 {
qui reg dif_growth_gdp dif_rule_of_law dif_inflation dif_urban dif_log_unemp year2020 if country_id==`i' 
scalar z`i'=e(rss)
scalar df`i'=e(df_r)
scalar n`i'=e(N)
scalar rss_ur=rss_ur+z`i'
scalar n_ur=n_ur+n`i'
scalar df_ur=df_ur+df`i'
scalar list rss_ur n_ur df_ur
}
scalar list rss_ur n_ur df_ur

/* Estimation of model (1) with FE of country */

qui reg dif_growth_gdp dif_rule_of_law dif_inflation dif_urban dif_log_unemp year2020
scalar rss_r1 = e(rss)
scalar n_r1=e(N)
scalar df_r1=e(df_r)
scalar list rss_r1 n_r1 df_r1


scalar list rss_r1 n_r1 df_r1
scalar df_r1_cor = df_r1 - 41 //вычитаем N-1
scalar list rss_r1 n_r1 df_r1_cor

/* Estimation of model (2) Pool */
qui reg growth_gdp rule_of_law inflation urban log_popul log_unemp year2020
scalar rss_r2 = e(rss)
scalar n_r2=e(N)
scalar df_r2=e(df_r)
scalar list rss_r2 n_r2 df_r2

/* Calculation of F-statistics and  p-values */
/*********************************************************/
scalar fh1 =((rss_r1 - rss_ur)/(df_r1_cor-df_ur))/(rss_ur/df_ur)
scalar pval1 = Ftail(df_r1_cor-df_ur,df_ur,fh1)

scalar fh2 =((rss_r2 - rss_ur)/(df_r2-df_ur))/(rss_ur/df_ur)
scalar pval2 = Ftail(df_r2-df_ur,df_ur,fh2)

scalar fh3 =((rss_r2-rss_r1)/(df_r2-df_r1_cor))/(rss_r1/df_r1_cor)
scalar pval3 = Ftail(df_r2-df_r1_cor,df_r1_cor,fh3)
scalar list pval1 pval2 pval3  fh1 fh2 fh3

*p-value везде очень маленький и ничего не можем редуцировать, то есть по странам корректно искать общие тенденции не можем
*нет единой модели для всех стран
*нужно оценивать регрессию без ограничений (смотри в лмс семинар 2 презу)
*Вывод:данные объединимы в панель, возможно можно не учитывать временной эффект, но учитывая явное падение в 2020 году, то будем учитывать (возможно этот тест не уловил эту значимую разницу но мы умные и будем его учитывать и собственно оценивать дамми перед 2020 годом)

**ОЦЕНИВАНИЕ РЕГРЕССИЙ

//здесь я тоже убрал население, так как оно очень сильно коррелировало с другими
//еще можно убрать уровень бизнеса, так как он не очень нормальный и тоже коррелирует

//ols
reg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2020
//нужно вывести эти таблички в ворд и проинтерпретировать что там в них есть

est store pool

//fe
xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2020, fe
//нужно вывести эти таблички в ворд и проинтерпретировать что там в них есть r2 все три штуки, sigma все и что за ними лежит
//здесь же есть тест вальда внизу, он говорит, что гипотеза все индивид эффекты не нужны отвергаются

//выбираем fe, а не pooled


est store fe

//мультиколлинеарность конечно жесть, предлагаю убрать бизнес
vif, uncentered

//re
xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2020, re
//нужно вывести эти таблички в ворд и проинтерпретировать что там в них есть
//здесь мы препдполагаем что корреляция ошибок и регрессоров ноль
//есть еще тест вальда хи2, по которому видно, что гипотеза о равенстве коэфу отвергается

//там же по сигмам неоднородность временных тактов выше неоднородности стран в 2 раза и 21% разброса роста ввп приходится на индивидуальные эффекты

est store  re

//все таблицы
est tab pool fe re, b(%7.4f) stats (N r2) se


est tab pool fe re, b(%7.4f) stats (N r2) star

//оценки значимо отличаются друг от друга

**ТЕСТЫ ПО ВЫБОРУ МОДЕЛЕЙ

//БРОЙШ-ПАГАН

xttest0

//гипотеза отвергается, выбираем re а не pooled

//нужно прописать гипотезы очень аккуратно


//ХАУСМАН

hausman fe re 

//гипотеза отвергается, выбираем fe
//гипотеза не отвергается, выбираем re

//Тестирование чувствительности временных эффектов к спецификации модели

reg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020

est store pool_t
testparm year*
//необходимо учитывать временные эффекты

xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, fe

est store fe_t
testparm year*

//здесь тест вальда тоже говорит, что временные эффекты важны
//значимость дамми подросла, то есть при учете индивид эффектов и временных эффектов значимость только выросла
//здесь видно, что в основном большая значимость у временных эффектов, а не у регрессоров, а больше всего у ковидного года
//это объясняется тем, что возникла мультиколлинеарность временных дамми и регрессоров, поэтому значимость обесценилась


//мультиколлинеарность

vif, uncentered //мультиколлинеарность конечно есть

//re

xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re

xttest0

est store re_t
testparm year*

hausman fe_t re_t

//не отвергается, поэтому берем re_t

outreg2 [pool fe re pool_t fe_t re_t] using test.doc, replace

***ТЕСТЫ на АВТОКОРРЕЛЯЦИЮ И ГЕТЕРОСКЕДАСТИЧНОСТЬ


//Тест бройша пагана

qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re

xttest1
//показывает что индивидуальные эффекты значимы, так еще есть и AR(1)-joint test

// тест вулдриджа 

xtserial growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020

//тоже говорит, что есть автокорреляция

//тест пространственной автокорреляции

//тест песарана
qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, fe

xtcsd, pesaran
//у нас есть слабая пространственная автокорреляция на 10% значимости

//поэтому проверим на чувствительность этот тест 
//сначала с re
qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re

xtcsd, pesaran

//такая же слабая пространственная автокорреляция

//добавим еще фиксированные эффекты странам

qui xtreg growth_gdp pol_stability inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020 i.country_id

xtcsd, pesaran

//такая же слабая пространственная автокорреляция

//А еще давайте проверим чувствительность теста на индивидуальные эффекты стран и лет

xi i.year i.country_id

qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd _Iyear* _Icountry_i*

xtcsd, pesaran

testparm _Iyear*
testparm _Icountry_i*

//оба теста значимы, что ожидаемо, так как рост ВВП у нас меняется как по странам так и по годам

//тест на гетероскедастичность

qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, fe
xttest3

//гетероскедастичность очень сильная, что ожидаемо, так как страны неоднородны
qui xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020 i.country_id,fe

xttest3

//гетероскедастичность есть даже при учете отдельно взятых эффектов

***КОРРЕКЦИЯ 

//гетероскедастичность

//там надо сравнить стандартные ошибки

//ну и так как мы выбрали рандом модель, то тоже самое и для нее

xtreg growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re robust
est store re_rob

//там надо сравнить стандартные ошибки


//коррекция на автокорреляцию
//(здесь gls)

//для re

xtregar growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re
est store regar_re

//(здесь пул с поправкой на автокорреляции)

xtpcse growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, correlation(ar1) 
est store pcar

//позволяет учитывать гетерогенность коэффициентов автокорреляции

xtpcse growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, correlation(psar1) 
est store pcpsar

//одновременно коррекция на все
//findit xtscc

//для re

xtscc growth_gdp rule_of_law inflation startbusin urban log_unemp schooling dummy_eu dummy_oecd year2015-year2020, re 
est store scc_re


outreg2 [re re_rob regar_re pcar pcpsar scc_re] using models1.doc, replace 

outreg2 [pool fe re fe_t re_t re_rob pcpsar scc_re] using models2.doc, replace 

//outreg2 [pool re fe fe_rob regar pcpsar scc_fe] using models.doc, replace 

//отдельно вывести лучшие из этих 2 таблиц и обычные, типо сделать итоговую таблиц

//мы будем выбирать xtpcse, так как там ошибки меньше всего и коэфы практически все значимы
