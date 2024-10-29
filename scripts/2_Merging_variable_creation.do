/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Uniendo las bases de datos y creación de variables
      - Unir bases de datos
	  - Definir y crear variables
  
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
gl TEMP		"$DRIVE\Temp"
*/


**************************
* 1. MERGING ALL MODULES 
**************************

cd "$TEMP"
use "rtahogar.dta", clear

sort interview__key
merge 1:1 interview__key using "hh_roster.dta"
drop _m
merge 1:1 interview__key using "employment.dta"
drop _m
merge 1:1 interview__key using "parcel_hh.dta"
drop _m
merge 1:1 interview__key using "harvest_ha_hh.dta"
drop _m
merge 1:1 interview__key using "crop_production_hh.dta"
drop _m
merge 1:1 interview__key using "livestock.dta"
drop _m
merge 1:1 interview__key using "housing.dta"
drop if _m==2
drop _m
merge 1:1 interview__key using "assets_1.dta"
drop _m
merge 1:1 interview__key using "assets_2.dta"
drop _m
merge 1:1 interview__key using "ddiv.dta"
drop if _m==2
drop _m
merge 1:1 interview__key using "fies.dta"
drop if _m==2
drop _m
merge 1:1 interview__key using "shocks.dta"
drop _m
merge 1:1 interview__key using "other_income.dta"
drop _m
merge 1:1 interview__key using "credit.dta"
drop if _m==2
drop _m
merge 1:1 interview__key using "GIS_variables.dta"
drop if _m==2
drop _m


************************
* IDENTIFY OUTLIERS
************************
*Income variables
g outlier_harv_cons_mval = harv_cons_mval>320000 & harv_cons_mval!=.
g outlier_prod_consval = prod_consval>70000 & prod_consval!=.

*Production
g outlier_harvest_ha = harvest_ha>100 & harvest_ha!=.
g outlier_harv_mval = (harv_mval_CAFE>1000000 & harv_mval_CAFE!=.)

g outlier_yield_CAFE = yields_CAFE>4000 & yields_CAFE!=.
g outlier_yield_PALTA = yields_PALTA>4000 & yields_PALTA!=.
g outlier_yield_QUINUA = yields_QUINUA>7000 & yields_QUINUA!=.

sum gross_margin , d
g top1 = r(p99)
g bot1 = r(p1)
g outlier_gross_margin = (gross_margin>top1 | gross_margin<bot1) & gross_margin!=.
drop top1 bot1

egen outliers_all = rowtotal(outlier_harv_cons_mval-outlier_gross_margin)
replace outliers_all=1 if outliers_all==2 | outliers_all==3


*********************************
* 2. DEFINING OUTCOME VARIABLES
*********************************

*...........
*2.1 INCOME
*...........

*Total wages earned
*...................
*Wage income
rename  tot_waged_income 	wage_inc
replace wage_inc=. if wage_inc==0

**Agricultural wages
rename	farm_waged_inc 		ag_wage
replace ag_wage=. if ag_wage==0

**Non-agricultural wages
rename 	nonfarm_waged_inc 	nonag_wage 
replace nonag_wage=. if nonag_wage==0


*Income from crop production
*............................

*Gross income from crop production of the 3 MAIN CROPS
//*gross_crop_inc = sales of crop produce + sales of by-products + own consumption
//*production excluding by losses and gifts
egen gross_3crop_inc = rowtotal (saleval harv_cons_mval) // sales income + own consumption valued at median prices

*Net income from crop production of the 3 MAIN CROPS
g net_3crop_inc = gross_3crop_inc - tot_exp_inputs // Gross income - total cost of inputs


*Total Gross Income from crop production: gross income 3 main crops
//*gross_3crop_inc 

*Total Net Income from crop production: 3 main crops + other crops
rename b37 net_ocrop_inc
egen net_crop_inc = rowtotal (net_3crop_inc net_ocrop_inc) // Ingresos netos de 3 cultivos principales + ingresos netos por la venta de sus otros cultivos

//*Nota: Solo 345 HH mencionaron un monto de ingreso neto (diferente a cero) de otros cultivos (ademas de los 3 principales)
//*La mayoria de HH tiene hasta 3 cultivos (1,587). 
//*Aunque en algunos casos, HH con 3 o menos cultivos, mencionaron un valor para el ingreso neto de otros cultivos. Es posible que se agregara diferentes tipos de papas o pastos

//*Only for All HHs with agricultural cultivations.
foreach v in gross_3crop net_3crop net_ocrop net_crop{
	replace `v'_inc=. if d_cultivate!=1 // No cultivo/cosecho en el periodo de referencia
	replace `v'_inc=0 if `v'_inc==. & d_cultivate==1 // Cultivo, pero no tuvo ingresos (puede haber perdido la cosecha,etc)
}


*Income from livestock & livestock products 
*...........................................
//*(live, slaugheter & products)

*Gross income from livestock & livestock products of the 3 MAIN LIVESTOCKS
//*gross_live_inc = sales of livestock +  sales of slaughtered livestock + sales of by-products + own consumption of slaughtered livestock + own consumption of by-products
egen gross_3live_inc = rowtotal(lstock_livesale_inc lstock_deadsale_inc prod_inc lstock_consval prod_consval)

*Net income from livestock & livestock products of the 3 MAIN LIVESTOCKS
//* Note: No se incluyo pregunta sobre el costo total de insumos en la produccion de bienes pecuarios

*Total gross income from livestock & livestock products 
//*gross_3live_inc  

*Total Net Income from livestock production: 3 main livestock + other livestock
rename d2_2 net_olive_inc 
egen net_live_inc = rowtotal( gross_3live_inc  net_olive_inc ) 

//*Nota: Solo 302 HH mencionaron un monto de ingreso neto (diferente a cero) de otros bienes pecuarios (ademas de los 3 principales)
//*La mayoria de HH tiene hasta 3 tipos de bienes pecuarios (1,516)

//*All HHs with livestock animals
//* d1==1 Tuvo o ha tenido bienes pecuarios
foreach v in gross_3live net_olive net_live{
	replace `v'_inc=. if d1==0 // No tiene o ha tenido bs pecuarios
	replace `v'_inc=0 if `v'_inc==. & d1==1 // Tiene bs pecuarios, pero no tuvo ingresos 
}


*Income self-employment 
*.......................
//*EMPRENDIMIENTO (incluido en la seccion OTROS INGRESOS de la encuesta)

*Gross income self-employment 
rename entrepre_inc gross_selfemploy_inc  
replace gross_selfemploy_inc=. if gross_selfemploy_inc==0

*Net income self-employment 
//*La pregunta de emprendimiento esta incluida en la seccion OTROS INGRESOS, donde solo se pregunta por el monto recibido, no por los costos de produccion


*Income from fisheries and fishing
*..................................
//*PRODUCCION DE PESCADO (incluido en la seccion OTROS INGRESOS de la encuesta)

