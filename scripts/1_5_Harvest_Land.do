/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar la base de cosecha de cultivos (tierra)
  
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

**********************
* 1. Prepare dataset
**********************

*Land measure unit
use "$TEMP\parcel_id.dta", clear

keep interview__key r_parcels__id parcel_size parcel_ha conversion_ha umedida_parcel unidad_medida_txt outlier_parcel_ha d_cultivate

sort interview__key r_parcels__id
tempfile parcel_size
save `parcel_size'

*Merging parcel_size and crops name
cd "$DATA/HOGAR"
use "r_crop_on_parcel.dta", clear

sort interview__key r_parcels__id
merge m:1 interview__key r_parcels__id using `parcel_size'
drop if _merge==2 // Almost all due to b7!=1 (no cultivo en los ultimos 12 meses)
drop _merge

sort r_crop_on_parcel__id
merge r_crop_on_parcel__id using "$DATA/crops_all.dta"
drop if _merge==2
drop _merge

sort interview__key r_parcels__id


*****************************
* 2. Definition of variables
*****************************

*Recode "Other crops" 
*.......................
tab otro_cultivo // These are the list of other crops
// Popular "Other crops": Avena, Papa, Oca, Pasto

* Create a new crops_name with the recoding of "Other crops" and including the remaining "Others crops" name
gen nombre_cultivo="" // This is a string variable
replace nombre_cultivo="CAFÉ" if (regexm(otro_cultivo, "CAFE|CAFÉ"))
replace nombre_cultivo="PALTA" if (regexm(otro_cultivo, "PALTO|paltA|palta"))
replace nombre_cultivo="PAPA" if (regexm(otro_cultivo, "[Pp]apa|PAPA"))
replace nombre_cultivo="ALFALFA" if (regexm(otro_cultivo, "ALFAHALFA")) 
replace nombre_cultivo="AVENA" if (regexm(otro_cultivo, "[Aa]vena|AVENA")) // Incluye: AVENA PARA GANADO/PASTO/FORRAJERA
replace nombre_cultivo="PASTO y FORRAJE" if (regexm(otro_cultivo, "[Pa]sto|PASTO|PASTOS|FORRAJE|GRASS|TREBOL|RAIGRAS|RAIGRASS|RAIRAZ|RAYGRASS|REIGRAS|REIGRASS|REY GRASS|REYGRASS|REY GRAS|RYE GRAS")) 
replace nombre_cultivo="OCA/MASHUA" if (regexm(otro_cultivo, "[Oo]ca|OCA|OCAS|mashua|MASHUA"))
replace nombre_cultivo="OLLUCO" if (regexm(otro_cultivo, "[Oo]lluco"))
replace nombre_cultivo="LIMÓN" if (regexm(otro_cultivo, "LIMON"))
replace nombre_cultivo="MAÍZ" if (regexm(otro_cultivo, "MAIZ|maíz|maiz"))
replace nombre_cultivo="FRIJOLES" if (regexm(otro_cultivo, "ÑUÑA|FREJOL|FREJOLITO")) // ÑUÑA: conocido como frijol reventón
replace nombre_cultivo="TARWI" if (regexm(otro_cultivo, "CHOCHO")) 
replace nombre_cultivo="ARVEJAS" if (regexm(otro_cultivo, "ALBERJA|ALVERJA")) 
replace nombre_cultivo="CILANTRO" if (regexm(otro_cultivo, "CULANTRO")) 
replace nombre_cultivo="KIWICHA" if (regexm(otro_cultivo, "QUIWUICHA")) 
replace nombre_cultivo="MANI" if (regexm(otro_cultivo, "[Mm]ani")) 
replace nombre_cultivo="PACAY" if (regexm(otro_cultivo, "PACAE")) 
replace nombre_cultivo="BRÓCOLI" if (regexm(otro_cultivo, "BROCOLI"))
replace nombre_cultivo="CAÑA DE AZÚCAR" if (regexm(otro_cultivo, "CAÑA DE AZUCAR"))
replace nombre_cultivo="ALCACHOFA" if (regexm(otro_cultivo, "ALCHACOFA"))

replace nombre_cultivo=otro_cultivo if nombre_cultivo==""
replace nombre_cultivo=crop_name if (otro_cultivo=="")

*reLabel CAFE instead of CAFÉ
replace nombre_cultivo="CAFE" if nombre_cultivo=="CAFÉ"

label variable nombre_cultivo "Cultivo"


*B12-B16: Harvest area size (Ha)
*................................
*Let's convert all measures in hectareas
*umedida_parcel: include the string name HECTAREAS, METROS CUADRADOS, and the name of OTRAS UNIDADES (e.g. yugadas)

