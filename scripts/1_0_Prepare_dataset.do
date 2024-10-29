/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Preparando la base de datos
      - Unir diferentes encuestas
	  - Trabajar con las variables de tratamiento
  
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
* 1. Append survey versions
*****************************

* Version 1: d2_2 from string to numeric
cd "$DATA/HOGAR/Version_1"
use RTAHOGAR.dta, clear

* Clean d2_2 variable from string values
replace d2_2="." if d2_2=="##N/A##"
replace d2_2="0" if d2_2=="00"
replace d2_2="400" if d2_2=="400 VENTA DE UN CHANCHO"
replace d2_2="6300" if d2_2=="6.300"
replace d2_2="9600" if d2_2=="9600 venta de leche"
replace d2_2="0" if (d2_2=="NINGUNO" | d2_2=="NO" | d2_2=="NO CUENTA CON INGRESOS" |  d2_2=="NO HAY SOLO SE DEDICA  Crianza de Cuyes" | d2_2=="NO SABE" | d2_2=="NO TIENE BIENES PECUARIOS" | d2_2=="NO TIENE NI UN BIEN PECUARIO"  | d2_2=="NO TIENE OTROS BIENES" | d2_2=="NO TIENEN GANADOS") 
replace d2_2="0" if d2_2=="O"

* destring d2_2
destring d2_2, replace

* Save 
save, replace


* Append Survey's version 1 with version 2
cd "$DATA/HOGAR/Version_1"

local datasets : dir . files "*.dta"
foreach f of local datasets{
    use "$DATA/HOGAR/Version_1/`f'", clear
	append using "$DATA/HOGAR/Version_2/`f'"
	save "$DATA/HOGAR/`f'", replace
}


*******************************
* 2. AGROIDEAS Treatment - OPA 
*******************************

use "$DATA/AGROIDEAS_final_sample.dta", clear

* Matched sample
keep if sample_kmatch==1

* Define variable opa_type: final sample or replacement
gen 	opa_type=1 if final_sample==1
replace opa_type=0 if (replacetreated_pool==1 | replacecontrol_pool==1)

label variable opa_type "OPA: muestra final o reemplazo"
label define opa_type 1 "Muestra Final" 0 "OPA reemplazo"
label values opa_type opa_type

drop if opa_type==.

* Label treatment variable
label define AGROIDEAS1 0 "Grupo Control" 1 "Grupo Tratamiento"
label values AGROIDEAS AGROIDEAS1

* Select variables
keep ruc_anonimizada opa_nombre estado estado_fecha AGROIDEAS  cadena  opa_type fecha_elegibilidad nombre_plan hectarea prod_tot inv_tot inv_pcc inv_opa ejecucion_acum2022

*Define additional variables
g opa_ha_pp = hectarea / prod_tot
g opa_inv_pp = inv_tot / prod_tot
g opa_desem_pp = ejecucion_acum2022 / prod_tot

*Merge with other incentives
sort ruc_anonimizada
merge ruc_anonimizada using "$DATA/opa_otros_incentivos.dta"
drop if _m==2
drop _m

* Order variables
order ruc_anonimizada opa_nombre opa_type AGROIDEAS  cadena estado estado_fecha, first  

sort ruc_anonimizada 
* Save sample  in \6_Data_and_analysis folder
save "$DATA\agroideas_treatment.dta", replace