*Gross income from fisheries and fishing
rename fish_inc gross_fish_inc 
replace gross_fish_inc=0 if gross_fish_inc ==.

*Net income from fisheries and fishing 
//*La pregunta de produccion de pescado esta incluida en la seccion OTROS INGRESOS, donde solo se pregunta por el monto recibido, no por los costos de produccion


*Income from transfers 
*......................
//*Nota: no se puede diferenciar entre transferencias privadas y publicas porque la pregunta no se activo
egen transfer_inc = rowtotal(cash_supp_inc food_supp_inc oth_supp_inc) // Asistencia en efectivo, ayuda alimentaria, otras transferencias


*Income from other sources
*..........................
egen other_inc = rowtotal(sav_inc pens_inc house_rent_inc house_sale_inc inherit_inc gambling_inc oth_rent_inc)


*Total Gross income
*...................
//*Ingreso Bruto Total:  
//* Ingreso por salario total + ingreso bruto de produccion agraria de (hasta) los 3 principales cultivos + ingreso bruto de (hasta) los 3 principales bienes pecuarios
//* + ingreso bruto de emprendimiento + ingreso bruto de produccion de pescado + ingresos totales por transferencias (públicas + privadas) + ingresos de otras fuentes
egen gross_income = rowtotal(wage_inc gross_3crop_inc gross_3live_inc gross_selfemploy_inc gross_fish_inc transfer_inc other_inc)

//*OUTLIERS: Drop HH with gross_income==0
drop if gross_income==0 // 9 observaciones


*Total Net income: 
*.................
//*Ingreso Neto Total:
//* Ingreso por salario total + ingreso neto de produccion agricola + ingreso bruto de produccion pecuaria de (hasta) los 3 principales bienes pecuarios mas ingreso neto de demas bienes pecuarios
//* + ingreso bruto de emprendimiento + ingreso bruto de produccion de pescado + ingresos totales por transferencias (públicas + privadas) + ingresos de otras fuentes
//*Es decir, solo el ingreso de produccion agraria y el ingreso de otros bienes pecuarios (que no son los 3 principales) son ingresos netos, los demas son ingreso bruto 
egen net_income = rowtotal(wage_inc net_crop_inc net_live_inc gross_selfemploy_inc gross_fish_inc transfer_inc other_inc)

//*OUTLIERS: Drop HH with extreme values 
drop if (net_income<=-20000 | net_income>=400000) & net_income!=. // 7 observaciones

*Dummy variable for income source
*.................................

foreach v in ag_wage nonag_wage gross_3crop_inc ///
 gross_3live_inc gross_selfemploy_inc gross_fish_inc transfer_inc other_inc {
	g d_inc_`v' = (`v'>0 & `v'!=.)
}
 
rename d_inc_gross_3crop_inc 		d_inc_crop
rename d_inc_gross_3live_inc 		d_inc_live
rename d_inc_gross_selfemploy_inc 	d_inc_selfemploy
rename d_inc_gross_fish_inc 		d_inc_fishing
rename d_inc_transfer_inc 			d_inc_transfer
rename d_inc_other_inc				d_inc_other


*CONVERT TO INCOME PER CAPITA
*............................
//*Income per capita S/.
foreach v in gross_3crop_inc gross_3live_inc ///
 gross_income net_income {
	g `v'_pc = `v' / hhsize
 }



*Gross Income diversification
*.............................
//* gsh_[i]: Share of income from source i out of gross income

foreach v in ag_wage nonag_wage gross_3crop_inc ///
 gross_3live_inc gross_selfemploy_inc gross_fish_inc transfer_inc other_inc {
	g gsh_`v' = (`v' / gross_income)*100
}

rename gsh_gross_3crop_inc 		gsh_crop
rename gsh_gross_3live_inc 		gsh_live
rename gsh_gross_selfemploy_inc gsh_selfemploy
rename gsh_gross_fish_inc 		gsh_fishing
rename gsh_transfer_inc 		gsh_transfer
rename gsh_other_inc			gsh_other

foreach v of varlist gsh_ag_wage-gsh_other {
replace `v' = 0 if `v'==.
}

*NUMBER OF INCOME SOURCES
*..........................
//*Number of income sources of the household [from 1 to 8]
egen n_incomesources = rowtotal(d_inc_ag_wage-d_inc_other)


*LABEL VARIABLES
*................
label variable d_inc_ag_wage "Hogar con ingreso de salarios agricolas"
label variable d_inc_nonag_wage "Hogar con ingreso de salarios no agricolas"
label variable d_inc_crop "Hogar con ingresos de la produccion de cultivos "
label variable d_inc_live "Hogar con ingreso del ganado y productos pecuarios "
label variable d_inc_selfemploy "Hogar con ingreso de empleo por cuenta propia"
label variable d_inc_fishing "Hogar con ingreso de la pesca"
label variable d_inc_transfer "Hogar con ingreso por transferencias"
label variable d_inc_other "Hogar con ingreso de otras fuentes"

label variable ag_wage "Ingresos de salarios agricolas (S/.)"
label variable nonag_wage "Ingresos de salarios no agricolas (S/.)"
label variable wage_inc "Ingresos de salarios totales ganados (S/.)"
label variable gross_3crop_inc "Ingresos brutos de la produccion de cultivos (S/.)"
label variable net_crop_inc "Ingresos netos de la produccion de cultivos (S/.)"
label variable gross_3live_inc "Ingresos brutos del ganado y productos pecuarios (S/.) "
label variable net_live_inc "Ingresos netos de ganado y productos pecuarios (S/.)"
label variable gross_selfemploy_inc "Ingresos brutos de empleo por cuenta propia (S/.)"
label variable gross_fish_inc "Ingresos brutos de la pesca (S/.)"
label variable transfer_inc "Ingresos por transferencias (S/.)"
label variable other_inc "Ingresos de otras fuentes (S/.)"
label variable gross_income "Ingresos brutos (S/.)"
label variable net_income "Ingresos netos (S/.)"

label variable gsh_ag_wage "Participacion de ingresos de salarios agricolas (%)"
label variable gsh_nonag_wage "Participacion de ingresos de salarios no agricolas (%)"
label variable gsh_crop "Participacion de ingresos brutos de la produccion de cultivos  (%)"
label variable gsh_live "Participacion de ingresos brutos del ganado y productos pecuarios  (%)"
label variable gsh_selfemploy "Participacion de ingresos brutos de empleo por cuenta propia (%)"
label variable gsh_fishing "Participacion de ingresos brutos de la pesca (%)"
label variable gsh_transfer "Participacion de ingresos por transferencias (%)"
label variable gsh_other "Participacion de ingresos de otras fuentes (%)"
label variable n_incomesources "Numero de fuentes de ingresos"

label variable gross_3crop_inc_pc  "Ingreso bruto agricola per capita (S/.)"
label variable gross_income_pc "Ingreso bruto total per capita (S/.)"


