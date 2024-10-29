/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar la base de datos de consumo de alimentos y seguridad alimentaria
  
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

**************************
* 1. CONSUMO DE ALIMENTOS
**************************

cd "$DATA/HOGAR"
use "fooditem.dta", clear

/*
1	Foods prepared from corn, wheat, rice or any other cereals or grains
2	Foods prepared from roots or tubers (potatoe, yuca, olluco, oca, mashua)
3	Fava beans, beans, lentils or any other legumes, nuts or seeds
4	Sweet potato, pumpkin, carrot or any other orange vegetable
5	Spinach, chard, or any other dark green leafy vegetables
6	Other vegetables for example, tomato, onion, aubergine
7	Mango, papaya, aguaje, cantaloupe, apricot, peaches
8	Other fruits for example pineapple, orange apple, etc
9	Liver, kidney, heart and / or other organ meats
10	Meat, pork, birds, guinea pigs
11	Fish or shellfish
12	Eggs
13	Milk, cheese, yogurt or other foods prepared with milk
14	Any food prepared with oil, butter, fat
15	Sugar, honey, sodas or any other sugary foods or drinks
16	Condiments, spices or non-sweetened drinks
*/


local products cer tuber leg veg fruit meat egg fish  milk oil sweet cond alcohol
gen d_cer_w=fooditem__id==1
gen d_veg_w=(fooditem__id==4 | fooditem__id==5 | fooditem__id==6)
gen d_tuber_w=fooditem__id==2 
gen d_fruit_w=(fooditem__id==7 | fooditem__id==8)
gen d_meat_w= (fooditem__id==9 | fooditem__id==10)
gen d_egg_w=fooditem__id==12 
gen d_fish_w=fooditem__id==11 
gen d_leg_w=fooditem__id==3 
gen d_milk_w=fooditem__id==13 
gen d_oil_w=fooditem__id==14 
gen d_sweet_w=fooditem__id==15 
gen d_cond_w=fooditem__id==16 

collapse (max) d_*, by(interview__key)

sort interview__key
tempfile fooditem
save `fooditem', replace

* COMPLETAR CONSUMO EN ULTIMOS 7 DIAS
*......................................
//*Nota: Hubo 2 semanas aprox. en las que las preguntas g1_2 g1_3 no aparecian en el cuestionario
//*Para dichos hogares, completar consumo de alimentos en los ultimos 7 dias con rtahogar.dta

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key g1_1__1-g1_1__16
sort interview__key

merge interview__key using `fooditem'
drop if g1_1__1==. & _m==1

*Completar d_food_w para _m==1 (575 hogares)
forvalues i = 1/16{
    replace g1_1__`i' = 0 if g1_1__`i'==.a & _m==1
}

replace d_cer_w=g1_1__1 if _m==1
replace d_veg_w=(g1_1__4 | g1_1__5 | g1_1__6) if _m==1
replace d_tuber_w=g1_1__2  if _m==1
replace d_fruit_w=(g1_1__7 | g1_1__8) if _m==1
replace d_meat_w= (g1_1__9 | g1_1__10) if _m==1
replace d_egg_w=g1_1__12  if _m==1
replace d_fish_w=g1_1__11  if _m==1
replace d_leg_w=g1_1__3 if _m==1
replace d_milk_w=g1_1__13 if _m==1
replace d_oil_w=g1_1__14 if _m==1
replace d_sweet_w=g1_1__15 if _m==1
replace d_cond_w=g1_1__16 if _m==1

*Label Variables
lab var d_cer_w "*1=  ate cereals during last 7 days"
lab var d_tuber_w "*2= ate white tubers and roots during last 7 days"
lab var d_veg_w "*3= ate vegetables  during last 7 days"
lab var d_fruit_w "*4= ate fruits  during last 7 days"
lab var d_meat_w "*5= ate meat (organ meat and flesh meat) during last 7 days"
lab var d_egg_w "*6=  ate eggs during last 7 days"
lab var d_fish_w "*7=  ate fish and other seafood during last 7 days"
lab var d_leg_w "*8= ate legumes, nuts and seeds during last 7 days"
lab var d_milk_w "*9= ate milk and milk products during last 7 days"
lab var d_oil_w "*10= ate oils and fats during last 7 days"
lab var d_sweet_w "*11= ate sweets during last 7 days"
lab var d_cond_w "*12= ate spices, condiments and caffinated beverages during last 7 days"

order d_cer_w d_tuber_w d_veg_w d_fruit_w d_meat_w d_egg_w d_fish_w d_leg_w d_milk_w d_oil_w d_sweet_w d_cond_w 

*Definition and coding food groups based on FAO (2010): number of food groups consumed
egen HDDS_w=rsum(d_cer_w-d_cond_w)
lab var HDDS_w "Household dietary diversity score based on 7 day recall"

drop g1_1* _m

sort interview__key
save "$TEMP\ddiv.dta", replace
      

***************************
* 2. SEGURIDAD ALIMENTARIA
***************************

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key g2*

foreach v of varlist g2m_* {
    //* Si responde NO SABE (98) o NO RESPONDE (99) => 0
	replace `v' = 0 if `v'==98 | `v'==99 
}

egen fies_hh=rsum(g2m_1-g2m_8), missing
lab var fies_hh "Food insecurity experience scale raw score"


local fies worried healthy fewfood skipped ateless runout hungry whlday
local i=1
ds g2m_1-g2m_8
foreach v of varlist `r(varlist)' {
    rename `v' d_`:word `i' of `fies''
	local ++i
}

lab var d_worried "Component 1: worried about food"
lab var d_healthy "Compoenet 2: healthy "
lab var d_fewfood "Component 3: few food"
lab var d_skipped "Component 4: skippd meals"
lab var d_ateless "Component 5: ate less food than wanted"
lab var d_runout "Component 6: run out of food"
lab var d_hungry "Component 7: hungry"
lab var d_whlday "Component 8: didn't eat for a whole day"


sort interview__key
save "$TEMP\fies.dta", replace

