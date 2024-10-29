/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Estimar la zona de soporte común
      - Realizar el Propensity Score Matching
	  - Definir la zona de soporte común
  
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

INSTALAR PROGRAMAS
net install spost13_ado.pkg  //install fitstat 
ssc install psmatch2

//Install pbalchk
net from http://personalpages.manchester.ac.uk/staff/mark.lunt

net install dm79.pkg // Install matselrc
net install sg97_5.pkg // Install frmttable

//Install grc1leg
net from http://www.stata.com
net cd users
net cd vwiggins
net install grc1leg
*/

**************************
* 1. SELECTING VARIABLES 
**************************

use "$DATA\hogar_encuesta_antesPSM.dta", clear

*1.1. Create three chain groups: Cafe, Lacteos, and 3rd group (other cadenas: Quinua, Palta, Cacao, and Cuyes)
gen 	cadena_grupo=1 if cadena=="Cafe"
replace cadena_grupo=2 if cadena=="Lacteos"
replace cadena_grupo=3 if cadena_grupo==.
label define cadena_grupo 1 "Cafe" 2 "Lacteos" 3 "Otras cadenas"
label values cadena_grupo cadena_grupo
label variable cadena_grupo "Cadena Productiva"

*1.2 Create a region variable: Norte/Centro
gen region=(departamento=="AMAZONAS" | departamento=="CAJAMARCA")
label variable region "Region"
label define region 1 "Norte" 0 "Centro"
label values region region

*1.2 Matching variables

gl var_match cadena_grupo region hhsize fem_head agehead ed_hhh disab ///
tot_tlu_bl dindex_pca_bl pindex_pca_bl housingindex_mca_bl /// 
lravg_totrain cov_totrain lravg_avgtemp_mean lravg_avgtemp_min lravg_avgtemp_max cov_avgtemp_mean cov_avgtemp_min cov_avgtemp_max lravg_evi lravg_ndvi pop_density_2020 altitude // Geographic variables


*********************
*2. REMOVING OUTLIERS
*********************

*Drop outliers identified in previos do-file
*............................................
drop if outliers_all==1 // 55 HHs


//*Remove outlier observations and trimming the top and bottom one per cent of the gross income distribution

*Trimming at 1% by cadena
*..........................
forvalues i = 1/3 {
    qui: sum gross_income if cadena_grupo==`i', d
	g top1 = r(p99)
	g bot1 = r(p1)
	g trim_1_cad`i' =  (gross_income>=top1 | gross_income<=bot1) & cadena_grupo==`i' 
	drop top1 bot1
}

g trim_1 = trim_1_cad1 + trim_1_cad2 + trim_1_cad3 // 42 HH

*Drop the trimming observations:
drop if trim_1==1

**************************
* 3. T-test pre-matching
**************************
mata: mata clear

pbalchk treated $var_match, p
	mat control = r(meanuntreat)'
	mat treat	= r(meantreat)'
	mat sd		= r(smeandiff)'
	mat pvalue	= r(pmat)'
	mat A		= (treat,control,sd,pvalue)
		
