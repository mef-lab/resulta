/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Tranajar la base de Producción de cultivos
	  - Uso de la cosecha: consumo, ventas.
	  - Precio medio por cultivo.
	  - Valores de cosecha.
	  - Valores de entrada.
  
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

*****************************
* 1. Prepare data
*****************************

cd "$DATA/HOGAR"
use "r_crops.dta", clear
//* ONLY FOR THE 3 MAIN CROPS

* Merge with harvest area
sort interview__key r_crops__id
merge interview__key r_crops__id using "$TEMP/harvest_ha.dta"

* _merge==2: crops that were not chosen as main
drop if _merge==2
drop _merge

*Merge with input cost
sort interview__key r_crops__id
merge interview__key r_crops__id using "$TEMP/inputs_cost.dta"
*tab _m // there is one observation without input cost
drop _m

*Merge with location data (departamento, provincia, distrito)
sort interview__key
merge interview__key using "$TEMP/rtahogar_geocode.dta"
drop if _merge==2
drop _merge


*****************************
* 2. Definition of variables
*****************************
/* 
REFIERE A ÁREA SEMBRADA EN TODAS LAS COSECHAS DURANTE LOS ÚLTIMOS 12 MESES
*/

///////////////////
*Converting to KG
///////////////////

*Factor conversion 
*..................
//* variable factor is pre-established conversion factor to KG for libra, arroba, quintal, tonelada.
//* For UNIDAD = BOLSA, CARGA, UNIDADES, CUBETA, SACO. The HH provides the conversion rate to KG. However, there are 28 crops that the conversion to KG is 0.
g factor_kg=factor if (b22==1 | b22==4 | b22==6 | b22==7)
replace factor_kg=b22_1 if (b22==2 | b22==3 | b22==5 | b22==8 | b22==9 | b22==10)
replace factor_kg=. if b22_1==0
//*the 213 crops with OTRO harvest unit do not have conversion rate to KG because it was not asked during the interviews
//*Create a variable that identifies HH without conversion rate to KG
g no_KG=1 if (factor==0 & b22_1==0) // 28 obsv
replace no_KG=1 if b22==99 // 213 obsv
//*In addition, there are HH that "CULTIVO PERO NO COSECHO" (b21==0), from which there is no information of harvest production.
replace no_KG=1 if b21==0


*Harvest production (harvest_kg)
*.................................
//*excluding crops without convertion to KG
g harvest_kg=equivalente_kg
replace harvest_kg=. if no_KG==1


*Production quantity by crop (harv_i)
*.....................................
foreach i in CACAO CAFE PALTA QUINUA  {
    g harv_`i'=harvest_kg if nombre_cultivo=="`i'"
}

*Yield (KG/ha)
*..............
g yields=harvest_kg/harvest_ha if (harvest_kg!=. & harvest_ha!=0) // min(harvest_kg=1) -> there is no harvest_kg==0. But there are harvest_ha==0

*Checking for outliers
*.......................
*tabstat yields, by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)
*sort yields
*br harvest_kg  harvest_ha  yields outlier_harvest_ha b22 nombre_cultivo if  (harvest_kg!=. & harvest_ha!=0)
//*The outliers with high values mostly corresponds to crops with tiny harvest_ha
//*There is a jump from 750 mil to 2 mill in the yield, therefore, yield_crop>=1000000 are labeled as outliers
g outlier_yield=1 if yields>=1000000 & yields!=.

*tabstat yields if outlier_yield!=1 , by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)


* Yield by crop (KG/ha) 
*........................
//*yields_[i]:	Yield  (kg/ha) of crop  [i]
//* where [i] is the name of the crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g yields_`i'=yields if nombre_cultivo=="`i'"
}


*Checking for outliers of cadena's crops
*........................................
//*CADENAS: Cacao, Cafe, Palta, Quinua
//*See the lowest and highest values per crop 
foreach i in CACAO CAFE PALTA QUINUA  {
	sum yields_`i' if (harvest_kg!=. & harvest_ha!=0)
	tab yields_`i' if (harvest_kg!=. & harvest_ha!=0)
	}	 


	
