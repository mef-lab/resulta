/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar la base de datos de shocks
  
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
* 1. Cleaning Variables
**************************

cd "$DATA/HOGAR"
use "shock.dta", clear


/*
1	Drought
2	Floods
3	Changes in the rainy season
4	Unusually high level of crop pests or disease
5	Restricted access to agricultural inputs (due to price or availability)
6	Unusually low prices/demand for agricultural outputs
7	Illness / accident / death of household member
8	Loss of (non-agricultural) employment (Not due to illness or accident)
9	End of regular assistance/aid/remittances from outside household
99	OTRO
*/

//* Nota: En la encuesta no se abrio la opcion para especificar que OTROS CHOQUE afecto al hogar
//* La condicion estaba como ESPECIFICAR OTROS si =999, en vez de =99

*Other shocks
replace shock__id=10 if shock__id==99

*Invertir escala de recuperación de shock 
g i_5b = i_5
replace i_5b=1 if i_5==5
replace i_5b=2 if i_5==4
replace i_5b=4 if i_5==2 
replace i_5b=5 if i_5==1

***********************
* 2. Create Variables
***********************

global shock "drought  floods  changerain  cropdisease  lowinput  lowoutprice illaccident employmentloss noassistance  othershock"
local id=1
foreach v in $shock  {

*N veces experimento shock desde 2018
gen n_`v'=i_2 if shock__id==`id'

*N veces experimento shock en los ultimos 12 meses
gen n12m_`v'=i_7 if shock__id==`id'   

*Hogares sin shock v
bys interview__key: egen n_`v'mean=mean(n_`v')
replace n_`v'=n_`v'mean
replace n_`v'=0 if n_`v'mean==. 

*HH experienced shock v in the last 5 years
gen d_`v'= (n_`v'>=1 & n_`v'!=.) if shock__id==`id' 
replace d_`v'=0 if n_`v'==0  
label var d_`v' "HH experienced `v'"

*HH experienced shock v in the last 12 months 
gen d_`v'_12mnth=i_7==1 if shock__id==`id'
replace d_`v'_12mnth=0 if n12m_`v'==0 | d_`v'==0
label var d_`v'_12mnth "HH experienced `v' in the last 12 months"

*Shock level of experiencing worst shock v
gen shocklevel_`v'=.
replace shocklevel_`v'=i_4  if shock__id==`id' 
label var shocklevel_`v' "HH's shock level after experiencing worst `v'"

*Recovery level from worst shock v
gen recovlvl_`v'=i_5b if shock__id==`id'
replace recovlvl_`v'=. if shock__id!=`id' 
label var recovlvl_`v' "HH's recovery level after experiencing the worst `v'"

*Recovered to same level or better off from worst shock v
gen d_recover_`v'=inlist(i_5b,3,4,5) if shock__id==`id'
label var d_recover_`v' "HH recovered after experiencing the worst `v'"	

local id=`id'+1
}

************************
* 3. Collapse variables
************************

*Keep variable labels
qui ds d_* shocklevel_* recovlvl_*
local vars `r(varlist)'

foreach v of local vars {
        local l`v' : variable label `v'
            if `"`l`v''"' == "" {
            local l`v' "`v'"
        }
}

collapse (max) d_* shocklevel_* recovlvl_* , by(interview__key)

**Attaching the collapsed labels
foreach v of local vars {
        label var `v' "`l`v''"
}


**********************************
* 4. Define variables at HH level
**********************************

*4.1 Experience shock
*......................

egen d_climaticshock=rowmax(d_drought  d_floods  d_changerain)
label var d_climaticshock "HH experienced climatic shock (drought/flood/changerain)"

egen d_nonclimaticshock=rowmax(d_cropdisease  d_lowinput  d_lowoutprice d_illaccident d_employmentloss d_noassistance  d_othershock)
label var d_nonclimaticshock "HH experienced non-climatic shock (economic/health/conflict etc)"

egen d_anyshock=rowmax(d_climaticshock d_nonclimaticshock)
label var d_anyshock "HH experienced any shock (climatic/nonclimatic)"

*4.2 Recovery from shocks
*..........................

egen d_atr=rowmedian(d_recover_*)
replace d_atr=1 if d_atr==0.5 //breaking a tie if any
lab var d_atr "HH recovered from worst shock (median)"

egen d_atrcc=rowmedian(d_recover_drought  d_recover_floods  d_recover_changerain)
replace d_atrcc=1 if d_atrcc==0.5 //breaking a tie if any
lab var d_atrcc "HH recovered from worst climatic shock (median)"

egen d_atrncc=rowmedian( d_recover_cropdisease d_recover_lowinput  d_recover_lowoutprice d_recover_illaccident d_recover_employmentloss d_recover_noassistance  d_recover_othershock)
replace d_atrncc=1 if d_atrncc==0.5 //breaking a tie if any
lab var d_atrncc "HH recovered from worst non-climatic shocks (median)"

************************
* 5. Save
************************

keep interview__key d_climaticshock d_nonclimaticshock d_anyshock d_atr d_atrcc d_atrncc

sort interview__key
save "$TEMP\shocks.dta", replace
