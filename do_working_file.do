//Calculating the effect of policy uncertainity on economic growth

//cd "C:\Users\debaleena.goswami\My Drive\Coursework at IIMU\Econometric Methods I\Assignment"
clear
/* Number of countries: 222, Years: 1970 - 2010*/


*------------------------------------------------------------------------------*


/*The data was collected from https://ourworldindata.org/grapher/trade-openness which uses data from Penn world tables.

It contains the variable 'Trade Openness' measured as the sum of a country's exports and imports as a share of that country's GDP (in %)

*/
/*Data cleaning: for this and each subsequent data sets, the years are ranged from 1970-2010*/

*Opened CSV file having the trade openness data
insheet using "trade-openness.csv", comma  //(4 vars, 11,382 obs)

*Renaming the variable containing the country names as 'country'
ren entity country

*Generated country_id variable to uniquely identify the countries
egen country_id = group(country)

*Restricting the observations to the defined period from 1970-2010
keep if year>=1970  //(1,828 observations deleted)
keep if year<=2010  //(1,472 observations deleted)

*Setting the panel data
xtset country_id year  //Panel variable: country_id ; Time variable: year, 1970-2010


*Renaming the main variable of interest for ease of indentification after merging
rename ratioofexportsandimportstogdppwt trade_openness

*Dropped an unnecessary variable from the data containing a code for the country
drop code

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = country + string(year)

*Generating a variable nyear which captures the number of observations by country-id
by country_id : gen nyear=[_N]

*Winsorizing the data at 1% and 99%
winsor2 nyear, cuts(1 99) replace

*Saved the final dataset as .dat (Stata data format)
save "trade openness", replace
clear


*------------------------------------------------------------------------------*


/*
This data is collected from the World Development Indicators (WDI) database, which is the primary World Bank collection of development indicators

It contains the variable 'Primary school enrolment': Adjusted net enrolment rate, primary (% of primary school age children)


*Opened CSV file
import delimited using "WDI_primary school enrollment.csv", varnames(1)  //(45 vars, 271 obs)

*Dropping rows that contain a textual description
drop if _n>265  //(6 observations deleted)

*Reshaping the data from wide to long format
reshape long yr, i(countryname) j(year)

*Dropped unnecessary variables from the data
drop countrycode seriesname seriescode

*Restricting the observations to the defined period from 1970-2010
keep if year>=1970  //(0 observations deleted)
keep if year<=2010  //(265 observations deleted)

*Generated country_id variable to uniquely identify the countries
egen country_id = group(country)

*Setting the panel data
xtset country_id year  //Panel variable: country_id ; Time variable: year, 1971 to 2010

*Renaming the primary enrolment variable from yr to WDT_e
ren yr WDI_e

replace WDI_e = "." if WDI_e ==".."
destring WDI_e, replace

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = countryname + string(year)

*Saved the final dataset as .dat (Stata data format)
save "WDI_primary enrollment", replace
clear
*/

*------------------------------------------------------------------------------*


/*
This dataset contains the independent variable 'Economic Policy Uncertainity'. The dataset contains indices-monthly data.

Source: https://www.policyuncertainty.com/
*/

*Importing the raw data downloaded in .xlsx format, the first row being the variable names
import excel using "policy uncertainity data.xlsx", sheet("EPU") firstrow  //(36 vars, 477 obs)

*Dropping rows that contain a textual description
drop if _n>446  //(31 observations deleted)

*Year converted from numeric to int
destring Year, replace

*Restricting the observations to the defined period from 1970-2010
keep if Year>=1970  //(0 observations deleted)
keep if Year<=2010  //(134 observations deleted)

*Generated a single variable containing a month-year id for reshaping to long format
egen idlong= concat(Month Year)

*Dropping unnecessary variables from the dataset
drop GEPU_current GEPU_ppp

*Added a prefix 'pop' to the year variables to help in reshaping the data
foreach x of var * { 
rename `x' pop`x' 
}

*Renamed the non-year variables; removed the prefix 'pop' so that these aren't captured in the reshape
rename (popYear popMonth popidlong) (Year Month idlong)

*Reshaping from wide to long format
reshape long pop, i(idlong) j(countryname) string