*Use of Improve seeds
*.....................
//*new_seeds_[i]: 1==yes, where [i] is the seed variety
g new_seeds_LOCAL=(b19==1) // Local/Reciclada (b19==1)
g new_seeds_MEJORADA=(b19==2) // Hibrida / Mejorada (b19==2)
g new_seeds_MEZCLA=(b19==3) // Mezcla (b19==3)


///////////////////
*HARVEST USE
///////////////////


*Amount by use
*..............
//*b27, b29, b32: are harvest quantity in the original unit of measure (kilos, arroba, etc).
g b27_kg=b27*factor_kg
g b29_kg=b29*factor_kg
g b32_kg=b32*factor_kg

//*Calculate the amounts
g harv_lost=b27_kg if b26==1 //perdio parte de la cosecha
g harv_cons=b29_kg if b28==1 //autoconsumo y/o alimento de animales
g harv_sold=b32_kg if b31==1 //vendio (no procesado)


*Crop-specific consumption (kg)
*...............................
foreach i in CACAO CAFE PALTA QUINUA  {
    g harv_cons_`i'=harv_cons if nombre_cultivo=="`i'"
}


///////////////////
*HARVEST VALUE
///////////////////


*Sales income
*.............
*Overall income
g saleval=b33 // Monto S/ recibio por la venta de lo cosechado	
replace saleval=. if b33==999 //NO SE PUEDE ESTIMAR
replace saleval=. if b33==0 //2 crops has b33=0

*Create crop-specific incomes
foreach i in CACAO CAFE PALTA QUINUA  {
    g `i'_inc=saleval if nombre_cultivo=="`i'"
}


*Sales Price
*.............
*Overall Prices 
g saleprice=saleval/harv_sold // valor ventas/cantidad cosechado para la venta
//*Extreme values => missing
*replace saleprice=. if saleprice>=60 & saleprice!=. // 3 observ.
*replace saleprice=. if saleprice<0.05 // 17 obs


*Buyer type and location:
g sold_indiv = b33_1__1==1 //Principal comprador: PARTICULARES
g sold_market = b33_2!=1 & b33_2!=2 & b33_2!=. //Lugar donde vendio mayor parte: mercados, etc (excepto desde casa o borde del camino)
g sold_gateroad = b33_2==1 | b33_2==2 //Desde casa o borde del camino

*Crop-specific sold in the market:
foreach i in CACAO CAFE PALTA QUINUA  {
    g sold_market_`i'=sold_market if nombre_cultivo=="`i'"
}

foreach i in CACAO CAFE PALTA QUINUA  {
    g sold_gateroad_`i'=sold_gateroad if nombre_cultivo=="`i'"
}

*Sale Price by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g saleprice_`i'=saleprice if nombre_cultivo=="`i'"
}

*Market: Sale Price by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g salepricemkt_`i'=saleprice if nombre_cultivo=="`i'" & sold_market==1
}

*Gate road:  Sale Price by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g salepricegte_`i'=saleprice if nombre_cultivo=="`i'" & sold_gateroad==1
}

*Buyer type:Sale Price by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g salepriceind_`i' = saleprice if nombre_cultivo=="`i'" & b33_1__1==1 //PARTICULARES
	g salepricesst_`i' = saleprice if nombre_cultivo=="`i'" & b33_1__4==1 //COMERCIANTE MINORISTA
	g salepricelst_`i' = saleprice if nombre_cultivo=="`i'" & b33_1__5==1 //COMERCIANTE MAYORISTA
	g salepricecop_`i' = saleprice if nombre_cultivo=="`i'" & b33_1__2==1 //COOPERATIVA
}


*Own consumption value (S/.)
*......................
*Overall own-consumption value
g consval=b30 //VALOR DE CONSUMO PROPIO
replace consval=. if b30==999 //NO SE PUEDE ESTIMAR
replace consval=. if b30==0 //2 crops has b33=0



*VALUING HARVEST USING MEDIAN PRICE: OVERALL
*............................................
*Median price per crop
bysort nombre_cultivo: egen med_harvprice_kg = median(saleprice)
*tabstat med_harvprice_kg , by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)

