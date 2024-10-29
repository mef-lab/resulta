/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con la data de empleo de los Miembros del Hogar
  
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
* 1. Definition of variables
*****************************

cd "$DATA/HOGAR"
use "wagejob.dta", clear

*Have agricultural wages
g farm_job = a4_4b==1
//*Hay algunos trabajos que no son del sector a4_4b==1 :AGRICULTURA, GANADERÍA, CAZA, SILVICULT
replace farm_job = 0 if a4_4b==1 & (regexm(a4_3, "SECTORISTA AGENCIA AGRARIA"))
//*Hay algunos trabajos del sector agropecuario en otras categorias
replace farm_job = 1 if a4_4b!=1 & (regexm(a4_3, "AGRICULTOR|AGRICULTURA|LACTEOS|TRABAJADORA AGRICOLA|ELABORAR Y VENTA DE QUESO|ORDEÑO DE VACAS|PLANTA DE QUESO|GANADERÍA")) 

*Have non-Agricultural wages  
g non_farm_job = farm_job!=1


*Wage per day (a4_6):
g wages_d = a4_6
*Identify Outliers 
//*Outliers: valores mayores a 400
g outlier_waged = (a4_6>400 & a4_6!=.a)
//* For values a4_6>=1000: it could be due to monthly value or extra zero
//* Look at extreme values by sector/activity (1-14)
foreach i of num 1/14 { 
	sum wages_d if a4_4b==`i'
	tab wages_d if a4_4b==`i'
}  
//* Since we are not sure, then replace with the second highest value in their category
replace wages_d = 400 if  a4_4b==1 & a4_6>=480 & a4_6!=. // 7 oulier
replace wages_d = 165 if  a4_4b==4 & a4_6==500  // 1 outlier
replace wages_d = 400 if  a4_4b==5 & a4_6==1400 // 1 outlier
replace wages_d = 200 if  a4_4b==6 & a4_6==2500 // 1 outlier
replace wages_d = 166 if  a4_4b==7 & a4_6==780  // 1 outlier
replace wages_d = 400 if  a4_4b==99 & a4_6>=800 & a4_6!=. // 4 outlier


*Income from wages
g tot_days = a4_4*a4_5 // meses de trabajo * dias al mes
g tot_waged_income = tot_days*wages_d
//*When the person worked less than one month, then income=days*wages_d
replace tot_waged_income= a4_5*wages_d if a4_4==0 

*Agricultural wages income
g farm_waged_inc=tot_waged_income if farm_job==1

*Non-Agricultural wages income
g nonfarm_waged_inc=tot_waged_income if non_farm_job==1


*Creating variables for each job to use later in livelihood diversification variable
sort interview__key member__id
by interview__key: g count = (_n)
forvalues i=1/7 {
    g job_`i' = tot_waged_income if count==`i'
}

*Demographic of working member
*..............................
merge m:1 interview__key member__id using "$TEMP\member_gender.dta" // brings in id of each household member to identify who held each job
drop if _m==2
drop _m

*Female/child worker
g fem_worker = gender==2
g child_worker = child==1 // Only one person less than 15 years old


*Wage income decision-maker
*...........................
*Create variable for each member id if they are female, to then be used to identify female decision maker
forvalues i=1/8 {
    g f_mem`i' = member__id==`i' & gender==2
}

*Female made decision about income usage: yes if the id of the person who makes the decision matches the id for a female from hh roster
g fem_first_dmake = (a4_7__0==1 & f_mem1==1) | (a4_7__0==2 & f_mem2==1) | (a4_7__0==3 & f_mem3==1) | ///
(a4_7__0==4 & f_mem4==1) | (a4_7__0==5 & f_mem5==1) | (a4_7__0==6 & f_mem6==1) | (a4_7__0==7 & f_mem7==1) | ///
(a4_7__0==8 & f_mem8==1) 

g fem_secnd_dmake = 15 if a4_7__1==.a //differentiating missing second decisionmaker
replace fem_secnd_dmake = 1 if (a4_7__1==1 & f_mem1==1) | (a4_7__1==2 & f_mem2==1) | (a4_7__1==3 & f_mem3==1) | ///
(a4_7__1==4 & f_mem4==1) | (a4_7__1==5 & f_mem5==1) | (a4_7__1==6 & f_mem6==1) | (a4_7__1==7 & f_mem7==1) | ///
(a4_7__1==8 & f_mem8==1) 

g male_dmake_job = fem_first_dmake==0 & fem_secnd_dmake!=1
g fem_dmake_job = fem_first_dmake==1 & (fem_secnd_dmake==1 | fem_secnd_dmake==15)
g joint_dmake_job = 1 if (fem_first_dmake==1 & fem_secnd_dmake==. ) | (fem_first_dmake==0 & fem_secnd_dmake==1)

g f_dmake_job = fem_dmake_job==1 | joint_dmake_job==1

g daily_wage_fem = a4_6 if fem_worker==1
   
g nr_jobs = 1

g wagepart = 1

******************************
* 2. Collapse at the HH level
******************************

collapse (sum) tot_waged_income farm_waged_inc nonfarm_waged_inc nr_jobs ///
 nr_male_dmk_job=male_dmake_job nr_fem_dmk_job=fem_dmake_job nr_jnt_dmk_job=joint_dmake_job ///
 nr_fem_jobs=fem_worker nr_child_jobs=child_worker  ///
 nr_farm_jobs=farm_job nr_nonfarm_jobs=non_farm_job ///
 (max) job_* f_dmake_job fem_worker outlier_waged wagepart ///
 /*(mean) daily_wage=wages_d daily_wage_fem (median) daily_wage_med=wages_d daily_wage_fem_med=daily_wage_fem ///
 (max) daily_wage_max=wages_d daily_wage_fem_max=daily_wage_fem*/ , by(interview__key)

sort interview__key
save "$TEMP\employment.dta", replace
