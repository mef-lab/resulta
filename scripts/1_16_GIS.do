/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con las variables GIS
  
AUTORES
  > Equipo FIDA 
	- Cristina Chiarella
	- Miguel Robles
	- Irina Valenzuela
  > Equipo MEF (Coordinación de evaluaciones independientes)
	- Rafael Visa Flores (rvisa@mef.gob.pe)
	- Richar Quispe Cuba (rquispe@mef.gob.pe)
	
SOFTWARE
  > STATA 17
  
DIRECTORIO
local user=c(username)
gl DRIVE "C:\Users\rquispe\Desktop\FIDA\Informe final\GITHUB"

FOLDER
gl DO		"$DRIVE\DO"
gl DATA		"$DRIVE\Bases"
*/

************************************
* 1. Import Files from CSV to STATA
************************************

cd "${DATA}\GIS_PERU"

foreach v in evi ndvi PrecipitationDekad TmaxDekad TmeanDekad TminDekad population{
	import delimited `v'.csv, clear
	save `v'.dta, replace
}


***********************
* 2. Define Variables
***********************
*.....................
* 2.1. Precipitation
*.....................
cd "${DATA}\GIS_PERU"
use "PrecipitationDekad.dta", clear

*Cleaning
*.........
drop v1553 v1554 v1555
rename ïinterview__key interview__key
rename *â *
rename *â*  **


*Total Rainfall (reference period: Agosto 2022 - Julio 2023)
*...........................................................
//* Total rainfall of the year/season of the survey reference period (Ago 2022 - July 2023)
//*Cumulative rainfall over the year/season relevant for the survey reference period in millimeter.

egen totrain = rowtotal(p_0801_22-p_0703_23)


*Long run average rainfall (August 2004 - July 2015)
*...................................................
//*Long Run Average of rainfall (average is taken for the 10 years before the project start date) 

*First, annual seasonal accumulative rainfall
//*sumar el total de precipitación recibida anualmente desde agosto de cada año a julio del siguiente año

* Rainy season: year variable reflects the year the season starts. 
* Season starts on Agosto year i to July year i+1

forvalues i = 4/8{
	local j = `i' + 1
	egen rainfall_200`i' = rowtotal(p_0801_0`i'-p_0703_0`j')
}

egen rainfall_2009 = rowtotal(p_0801_09-p_0703_10) 

forvalues i = 10/14{
	local j = `i' + 1
	egen rainfall_20`i' = rowtotal(p_0801_`i'-p_0703_`j')
}

*Average over seasonal rainfall years 2004 - 2014
egen lravg_totrain= rowmean(rainfall_2004-rainfall_2014)  
	

*CoV of Rainfall
*................

*First, we calculate the standard deviation
egen sd_rain = rowsd(rainfall_2004-rainfall_2014)
		
//*Coefficient of variation (CoV) of annual rainfall over the long run
//*CoV: ratio of the standard deviation to the mean.
gen cov_totrain=sd_rain/lravg_totrain

*Save
*....

keep interview__key cod_ccpp totrain lravg_totrain cov_totrain
sort interview__key

save "$TEMP/rainfall_variables.dta", replace

*...................
* 2.2. Temperature
*...................


*Mean temperature
*..................

cd "${DATA}\GIS_PERU"
use "TmeanDekad.dta", clear

*Cleaning
*.........
rename ïinterview__key interview__key
rename *â *
rename *â*  **


*Average temperature: mean
*...........................
//*Average of the daily/dekadal mean, maximum, minimum temperature during relevant year/season for survey in celsius, where [i] is mean, min, max
//* Setiembre 2022 - Agosto 2023

egen avgtemp_mean = rowmean(tmean_0901_22-tmean_0803_23)

*Long run averages of mean temperature over years 
egen lravg_avgtemp_mean= rowmean(tmean_0101_04-tmean_1203_14)

*Long run CoV before project start
egen sd_temp = rowsd(tmean_0101_04-tmean_1203_14) 
gen cov_avgtemp_mean=sd_temp/lravg_avgtemp_mean

