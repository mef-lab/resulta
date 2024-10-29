/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Preparando la base de datos
      - Uniendo con el tratamiento de Agroideas
	  - Trabajando con las coordenadas del GPS
	  - Trabajando con altitudes
	  - Guardando: Lista de HH con coordenadas del GPS
  
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
gl DRIVE "C:\Users\rquispe\Desktop\FIDA\Informe final\GITHUB\DO"

FOLDER
gl DO		"$DRIVE\DO"
gl DATA		"$DRIVE\Bases"
*/


*****************
* 1. Cleaning
*****************

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

*Drop HH with empty answers 
//*consent==.a, which it is the same as result==.a
drop if consent==.a // drop 11 interviews without any answers
//*drop interview__status==125  RejectedByHeadquarters
drop if interview__status==125 // drop 5 interviews


**************************
* 2. Merge with AGROIDEAS
**************************
sort ruc_anonimizada 
merge ruc_anonimizada using "$DATA/agroideas_treatment.dta"
drop if _merge==2
drop _merge

rename AGROIDEAS treated

***********************
* 3. GPS coordinates
***********************

* Integrate one variable for latitude, longitude, and altitude
rename start_location__Latitude latitude
rename start_location__Longitude longitude
rename start_location__Altitude altitude

* Replace missing values with coordinates included by hand: gps_latitud gps_longitud
replace latitude=gps_latitud if gps_ok==0
replace longitude=gps_longitud if gps_ok==0

*Altitude: replace missing values using end_location__Altitude
replace altitude=end_location__Altitude if altitude==. | altitude==.a

*Coordinates entered by hand, some are positive. Change sign
replace latitude=-1*gps_latitud if gps_ok==0 & latitude>0
replace longitude=-1*gps_longitud if gps_ok==0 & longitude>0

*Identify Extreme values for coordinates
//*Create median at the CCPP level
bys departamento provincia distrito centro_poblado: egen median_lat=median(latitude)
bys departamento provincia distrito centro_poblado: egen median_long=median(longitude)
bys departamento provincia distrito centro_poblado: egen median_alt=median(altitude)
//*Altitude median: for special cases replace with ATLAS values (http://sige.inei.gob.pe/test/atlas/)
replace median_alt=927.10 if cod_ccpp=="107020055" //Para este CCPP, solo dos valores de altitud. Reemplazar mediana con el valor mas cercano al valor del CCPP en el ATLAS(1025)
replace median_alt=1136.6 if cod_ccpp=="107070042" // CCPP:El Palto. La altitud en el ATLAS es 1136.6
replace median_alt=3226.9 if cod_ccpp=="502010017" // CCPP: Incaraccay no tenia ninguna observacion con altitud. ATLAS: 3226.9
replace median_alt=3001.0 if cod_ccpp=="601050100" // CCPP: Rosario de Polloc  no tenia ninguna observacion con altitud
replace median_alt=1331.6 if cod_ccpp=="608010058" // CCPP: El Mirador tenia obsrvaciones con altitud muy pequena (42.2). Se reemplaza la median por el valor ATLAS (1331.6)
replace median_alt=1267.4 if cod_ccpp=="609040065" // CCPP: Canas Bravas tiene valores de altitude 1517.56 y 758.40, y la mediana es cerca a 758.40, pero segun el ATLAS es 1267.4
replace median_alt=1549.2 if cod_ccpp=="609060030" // CCPP: Diamante no tenia ninguna observacion con altitud. ATLAS: 1549.2
replace median_alt= 803.8 if cod_ccpp=="1203010001" // CCPP: La Merced no tenia ninguna observacion con altitud. ATLAS: 803.8
replace median_alt=1564.7 if cod_ccpp=="1203040005" // CCPP: Centro Union Palomar no tenia ninguna observacion con altitud. ATLAS: 1564.7
replace median_alt=2395.2 if cod_ccpp=="1202030034" // CCPP: Lauca tiene observaciones de altitud 2415.88 y 4038.31, sin embargo segun ATLAS: 2395.2
replace median_alt=1495.3 if cod_ccpp=="1204190001" // CCPP: Monobamba tiene observaciones de altitud -43.48 y 774.30, sin embargo segun ATLAS: 1495.3
replace median_alt=1199.9 if cod_ccpp=="1206080101" // CCPP: Cana Eden tiene observaciones de altitud 1202.20 y 542.80, sin embargo segun ATLAS: 1199.9

//*Calculate the distance between HH coordinate with the median of their CCPP
g dist_lat=latitude-median_lat
g dist_long=longitude-median_long 
g dist_alt=altitude-median_alt
//Identify rare/extreme values
g outlier_lat=1 if (dist_lat>1 | dist_lat<-1) & dist_lat!=.
g outlier_long=1 if (dist_long>1 | dist_long<-1) & dist_long!=.
g outlier_alt=1 if (dist_alt>200 | dist_alt<-200) & dist_al!=. & median_alt<=1000
replace outlier_alt=1 if (dist_alt>450 | dist_alt<-450) & dist_al!=. & median_alt>1000
//* Replace with median of the centro poblado
replace latitude=median_lat if outlier_lat==1
replace longitude=median_long if outlier_long==1
replace altitude=median_alt if outlier_alt==1
*Missing values
//Latitud and Longitude: if capture GPS using laptop gps_ok==1 => 2 missing
//*replace with end_location__: 1 missing
replace latitude=end_location__Latitude if latitude==.a & gps_ok==1
replace longitude=end_location__Longitude if longitude==.a & gps_ok==1
//*replace the other missing with median
replace latitude=median_lat if latitude==.a
replace longitude=median_long if longitude==.a
replace altitude=median_alt if altitud==. | altitud==.a


*************************************
* 4. Save 1: Keep relevant variables
*************************************

*Calculate the number of livestock type a HH has
egen nr_lstock = rowmax(d2__1-d2__99) 

*HH in the sample list (first 5 and next 5)
g hh_sample = informante!=-99
replace hh_sample = 1 if reemplazo!=-99 & hh_sample==0

*Keep
keep interview__key departamento provincia distrito centro_poblado ruc_anonimizada cod_dep cod_prov cod_dis cod_ccpp member_status latitude longitude altitude b37 b38 d1 d2_2 d20 nr_lstock result treated cadena estado estado_fecha fecha_elegibilidad nombre_plan hh_sample opa_ha_pp opa_desem_pp opa_inv_pp prod_tot

* Save at the interview__key level
sort interview__key
save "$TEMP/rtahogar.dta", replace



******************************************
* 5. Save 2: HH list with GPS coordinates
******************************************


* Keep relevant variables
keep interview__key departamento provincia distrito centro_poblado cod_dep cod_prov cod_dis cod_ccpp latitude longitude treated

* Order 
order interview__key departamento cod_dep provincia cod_prov distrito cod_dis  centro_poblado cod_ccpp latitude longitude, first  

* Export to excel 
export excel using "$DRIVE\HH_GPS_coordinates.xlsx", firstrow(variables) replace


*************************************************
* 6. Save 3: interview__key with geographic data
*************************************************

use "$TEMP/rtahogar.dta", clear

keep interview__key departamento provincia distrito centro_poblado cod_dep cod_prov cod_dis cod_ccpp
sort interview__key
save "$TEMP/rtahogar_geocode.dta", replace


