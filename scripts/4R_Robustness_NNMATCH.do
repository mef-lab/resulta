/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Análisis de robustez (NNMATCH)
      - IPWRA - ANALYSIS ATET
  
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
gl TABLES	"$DRIVE\Table"

FORMATO DE GRÁFICOS
grstyle init
grstyle set plain
grstyle set colo Set1, opacity(50): p#bar p#barline  p#pie
grstyle set intensity 30: bar pie
*/

**********************************
* 1. MATCHING & CONTROL VARIABLES
**********************************

use "$DATA\RTA_Peru_Hogar_final.dta", clear 

*1.1 Matching Variables
*.......................

gl matching		cadena_grupo region ///
				hhsize fem_head agehead ed_hhh disab /// //demographics
				tot_tlu_bl dindex_pca_bl pindex_pca_bl housingindex_mca_bl /// //Asset
				lravg_totrain cov_totrain lravg_avgtemp_mean lravg_avgtemp_min lravg_avgtemp_max cov_avgtemp_mean cov_avgtemp_min cov_avgtemp_max lravg_evi lravg_ndvi /// // GIS
				pop_density_2020 altitude // Geographic variables

				
******************
* 2. PSM METHOD
******************		 

**Methods
global method nnmatch

**Standard errors for clustering at the level of treatment
global cluster_id ruc_anonimizada


**************************************
* 3. ECONOMIC GOAL: ECONOMIC MOBILITY
**************************************	

* 3.1 Income
*............

global dep_vars gross_income net_income gross_3crop_inc  gross_3live_inc gross_income_pc gross_3crop_inc_pc 

*Transform income variables
foreach var of global dep_vars {
replace `var'=asinh(`var')
 }

*Control variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k lravg_evi lindex_pca_bl member_status hh_sample i.cadena_grupo i.cod_prov

/*Individual regressions:
xi: teffects nnmatch (gross_income $outcomeeq) (treated),  nn(3) biasadj($matching) atet vce(robust)
*/
 
*Variable transformation type: original binary log arcsinh
global vartype arcsinh

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Income, replace) 
restore


* 3.1.2 Income 2
*................

global dep_vars  ag_wage nonag_wage gross_selfemploy_inc

*Transform income variables
foreach var of global dep_vars {
replace `var'=asinh(`var') 
 }

*Control variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k lravg_evi lindex_pca_bl member_status hh_sample i.cadena_grupo


*Variable transformation type: original binary log arcsinh
global vartype arcsinh

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Income2, replace) 
restore


* 3.2 Activos
*............

**Dependent variables: Assets
global dep_vars tot_tlu dindex_pca pindex_pca housingindex_mca lindex_pca  own_land

*Control variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k lravg_evi lindex_pca_bl member_status hh_sample i.cadena_grupo i.cod_prov

** Variable transformation type:  original binary log arcsinh
global vartype original

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell  (A1) sheet(Activos, replace) 
restore	


*3.3 probabilidad de recibir ingresos de diferentes fuentes
*...........................................................

global dep_vars d_inc_live d_inc_ag_wage d_inc_nonag_wage d_inc_transfer d_inc_selfemploy 


** Variable transformation type: original binary log arcsinh
	global vartype binary

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Fuente, replace) 
restore


*3.4 Participacion de ingresos de diferentes fuentes (%)
*........................................................

global dep_vars gsh_live gsh_ag_wage gsh_nonag_wage gsh_transfer gsh_selfemploy  

** Variable transformation type: original binary log arcsinh
	global vartype original

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Fuente_perc, replace) 
restore


********************************************
* 4. IMPACTS ON PRODUCTION AND PRODUCTIVITY
********************************************

global dep_vars tot_crop_val tot_crop_val_ha gross_margin cost_labor tot_exp_inputs tot_exp_input_ha  tot_val_prod  

*Transform variables 
foreach var of global dep_vars {
replace `var'=asinh(`var')
 }

*Control Variables
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample  i.cadena_grupo i.cod_prov

 
** Variable transformation type: original binary log arcsinh
global vartype arcsinh

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Prod, replace) 
restore


********************************
* 5. IMPACTS ON MARKET ACCESS
********************************

*5.1 Valor de ventas
*....................

global dep_vars v_ag_sales 

*Transform variables 
foreach var of global dep_vars {
replace `var'=asinh(`var')
 }

*Control Variables v_ag_sales
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample i.cadena_grupo  i.cod_prov
 	
** Variable transformation type:  original binary log arcsinh
	global vartype arcsinh

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Ventas, replace) 
restore	