local matrownum "`=rowsof(A)'"
matrix matstar = J(`matrownum',3,0)
forval a = 1/`matrownum' {
matrix matstar[`a',3] = (abs(A[`a',4]) <= 0.01) + (abs(A[`a',4]) <= 0.05) + (abs(A[`a',4]) <= 0.10)
}

matselrc A A, r(1/`matrownum') c(1,2,3)
mat B=J(1,3,.)
quietly sum treated
mat B[1,1]=r(sum)
mat B[1,2]=r(N)-r(sum)
mat B[1,3]=r(N)
mat rowname B="Observations"
mat A=A\B
frmttable using "$TABLES\balance_variables_TC", statmat(A) sdec(2) annotate(matstar) asymbol(*,**,***) ///
ctitles("","","Unmatched",""\"","Treated","Control","Standardised diff.") note("Statistical significance: * <0.10; ** <0.05; *** < 0.01") ///
title("T-test of matching variables: unmatched vs. matched sample") landscape replace


*****************************
* 3. CALCULATING PSM SCORES
*****************************		
		
/*
As is best practice, the sample is then trimmed based on the common support (see Heckman et al. 1998).
- Propensity score is predicted using the probit model
- The treated and untreated HH are matched using the nearest neighbour
- Caliper width = 0.2 * standard deviation of the estimated predicted probability (Austin, 2009, 2011)
- Assign Propensity Scores to each household
*/
		
*3.1 Caliper
*.............
probit treated $var_match
fitstat

probit treated $var_match
test $var_match

* According to Austin (2009, 2011): 0.2*SD as a caliper width
probit treated $var_match
predict phat, pr
sum phat
local caliper 0.2*r(sd)
di `caliper'

// 0.2*SD = .03

*3.2 Using psmatch
*...................
//* * Nearest neighbor propensity score matching on a 0/1 variable requires the observations to be sorted in a random order. 
*set seed before calling psmatch2 to be able to replicate results
*ssc install psmatch2, replace //update psmatch2 as it is improved all the time
set seed 123456

psmatch2 treated $var_match, n(3) caliper(0.03)


*3.3 Using kmatch
*...................
kmatch ps treated $var_match,  pscmd(probit) ematch(cadena_grupo region) nn(3) caliper(0.03) comsup gen(_KM_*) wgen(_W_) idgenerate(_ID_*) replace


********************************
* 4. TRIMMING ON COMMON SUPPORT
********************************	

/*
- Removing treatment households with a Propensity Score 
above the highest score from the control group
- Removing control households with a score below the lowest score 
from the treatment group. 
*/

*4.1 Trimming 1
*...............

egen mintreat = min(_pscore) if treated==1
egen mintreat1 = max(mintreat)
egen maxcontrol = max(_pscore) if treated==0
egen maxcontrol1 = max(maxcontrol)

g on_supp = 0 		if treated==1 & _pscore > maxcontrol1
replace on_supp = 0 if treated==0 & _pscore < mintreat1
replace on_supp = 1 if on_supp==.

tab on_supp
//*14 HH fuera del support


*4.2 Trimming 2: by cadena_grupo
*................................

bys cadena_grupo region: egen mintreat_km = min(_KM_ps) if treated==1
bys cadena_grupo region: egen maxcontrol_km = max(_KM_ps) if treated==0

bys cadena_grupo region: egen mintreat1_km = max(mintreat_km)
bys cadena_grupo region: egen maxcontrol1_km = max(maxcontrol_km)

g on_supp_km = 0 		if treated==1 & _KM_ps > maxcontrol1_km
replace on_supp_km = 0 if treated==0 & _KM_ps < mintreat1_km
replace on_supp_km = 1 if on_supp_km==.

tab on_supp_km
//*54 HH fuera del support


********************************
* 5. POST-ESTIMATION DIAGNOSTIC
********************************

* 5.1. T-test of matching variables: unmatched vs. matched sample.
*..................................................................
//* Using PSM weights

pbalchk treated $var_match if on_supp_km==1, p wt(_weight)
	mat control = r(meanuntreat)'
	mat treat	= r(meantreat)'
	mat sd		= r(smeandiff)'
	mat pvalue	= r(pmat)'
	mat A		= (treat,control,sd,pvalue)
		
local matrownum "`=rowsof(A)'"
matrix matstar = J(`matrownum',3,0)
forval a = 1/`matrownum' {
matrix matstar[`a',3] = (abs(A[`a',4]) <= 0.01) + (abs(A[`a',4]) <= 0.05) + (abs(A[`a',4]) <= 0.10)
}

matselrc A A, r(1/`matrownum') c(1,2,3)
mat B=J(1,3,.)
quietly sum treated 
mat B[1,1]=r(sum)
mat B[1,2]=r(N)-r(sum)
mat B[1,3]=r(N)
mat rowname B="Observations"
mat A=A\B
frmttable using "$TABLES\balance_variables_TC", statmat(A) sdec(2) annotate(matstar) asymbol(*,**,***) ///
ctitles("","","Matched",""\"","Treated","Control","Standardised diff.") note("Statistical significance: * <0.10; ** <0.05; *** < 0.01") ///
title("T-test of matching variables: unmatched vs. matched sample") landscape merge


* 5.2. Graph post-matching
*..........................

gen pscore=_pscore
lab var pscore "psmatch2: Puntuacion de propension"

//*Histogram of common support
psgraph, treated(_treated) pscore(_pscore) support(on_supp_km)  bin(20) 
gr export "$FIGURES\commonsupport_TCpsm.png", as(png) replace

//*Pscore distribution within common support
twoway histogram pscore, color(*.5) || kdensity pscore || if on_supp_km==1 , by(_treated)
gr export "$FIGURES\histogram_TCpsm.png", as(png) replace

//*Kernel density unmatched vs matched
//Unmatched sample
global o `"legend(order(1 "Tratado" 2 "Control" )) xti(Probabilidad pronosticada) yti(Densidad)"'
twoway (kdensity pscore if _treated==1 ) (kdensity pscore if _treated==0, lpattern(dash)), ${o} title("Muestra No Emparejada") saving("$FIGURES\kernelunmatch_TCpsm.gph", replace) 
gr export "$FIGURES\kernelunmatch_TCpsm.png", as(png) replace

//Matched sample
global o `"legend(order(1 "Tratado" 2 "Control Emparejado" )) xti(Probabilidad pronosticada) yti(Densidad)"'
twoway (kdensity pscore if _treated==1 & _weight<.) (kdensity pscore [aw=_weight] if _treated==0, lpattern(dash)), ${o} title("Muestra Emparejada") saving("$FIGURES\kernelmatch_TCpsm.gph", replace) 
gr export "$FIGURES\kernelmatch_TCpsm.png", as(png) replace

grc1leg "$FIGURES\kernelunmatch_TCpsm.gph" "$FIGURES\kernelmatch_TCpsm.gph"
graph export "$FIGURES\kernel_psm.png", replace

//*Percentage reduction in bias
pstest $var_match, both graph label 
graph export "$FIGURES\biasreduction.png", replace



************************************************
* 6. DESCRIPTIVE STATISTICS: MATCHING VARIABLES
************************************************

*6.1 ATET weigth
*................
//*ATET weigth = Treated [1] - Untreated [phat/(1-phat)]
probit treated $var_match
predict phat2, pr
g atet_w=cond(treated==1,1,phat2/(1-phat2)) 
	
*6.2 Table: T-test post-matching
*................................

mata: mata clear

pbalchk treated $var_match if on_supp_km==1, p wt(atet_w)
	mat control = r(meanuntreat)'
	mat treat	= r(meantreat)'
	mat diff	= r(meandiff)' //Differences in means of each variable between treated and untreated subjects, after adjustment
	mat sd		= r(smeandiff)' //Standardised differences between treated and untreated after adjustment
	mat pvalue	= r(pmat)'
	mat A		= (treat,control,diff,pvalue)
		
local matrownum "`=rowsof(A)'"
matrix matstar = J(`matrownum',3,0)
forval a = 1/`matrownum' {
matrix matstar[`a',3] = (abs(A[`a',4]) <= 0.01) + (abs(A[`a',4]) <= 0.05) + (abs(A[`a',4]) <= 0.10)
}

matselrc A A, r(1/`matrownum') c(1,2,3)
mat B=J(1,3,.)

quietly sum treated if on_supp_km==1
mat B[1,1]=r(sum)
mat B[1,2]=r(N)-r(sum)
mat B[1,3]=r(N)
mat rowname B="Observations"
mat A=A\B

frmttable using "$TABLES\balance_variables_MATCHING", statmat(A) sdec(2) annotate(matstar) asymbol(*,**,***) ///
ctitles("Variables","Tratado","Control","Diferencia (T-C)") note("Statistical significance: * <0.10; ** <0.05; *** < 0.01") ///
title("Estadisticas descriptivas de las variables utilizadas en el matching") landscape 


****************************
* 7. POST-MATCHING DATASET
****************************

gen ps_weight=_weight
lab var ps_weight "psmatch2: weight of matched controls"

*drop if on_supp==0 // 32 observations dropped
drop if on_supp_km==0 // 54 observations dropped
drop mintreat mintreat1 maxcontrol maxcontrol1 on_supp*
drop _pscore-_pdif   _KM_treat-_W_  trim_1_cad1-ps_weight


*****************************
* 8. SUMMARY STATISTIC TABLE
*****************************

*Selected variables:
gl var_hh		hhsize dep_ratio agehead fem_head mean_ed disab 
gl var_assets 	tot_tlu dindex_pca pindex_pca housingindex_mca lindex_pca own_land
gl var_inc		gross_income gross_income_pc 
gl var_prod		tot_crop_val val_liv
gl var_other	HDDS_w fies_hh fem_worker fem_income_dmake  have_savings_formal loan_applied_formal 


est clear
eststo all: quietly estpost summarize $var_hh $var_assets $var_inc $var_prod $var_other 	
eststo cafe: quietly estpost summarize  $var_hh $var_assets $var_inc $var_prod $var_other  if  cadena_grupo==1
eststo lacteos: quietly estpost summarize $var_hh $var_assets $var_inc $var_prod $var_other  if  cadena_grupo==2
eststo tercer: quietly estpost summarize $var_hh $var_assets $var_inc $var_prod $var_other  if  cadena_grupo==3

esttab all cafe lacteos tercer using "${TABLES}\table_hhsample_summary.csv", replace ///
refcat(hhsize "Composicion del hogar y educacion" tot_tlu "Propiedad de activos" gross_income "Medios de vida" HDDS_w "Consumo de alimentos y empoderamiento de las mujeres" have_savings_formal "Inclusion financiera", nolabel) ///
 cells("mean(pattern(1 1 1 1) fmt(2))")  nonumber ///
not mtitles nonote label nogaps 


save "$DATA\RTA_Peru_Hogar_final.dta", replace // Household final data


