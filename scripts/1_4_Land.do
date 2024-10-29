/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con el tamaño de la parcela (Ha)
      - Propiedad de la tierra
	  - Agriculture: Género del tomador de decisiones
  
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

*PREPARE: DECISION MAKER GENDER
*Gender of manager - brings in id of female household members from hh roster to be used later to identify female land managers
use "$TEMP\member_gender.dta", clear
//* There are 13 member__id
forvalues i=1/13 {
    g f_mem`i' = member__id==`i' & gender==2
}

collapse (max) f_mem*, by(interview__key)
tempfile genderent
save `genderent', replace 


*Merge dataset
cd "$DATA/HOGAR"
use "r_parcels.dta", clear
merge m:1 interview__key using `genderent' // merge in hh member id and gender
drop if _m==2
drop _m


*****************************
* 2. Definition of variables
*****************************

*PARCEL SIZE
*.............
*Unit of measure: mostly hectares
tab b5_1
tab unidad_medida // If different from hectares/m2: usually Yugadas
/*
According to INEI:
Yugada: equivalencia de 0.33 Hectáreas en Amazonas y Loreto.
Yugada: equivalencia de 0.25 Hectáreas en Arequipa, Piura, Apurimac, Cusco,
Huancavelica, Ica, La Libertad
*/
tab equivalencia_ha

*Convertion rate 
gen 	conversion_ha=equivalencia_ha 	if b5_1==3
replace conversion_ha=0.30 				if equivalencia_ha==0 & (regexm(unidad_medida, "YUGADAS|yugada"))

*Converting to ha
gen 	parcel_size=parcel_ha
replace parcel_size=b5*conversion_ha if b5_1==3

*Extreme values of land size (ha)
*.................................
*For values lower than 0.001 ha, the original values are very low to be in m2. So, we can assume they are in hectares
replace parcel_size=parcel_size*10000 if parcel_size<=0.001 
*For values greater than 1000, we can assume it is m2
replace parcel_size=parcel_size/10000 if parcel_size>=1000 & parcel_size!=.

*Updating UNIDAD DE MEDIDA for the extreme values (will need for crops)
gen umedida_parcel=unidad_medida_txt 
replace umedida_parcel="HECTAREAS" if parcel_ha<=0.001 & unidad_medida_txt=="METROS"
replace umedida_parcel="METROS" if (parcel_ha>=1000 & parcel_ha!=.) & unidad_medida_txt=="HECTAREAS"

*Identification of parcels larger than 30 ha.
g outlier_parcel_ha = parcel_size>30 & parcel_size!=.

*Identification households with total land above 50 ha.
bysort interview__key: egen sum_parcel_size = sum(parcel_size)
replace outlier_parcel_ha= sum_parcel_size>50 


*LAND OWNERSHIP: STATUS/DOCUMENT
*..................................
g owned_hec = parcel_size if inlist(b3, 1,2,3,4) // Heredado, comprado, asignado x gobierno or comunidad
g ownedtitle_hec = parcel_size if inlist(b3, 1,2,3,4) & (b4==2 | b4==4) // owned_hec + Titulo de propiedad (registrada y no registrada)
g rented_hec = parcel_size if b3==5 // tenencia: arrendado/alquilado
g rentedag_hec = parcel_size if b3==5 & inlist(b4, 3,5) // alquilado + (contrato o ACTA DE POSESION)
g scrop_hec = parcel_size if b3==6 //al partido
g borro_hec = parcel_size if b3==7 | b3==8 // prestado o ocupada sin permiso


*INCOME FROM RENTING OUT
//*AGROIDEAS survey does not include questions about income from renting land

	
*PAYMENTS FOR RENTING IN
g parc_rent_pay = b3_1
	*Checking for outliers
	g parc_rent_pay_d = parc_rent_pay*0.3
	tab parc_rent_pay_d // Hay un valor de $21,000

*LAND DEDICATED TO GRAZING
g parc_grazinglnd = parcel_size if b7_2==1 // use parcial o total para pastoreo/produccion de madera

*Indicator variables
*....................
g d_rentin=(b3==5) //Indicator whether HH rents some portion of land
g d_own=(ownedtitle_hec) // Indicator whether HH  owns land (with title)