*...................
*2.2 ENDLINE ASSETS
*...................

*Cleaning
*........
foreach v of varlist nr_alpaca-nr_cuy   ///
nr_chair-nr_cpu ///
nr_hhoe-nr_fumig {
replace `v' = 0 if `v'==.
}

*Tropical Livestock Units
*.........................
*tlu (https://www.fao.org/3/i2294e/i2294e.pdf)
g tlu_nr_alpaca = nr_alpaca* 0.7
g tlu_nr_llama = nr_llama *0.7
*g tlu_nr_vicuna = nr_vicuna* 0.7
*g tlu_nr_ox = nr_ox * 1.1
*g tlu_nr_calf = nr_calf * 0.2
g tlu_nr_cow = nr_cow * 0.7
g tlu_nr_donk = nr_donk* 0.7
g tlu_nr_sheep = nr_sheep*0.1
g tlu_nr_goat = nr_goat*0.1
g tlu_nr_pig = nr_pig*0.2
g tlu_nr_ckn = nr_ckn*0.01
g tlu_nr_dck = nr_dck*0.01
g tlu_nr_dove = nr_dove *0.01
g tlu_nr_turk = nr_turk*0.01
g tlu_nr_rabt = nr_rabt *0.01
g tlu_nr_cuy = nr_cuy*0.01
*g tlu_nr_cock = nr_cock*0.01

egen tot_tlu = rowtotal(tlu_nr_alpaca-tlu_nr_cuy)


*Durable assets index 
*.....................
foreach v of varlist nr_chair-nr_cpu {
sum `v' if `v' !=0
} 
//*Dropping those with small variation (Std. Dev.=0):  nr_parafstove 

*Creating index
/*PSSA: 
factor nr_chair-nr_charstove nr_gasstove-nr_cpu if treat==0, comp(1) pcf
predict aindex_pca
*/

factor nr_chair-nr_charstove nr_gasstove-nr_cpu, comp(1) pcf 
predict aindex_pca

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 dindex_pca
drop aindex_pca


*Productive assets index 
*.........................
foreach v of varlist nr_hhoe-nr_fumig {
sum `v' if `v'!=0
}

//*Dropping those with small variation (Std. Dev.=0): nr_oxcrt nr_mechdryr nr_gran
*Creating index
factor nr_hhoe-nr_hndcrt nr_oxplough-nr_motpmp nr_soldryr-nr_storehs nr_pond-nr_fumig, comp(1) pcf // all non negative
predict aindex_pca 

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 pindex_pca
drop aindex_pca


*Housing assets index 
*.....................
mca wall_score-water_score
predict aindex_mca

*Standarized [0 1]
foreach v of varlist aindex_mca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_mca2 housingindex_mca
drop aindex_mca


*Livestock assets index 
*.......................
foreach v of varlist nr_alpaca-nr_cuy  {
sum `v' if `v'!=0
}

//*Dropping those with small variation (Std. Dev.=0 | .): nr_alpaca nr_dove
*Creating index
factor nr_llama-nr_dck nr_turk-nr_cuy , comp(1) pcf 
predict aindex_pca 

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 lindex_pca
drop aindex_pca


*Overall assets  index  
*......................
//*Polychloric factor analysis (Normalized 0 to 1)
//* of all asset categories (i.e. durable, productive, housing and livestock) 
*g oindex_poly


*Indicator for assets owned at endline
*......................................
//* d_[asset]	Dummy variable for ownership of [asset], where [asset] is the name of the good


*Number of  assets owned at endline: nr_asset
*.............................................
/*n_[asset]: Number of [asset] owned at endline
	where [asset] is the name of the good
	The variales are nr_[asset]: 
	Livestock assets: 	nr_alpaca-nr_cuy 
	Durable assets: 	nr_chair-nr_cpu 
	Productive assets:	nr_hhoe-nr_fumig 	
*/


*Indicators of Housing Quality at endline
*.........................................
/*
d_[housing]	
Dummy variable for exisistence of improved housing component, where [housing] is the characteristic (i.e. walls, roof, water, toilet, etc.), based on local material and distribution of the sample
*/


*Number of rooms in home at endline
*...................................
//*nr_rooms


*Land Owned 
*...........
//*Missing = 0:
//Durante los ultimos 12 meses, ningun miembro del hogar usó, alquiló o fue propietario de algún terreno o predio
replace ownedtitle_hec=0 if ownedtitle_hec==. 
rename ownedtitle_hec own_land


*LABEL VARIABLES
label variable tot_tlu "Indice de Unidades Ganaderas Tropicales (TLU)"
label variable dindex_pca "Indice de activos duraderos"
label variable pindex_pca "Indice de activos productivos"
label variable housingindex_mca "Indice de activos inmobiliarios"
label variable lindex_pca "Indice de activos ganaderos"
label variable nr_rooms "Numero de habitaciones de la casa"
label variable own_land "Tamano de la tierra propia del hogar (ha)"


*....................
*2.3 CROP PRODUCTION 
*....................
//*All HHs with agricultural cultivations 

*Tamaño de la tierra del hogar cultivada (ha)
g 		land_crop = harvest_ha

*Land Area farmed with crop [i]
//*harvest_ha_*, i=CACAO, CAFE, PALTA, QUINUA


*Proportion of cultivated land used for crop[i]
//*p_land_crop_*, i=CACAO, CAFE, PALTA, QUINUA

	
*Production quantity by crop
//*harv_[i], i=CACAO, CAFE, PALTA, QUINUA

	
*Value of production by crop: crop_val_[i]
foreach v in CACAO CAFE PALTA QUINUA {
	rename harv_mval_`v' crop_val_`v'
}

*Yields by crop
//*yields_[i], i=CACAO, CAFE, PALTA, QUINUA	


*Total value of crop production
//*tot_crop_val	


*Total value of crop production per ha.
//*tot_crop_val_ha	// Solo para HH con harvest_ha>0


*Gross Margin
//*Value of production minus value of inputs
//*gross_margin, gross_margin_[i]	


*Input expenditure/value by type
//*exp_input_[i]
	

*Cost/Value of labor
//*cost_labor	
	

*Total input Expenditure/Value
//*tot_exp_inputs	



*Otras Variables
*................

*Expenditure on inputs per ha
g tot_exp_input_ha = tot_exp_inputs/harvest_ha


*N crop production by trees
foreach v in CACAO CAFE PALTA  {
g harv_tree_`v' = harv_`v' / tree_crop_`v' 
}


*Sales value by quantity harvested for sale
//*saleprice_`i'


*CLEANING
*.........
//*Defining farm households as any household that cultivated land
//*And having harvest production greater than zero (harvest_kg>0)
g farm_ha= d_cultivate==1 & (harvest_kg>0 & harvest_kg!=.)

foreach v of varlist harvest_ha_* p_land_crop_* harv_* crop_val_* yields_* ///
tot_crop_val tot_crop_val_ha gross_margin gross_margin_* ///
 exp_input_* cost_labor tot_exp_inputs tot_exp_input_ha ///
 harv_tree_* saleprice_*{
	replace `v' = . if farm_ha==0
}

*For crop-specific variables, replace with missing if harvested quantity with crop [i] = 0
foreach v in CACAO CAFE PALTA QUINUA {
	replace harv_`v' = . if  harv_`v'==0 | harv_`v'==.
	replace crop_val_`v'= . if  harv_`v'==0 | harv_`v'==.
	replace yields_`v'= . if  harv_`v'==0 | harv_`v'==.
	replace gross_margin_`v'= . if  harv_`v'==0 | harv_`v'==.
	replace saleprice_`v'= . if  harv_`v'==0 | harv_`v'==.
}

*There are still some zeros in yields
foreach v in CACAO CAFE PALTA QUINUA {
    replace yields_`v'= . if  yields_`v'==0
}	

foreach v in CACAO CAFE PALTA  {
	replace harv_tree_`v'= . if  harv_`v'==0 | harv_`v'==.
}


*LABEL VARIABLES
*...............
label variable harvest_ha_CACAO "Area de tierra cultivada (ha): CACAO"
label variable harvest_ha_CAFE "Area de tierra cultivada (ha): CAFE"
label variable harvest_ha_PALTA "Area de tierra cultivada (ha): PALTA"
label variable harvest_ha_QUINUA "Area de tierra cultivada (ha): QUINUA"
label variable p_land_crop_CACAO "Proporcion de tierra cultivada utilizada para: CACAO"
label variable p_land_crop_CAFE "Proporcion de tierra cultivada utilizada para: CAFE"
label variable p_land_crop_PALTA "Proporcion de tierra cultivada utilizada para: PALTA"
label variable p_land_crop_QUINUA "Proporcion de tierra cultivada utilizada para: QUINUA"
label variable harv_CACAO "Cantidad de produccion (Kg): CACAO"
label variable harv_CAFE "Cantidad de produccion (Kg): CAFE"
label variable harv_PALTA "Cantidad de produccion (Kg): PALTA"
label variable harv_QUINUA "Cantidad de produccion (Kg): QUINUA"
label variable crop_val_CACAO "Valor de produccion (S/.): CACAO"
label variable crop_val_CAFE "Valor de produccion (S/.): CAFE"
label variable crop_val_PALTA "Valor de produccion (S/.): PALTA"
label variable crop_val_QUINUA "Valor de produccion (S/.): QUINUA"
label variable yields_CACAO "Rendimientos por cultivo (Kg/ha): CACAO"
label variable yields_CAFE "Rendimientos por cultivo (Kg/ha): CAFE"
label variable yields_PALTA "Rendimientos por cultivo (Kg/ha): PALTA"
label variable yields_QUINUA "Rendimientos por cultivo (Kg/ha): QUINUA"
label variable tot_crop_val "Valor total de la produccion agricola (S/.)"
label variable tot_crop_val_ha "Valor total de la produccion agricola por ha (S/.)"
label variable gross_margin "Margen bruto (S/.)"
label variable gross_margin_CACAO "Margen bruto (S/.) CACAO"
label variable gross_margin_CAFE "Margen bruto (S/.): CAFE"
label variable gross_margin_PALTA "Margen bruto (S/.): PALTA"
label variable gross_margin_QUINUA "Margen bruto (S/.): QUINUA"
label variable cost_labor "Costo de mano de obra (S/.)"
label variable tot_exp_inputs "Gasto total de insumos (S/.)"
label variable tot_exp_input_ha "Gasto total de insumos por ha (S/.)"
label variable saleprice_CACAO "Precio de venta (S/. por Kg): CACAO"
label variable saleprice_CAFE "Precio de venta (S/. por Kg): CAFE"
label variable saleprice_PALTA "Precio de venta (S/. por Kg): PALTA"
label variable saleprice_QUINUA "Precio de venta (S/. por Kg): QUINUA"
label variable harv_tree_CACAO "Rendimiento por cultivo (Kg/arbol): CACAO"
label variable harv_tree_CAFE "Rendimiento por cultivo (Kg/arbol): CAFE"
label variable harv_tree_PALTA "Rendimiento por cultivo (Kg/arbol): PALTA"

*..........................
*2.4 LIVESTOCK PRODUCTION
*..........................

//*All variables in livestock production are from HH that have livestock (d1==1)


*Value of livestock production
//*Total value of (quantity produced * Price) 
*val_liv		

//*val_liv_[i]
//*By type, where [i] is live livestock sales, slaughtered livestock (sales & own consumed) and livestock products (sales & own consumed)
g val_liv_live = lstock_livesale_inc
egen val_liv_dead = rowtotal(lstock_deadsale_inc  lstock_consval)
egen val_liv_prod = rowtotal(prod_inc  prod_consval)


*OTHER VARIABLES
*................
*Valor de produccion de cuyes (solo para los HH que tienen cuyes en los ultimos 12 meses)
replace cow_val_liv=. if nr_cow==0 & cow_val_liv==0
replace cuy_val_liv=. if nr_cuy==0 & cuy_val_liv==0

*Valor de produccion de leche y derivados lacteos (solo para los HH que han tenido vacunos en los ultimos 12 meses)
egen dairy_val_liv = rowtotal(cow_prod_inc cow_prod_consval)
replace dairy_val_liv =. if nr_cow==0 & dairy_val_liv==0



*LABEL VARIABLES
*................

label variable val_liv "Valor de la produccion ganadera (S/.)"
label variable val_liv_live "Valor de venta de ganado vivo (S/.)"
label variable val_liv_dead "Valor de ganado sacrificado (S/.)"
label variable val_liv_prod "Valor de productos pecuarios (S/.)"
label variable cow_val_liv "Valor de produccion de vacunos (S/.)" 
label variable cuy_val_liv "Valor de produccion de cuyes (S/.)" 
label variable dairy_val_liv "Valor de produccion de lacteos (S/.)" 

*...............................
*2.5 TOTAL VALUE OF PRODUCTION
*...............................
//* Total of value of cropping, livestock, fisheries and self-employment 
egen tot_val_prod = rowtotal(tot_crop_val  val_liv  gross_selfemploy_inc  gross_fish_inc)	

label variable tot_val_prod "Valor total de la produccion"


*................................
*2.6 MARKET ACCESS/PARTICIPATION
*................................

*Market participation for crop / by crop type
*.............................................
//*1 = produce & sell ; 0 = produce and don't sell  
g dmktac_crop = saleval>0 &  saleval!=.


//*Crop-specific
foreach v in CACAO CAFE PALTA QUINUA { 	
	g dmktac_crop_`v' = `v'_inc>0 &  `v'_inc!=.
}


*Value of agricultural sales for crop
*..................................... 
*Revenue from crop sales
rename saleval v_ag_sales 	// Monto S/ recibio por la venta de lo cosechado

*by crop type
foreach v in CACAO CAFE PALTA QUINUA { 	
	rename `v'_inc v_ag_sales_`v'	
}
 

*Share of agricultural sales in total ag prod value
*...................................................
//*Proportion of sale value (kg * price) over the total value of crop
g prop_ag_sales = v_ag_sales / tot_crop_val
replace prop_ag_sales = 0 if prop_ag_sales==. & tot_crop_val!=. & tot_crop_val!=0

*Crop-specific	
foreach v in CACAO CAFE PALTA QUINUA { 	
	g 	prop_ag_sales_`v' = v_ag_sales_`v' / crop_val_`v'
}


*Market participation for livestock / by livestock products
*...........................................................
//*1 = produce & sell live animals, meat, and by products ; 0 = produce and don't sell
g dmktac_liv = 	(lstock_livesale_inc>0 & lstock_livesale_inc!=.) | ///
				(lstock_deadsale_inc>0 & lstock_deadsale_inc!=.) | ///
				(prod_inc>0 & prod_inc!=.)

*by livestock type
foreach v in cow cuy{ 	
	g dmktac_liv_`v' = 	(`v'_livesale_inc>0 & `v'_livesale_inc!=.) | ///
						(`v'_deadsale_inc>0 & `v'_deadsale_inc!=.) | ///
						(`v'_prod_inc>0 & `v'_prod_inc!=.)
}


foreach v in dairy{ 	
	g dmktac_liv_`v' = 	(cow_prod_inc>0 & cow_prod_inc!=.)
}
				
				
*Value of livestock sales 	
*.........................
//*Sales value of live animals, meat, and by products (milk, honey, eggs)
//* (livestock revenue and livestock product revenue)

egen v_liv_sales = rowtotal( lstock_livesale_inc lstock_deadsale_inc prod_inc)

*Livestoc-specific
foreach v in cow cuy { 	
	egen v_liv_sales_`v' = rowtotal(`v'_livesale_inc `v'_deadsale_inc `v'_prod_inc)
}
		
g v_liv_sales_dairy = cow_prod_inc


*Share of livestock&products sales in total livestock prod value
*................................................................
//*Proportion of sale value (kg * price) over the total value of livestock

g prop_liv_sales = v_liv_sales / val_liv
	
*Specific
foreach v in cow cuy dairy { 	
	g 	prop_liv_sales_`v' = v_liv_sales_`v' / `v'_val_liv
}


*CLEANING
*.........

*Market access: Farm
//*Define for all HHs with agricultural cultivations.
foreach v in dmktac_crop v_ag_sales prop_ag_sales{
	replace `v'=. if farm_ha==0
}

*For crop-specific:
foreach v in CACAO CAFE PALTA QUINUA { 	
	replace dmktac_crop_`v'	=. if harv_`v'==0 | harv_`v'==.
	replace v_ag_sales_`v'=. if harv_`v'==0 | harv_`v'==.
	replace prop_ag_sales_`v'=. if harv_`v'==0 | harv_`v'==.
}


*Market access: Livestock
//*Define for all HHs with livestock.
foreach v in v_liv_sales prop_liv_sales{
	replace `v'=. if d1==0
}

*Livestock-specific
foreach v in cow cuy { 	
	replace v_liv_sales_`v'	=. if nr_`v'==0 
	replace prop_liv_sales_`v'=. if  nr_`v'==0 
}

foreach v in dairy { 	
	replace v_liv_sales_`v'	=. if nr_cow==0 
	replace prop_liv_sales_`v'=. if  nr_cow==0 
}

		
*LABEL VARIABLES
*................
label variable dmktac_crop "Participacion en el mercado por cultivo"
label variable dmktac_crop_CACAO "Participacion en el mercado por cultivo: CACAO"
label variable dmktac_crop_CAFE "Participacion en el mercado por cultivo: CAFE"
label variable dmktac_crop_PALTA "Participacion en el mercado por cultivo: PALTA"
label variable dmktac_crop_QUINUA "Participacion en el mercado por cultivo: QUINUA"
label variable v_ag_sales "Valor de las ventas agricolas (S/.)"
label variable v_ag_sales_CACAO "Valor de las ventas agricolas (S/.): CACAO"
label variable v_ag_sales_CAFE "Valor de las ventas agricolas (S/.): CAFE"
label variable v_ag_sales_PALTA "Valor de las ventas agricolas (S/.): PALTA"
label variable v_ag_sales_QUINUA "Valor de las ventas agricolas (S/.): QUINUA"
label variable prop_ag_sales "Participacion de las ventas agricolas en el valor total de la produccion agricola"
label variable prop_ag_sales_CACAO "Participacion de las ventas agricolas en el valor total de la produccion agricola: CACAO"
label variable prop_ag_sales_CAFE "Participacion de las ventas agricolas en el valor total de la produccion agricola: CAFE"
label variable prop_ag_sales_PALTA "Participacion de las ventas agricolas en el valor total de la produccion agricola: PALTA"
label variable prop_ag_sales_QUINUA "Participacion de las ventas agricolas en el valor total de la produccion agricola: QUINUA"

label variable dmktac_liv "Participacion en el mercado de ganado"
label variable dmktac_liv_cow "Participacion en el mercado de ganado: VACUNO"
label variable dmktac_liv_cuy "Participacion en el mercado de ganado: CUYES"
label variable dmktac_liv_dairy "Participacion en el mercado de productos pecuarios: LACTEOS"

label variable v_liv_sales "Valor de las ventas de ganado (S/.)"
label variable v_liv_sales_cow "Valor de las ventas de ganado (S/.): VACUNO"
label variable v_liv_sales_cuy "Valor de las ventas de ganado (S/.): CUYES"
label variable v_liv_sales_dairy "Valor de las ventas de productos (S/.): LACTEOS"
label variable prop_liv_sales "Participacion de las ventas de ganado y productos en el valor total de los productos pecuarios"
label variable prop_liv_sales_cow "Participacion de las ventas de ganado y productos en el valor total de los productos pecuarios: VACUNO"
label variable prop_liv_sales_cuy "Participacion de las ventas de ganado y productos en el valor total de los productos pecuarios: CUYES"
label variable prop_liv_sales_dairy "Participacion de las ventas de productos en el valor total de los productos pecuarios: LACTEOS"


*..........................
*2.7 RESILIENCE
*..........................

*Gini Simpson income diversification index (based on gross income shares)

foreach v in ag_wage nonag_wage crop live selfemp fishing transfer other {
gen gsh_`v'_sq=(gsh_`v'/100)^2
}

egen sum_gsh_sq=rowtotal(gsh_*_sq) 
gen income_div_gs=1-(sum_gsh_sq)

drop gsh_*_sq sum_gsh_sq  


*Rename variables
*.................
rename d_atrcc d_atr_clim
rename d_atrncc d_atr_noclim

*Cleaning
*.........
//*Variables de haber experimentado un shock en los últimos 5 años definido sobre Todos los hogares
//Not being in shock module=not experiencing any shock

foreach v in d_climaticshock d_nonclimaticshock d_anyshock {
    replace `v'=0 if `v'==.  //Not being in shock module=not experiencing any shock
}

*LABEL VARIABLES
*................

lab var income_div_gs "Diversificacion del Ingreso Bruto (Indice Gini Simpson)"

label var d_climaticshock "El hogar experimento un shock climatico"
label var d_nonclimaticshock "El hogar experimento un shock no climatico"
label var d_anyshock "El hogar experimento un shock"

lab var d_atr "Hogar recuperado del peor shock"
lab var d_atr_clim "Hogar recuperado del peor shock climatico"
lab var d_atr_noclim "Hogar recuperado del peor shock no climatico"

*..........................
*2.8 FOOD SECURITY
*..........................

*LABEL VARIABLES
*................
lab var HDDS_w "Puntuacion de diversidad dietetica del hogar (HDDS)"

lab var d_cer_w "*1= Comió cereales durante los últimos 7 días"
lab var d_tuber_w "*2= Comió tubérculos y raíces blancos durante los últimos 7 días"
lab var d_veg_w "*3= Comió verduras durante los últimos 7 días"
lab var d_fruit_w "*4= Comió frutas durante los últimos 7 días"
lab var d_meat_w "*5= Comió carne durante los últimos 7 días"
lab var d_egg_w "*6= Comió huevos durante los últimos 7 días"
lab var d_fish_w "*7= Comió pescado y otros mariscos durante los últimos 7 días"
lab var d_leg_w "*8= Comió legumbres, nueces y semillas durante los últimos 7 días"
lab var d_milk_w "*9= Consumió leche y productos lácteos durante los últimos 7 días"
lab var d_oil_w "*10= Consumió aceites y grasas durante los últimos 7 días"
lab var d_sweet_w "*11= Comió dulces durante los últimos 7 días"
lab var d_cond_w "*12= Comió especias, condimentos y bebidas  durante los últimos 7 días"


lab var fies_hh "Escala de experiencia de inseguridad alimentaria (FIES)"

lab var d_worried "Componente 1: preocupado por la comida"
lab var d_healthy "Componente 2: saludable "
lab var d_fewfood "Componente 3: poca comida"
lab var d_skipped "Componente 4: comidas omitidas"
lab var d_ateless "Componente 5: comió menos comida de la que quería"
lab var d_runout "Componente 6: quedarse sin comida"
lab var d_hungry "Componente 7: hambriento"
lab var d_whlday "Componente 8: no comió durante todo un día"

*..........................
*2.9 GENDER EMPOWERMENT
*..........................

*GENDER EMPOWERMENT VARIABLES
*..............................

/*
Al menos una mujer miembro del hogar esta involucrada en las decisiones de actividades economicas/sustento:
f_dmake_job	: Suele tomar las decisiones sobre el ingreso salariado
f_dmake_ag	: Suele tomar las decisiones sobre la produccion agricola (en al menos una parcela)
f_dmake_lstock: Suele tomar las decisiones sobre la venta de bienes pecuarios
f_dmake_prodliv: Suele tomar las decisiones sobre productos pecuarios que no es carne
f_dmake_othinc: Suele tomar las decisiones sobre el uso de otras ganancias/transferencias 

fem_worker	: En el empleo asalariado
*/

foreach v of varlist f_dmake_job f_dmake_ag f_dmake_lstock f_dmake_prodliv f_dmake_othinc  {
tab `v'
}

*Income Decision-maker
g fem_income_dmake = f_dmake_job==1 | f_dmake_ag==1 | f_dmake_lstock==1 | f_dmake_othinc==1 

*fem_worker:
replace fem_worker = 0 if fem_worker==.

*LABEL VARIABLES
*................

label variable fem_worker "Probabilidad de que las mujeres trabajen en un empleo asalariado"
label variable fem_income_dmake "Probabilidad de que las mujeres controlen al menos una fuente de ingresos del hogar (solas o junto con los hombres)"



*..........................
*2.10 FINANCIAL INCLUSION
*..........................

*LABEL VARIABLES
*................

*All HH
label variable bank_account "Hogar tiene cuenta bancaria (ahorro o credito)"
label variable have_savings "Hogar tiene ahorros"
label variable have_savings_formal "Hogar tiene ahorros en instituciones formales"

label variable loan_applied "Hogar solicito credito en los ultimos 12 meses"
label variable loan_applied_formal "Hogar solicito credito formal en los ultimos 12 meses"

label variable nr_loan_formal_applied "Numero de creditos solicitados a instituciones formales"

*For HH who applied to a formal loan
label variable loan_rejected "Hogar tuvo al menos un credito formal rechazado en los ultimos 12 meses"

label variable loan_approved "Hogar tuvo al menos un credito formal aprobado en los ultimos 12 meses"



*****************************************
* 3. DEFINING MATCHING/CONTROL VARIABLES
*****************************************

*.................
*3.1 DEMOGRAPHICS
*.................

label variable hhsize  		"Tamano del hogar"
label variable nr_adults 	"N de adultos"
label variable fem_head 	"Hogar encabezado por una mujer"
label variable mean_ed		"Educacion promedio del hogar"
label variable dep_ratio 	"Tasa de dependencia"
label variable agehead 		"Edad del jefe de hogar"
label variable read_head 	"El jefe de HH sabe leer"
label variable ed_hhh 		"Educacion del jefe de hogar"
label variable nr_disab 	"N de miembros del hogar con discapacidades"
label variable disab		"Miembro del hogar con discapacidad"


*....................
*3.2 BASELINE ASSETS
*....................

*Cleaning
*........
foreach v of varlist nr_alpaca_bl-nr_cuy_bl   ///
nr_chair_bl-nr_cpu_bl ///
nr_hhoe_bl-nr_fumig_bl {
replace `v' = 0 if `v'==.
}

*Tropical Livestock Units BL
*...........................
*tlu (https://www.fao.org/3/i2294e/i2294e.pdf)
g tlu_nr_alpaca_bl = nr_alpaca_bl* 0.7
g tlu_nr_llama_bl = nr_llama_bl *0.7
*g tlu_nr_vicuna = nr_vicuna* 0.7
*g tlu_nr_ox = nr_ox * 1.1
*g tlu_nr_calf = nr_calf * 0.2
g tlu_nr_cow_bl = nr_cow_bl * 0.7
g tlu_nr_donk_bl = nr_donk_bl* 0.7
g tlu_nr_sheep_bl = nr_sheep_bl*0.1
g tlu_nr_goat_bl = nr_goat_bl*0.1
g tlu_nr_pig_bl = nr_pig_bl*0.2
g tlu_nr_ckn_bl = nr_ckn_bl*0.01
g tlu_nr_dck_bl = nr_dck_bl*0.01
g tlu_nr_dove_bl = nr_dove_bl *0.01
g tlu_nr_turk_bl = nr_turk_bl*0.01
g tlu_nr_rabt_bl = nr_rabt_bl *0.01
g tlu_nr_cuy_bl = nr_cuy_bl*0.01

egen tot_tlu_bl = rowtotal(tlu_nr_alpaca_bl-tlu_nr_cuy_bl)


*Durable assets index BL 
*........................
foreach v of varlist nr_chair_bl-nr_cpu_bl {
sum `v' if `v' !=0
} 
//*Dropping those with small variation (Std. Dev.=0): nr_fan_bl nr_parafstove nr_cdplyr_bl

*Creating index
factor nr_chair_bl nr_sewmac_bl-nr_charstove_bl nr_gasstove_bl- nr_radio_bl nr_tv_bl-nr_cpu_bl, comp(1) pcf 
predict aindex_pca

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 dindex_pca_bl
drop aindex_pca


*Productive assets index BL
*............................
foreach v of varlist nr_hhoe_bl-nr_fumig_bl {
sum `v' if `v'!=0
}

//*Dropping those with small variation (Std. Dev.=0): nr_oxcrt nr_trcplou~l nr_motpmp_bl nr_mechdry~l
*Creating index
factor nr_hhoe_bl-nr_hndcrt_bl nr_oxplough_bl-nr_trac_bl nr_soldryr_bl-nr_fumig_bl, comp(1) pcf // all non negative
predict aindex_pca 

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 pindex_pca_bl
drop aindex_pca


*Housing assets index BL 
*........................
mca wall_score_bl-water_score_bl
predict aindex_mca

*Standarized [0 1]
foreach v of varlist aindex_mca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_mca2 housingindex_mca_bl
drop aindex_mca


*Livestock assets index BL 
*...........................
foreach v of varlist nr_alpaca_bl-nr_cuy_bl  {
sum `v' if `v'!=0
}

//*Dropping those with small variation (Std. Dev.=0 | .): nr_alpaca_bl nr_llama_bl nr_dove_bl
*Creating index
factor nr_cow_bl-nr_dck_bl nr_turk_bl-nr_cuy_bl , comp(1) pcf 
predict aindex_pca 

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 lindex_pca_bl
drop aindex_pca


*Overall assets  index  
*......................
//*Polychloric factor analysis (Normalized 0 to 1)
//* of all asset categories (i.e. durable, productive, housing and livestock) 
*g oindex_poly


*Number of  assets owned at BL: nr_asset_bl
*.............................................
/*nr_[asset]_nl: Number of [asset] owned at baseline
	where [asset] is the name of the good
	The variales are nr_[asset]_bl: 
	Livestock assets: 	nr_alpaca_bl-nr_cuy_bl 
	Durable assets: 	nr_chair_bl-nr_cpu_bl 
	Productive assets:	nr_hhoe_bl-nr_fumig_bl 	
*/


*Number of rooms in home at endline
*...................................
//*nr_rooms_bl



*LABEL VARIABLES
label variable tot_tlu_bl "Indice de Unidades Ganaderas Tropicales (TLU) en el escenario base"
label variable dindex_pca_bl "Indice de activos duraderos en el escenario base"
label variable pindex_pca_bl "Indice de activos productivos en el escenario base"
label variable housingindex_mca_bl "Indice de activos inmobiliarios en el escenario base"
label variable lindex_pca_bl "Indice de activos ganaderos en el escenario base"
label variable nr_rooms_bl "Numero de habitaciones de la casa en el escenario base"



*.............
*3.3 LAND USE
*.............

*Total Land cultivated 
//*harvest_ha	

*Number of crops cultivated
//*n_crops	

*Total Land Rented In: rented_hec	

*Rents land: d_rentin
//*Indicator whether HH rents some portion of land
	

*Owns land: 
//*Indicator whether HH  owns land (with title)
replace d_own=0 if 	d_own==.

*Cultivates land


//*Indicator whether HH cultivates at least some portion of land. 
replace d_cultivate=0 if d_cultivate==.


*..........................
*3.4 Ag technology adoption
*..........................

*Use of improved seeds 
//*i: LOCAL, MEJORADA, MEZCLA
//*new_seeds_[i]	

label variable new_seeds_LOCAL "Semilla Local"
label variable new_seeds_MEJORADA "Semilla Mejorada"
label variable new_seeds_MEZCLA "Semilla Mezcla"

*..........................
*3.5 Access to Markets
*..........................

label variable dis_main_road "Distancia a la carretera"
label variable t_main_town 	"Tiempo de viaje a la siguiente ciudad (min)"
label variable output_market_15k "Nro de mercados locales dentro de 15 km"


*..............
*3.6 COVID
*..............

g covid_affect = b38==1 | d20==1

label variable covid_affect "Afectado por COVID"

*..................
*3.8 GIS Variables
*..................

*LABEL
*......

label variable totrain "Precipitacion total"
label variable lravg_totrain "Precipitacion media a largo plazo"
label variable cov_totrain "CoV de la lluvia"
label variable avgtemp_mean "Variables de temperatura: media"
label variable lravg_avgtemp_mean "Promedios a largo plazo de las variaciones de temperatura: media"
label variable cov_avgtemp_mean "CoV de vars de temperatura: media"
label variable avgtemp_min "Variables de temperatura: min"
label variable lravg_avgtemp_min "Promedios a largo plazo de las variaciones de temperatura: min"
label variable cov_avgtemp_min "CoV de vars de temperatura: min"
label variable avgtemp_max "Variables de temperatura: max"
label variable lravg_avgtemp_max "Promedios a largo plazo de las variaciones de temperatura: max"
label variable cov_avgtemp_max "CoV de vars de temperatura: max"
label variable evi "Indice de vegetacion mejorado (EVI)"
label variable lravg_evi "Promedio a largo plazo del indice de vegetacion mejorada (EVI)"
label variable cov_evi "CoV del indice de vegetacion mejorado (EVI)"
label variable ndvi "Indice de diferencia de vegetacion normalizado (NDVI)"
label variable lravg_ndvi "Promedio a largo plazo del indice de vegetación de diferencia normalizada (NDVI)"
label variable cov_ndvi "CoV del indice de vegetacion de diferencia normalizada (NDVI)"

label variable pop_density_2020 "Densidad de poblacion: 2020"
label variable pop_dens_2014 "Densidad de poblacion: 2014"

label variable altitude "Altitud"


************************
* 4. OTHER VARIABLES
************************

*member_status as binary variable
replace member_status=0 if member_status==2


label variable member_status "Estado del socio: Activo"
label variable hh_sample "Hogar dentro de la muestra pre-elegida"	
label variable opa_ha_pp "Hectarea de OPA por socio"
label variable opa_desem_pp "Desembolso recibido de AGROIDEAS por socio"
label variable opa_inv_pp "Inversion total del plan de negocios por socio"
label variable prod_tot "Numero de socios de la OPA"


*********************
*5. SUMMARY TABLE
*********************


//*OUTCOMES
gl var_inc			d_inc_ag_wage d_inc_nonag_wage d_inc_crop d_inc_live d_inc_selfemploy d_inc_fishing d_inc_transfer d_inc_other /// 
ag_wage nonag_wage wage_inc gross_3crop_inc net_crop_inc gross_3live_inc net_live_inc ///
gross_selfemploy_inc gross_fish_inc transfer_inc other_inc gross_income net_income /// 
gsh_ag_wage gsh_nonag_wage gsh_crop gsh_live gsh_selfemploy gsh_fishing gsh_transfer gsh_other ///
n_incomesources gross_3crop_inc_pc  gross_income_pc 

gl var_asset_end 	tot_tlu dindex_pca pindex_pca housingindex_mca lindex_pca nr_rooms own_land

gl var_crop 		harvest_ha_CACAO harvest_ha_CAFE harvest_ha_PALTA harvest_ha_QUINUA p_land_crop_CACAO p_land_crop_CAFE p_land_crop_PALTA p_land_crop_QUINUA harv_CACAO harv_CAFE harv_PALTA harv_QUINUA crop_val_CACAO crop_val_CAFE crop_val_PALTA crop_val_QUINUA yields_CACAO yields_CAFE yields_PALTA yields_QUINUA tot_crop_val tot_crop_val_ha gross_margin gross_margin_CACAO gross_margin_CAFE gross_margin_PALTA gross_margin_QUINUA cost_labor tot_exp_inputs tot_exp_input_ha saleprice_CACAO saleprice_CAFE saleprice_PALTA saleprice_QUINUA harv_tree_CAFE  harv_tree_CACAO harv_tree_PALTA

gl var_live			val_liv val_liv_live val_liv_dead val_liv_prod cow_val_liv cuy_val_liv dairy_val_liv

*tot_val_prod

gl var_market		dmktac_crop dmktac_crop_CACAO dmktac_crop_CAFE dmktac_crop_PALTA dmktac_crop_QUINUA v_ag_sales v_ag_sales_CACAO v_ag_sales_CAFE v_ag_sales_PALTA v_ag_sales_QUINUA prop_ag_sales prop_ag_sales_CACAO prop_ag_sales_CAFE prop_ag_sales_PALTA prop_ag_sales_QUINUA dmktac_liv_cuy dmktac_liv_dairy v_liv_sales v_liv_sales_cow v_liv_sales_cuy v_liv_sales_dairy prop_liv_sales prop_liv_sales_cow prop_liv_sales_cuy prop_liv_sales_dairy 

gl var_resilience	 income_div_gs d_climaticshock d_nonclimaticshock d_anyshock d_atr d_atr_clim d_atr_noclim

gl var_food 	HDDS_w d_cer_w d_tuber_w d_veg_w d_fruit_w d_meat_w d_egg_w d_fish_w d_leg_w d_milk_w d_oil_w d_sweet_w d_cond_w  fies_hh d_worried d_healthy d_fewfood d_skipped d_ateless d_runout d_hungry d_whlday     

gl var_women 		fem_worker fem_income_dmake 

gl var_credit 		bank_account have_savings have_savings_formal  loan_applied loan_applied_formal loan_rejected loan_approved

gl var_techno 		new_seeds_LOCAL new_seeds_MEJORADA new_seeds_MEZCLA

//*MATCHING AND CONTROL
gl var_demo			hhsize nr_adults fem_head mean_ed dep_ratio agehead read_head ed_hhh nr_disab disab 

gl var_asset_base	tot_tlu_bl dindex_pca_bl pindex_pca_bl housingindex_mca_bl lindex_pca_bl nr_rooms_bl 	

gl var_access_market dis_main_road t_main_town output_market_15k

gl covid 			covid_affect 

gl var_gis 			totrain lravg_totrain cov_totrain avgtemp_mean lravg_avgtemp_mean cov_avgtemp_mean avgtemp_min lravg_avgtemp_min cov_avgtemp_min avgtemp_max lravg_avgtemp_max cov_avgtemp_max evi lravg_evi cov_evi ndvi lravg_ndvi cov_ndvi pop_density_2020 pop_dens_2014 

//*OTHER VARIABLES
gl var_other		member_status hh_sample opa_ha_pp opa_inv_pp prod_tot


* Table: Summary Statistics 
*...........................
est clear 
eststo: estpost summarize $var_inc $var_asset_end $var_crop $var_live tot_val_prod $var_market $var_resilience $var_food $var_women  $var_credit $var_techno $var_demo $var_asset_base $var_access_market  $covid $var_gis $var_other

esttab using "$TABLES\table1-summary.csv", replace ///
refcat(d_inc_ag_wage "INGRESO" tot_tlu "ACTIVOS FINALES" harvest_ha_CACAO "PRODUCCION DE CULTIVOS" val_liv "PRODUCCION GANADERA" tot_val_prod "PRODUCCION TOTAL" dmktac_crop  "ACCESO AL MERCADO"  income_div_gs "RESILIENCIA" HDDS_w "SEGURIDAD ALIMENTARIA" fem_worker "EMPODERAMIENTO DE LAS MUJERES"  bank_account "ACCESO AL CREDITO" new_seeds_LOCAL "VARIEDAD DE SEMILLA" hhsize "DEMOGRAFIA" tot_tlu_bl "ACTIVOS BASE" dis_main_road "ACCESO A MERCADOS" covid_affect "COVID" totrain "VARIABLES GIS" member_status "OTRAS VARIABLES", nolabel) ///
 cells("mean(fmt(3)) sd(fmt(2)) min(fmt(0)) max(fmt(0)) count(fmt(0))") nostar nonumber  ///
not mtitles nonote label collabels("Mean" "Std.Dev." "Min" "Max" "N")  


*************************
*5. SAVE FINAL DATASET
*************************
*Create year of eligibility and OPA status
g year_elegible=year(fecha_elegibilidad)
g year_estado=year(estado_fecha)

*Keep relevant variables
keep interview__key ruc_anonimizada departamento cod_dep cod_prov cod_dis cod_ccpp latitude longitude altitude treated cadena estado estado_fecha fecha_elegibilidad nombre_plan year_elegible year_estado member_status hh_sample opa_ha_pp opa_desem_pp opa_inv_pp prod_tot $var_inc $var_asset_end $var_crop $var_live tot_val_prod $var_market $var_resilience $var_food $var_women $var_credit $var_techno $var_demo $var_asset_base $var_access_market  $covid $var_gis outliers_all

sort interview__key
save "$DATA/hogar_encuesta_antesPSM", replace