*dropped the unnecessary variable
drop idlong

*Generated country_id variable to uniquely identify the countries
egen country_id = group(country)

*Dropping extra variables imported due to the original data being in .xls format
drop if countryname=="AE" | countryname== "AF" | countryname== "AG" | countryname== "AH" | countryname== "AI" |countryname== "AJ" |countryname== "AD" |countryname== "AC"  //(2,496 observations deleted)

*Sorting country year-wise
sort country_id Year

*Converted a monthly data series to yearly data by taking the yearly mean
by country_id Year: egen mean_pop = mean(pop)  //(2,412 missing values generated)

*Removing duplicates from the dataset by creating a variable 'dup' indicating the number of duplicates, and then filtering the data by observations that are repeated
by country_id Year: gen dup = cond(_N==1, 0, _n)
drop if dup > 1  //(6,864 observations deleted)
drop dup

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = countryname + string(Year)

*Renamed the variables containing the country names and the year
ren countryname country
ren Year year

*Setting the panel data
xtset country_id year

*Saved the final dataset as .dat (Stata data format)
save "policy uncertainity", replace
clear


*------------------------------------------------------------------------------*


/* Data of the Index of Economic Freedom published by the Heritage Foundation. The Index covers 12 freedoms – from property rights to financial freedom – in 184 countries.

Contains data for the control variable 'economic freedom'.
*/

*Opened CSV file
insheet using "economic freedom data.csv", comma  //(15 vars, 5,152 obs)

*Dropping unnecessary variables from the dataset
drop propertyrights governmentintegrity judicialeffectiveness taxburden governmentspending fiscalhealth businessfreedom laborfreedom monetaryfreedom tradefreedom investmentfreedom financialfreedom

*Generated country_id variable to uniquely identify the countries
egen country_id = group(name)

*Restricting the observations to the defined period from 1970-2010
keep if indexyear<=2010  //(2,224 observations deleted)
keep if indexyear >=1970  //(0 observations deleted)

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = name + string(indexyear)  //Panel variable: country_id ; Time variable: indexyear, 1995 to 2010

*Setting the panel data
xtset country_id indexyear

*Addressing non-numeric missing values
foreach v of varlist overallscore {
     replace `v' = "" if `v' == "N/A"
     }
destring overallscore, replace

*Renamed the Year variable
ren indexyear year

*Saved the final dataset as .dat (Stata data format)
save "economic freedom", replace
clear


*------------------------------------------------------------------------------*


/*Historical Index of Ethnic Fractionalization Dataset (HIEF) containing an ethnic fractionalization index for 165 countries across all continents by the Harvard Dataverse

Contains the data for the control variable 'ethnic homogeneity' ranging from 0 to 1, with higher values indicating ethnic homogeneity, implying greater social cohesion.
*/

*Opened CSV file having the ethnic homogenity data
insheet using "ethnic homogenity.csv", comma

*Sorted the data country-wise
sort country

*Generated country_id variable to uniquely identify the countries
egen country_id = group( country )

*Restricting the observations to the defined period from 1970-2010
keep if year>=1970
keep if year<=2010

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = country + string(year)

*Sorting country year-wise
sort country year

*Generating the country-year wise duplicates
quietly by country year:  gen dup = cond(_N==1,0,_n)

*Dropping the duplicates
drop if dup>1
drop dup

*Setting the panel data
xtset country_id year

*Generating a variable nyear which captures the number of observations by country-id
by country_id : gen nyear=[_N]

*Winsorizing the data at 1% and 99%
winsor2 nyear, cuts(1 99) replace
drop nyear

*Saved the final dataset as .dat (Stata data format)
save "ethnic homogenity", replace
clear


*------------------------------------------------------------------------------*


/*
Cleaning data for the control variable "Polity Scale" which is a proxy for democracy, indicates the democracy index on a scale of strongly autocratic (-10) to strongly democratic (10).
*/
*Importing the raw data downloaded in .xls format, the first row being the variable names
import excel "p5v2018.xls", sheet("p5v2018") firstrow

*Restricting the observations to the defined period from 1970-2010
keep if year>=1970
keep if year<=2010

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = country + string(year)

