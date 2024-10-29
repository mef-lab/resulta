/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con la base de datos de COVID
  
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
* 1. PREPARE DATASET
**************************

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key ruc_anonimizada  tipo_opa departamento provincia distrito centro_poblado opa_nombre cod_dep cod_prov cod_dis cod_ccpp b38 b39* b40 d20 d21* d22 consent interview__status


*Drop HH with empty answers 
//*consent==.a, which it is the same as result==.a
drop if consent==.a // drop 11 interviews without any answers
//*drop interview__status==125  RejectedByHeadquarters
drop if interview__status==125 // drop 5 interviews


*Merge with AGROIDEAS
*.....................
sort ruc_anonimizada 
merge ruc_anonimizada using "$DATA/agroideas_treatment.dta"
drop if _merge==2
drop _merge

rename AGROIDEAS treated

*Create three chain groups: Cafe, Lacteos, and 3rd group (other cadenas: Quinua, Palta, Cacao, and Cuyes)
gen 	cadena_grupo=1 if cadena=="Cafe"
replace cadena_grupo=2 if cadena=="Lacteos"
replace cadena_grupo=3 if cadena_grupo==.
label define cadena_grupo 1 "Cafe" 2 "Lacteos" 3 "Otras cadenas"
label values cadena_grupo cadena_grupo
label variable cadena_grupo "Cadena Productiva"

*Create a region variable: Norte/Centro
gen region=(departamento=="AMAZONAS" | departamento=="CAJAMARCA")
label variable region "Region"
label define region 1 "Norte" 0 "Centro"
label values region region


************************
* 2. DEFINE VARIABLES
************************

/*
*The index includes six dummy variables that indicate: 
*(i) Whether access to inputs have decreased due to the COVID-19 outbreak
*(ii) Whether marketing activities have been affected by the COVID-19 outbreak; 
*(iii) Whether household has sold any livestock to cope with the negative economic effect of the COVID-19 outbreak; 
*(iv) Whether the COVID-19 restrictions have affected the regular performance of crop processing; 
*(v) Whether the househod has sold any durable goods to cope with the negative economic effect of the COVID-19 outbreak; 
*(vi) Whether the source of other income and/or transfers have been negatively affected by the COVID-19 outbreak. 

*The PCA index is then normalized to an index between 0 and 1. In the estimation of the S3P’s impact, the normalized index is interacted with the variable indicating whether the household has received any transfers as a response to COVID-19 outbreak.
*/


*2.1. Afectado por covid
*........................
//*produccion agricola y/o pecuaria

g covid_ag = b38 // 1157 HH se vieron afectados por COVID
g covid_lstock =  d20

*2.2. Produccion agricola: Como se vieron afectados?
*....................................................

/*Access to inputs have decreased
b39__2   ¿cómo se afectaron?:NO PUDO CONTRATAR TRABAJADORES A PESAR DE LA NECESIDAD
b39__8   ¿cómo se afectaron?:RETRASO O IMPOSIBILIDAD DE ADQUIRIR / TRANSPORTAR INSUMOS


*Marketing activities have been affected
b39__9   ¿cómo se afectaron?:RETRASO O IMPOSIBILIDAD DE VENDER / TRANSPORTAR PRODUCTOS
 
*COVID-19 restrictions have affected the regular performance of crop processing
b39__3   ¿cómo se afectaron?:CONTRATÓ MENOS TRABAJADORES DE LOS DESEADOS                                               
b39__4   ¿cómo se afectaron?:ABANDONÓ CULTIVOS EN EL CAMPO
b39__5   ¿cómo se afectaron?:RETRASO EN LA SIEMBRA / COSECHA
b39__6   ¿cómo se afectaron?:NO PUDO ACCEDER A LA PARCELA 
b39__7   ¿cómo se afectaron?:REDUJO EL ÁREA SEMBRADA / PLANTÓ MENOS CULTIVOS

*Househod has sold any ASSET to cope with the negative economic effect
b39__1   ¿cómo se afectaron?:TUVO QUE VENDER / ALQUILAR PARCELAS

*OTROS                                                                                                                                    
b39__10  ¿cómo se afectaron?:SE ENFERMÓ O TUVO NECESIDAD DE CUIDAR A UN MIEMBRO DE LA FAM
*No incluyo b39__10 porque su efecto directo a como se afecto las actividades de produccion de cultivos se ve reflejada en las opciones anteriormente mencionadas                                                
*/

*Agricola: Agregacion del efecto del covid
*..........................................

*Numero de efectos si el HH fue afectado por covid
egen n_covid_ag = rowtotal(b39__1-b39__9)
replace n_covid_ag=. if b38==. // Solo para HH con produccion de cultivos
replace n_covid_ag=. if b38==0 // Excluir HH que sus cultivos no fueron afectados