*Cultivated area in Ha: B12
//* conversion_ha only had for OTRA UNIDAD DE MEDIDA (YUGADAS, yugada)
gen 	b12_ha=b12 					if umedida_parcel=="HECTAREAS" //"HECTAREAS"
replace b12_ha=b12/10000 			if umedida_parcel=="METROS" //"METROS"
replace b12_ha=b12*conversion_ha 	if (umedida_parcel=="YUGADAS" | umedida_parcel=="yugada") //Otras 

* Harvest in Ha: B13, B14, B15, B16
forvalues i=13/16 {
    gen 	b`i'_ha=b`i' 				if umedida_parcel=="HECTAREAS" //"HECTAREAS"
	replace b`i'_ha=b`i'/10000 			if umedida_parcel=="METROS" //"METROS CUADRADOS"
	replace b`i'_ha=b`i'*conversion_ha 	if (umedida_parcel=="YUGADAS" | umedida_parcel=="yugada") //Otras 
}


*Cleaning extreme values
*........................
*b1_ha>=40. There is one value of 678 ha of ARVERJAS -> 678 METROS
replace b12_ha=b12/10000 if b12==678
*diff: identify values b12 greater than parcel_size if b12_ha<=0.001 & umedida_parcel==METROS
g diff=1 if b12>=parcel_size & b12_ha<=0.001 & umedida_parcel=="METROS" 
*If b12_ha Lower than 0.001 ha and unidad medida "METROS" and b12 is not greater than parcel_size (diff==.) => b12 is HECTAREAS
replace b12_ha=b12 if (b12_ha<=0.001 & umedida_parcel=="METROS") & diff==.
*If b12_ha lower than 0.001 ha and unidad medida "METROS" and b12 GREATER or EQUAL than parcel_size (diff=1)
g diff2=b12-parcel_size if b12_ha<=0.001 & umedida_parcel=="METROS" 
replace b12_ha=b12 if (b12_ha<=0.001 & umedida_parcel=="METROS") & diff==1 & diff2<=0.0001
*Lower than 0.001 ha and umedida_parcel=="HECTAREAS"
//* there are values very small
//*Additional check: portion between crop_size and parcel_size
g ratio=(b12_ha/parcel_size)*100
//*Crop area less than 0.1 percent of the plot, I include it as an outlier

*Identify HH with outliers in harvest area ha
*............................................
//*There is no values greater than 30 ha
*Lower than 0.001 ha and umedida_parcel=="HECTAREAS"
//*Crop area less than 0.1 percent of the plot, I include it as an outlier
gen outlier_harvest_ha=1 if (b12_ha<=0.01 & umedida_parcel=="HECTAREAS") & ratio<0.1 
*HH with crops with 0 cultivated/harvest are
replace outlier_harvest_ha=1 if b12==0 // Only 2 values
*b12_ha Lower than 0.001 ha and umedida_parcel=="METROS", and b12 is much greater than parcel_size
replace  outlier_harvest_ha=1 if (b12_ha<=0.001 & umedida_parcel=="METROS") & diff==1 & diff2>0.0001


* HARVEST_HA: Sum all harvest area 
*..................................
* Tablas de área considerando B12_ha si una cosecha, más de 4 cosechas o cosecha permanente y  B13_ha+B14_ha+B15_ha+b16_ha si entre 2 a 4 cosechas
egen harvest_ha=rowtotal(b13_ha b14_ha b15_ha b16_ha) if (b11>=2 & b11<=4) // Entre 2 y 4 cosechas
replace harvest_ha=b12_ha if (b11==1 | b11==10 | b11==11) // Si es una cosecha, o mas de 4 cosechas, o cosecha permanente


*Cultivated land used for crop[i]
*.................................
foreach i in CACAO CAFE PALTA QUINUA  {
    g harvest_ha_`i'=harvest_ha if nombre_cultivo=="`i'"
}


* B17. Cuantos plantas/arboles/arbustos produjeron cultivo X
*............................................................

* Create a variable for "NO SE PUEDE ESTIMAR" trees numbers
gen no_estimar_tree=(b17==999)
label define no_estimar_tree 0 "SI" 1"NO"
label values no_estimar_tree no_estimar_tree
label variable no_estimar_tree "NO SE PUEDE ESTIMAR ARBOLES"

* B17
*missing if it cannot be estimated
gen b17_tree=b17
replace b17_tree=. if b17==999
*missing if b17==0
replace b17_tree=. if b17==0 // 3 cases

*Identification of extreme values
*See values at the crop level
bys nombre_cultivo: egen tree=sum(b17_tree)
tabstat b17_tree if tree!=0, by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)

