/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con los miembros por Hogar
  
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
use "member.dta", clear

*Gender 
g male = a1_3==1
g female = a1_3==2
g gender_hhh = a1_3 if a1_4==. // Gender of Head of household 
g fem_head = female==1 &  a1_4==. // (1 == female household head)


*Age
g child = a1_5a<15 // people aged <15
g adult = a1_5a>=15 & a1_5a!=. // Adult: Mayor o igual a 15
g youth = a1_5a>=15 & a1_5a<24 // Youth: entre 15 y 24
g elder = a1_5a>65 & a1_5a!=.
g dependent = child==1 | elder==1
g school_age = a1_5a>=5 & a1_5a<=16
g agehead = a1_5a if a1_4==. // Age of household head 
g labor_age = a1_5a>=15 & a1_5a<=64  // Number of HH members of working age (15-64)

* GenderxAge
g adult_fem = female==1 & adult==1

*Education
g unenrolled = a2_4==0 & child==1 // No asiste actualmente a la escuela
g enrolled = a2_4==1 & school_age==1 // Asiste actualmente a la escuela
g nr_edyears = a2_3
replace nr_edyears = 0 if a1_5a>=5  & nr_edyears==.
g nr_edyears_adult = nr_edyears if adult==1 // N de anhos de educacion de adultos

*Education of the HH Head 
g head = 1 if a1_4==.
bysort interview__key: egen maxhead = max(head)
g ed_hhh = a2_3 if a1_4==. // N years of schooling of HHH
replace ed_hhh = 0 if ed_hhh==. & a1_4==.
g read_head = (a2_1==2 | a2_1==1) & head==1  // Head of HH sabe leer con fluidez (==2) y con dificultad (==1 


*Disability
g disab = inlist(a2_5, 3,4) | inlist(a2_6, 3,4) | inlist(a2_7, 3,4) ///
| inlist(a2_8, 3,4) | inlist(a2_9, 3,4) | inlist(a2_10, 3,4)


*******************************
* 2. Collapse: at the HH level
*******************************

collapse (sum) nr_males=male nr_females=female nr_adults=adult nr_children=child nr_youth=youth enrolled school_age nr_unenrolled=unenrolled nr_disab=disab nr_dependent=dependent ed_hhh agehead hh_labor=labor_age   ///
(mean) mean_ed=nr_edyears educaveadult=nr_edyears_adult (max) disab fem_head gender_hhh adult_fem read_head, by(interview__key)


*******************************
* 3. Variables at the HH level
*******************************

egen hhsize = rowtotal(nr_males nr_females) 

g dep_ratio = nr_dependent/hhsize

replace enrolled=0 if enrolled==.
g ed_enrol_pc = enrolled/school_age

* Save at the HH level
sort interview__key
save "$TEMP\hh_roster.dta", replace


*******************************
* 4. Dataset with member__id
*******************************

*Creating dataset of gender and member id for use in other datasets
cd "$DATA/HOGAR"
use "member.dta", clear

g child = a1_5a<15 // number of people aged <15

keep interview__key  a1_3 child a1_5a member__id
rename a1_3 gender
save "$TEMP\member_gender.dta", replace


***************************************************
* 5. Dataset with member__id and gender at HH level
***************************************************

use "$TEMP\member_gender.dta", clear

*Create variable for each member id if they are female, to then be used to identify female decision maker
forvalues i=1/11 {
    g f_mem`i' = member__id==`i' & gender==2
}                        

collapse (max) f_mem*, by(interview__key)

save "$TEMP\member_gender_HH", replace 