*Harvest value (S/.por Kg) using median price
g harv_mval = harvest_kg * med_harvprice_kg

*Harvest value by use
g harv_lost_mval = harv_lost * med_harvprice_kg
g harv_cons_mval = harv_cons * med_harvprice_kg
g harv_sold_mval = harv_sold * med_harvprice_kg

*Harvest values by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g harv_mval_`i' = harv_mval if nombre_cultivo=="`i'"
}


*VALUING HARVEST USING MEDIAN PRICE: DISTRICT/PROV/DEP LEVEL
*............................................................
//*1. Calculate median price at the district, province, and departamental level:
*District level: Median price per crop
bysort nombre_cultivo cod_dis: egen dist_harvprice_kg = median(saleprice)

*Province level
bysort nombre_cultivo cod_prov: egen prov_harvprice_kg = median(saleprice)

*Departamental level
bysort nombre_cultivo cod_dep: egen dep_harvprice_kg = median(saleprice)

*Region level
gen region=(departamento=="AMAZONAS" | departamento=="CAJAMARCA")
bysort nombre_cultivo region: egen reg_harvprice_kg = median(saleprice)


//*2. Median price
*If there is no information at the district level, go to the next level: province level and departamento
gen med2_harvprice_kg = dist_harvprice_kg
replace med2_harvprice_kg = prov_harvprice_kg  if dist_harvprice_kg==.
replace med2_harvprice_kg = dep_harvprice_kg  if prov_harvprice_kg==.
replace med2_harvprice_kg = reg_harvprice_kg  if dep_harvprice_kg==.
replace med2_harvprice_kg = med_harvprice_kg  if reg_harvprice_kg==.

tabstat med2_harvprice_kg, by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)


*Harvest value (S/.por Kg) using median price 2
g harv_mval2 = harvest_kg * med2_harvprice_kg

*Harvest value by use
g harv_lost_mval2 = harv_lost * med2_harvprice_kg
g harv_cons_mval2 = harv_cons * med2_harvprice_kg
g harv_sold_mval2 = harv_sold * med2_harvprice_kg

*Harvest values by crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g harv_mval2_`i' = harv_mval2 if nombre_cultivo=="`i'"
}




//////////
*INPUTS
//////////

*Cost of fertilizer / pesticide(includes: herbicide, insecticida, fungicidas) 
g fphcost = exp_input_FERT_O + exp_input_FERT_I + exp_input_PEST

*cost_labor
//*	Total expenditure on hired labor in production process
g cost_labor=exp_input_LABOR_MALE  + exp_input_LABOR_FEMALE

*Total input expenditure by crops
foreach i in CACAO CAFE PALTA QUINUA  {
    g tot_exp_inputs_`i' = b_costo if nombre_cultivo=="`i'"
}


*Number of up to three top crops
//*Using the crop code
bys interview__key: egen n_top_crops=count(r_crops__id)

	
************************************
* 3. Save at the household level
************************************ 

*Collapse at the interview__key 
collapse (sum) harvest_ha harvest_kg harv_* yields_*  consval saleval *_inc tot_crop_val=harv_mval tot_crop_val2=harv_mval2 exp_input_* tot_exp_inputs=b_costo cost_labor tot_exp_inputs_* (mean) saleprice* (max) new_seeds_* sold_market* sold_indiv sold_gateroad* n_top_crops, by(interview__key)

*Total value of crop production per ha.	
//* Total value of production divided by the harvested land in hectares
g tot_crop_val_ha=	tot_crop_val / harvest_ha
g tot_crop_val2_ha=	tot_crop_val2 / harvest_ha

*Gross Margin
//*Value of production minus value of inputs
g gross_margin=tot_crop_val - tot_exp_inputs
g gross_margin2=tot_crop_val2 - tot_exp_inputs

*Gross Margin by crops
//*where [i] is the name of the crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g gross_margin_`i' = harv_mval_`i' - tot_exp_inputs_`i' 
}

foreach i in CACAO CAFE PALTA QUINUA  {
    g gross_margin2_`i' = harv_mval2_`i' - tot_exp_inputs_`i' 
}

sort interview__key  
save "$TEMP/crop_production_hh.dta", replace 