*5.2 Participacion en el mercado (%)
*....................................

global dep_vars prop_ag_sales 

 
** Variable transformation type: original binary log arcsinh
	global vartype original

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Ventas_sh, replace) 
restore


*******************
* 6. RESILIENCIA
*******************

*6.1 Income Diversification (Gini Simpson)
*.........................................
global dep_vars income_div_gs

*Control Variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample i.cadena_grupo  i.cod_prov

** Variable transformation type: original binary log arcsinh
	global vartype original

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Resiliencia, replace) 
restore

*6.2 Shocks
*.............

global dep_vars d_climaticshock d_nonclimaticshock  d_anyshock d_atr  d_atr_clim  d_atr_noclim


** Variable transformation type: original binary log arcsinh
	global vartype binary

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Resiliencia2, replace) 
restore

****************************
* 7. SEGURIDAD ALIMENTARIA
****************************

*7.1. Score variables
*.....................

global dep_vars HDDS_w fies_hh

*Control Variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample hhsize fem_head   i.cadena_grupo  i.cod_prov


** Variable transformation type: original binary log arcsinh
	global vartype original

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Alimentos, replace) 
restore

*7.2. Binary variables
*.....................
global dep_vars d_cer_w d_tuber_w d_veg_w d_fruit_w d_meat_w d_egg_w d_fish_w d_leg_w d_milk_w d_oil_w d_sweet_w d_cond_w   d_worried d_healthy d_fewfood d_skipped d_ateless d_runout d_hungry d_whlday  

*Control Variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample hhsize fem_head   i.cadena_grupo  i.cod_prov


** Variable transformation type: original binary log arcsinh
	global vartype binary

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Alimentos2, replace) 
restore

***********************************
* 8. EMPODERAMIENTO DE LAS MUJERES 
***********************************

global dep_vars  fem_worker fem_income_dmake 

*Control Variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample fem_head  i.cadena_grupo  i.cod_prov


** Variable transformation type: original binary log arcsinh
	global vartype binary

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Women, replace) 
restore


***********************
* 9. ACCESO AL CREDITO
***********************

global dep_vars bank_account have_savings have_savings_formal  loan_applied loan_applied_formal loan_rejected loan_approved new_seeds_LOCAL new_seeds_MEJORADA new_seeds_MEZCLA

*Control Variables 
gl outcomeeq	agehead ed_hhh prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample  i.cadena_grupo  i.cod_prov

/*output_market_15k*/

** Variable transformation type: original binary log arcsinh
	global vartype binary

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Otros, replace) 
restore


********************************
* 10. CROP-SPECIFIC REGRESSIONS
********************************

**Matching variables for crop-specific regressions
gl matching		hhsize fem_head agehead ed_hhh disab /// //demographics
				tot_tlu_bl dindex_pca_bl pindex_pca_bl housingindex_mca_bl /// //Asset
				lravg_totrain cov_totrain lravg_avgtemp_mean lravg_avgtemp_min lravg_avgtemp_max cov_avgtemp_mean cov_avgtemp_min cov_avgtemp_max lravg_evi lravg_ndvi /// // GIS
				pop_density_2020 altitude  // Geographic variables
				
**Methods
global method nnmatch2

*10.1 Production 
*................

global dep_vars crop_val_CAFE  crop_val_CACAO  crop_val_PALTA  crop_val_QUINUA yields_CAFE yields_CACAO  yields_PALTA yields_QUINUA cuy_val_liv dairy_val_liv 

*Transform variables  
foreach var of global dep_vars {
replace `var'=asinh(`var')
 }

 
*Control Variables
gl outcomeeq	agehead ed_hhh  prod_tot dis_main_road t_main_town output_market_15k  lravg_evi lindex_pca_bl member_status hh_sample i.cod_prov

*
xi: teffects nnmatch (crop_val_CAFE  $outcomeeq) (treated), nn(3) atet vce(robust) 

xi: teffects ipwra (crop_val_CAFE $outcomeeq) (treated $matching, probit) , atet  iterate(10) pstolerance(0) 

*xi: teffects nnmatch (crop_val_CAFE $outcomeeq) (treated), ematch(region) nn(3) biasadj($matching) atet vce(robust) 


 
** Variable transformation type: original binary log arcsinh
global vartype arcsinh

do "$DO\PSM_ATET.do"

preserve
clear
getmata (var*)=table
export excel using "$TABLES\NNMATCH_ATET.xlsx", cell (A1) sheet(Prod2, replace) 
restore
				