*Save
*....
keep interview__key avgtemp_mean lravg_avgtemp_mean cov_avgtemp_mean
sort interview__key

save "$TEMP/temp_mean.dta", replace


*Min temperature
*..................

cd "${DATA}\GIS_PERU"
use "TminDekad.dta", clear

*Cleaning
*.........
rename ïinterview__key interview__key
rename *â *
rename *â*  **


*Average temperature: min
//*Average of the daily/dekadal mean, maximum, minimum temperature during relevant year/season for survey in celsius, where [i] is mean, min, max
//* Setiembre 2022 - Agosto 2023

egen avgtemp_min = rowmean(tmin_0901_22-tmin_0803_23)

*Long run averages of mean temperature over years 
egen lravg_avgtemp_min= rowmean(tmin_0101_04-tmin_1203_14)

*Long run CoV before project start
egen sd_temp = rowsd(tmin_0101_04-tmin_1203_14) 
gen cov_avgtemp_min=sd_temp/lravg_avgtemp_min

*Save
*....
keep interview__key avgtemp_min lravg_avgtemp_min cov_avgtemp_min
sort interview__key

save "$TEMP/temp_min.dta", replace


*Max temperature
*..................

cd "${DATA}\GIS_PERU"
use "TmaxDekad.dta", clear

*Cleaning
*.........
rename ïinterview__key interview__key


*Average temperature: max
//*Average of the daily/dekadal mean, maximum, minimum temperature during relevant year/season for survey in celsius, where [i] is mean, min, max
//* Setiembre 2022 - Agosto 2023

egen avtemp_09_12 = rowmean(tmax_0901-tmax_1203) if year==2022

egen avtemp_01_08 = rowmean(tmax_0101-tmax_0803) if year==2023

bys interview__key: egen avtemp_09_22 = mean(avtemp_09_12)
bys interview__key: egen avtemp_01_23 = mean(avtemp_01_08)

egen avgtemp_max= rowmean(avtemp_09_22 avtemp_01_23) 


*Long run averages of mean temperature over years 
egen s_avtemp = rowmean(tmax_0101-tmax_1203)
bys interview__key: egen lravg_avgtemp_max= mean(s_avtemp) if year>=2004 & year<=2014

*Long run CoV before project start
bys interview__key: egen sd_temp = sd(s_avtemp) if year>=2004 & year<=2014
gen cov_avgtemp_max=sd_temp/lravg_avgtemp_max

*Save
*....
* Collapse by interview__key
collapse avgtemp_max lravg_avgtemp_max cov_avgtemp_max , by(interview__key)

sort interview__key
save "$TEMP/temp_max.dta", replace


*............................
* 2.3. Vegetation index: EVI 
*............................

cd "${DATA}\GIS_PERU"
use "evi.dta", clear


*Cleaning
*.........
rename ïinterview_ interview__key

*Average period of reference
*............................
egen evi=rowmean(_9_14_2022-_8_29_2023) 


* Long run average Enhanced Vegetation Index
*.............................................
//* 2004-2014
egen lravg_evi = rowmean(_1_1_2004-_12_19_2014) 

* Long run CoV of between EVI
*.............................
//* before project start
egen sd_evi = sd(lravg_evi) 
gen cov_evi=sd_evi/lravg_evi


*Save
*....

keep interview__key evi lravg_evi cov_evi
sort interview__key

save "$TEMP/evi_variables.dta", replace


*............................
* 2.4. Vegetation index: NDVI 
*............................

cd "${DATA}\GIS_PERU"
use "ndvi.dta", clear


*Cleaning
*.........
rename ïinterview_ interview__key

*Average period of reference
*............................
egen ndvi=rowmean(_9_14_2022-_8_29_2023) 



* Long run average Enhanced Vegetation Index
*.............................................
//* 2004-2014
egen lravg_ndvi = rowmean(_1_1_2004-_12_19_2014) 