*b7: HH with harvest parcel i in the last 12 months
//*Indicator whether HH cultivates at least some portion of land. 
//*Includes b7=1 (CULTIVO) and b7=3 (CULTIVO, PERO PERDIO TODA LA COSECHA)
g d_cultivate= b7==1 | b7==3 
//*Differenciate between b7=1 and b7=3
g d_b7_1= 1 if  b7==1 
g d_b7_3= 1 if  b7==3

*GENDER OF DECISIONMAKER 
g fem_first_dmake = (b7_1__0==1 & f_mem1==1) | (b7_1__0==2 & f_mem2==1) | (b7_1__0==3 & f_mem3==1) | (b7_1__0==4 & f_mem4==1) | (b7_1__0==5 & f_mem5==1) | (b7_1__0==6 & f_mem6==1) | (b7_1__0==7 & f_mem7==1) | (b7_1__0==8 & f_mem8==1) | (b7_1__0==9 & f_mem9==1) | (b7_1__0==10 & f_mem10==1) | (b7_1__0==11 & f_mem11==1) | (b7_1__0==12 & f_mem12==1) | (b7_1__0==13 & f_mem13==1)
//* b7_1 questions were only  made to HH which had cultivated/harvested within the last 12 months
replace  fem_first_dmake=. if b7_1__0==.

g fem_secnd_dmake = 15 if b7_1__1==.a //differentiating missing second decisionmaker
replace fem_secnd_dmake = 1 if (b7_1__1==1 & f_mem1==1) | (b7_1__1==2 & f_mem2==1) | (b7_1__1==3 & f_mem3==1) | (b7_1__1==4 & f_mem4==1) | (b7_1__1==5 & f_mem5==1) | (b7_1__1==6 & f_mem6==1) | (b7_1__1==7 & f_mem7==1) | (b7_1__1==8 & f_mem8==1) | (b7_1__1==9 & f_mem9==1) | (b7_1__1==10 & f_mem10==1) | (b7_1__1==11 & f_mem11==1) | (b7_1__1==12 & f_mem12==1) | (b7_1__1==13 & f_mem13==1)
replace fem_secnd_dmake=. if b7_1__1==.

g male_dmake_ent = fem_first_dmake==0 & fem_secnd_dmake!=1
replace male_dmake_ent=. if fem_first_dmake==.

g fem_dmake_ent = fem_first_dmake==1 & (fem_secnd_dmake==1 | fem_secnd_dmake==15)
replace fem_dmake_ent=. if fem_first_dmake==.

g joint_dmake_ent = 1 if (fem_first_dmake==1 & fem_secnd_dmake==. ) | (fem_first_dmake==0 & fem_secnd_dmake==1)
   
g dmake_entinc = 1 if fem_dmake_ent==1
replace dmake_entinc = 2 if male_dmake_ent==1
replace dmake_entinc = 3 if joint_dmake_ent==1

g f_dmake_ag = dmake_entinc==1 | dmake_entinc==3
replace f_dmake_ag=. if dmake_entinc==.

****************************************
* 3. Save 1: At the r_parcels__id level
****************************************
//* b7: Cultivo/cosecho en ultimos 12 meses == SI

keep interview__key r_parcels__id parcel_size parcel_ha conversion_ha umedida_parcel unidad_medida_txt outlier_parcel_ha owned_hec ownedtitle_hec rented_hec rentedag_hec scrop_hec borro_hec parc_rent_pay f_dmake_ag parc_grazinglnd d_*

sort interview__key r_parcels__id
save "$TEMP\parcel_id.dta", replace


******************************
* 4. Save 2: At the HH level
******************************

use "$TEMP\parcel_id.dta", clear

*Summing to HH level
collapse (sum) tot_land=parcel_size owned_hec ownedtitle_hec rented_hec rentedag_hec scrop_hec borro_hec parc_rent_pay parc_grazinglnd (max) f_dmake_ag outlier_parcel_ha d_rentin d_own d_cultivate d_b7_*, by(interview__key)

*Proportion of land use
g pc_land_owned = owned_hec/tot_land
g pc_land_owned_title = ownedtitle_hec/tot_land
g pc_land_rented = rented_hec/tot_land
g pc_land_rentedag = rentedag_hec/tot_land
g pc_land_scrop = scrop_hec/tot_land
g pc_land_borro = borro_hec/tot_land

sort interview__key
save "$TEMP\parcel_hh.dta", replace





