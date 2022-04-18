//Calculating the effect of policy uncertainity on economic growth

cd "C:\Users\debaleena.goswami\My Drive\Coursework at IIMU\Econometric Methods I\Assignment"
clear
///The data was collected from https://ourworldindata.org/grapher/trade-openness which uses data from Penn world tables
//Data cleaning: for this and each subsequent data sets, the years are ranged from 1970-2010
insheet using "trade-openness.csv", comma
ren entity country
egen country_id = group(country)
keep if year>=1970  
keep if year<=2010
xtset country_id year
rename ratioofexportsandimportstogdppwt trade_openness
drop code
gen country_year = country + string(year)
by country_id : gen nyear=[_N]
keep if nyear==41
drop nyear
save "trade openness", replace
clear
****
//WDI data: Cleaning primary school enrollment data


import delimited using "WDI_primary school enrollment.csv", varnames(1)
drop if _n>265
reshape long yr, i(countryname) j(year)
drop countrycode seriesname seriescode
keep if year>=1970
keep if year<=2010
egen country_id = group(country)
xtset country_id year
gen country_year = countryname + string(year)
save "WDI_primary enrollment", replace
clear

****************************
//Policy uncertainity data collected from economicpolicyuncertainity
import excel using "policy uncertainity data.xlsx", sheet("EPU") firstrow
drop if _n>446
destring Year, replace
keep if Year>=1970
keep if Year<=2010
egen idlong= concat(Month Year)
drop GEPU_current GEPU_ppp
renvars ( Australia - AJ) ,  prefix(pop)
reshape long pop, i(idlong) j(countryname) string
drop idlong
egen country_id = group(country)
drop if Month<12
drop if countryname=="AE" | countryname== "AF" | countryname== "AG" | countryname== "AH" | countryname== "AI" |countryname== "AJ" |countryname== "AD" |countryname== "AC"
gen country_year = countryname + string(Year)
ren countryname country
ren Year year
xtset country_id year
save "policy uncertainity", replace
clear


//// Economic freedom data collected from heritage.org


insheet using "economic freedom data.csv", comma
drop propertyrights governmentintegrity judicialeffectiveness taxburden governmentspending fiscalhealth businessfreedom laborfreedom monetaryfreedom tradefreedom investmentfreedom financialfreedom
destring indexyear, replace
egen country_id = group(name)
keep if indexyear<=2010
keep if indexyear >=1970
gen country_year = name + string(indexyear)
xtset country_id indexyear
ren indexyear year
save "economic freedom", replace
clear

//// Ethnic homogenity data collected from Harvard database, historical data of ethnic fractionalization


insheet using "ethnic homogenity.csv", comma
sort country
egen country_id = group( country )
keep if year>=1970
keep if year<=2010
gen country_year = country + string(year)
sort country year
quietly by country year:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
xtset country_id year
by country_id : gen nyear=[_N]
drop if nyear<41
drop nyear
save "ethnic homogenity", replace
clear


//// Polity scale (autocratic to democratic, countried scored on a scale on -1 to 1)


import excel "p5v2018.xls", sheet("p5v2018") firstrow
keep if year>=1970
keep if year<=2010
gen country_year = country + string(year)
keep country year polity
gen country_year = country + string(year)
sort country year
quietly by country year:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
save "polity scale", replace
clear


///Cleaning variables collected from Penn world Tables: PPP adjusted GDP per capita at current prices, Investment as a percentage of GDP, population growth, trade openness, govt spending


use "PWTvar_combined and cleaned"
gen country_year = country + string(year)
drop country_id_year
sort country year
quietly by country year:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
xtset
clear

/////merging files using key variable country_year

insheet using "pwt variables.csv", comma
keep if year>=1970
keep if year<=2010
egen country_id = group(country)
xtset country_id year
rename pop population
rename ci investment_percent_GDP
rename cg govt_share_gdp
rename cgdp gdp_pc
gen log_gdp = ln(gdp_pc)
gen gdp_growth = D.log_gdp
drop if gdp_pc==.
gen ln_pop=ln(population)
gen g_pop = D.ln_pop
xtset
gen country_year = country + string(year)
merge 1:1 country_year using "WDI_primary enrollment"
keep if _merge==3
ren yr WDI_e
drop _merge
merge 1:1 country_year using "polity scale"
drop _merge
merge 1:1 country_year using "economic freedom"
drop _merge
merge 1:1 country_year using "ethnic homogenity"
drop _merge
merge 1:1 country_year using "trade openness"
drop _merge
merge 1:1 country_year using "policy uncertainity"
drop isocode population ln_pop countryname country_id name Month _merge
asdoc sum

//// destringing overall score (the economic freedom variable, because it had nonnumeric characters)

foreach v of varlist overallscore {
     replace `v' = "" if `v' == "N/A"
     }
destring overallscore, replace
replace WDI_e = "." if WDI_e ==".."
destring WDI_e, replace

/////5-year lag generation

sort country year
by country: gen lag_lngdp_pc = log_gdp[_n-1]

gen period = 5 * floor(year/5)
sort country year
rangestat (last) initiallngdppc= log_gdp, interval(period, -5, -5) by(country)
egen period1 = group(period) if inrange(year,1970,2010)
label var period1 "5-yr period"
label define fiveyr 1 "1970-74" 2 "1975-79" 3 "1980-84" 4 "1984-89" 5 "1990-94" 6 "1995-99" 7 "2000-2004" 8 "2004-09"
lab val period1 fiveyr
collapse (mean) g_pop log_gdp gdp_growth investment_percent_GDP govt_share_gdp WDI_e polity overallscore efindex trade_openness pop initiallngdppc if !missing(period1), by(country period1)

///Understanding the structure of the databasecorrelate gdp_growth initiallngdppc
graph twoway (scatter gdp_growth initiallngdppc)
graph twoway (scatter gdp_growth initiallngdppc) (lfit gdp_growth initiallngdppc)
reg gdp_growth initiallngdppc
predict y1hat, xb
summarize $initiallngdppc y1hat
pwcorr gdp_growth initiallngdppc pop investment_percent_GDP WDI_e trade_openness g_pop efindex overallscore polity, star(0.05) sig

////regressions
reghdfe gdp_growth initiallngdppc pop, absorb( country period1)
eststo model1
reghdfe gdp_growth initiallngdppc pop investment_percent_GDP WDI_e trade_openness g_pop , absorb( country period1)
eststo model2
reghdfe gdp_growth initiallngdppc pop investment_percent_GDP WDI_e trade_openness g_pop efindex overallscore polity , absorb( country period1)
eststo model3
esttab, r2 ar2 se scalar(rmse)
esttab using "test.csv", r2 ar2 se scalar(rmse)
asdoc sum