*Kept only the relevant variables
keep country year polity

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = country + string(year)


*Sorting country-year wise
sort country year

*Generating the country-year wise duplicates
quietly by country year:  gen dup = cond(_N==1,0,_n)

*Dropping the duplicates
drop if dup>1
drop dup

*Saved the final dataset as .dat (Stata data format)
save "polity scale", replace
clear


*------------------------------------------------------------------------------*


/* Cleaning a dataset for the control variable 'Inflation' as GDP deflator (annual %)
Source: World Development Indicators database by the World Bank
*/

*Importing the raw data downloaded in .csv format, the first row being the variable names
import delimited "G:\My Drive\Coursework at IIMU\Econometric Methods I\Assignment\d45ae254-0d79-4eab-a34f-7c6c1fcd53ad_Data.csv", varnames(1)

*Dropped the rows that contain a textual description of the data in the last rows
drop if _n>266

*Reshaping from wide to long format
reshape long yr, i(countryname) j(Year) string

*Renaming the main variable of interest
rename yr Inflation

*Dropping the variables unnecessary for the main analysis
drop countrycode seriesname seriescode

*Generated country_id variable to uniquely identify the countries
egen country_id = group(countryname)

*Year converted from numeric to int
destring Year, replace

*Restricting the observations to the defined period from 1970-2010
keep if Year>=1970  
keep if Year<=2010

*Setting the panel data
xtset country_id Year

*Missing value formatting
replace Inflation = "." if Inflation ==".."
destring Inflation, replace

*Generating a variable nyear which captures the number of observations by country-id
by country_id : gen nyear=[_N]

*Winsorizing the data at 1% and 99%
winsor2 nyear, cuts(1 99) replace

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = countryname + string(Year)
drop nyear

*Saved the final dataset as .dat (Stata data format)
save "inflation", replace
clear


*-------------------------------------------------------------------------------*


/*Contains the variables: Poplation, GDP Per Capita, Govt Consumption as a share of GDP, Investment as a percentage of GDP

Source: Penn World Table
*/


insheet using "pwt variables.csv", comma

*Restricting the observations to the defined period from 1970-2010
keep if year>=1970
keep if year<=2010

*Generated country_id variable to uniquely identify the countries
egen country_id = group(country)

*Setting the panel data
xtset country_id year

*Renamed the population variable
rename pop population

*Renamed the investment as a share of GDP variable
rename ci investment_percent_GDP

*Renamed the Govt consumption as a share of GDP variable
rename cg govt_share_gdp

*Renamed the GDP per capita variable
rename cgdp gdp_pc

*Generated the log of GDP per capita
gen log_gdp = ln(gdp_pc)

*Generated the difference of log of GDP per capita
gen gdp_growth = D.log_gdp

*Dropped missing values, as this is the dependent variable
drop if gdp_pc==.

*Generated the log of population
gen ln_pop=ln(population)

*Generated the growth of population
gen g_pop = D.ln_pop

*Checking if the data is balanced
xtset

*Defining the country-year wise variable so that it uniquely identifies each country-year observation
gen country_year = country + string(year)


*-------------------------------------------------------------------------------*


/*Merging datasets using key variable country_year to create the final dataset for analysis

Main dataset: "pwt variables.csv"
*/

/*Merging the dataset containing the control variable 'primary school enrolment'
merge 1:1 country_year using "WDI_primary enrollment"
keep if _merge==3

*dropping the _merge variable that stata automatically generates
drop _merge
*/
*merge the polity scale dataset that contains information about the democracy index of a country in a year
merge 1:1 country_year using "polity scale"

*dropping the _merge variable that stata automatically generates
drop _merge
merge 1:1 country_year using "economic freedom"

*dropping the _merge variable that stata automatically generates
drop _merge

*Merge the dataset containing the control variable indicating ethnic homogenity of a country in a year
merge 1:1 country_year using "ethnic homogenity"

*dropping the _merge variable that stata automatically generates
drop _merge

*Merging the trade openness dataset
merge 1:1 country_year using "trade openness"

*dropping the _merge variable that stata automatically generates
drop _merge