*2.3. Ingresos agricola: Como se vieron afectados?
*....................................................
* Question b40: ¿cambio en los ingresos por la producción de cultivos por covid?
*Ingresos actuales/antes del covid: se ha mantenido o aumentado los ingresos agricolas actual en comparacion al periodo inmediato previo de la ocurrencia del covid
gen income_covid_ag = b40==4 |  b40==5 |  b40==6
replace income_covid_ag =. if b40==. | b40==7 //*7 (No habia produccion antes del covid) to missing


*2.4 Actividad pecuaria: como se vio afectado x el covid
*........................................................

*1=No pudo comprar alimentos adecuados para animales: a1_covid_lstock
*2=No podia pastar animales: a2_covid_lstock
*3=Retraso o imposibilidad de comprar animales: a3_covid_lstock
*4=No pudo acceder a los servicios veterinarios: a4_covid_lstock
*5=No se pudo desparasitar/tratar/vacunar a ningun animal: a5_covid_lstock
*6=Se desparasitaron/trataron/vacunaron menos animales: a6_covid_lstock
*7=Tuvo que vender/sacrificar/regalar animales: a7_covid_lstock
*8=Se retraso o imposibilito la venta de animales: a8_covid_lstock
*9=Se redujo la capacidad de procesamiento: a9_covid_lstock

*Loop:
forvalues i = 1/9 {
gen a`i'_covid_lstock = (d21__0==`i' | d21__1==`i' | d21__2==`i' | d21__3==`i' | d21__4==`i' | d21__5==`i' | d21__6==`i' | d21__7==`i' | d21__8==`i')
replace a`i'_covid_lstock=. if d20==. | d20==0
}


*Pecuario: Agregacion del efecto del covid
*..........................................

*Numero de efectos si el HH fue afectado por covid
egen n_covid_lstock = rowtotal(a1_covid_lstock-a9_covid_lstock)
replace n_covid_lstock=. if d20==. // Solo para HH con produccion pecuaria
replace n_covid_lstock=. if d20==0 // Excluir HH que su act. pecuaria no fueron afectados


*2.5. Ingresos pecuarios: Como se vieron afectados?
*....................................................
*Ingresos actuales/antes del covid: se ha mantenido o aumentado los ingresos pecuarios actual en comparacion al periodo inmediato previo de la ocurrencia del covid
gen income_covid_lstock = d22==4 |  d22==5 |  d22==6
replace income_covid_lstock =. if d22==. | d22==7 //*7 (No habia produccion antes del covid) to missing


* 2.6 Hogar afectado por COVID
*..............................

g covid_affect = b38==1 | d20==1


********************
* 3. COVID INTENSITY
********************
*Para controlar la intensidad del efecto del COVID, se construye un indice usando PCA

* 5.1.El indice incluye cinco dummies:
*.....................................

*i) Acceso a insumos: Si el acceso a los insumos ha disminuido debido al Brote de COVID-19

gen icovid_1= b39__2==1 // "No pudo contratar trabajadores"
replace icovid_1=1 if b39__8==1 // "Dificultad de adquirir insumos" 
replace icovid_1=1 if a1_covid_lstock==1 // "No pudo comprar alimentos adecuados para animales" 

replace icovid_1=1 if a4_covid_lstock==1 // "No pudo acceder a los servicios veterinarios" 
replace icovid_1=1 if a3_covid_lstock==1 // "Dificultad de comprar animales"

*ii) Afecto comercializacion: Si las actividades de ventas/marketing se han visto afectadas por el brote de COVID-19  

gen icovid_2= b39__9==1 // "Dificultad de vender o transportar productos" 
replace icovid_2=1 if a8_covid_lstock==1 // "Se retraso o imposibilito la venta de animales" 

*iii) Afecto procesamiento/actividades de produccion: Si las restricciones de COVID-19 han afectado el rendimiento regular del procesamiento de cultivos

gen icovid_3= b39__3==1 // "Contrato menos trabajores"
replace icovid_3=1 if  b39__4==1 // "Abandono cultivos" 
replace icovid_3=1 if  b39__5==1 // "Retraso en la siembra" 
replace icovid_3=1 if  b39__7 // "Redujo area sembrada" 

replace icovid_3=1 if  a9_covid_lstock==1 // "Se redujo la capacidad de procesamiento" 
replace icovid_3=1 if  a5_covid_lstock==1 // "No se pudo desparasitar/tratar/vacunar a ningun animal" 
replace icovid_3=1 if  a6_covid_lstock==1 // "Se desparasitaron/trataron/vacunaron menos animales" 


*iv) Si el hogar ha vendido algun activo (e.g.ganado) o bien durable para hacer frente al efecto económico negativo del brote de COVID-19