* Long run CoV of between EVI
*.............................
//* before project start
egen sd_ndvi = sd(lravg_ndvi) 
gen cov_ndvi=sd_ndvi/lravg_ndvi


*Save
*....

keep interview__key ndvi lravg_ndvi cov_ndvi
sort interview__key

save "$TEMP/ndvi_variables.dta", replace

*...................
* 2.5. Population 
*...................

*2.5.1 Population density 2020
*.................................

cd "${DATA}\GIS_PERU"
use "population.dta", clear


*Cleaning
*.........
rename interview_ interview__key

*Convert pop_density from string to numeric
replace pop_density="." if pop_density=="#N/A"
destring pop_density, replace

bys cod_ccpp: egen mean_d = mean(pop_density)
replace pop_density=mean_d if pop_density==. & mean_d!=.

//*There is one CCPP (101160007) without any pop_density value, 
//*I replace with the closest CCPP (101140019) mean: 149
replace pop_density=149 if pop_density==. 

rename pop_density pop_density_2020

*Save
*....
keep interview__key pop_density_2020
sort interview__key

save "$TEMP/population_2020.dta", replace



*2.5.2 Population density: 2000 - 2022
*.......................................
* Population  from 2000 to 2022
* WorldPop Global Project Population Data: Estimated Residential Population per 100x100m Grid Square
* Unit: person per sqkm
* Population density: Annual population densities (based on the number of people per 100m grid cells from WorlPop data

cd "${DATA}\GIS_PERU"
use PER_POP_SUM.dta, clear

* Choose v16==2014 as the populationn 
gen pop_dens_2014=v16
gen pop_dens_2020=v22

keep idccpp pop_dens_*
rename idccpp cod_ccpp
sort cod_ccpp

save "$TEMP/population_variables.dta", replace


*.......................
* 2.6. Distance to road 
*.......................

cd "${DATA}\GIS_PERU"
use PER_DIST_ROAD.dta, clear

rename distancetoroadm dis_main_road

rename idccpp cod_ccpp
sort cod_ccpp

save "$TEMP/distance_road_variables.dta", replace


*.......................
* 2.7. Travel time  
*.......................

cd "${DATA}\GIS_PERU"
use PER_TTIME.dta, clear

keep idccpp ttime_12 

rename ttime_12  t_main_town
rename idccpp cod_ccpp
sort cod_ccpp

save "$TEMP/traveltime_variables.dta", replace


*.................................
* 2.8. Distance to local markets  
*.................................


cd "${DATA}\GIS_PERU"
use Final_CP-Markets.dta, clear

drop departamento

keep idccpp n_15k

rename n_15k output_market_15k

destring idccpp, replace
rename idccpp cod_ccpp
sort cod_ccpp

save "$TEMP/local_markets.dta", replace


***********************
* 3. Merge databases
***********************

cd "$TEMP"
use rainfall_variables.dta, clear
sort interview__key
merge interview__key using temp_mean.dta
drop _merge
sort interview__key
merge interview__key using temp_min.dta
drop _merge
sort interview__key
merge interview__key using temp_max.dta
drop _merge
sort interview__key
merge interview__key using evi_variables.dta
drop _merge
sort interview__key
merge interview__key using ndvi_variables.dta
drop _merge
sort interview__key
merge interview__key using population_2020.dta
drop _merge
sort interview__key

*Now Merge with other GIS variables
order cod_ccpp, first
sort cod_ccpp
merge cod_ccpp using distance_road_variables.dta
drop if _m==2
drop _merge
sort cod_ccpp
merge cod_ccpp using traveltime_variables.dta
drop if _m==2
drop _merge
sort cod_ccpp
merge cod_ccpp using local_markets.dta
drop if _m==2
drop _merge
sort cod_ccpp
merge cod_ccpp using population_variables.dta
drop if _m==2
drop _merge

*cod_ccpp from numeric to string
tostring cod_ccpp, replace

sort interview__key

save "$TEMP/GIS_variables.dta", replace



**************************
* 4. GIS at the CCPP level
**************************

use "$TEMP/GIS_variables.dta", clear