*Merging the policy uncertainity (independent variable) dataset
merge 1:1 country_year using "policy uncertainity"

*dropping the _merge variable that stata automatically generates
drop _merge

*Merging the inflation indicator variable
merge 1:1 country_year using "inflation"

*Dropping extra variables that are not necessary in the final dataset
drop isocode population ln_pop countryname country_id name Month _merge


*-------------------------------------------------------------------------------*


/* Re-labeling the variables to have a clarity on the varnames*/

*The variable g_pop indicates the growth of population of a country in an year
label variable g_pop "population growth"

*The variable Inflation indicates the 
label variable Inflation "Inflation, GDP deflator"

* log_GDP defines the log of the gdp_pc variable
label variable log_gdp "Log of GDP per capita"

*gdp_growth defines the growth of GDP in percentage
label variable gdp_growth "growth of GDP in percentage"

*The variable country_year is generated as a unique ID to merge the datasets
label variable country_year "unique ID for all observations"

*the variable inflation_percent_GDP contains the data on inflation as GDP deflator (annual %)
label variable investment_percent_GDP "Investment share of converted GDP per capita at current prices"

/*WDI_e contains the primary school enrolment data
label variable WDI_e "Adjusted net enrolment rate, primary (% of primary school age children)"
*/
* govt_share_gdp contains government consumption share of PPP converted GDP per capita at current prices
label variable govt_share_gdp "government consumption share of PPP converted GDP per capita at current prices"

*pop contains the independent variable EPU
label variable pop "Policy Uncertainty index (EPU)"

*mean_pop is the yearly mean of EPU
label variable mean_pop "Yearly mean of EPU"

*gdp_pc is the GDP per capita country-year wise
label variable gdp_pc "GDP per capita"

*polity contains the political scale, used as a proxy for democracy
label variable polity "democracy index"

*overallscore contains the economic freedom index data
label variable overallscore "Index of economic freedom"

*efindex is the Ethnic Homogeneity index data
label variable efindex "Ethnic homogenity index"

*trade openness variable re-labelled
label variable trade_openness "sum of a country's exports and imports as a share of that country's GDP (in %)"
//asdoc sum


*------------------------------------------------------------------------------*


/* Running baseline regressions
*/

*Generated country_id variable to uniquely identify the countries
egen country_id = group(country)

*Sorting country-year wise
sort country_id year

*Generating the country-year wise duplicates
by country_id year: gen dup = cond(_N==1,0,_n)

*Dropping duplicates
drop if dup > 1
drop dup

*Setting the panel data
xtset country_id year

*Generate 1-year lag of log of GDP per capita
gen lag1_log_gdp = l.log_gdp

*Generate the GDP growth using a different method
gen gdp_growth2 = log_gdp - lag1_log_gdp

*Winsorize the main and the control variables at 1% and 99%
winsor2 lag1_log_gdp gdp_growth2 Inflation mean_pop trade_openness efindex overallscore polity g_pop investment_percent_GDP govt_share_gdp , cuts(1 99) replace

*Saving the final compiled dataset
save "epu_gdp dataset", replace


*------------------------------------------------------------------------------*


*Regression: Dependent variable: Growth of GDP per Capita and Independent Variables: Log of Initial GDP Per Capita and Economic Policy Uncertainity

reghdfe gdp_growth2 lag1_log_gdp mean_pop , a(country_id) cluster(country_id)

*Saving the output as model1
eststo model1
*Regression 2: Controls: investment, inflation, primary school enrolment, population growth and trade openness
reghdfe gdp_growth2 lag1_log_gdp mean_pop investment_percent_GDP Inflation g_pop trade_openness , a(country_id) cluster(country_id)

*Saving the output as model2
eststo model2

*Regression 3: Additional controls: economic freedom index, ethnic homogeneity index and polity scale as a proxy for democracy indicator
reghdfe gdp_growth2 lag1_log_gdp mean_pop investment_percent_GDP Inflation g_pop trade_openness overallscore efindex polity , a(country_id) cluster(country_id)

*Saving the output as model3
eststo model3

*Tabulating the three outputs
esttab using "test08.csv", r2 ar2 se scalar(rmse)



*/
