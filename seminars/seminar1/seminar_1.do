use Panel101.dta 

*нужно чтобы скзать стате, что будем работать с панелькой
xtset country year

*описание таблицы с панелями
xtdes 

*графики по каждой стране отдельно
*можно понять какие динамики и удалять те страны, которые искажают оценки (детекция выбросов)
xtline y 

*динамики в странах отличается поэтому FE может не подходить
*графики через программу:Graphics->Panel data line plots-> override panel settings->country+x1 (variables=y)

*совместный график по странам
xtline y, overlay 

************************************ 
 
// ЭТИ ГРАФИКИ НУЖНЫ ЧТОБЫ ПОНЯТЬ БОЛЬШЕ НЕОДНОРОДНОСТЬ ПО ОБЪЕКТАМ ИЛИ ВРЕМЕНИ// 

*сортировка по средним посчитанным по времени для каждого объекта(страны)
*y_mean = y_{i*}
 bysort country: egen y_mean=mean(y) 
*график по каждой стране со средним 
twoway scatter y country, msymbol(circle_hollow) || connected y_mean country, msymbol(diamond) || , xlabel(1 "A" 2 "B" 3 "C" 4 "D" 5 "E" 6 "F" 7 "G") 

*сортировка по средним посчитанным по времени для каждого объекта(страны)
*y_mean1 = y_{*t}

bysort year: egen y_mean1=mean(y) 
*график по каждому году со средним
twoway scatter y year, msymbol(circle_hollow) || connected y_mean1 year, msymbol(diamond) || , xlabel(1990(1)1999) 


************************************

*смотрим на общую картинку, видим, что как будто нет зависимости
twoway scatter y x1, mlabel (country) || lfit y x1, clstyle (p2) 


*делаем регрессию для каждой страны

*Модель LSDV - МНК с дамми переменными
*Y_it = X'_it*beta+D'_i*alpha_i + epsilon_it
*tau = (1...1)'
*D = (tau 0 .....0)
*.     0. tau.....
*                tau

*Y = X*beta +D*alpha +epsilon (beta по N*T наблюдениям , alpha по T наблюдениям)

regress y x1 i.country 

predict yhat 
separate y, by(country) 
separate yhat, by(country)

**графики FE по каждой стране + черная Pooled 
twoway connected yhat1-yhat7 x1, msymbol(none diamond_hollow triangle_hollow square_hollow + circle_hollow x) msize(medium) mcolor(black black black black black black black) || lfit y x1, clwidth(thick) clcolor(black) 


**добавляем диаграмму рассеивания
twoway connected yhat1-yhat7 x1, msymbol(none diamond_hollow triangle_hollow square_hollow + circle_hollow x) msize(medium) mcolor(black black black black black black black) || lfit y x1, clwidth(thick) clcolor(black) || scatter y x1, mlabel (country)

************************************

//СМОТРИМ НА СВОДНЫЕ ТАБЛИЦЫ//

**убираем дамми на страну и выводим сводную таблицу
**просто сырая таблица по регрессиям и кста появилась значимость x1
**estimates store сохраняет результаты в памяти
**est выводит все в таблице
regress y x1 
estimates store ols 
regress y x1 i.country 
estimates store ols_dum 
estimates table ols ols_dum, star stats(N) 


*** строим для множественной регрессии
xtreg y x1 x2 x3, fe 
*R2 within - нам нужный

*LSDV: Y = Xbeta + D alpha + epsilon
* within: WY = WX*beta +W*epsilon 
*			Y_it-Y_{i*} = (X'_{it} - X'_{i*})*beta + (epsilon_it-epsilon_i*)
*			 по теореме Фриш-Во-Ловелла
*			 beta^_LSDV = beta^_within = beta^_FE
* R^2_w = RSS_w/TSS_w		
*R^2_between = r^2 ({Y_*i}, Y^_{i*}_within) 
*R^2_overall = r^2 (Y, Y^_within)

*регрессия адекватна на уровне значимости 10%
*есть корреляция между регрессорами
*временная неоднородсть в панели сильнее чем страновая, так как F тест говорит, что FE лучше


xtreg y x1 x2 x3, fe 
*alpha^_i = Y_i* - X'_i*beta^_within (проверить, что совпадет с оценкой из LSDV)
estimates store fixed 
regress y x1 x2 x3 i.country 
estimates store ols 
areg y x1 x2 x3, absorb(country) //учитываем страновые дамми, но не выводит их на экран
estimates store areg 
estimates table fixed ols areg, star stats(N r2 r2_a)


findit outreg2
*находит в инете, находим outreg2 и качаем
 
outreg2 [fixed ols areg]  using test.doc, nolabel replace
*можно вместо replace написать append и будут добавляться в таблицу

*выгрузка в общую таблицу типо как для статьи