*See values at the HH level: n of trees/harvest ha by b10 (solo cultivo/cultivo mixto)
g tree_ha= b17_tree/harvest_ha if b17_tree!=.
tabstat tree_ha if tree!=0, by(nombre_cultivo) c(stat) stat(mean sd min max n) format(%9.1g)

*N of (different) crops cultivated by a HH
*..........................................
bys interview__key nombre_cultivo: g nvals = _n == 1 
by interview__key: replace nvals = sum(nvals)
by interview__key: gen n_crops = nvals[_N]


*N OF TREES FOR CHAINS
*...........................
foreach i in CACAO CAFE PALTA {
    g tree_crop_`i'=b17_tree if nombre_cultivo=="`i'"
}


**************************************
* 3. Save at household-crop_code level
**************************************

*Keep relevant variables
keep interview__key r_parcels__id r_crop_on_parcel__id  nombre_cultivo b11 harvest_ha outlier_harvest_ha  b17_tree harvest_ha_* tree_crop_* n_crops

*Withing HH, identify the crops with codes 995, 996, 997, 998, 999
bys interview__key: egen n_995=count(r_crop_on_parcel__id) if r_crop_on_parcel__id==995
bys interview__key: egen n_996=count(r_crop_on_parcel__id) if r_crop_on_parcel__id==996
bys interview__key: egen n_997=count(r_crop_on_parcel__id) if r_crop_on_parcel__id==997
//*Only OTRO CULTIVO 1 (995) and OTRO CULTIVO 2 (996) appear in different parcels within HH

*For n_995>=2 and n_996>=2: identify different crops with same 995 and 996 code
egen crop_id=concat(r_crop_on_parcel__id nombre_cultivo) if (n_995>=2 & n_995!=.) | (n_996>=2 & n_996!=.)
//*crop_id is string
tostring r_crop_on_parcel__id, gen(r_crop_on_parcel_str)
replace crop_id=r_crop_on_parcel_str if crop_id==""

sort interview__key crop_id r_parcels__id

*Collapse at the interview__key crop_id level
collapse (sum) harvest_ha b17_tree harvest_ha_* tree_crop_* (first) r_parcels__id nombre_cultivo r_crop_on_parcel__id n_crops (max) outlier_harvest_ha n_995 n_996, by(interview__key crop_id)

*For the HH with n_995>=2: choose the 995_crop that have the largest harvest_ha. In that way, a HH will have only one OTRO CULTIVO code (99*) that will be used to merge with r_crops.dta
//*Identify the HH with two or more different 995_cultivo or 996_cultivo
bys interview__key: egen n_995crop=count(crop_id) if n_995>=2 & n_995!=.
bys interview__key: egen n_996crop=count(crop_id) if n_996>=2 & n_996!=.
//*for 996: n_996crop==1. Only 995 crops are the ones with more than one within a HH
//*Identify the HH with the largest harvest_ha for the ones with n_995crop>=2 
bys interview__key: egen max_995=max(harvest_ha) if (n_995crop==2 | n_995crop==3)
g select_995=1 if harvest_ha==max_995 & (n_995crop==2 | n_995crop==3)
replace select_995=0 if select_995==. & (n_995crop==2 | n_995crop==3)
//*Identify the HH with two or more crop with similar max values
bys interview__key select_995: egen n_select995=count(crop_id) if (n_995crop==2 | n_995crop==3) & select_995==1
//*For HH with n_select995==2, choose the one that belongs to the first parcels (min r_parcels__id)
bys interview__key select_995: egen min_parcel=min(r_parcels__id) if n_select995==2
replace select_995=1 if r_parcels__id==min_parcel & n_select995==2
replace select_995=0 if r_parcels__id!=min_parcel & n_select995==2

*Drop 995_crops with lowest harvest_ha (or lowest parcel_id) for HH with more than one 995 crop codes
drop if select_995==0

*Keep relevant variables
keep interview__key r_crop_on_parcel__id  nombre_cultivo harvest_ha outlier_harvest_ha  b17_tree harvest_ha_* tree_crop_* n_crops

* Sort
rename r_crop_on_parcel__id r_crops__id
sort interview__key  r_crops__id
save "$TEMP/harvest_ha.dta", replace


************************************
* 4. Save 2: at the household level
************************************
use "$TEMP/harvest_ha.dta", clear 
 
*Collapse at the interview__key 
collapse (sum) harvest_ha harvest_ha_* tree_crop_* (first) n_crops, by(interview__key)

*Proportion of cultivated land used for crop[i]
//*Proportion of land_cultivated used for crop [i], where [i] is the name of the crop
foreach i in CACAO CAFE PALTA QUINUA  {
    g p_land_crop_`i'=harvest_ha_`i'/harvest_ha 
}


sort interview__key  
save "$TEMP/harvest_ha_hh.dta", replace 
 
 