gen icovid_4= b39__1==1 // "Hogar vendio/alquilo parcela"
replace icovid_4=1 if a7_covid_lstock==1 // "Tuvo que vender/sacrificar/regalar animales" 

*v) Limitaciones a las actividades de produccion     
gen icovid_5= b39__6==1 // "No pudo acceder a la parcela" 
replace icovid_5=1 if  a2_covid_lstock==1 // "No podia pastar animales"


* 3.2. PCA
*...........

*Creating index
factor  icovid_1-icovid_5, comp(1) pcf 
predict aindex_pca 

*Standarized [0 1]
foreach v of varlist aindex_pca {
    qui summ `v'
    gen `v'2 = (`v' - r(min)) / (r(max) - r(min))
}
rename aindex_pca2 covid_pca
drop aindex_pca


**************************
* 4. LABEL VARIABLES
**************************

label variable covid_ag "Produccion de cultivos afectadas por el COVID"
label variable b39__1 "Hogar vendio/alquilo parcela"
label variable b39__2 "Acceso a insumos: no pudo contratar trabajadores"
label variable b39__3 "Afecto produccion: contrato menos trabajores"
label variable b39__4 "Afecto produccion: abandono cultivos" 
label variable b39__5 "Afecto produccion: retraso en la siembra" 
label variable b39__6 "Afecto produccion: no pudo acceder a la parcela" 
label variable b39__7 "Afecto produccion: redujo area sembrada" 
label variable b39__8 "Acceso a insumos: dificultad de adquirir insumos" 
label variable b39__9 "Afecto comercializacion: dificultad de vender o transportar productos" 
label variable n_covid_ag "Actividad agricola: N de efectos del COVID"
label variable income_covid_ag "Ingresos agricolas actuales vs. antes del COVID: se mantienen o mejoran"

label variable covid_lstock "Actividades pecuarias afectadas por el COVID"
label variable a1_covid_lstock "No pudo comprar alimentos adecuados para animales" 
label variable a2_covid_lstock "No podia pastar animales"
label variable a3_covid_lstock "Dificultad de comprar animales" 
label variable a4_covid_lstock "No pudo acceder a los servicios veterinarios" 
label variable a5_covid_lstock "No se pudo desparasitar/tratar/vacunar a ningun animal" 
label variable a6_covid_lstock "Se desparasitaron/trataron/vacunaron menos animales" 
label variable a7_covid_lstock "Tuvo que vender/sacrificar/regalar animales" 
label variable a8_covid_lstock "Se retraso o imposibilito la venta de animales" 
label variable a9_covid_lstock "Se redujo la capacidad de procesamiento" 

label variable n_covid_lstock "Actividad pecuaria: N de efectos del COVID"
label variable income_covid_lstock "Ingresos pecuarios actuales vs. antes del COVID: se mantienen o mejoran"

label variable covid_affect "Afectado por COVID"

label variable covid_pca "Indice de Intensidad de COVID" 

********************
* 4. SUMMARY TABLE
********************

gl covid_ag			covid_ag b39__1 b39__2 b39__3 b39__4 b39__5 b39__6 b39__7 b39__8 b39__9 n_covid_ag income_covid_ag
gl covid_lstock		covid_lstock a1_covid_lstock a2_covid_lstock a3_covid_lstock a4_covid_lstock a5_covid_lstock a6_covid_lstock a7_covid_lstock a8_covid_lstock a9_covid_lstock n_covid_lstock income_covid_lstock

gl covid 	covid_affect  covid_pca

*Simple Comparison treatment and Control group
*...................................................
g treated2 = treated==0

est clear 
eststo all: quietly estpost summarize $covid_ag  $covid_lstock 	$covid
eststo treat: quietly estpost summarize $covid_ag  $covid_lstock $covid  if treated == 1 	
eststo control: quietly estpost summarize $covid_ag  $covid_lstock $covid  if treated == 0
	
eststo diff: quietly estpost ttest $covid_ag  $covid_lstock $covid , by(treated2) unequal 

esttab all treat control diff using "${TABLES}\tabla_hh_covid.csv", replace ///
refcat(covid_ag "Actividad Agricola" b39__1 "Produccion agricola: Como se vieron afectados" covid_lstock "Actividad Pecuaria" a1_covid_lstock "Produccion pecuaria: Como se vieron afectados" covid_affect "TOTAL DE HOGARES: AFECTADO E INTENSIDAD DEL COVID", nolabel) ///
 cells("mean(pattern(1 1 1 0) fmt(2)) count(pattern(0 1 1 0) fmt(0)) b(star pattern(0 0 0 1) fmt(2))")   nonumber ///
not mtitles nonote label collabels("Promedio" "Obs." "Diferencia (T-C)") nogaps 



*SAVE
*.....
keep interview__key covid_pca
sort interview__key
save "$TEMP/hh_covid", replace
