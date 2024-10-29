/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con la información  de otros ingresos
  
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
* 1. Preparing dataset
**************************

//*Fusionar las bases para tener los hogares que especificaron 99=OTRO en OTROS INGRESOS
cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key j1_1_otro
sort interview__key

tempfile otherj1_1
save `otherj1_1', replace 

use "transfers.dta", clear
sort interview__key
merge interview__key using `otherj1_1'
drop if _m==2
drop _m

*j1_1_otro only if transfers__id==99
replace j1_1_otro="" if transfers__id!=99

**************************
* 2. Cleaning Variables
**************************

/*
1	Entrepreneurship
2	Fish Production
3	Cash Assistance (From Friends/Relatives, NGOs, Government, etc.)
4	Food Support (From Friends/Relatives, NGOs, Government, etc.)
5	Other In-Kind Transfers/Gifts (From Friends/Relatives, NGOs, Government, etc.)
6	Savings, Interest or Other Investment Income
7	Pension, Disability Grant, or Widow Allowance
8	Income from Apartment, House Rental
9	Income from Real Estate Sales
10	Inheritance
11	Lottery/Gambling Winnings
99	OTROS

Anadir:
12	Alquiler otros
*/

*Reclasificar OTROS - ESPECIFICAR:
*.................................
//*Nota: Aqui se incluye alquiler de terrenos (ingreso). En la seccion de terrenos, solo se preguntaba por pago de alquiler (gasto)
replace transfers__id = 12 if strpos(j1_1_otro, "ALQUILA") | strpos(j1_1_otro, "ALQUILER") | strpos(j1_1_otro, "ARIENDA") | strpos(j1_1_otro, "ARRIENDA") | strpos(j1_1_otro, "alquiler") // Alquiler de caballos, alquiler de pastos, alquiler de terreno

//*Emprendimiento: 
replace transfers__id = 1 if strpos(j1_1_otro, "RESTAURANTE") | strpos(j1_1_otro, "TIENDA") | strpos(j1_1_otro, "VENTA")

//*Otros
replace transfers__id = 11 if strpos(j1_1_otro, "JUEGO DE PELEA")
replace transfers__id = 5 if strpos(j1_1_otro, "OBSEQUIOS")

//*No deberia incluirse: aguinaldo, ELABORACION Y VENTA DE QUESOS, JORNALERO EVENTUAL, PROCESADORA DE YOGURT, programa trabaja peru
drop if j1_1_otro=="AGUINALDO" | j1_1_otro=="ELABORACION Y VENTA DE QUESOS" | strpos(j1_1_otro, "JORNALERO") | j1_1_otro=="PROCESADORA DE YOGURT" | j1_1_otro=="programa trabaja peru"


*Outliers: valor del ingreso
*............................
//* Hay dos valores muy altos: 200000 y 2000000. Reemplazar con el segundo valor mas alto de su categoria
replace j1_2=50000 if  j1_2==200000 & transfers__id == 1
replace j1_2=36000 if  j1_2==2000000 & transfers__id == 6


***********************************
* 3. Create Other Income Variables
***********************************

g entrepre_inc = j1_2 if transfers__id==1
g fish_inc = j1_2 if transfers__id==2
g cash_supp_inc = j1_2 if transfers__id==3
g food_supp_inc = j1_2 if transfers__id==4
g oth_supp_inc = j1_2 if transfers__id==5
g sav_inc = j1_2 if transfers__id==6
g pens_inc = j1_2 if transfers__id==7
g house_rent_inc = j1_2 if transfers__id==8
g house_sale_inc = j1_2 if transfers__id==9
g inherit_inc = j1_2 if transfers__id==10
g gambling_inc = j1_2 if transfers__id==11
g oth_rent_inc = j1_2 if transfers__id==12 | transfers__id==99

//*Nota: Hay HH con mas de una transferencia/otro ingreso
//*Por lo que es posible que la persona tomadora de decisiones sea diferente para cada tipo de ingreso
//*En dichos casos, se elije a la persona tomadora de decisiones de la categoria con el mayor monto de ingresos  	
gsort interview__key -j1_2

collapse (max) *_inc (firstnm) j1_4__0 j1_4__1, by(interview__key)
egen tot_otherinc = rowtotal(*_inc)


***********************************
* 4. Other Income decision-maker
***********************************

*Merging in member gender to identify income decisionmaker. 
sort interview__key
merge m:1 interview__key using "$TEMP\member_gender_HH"
drop if _m==2
drop _m

//*j1_4__0: tiene 1 member_id==10
g fem_first_dmake = (j1_4__0==1 & f_mem1==1) | (j1_4__0==2 & f_mem2==1) | (j1_4__0==3 & f_mem3==1) | ///
(j1_4__0==4 & f_mem4==1) | (j1_4__0==5 & f_mem5==1) | (j1_4__0==6 & f_mem6==1) | (j1_4__0==7 & f_mem7==1) | ///
(j1_4__0==8 & f_mem8==1) | (j1_4__0==10 & f_mem10==1)

//*j1_4__1: tiene 1 member_id==11
g fem_secnd_dmake = 15 if j1_4__1==.a //differentiating missing second decisionmaker
replace fem_secnd_dmake = 1 if (j1_4__1==1 & f_mem1==1) | (j1_4__1==2 & f_mem2==1) | (j1_4__1==3 & f_mem3==1) | ///
(j1_4__1==4 & f_mem4==1) | (j1_4__1==5 & f_mem5==1) | (j1_4__1==6 & f_mem6==1) | (j1_4__1==7 & f_mem7==1) | ///
(j1_4__1==8 & f_mem8==1) | (j1_4__1==11 & f_mem11==1)

g male_dmake_othinc = fem_first_dmake==0 & fem_secnd_dmake!=1

g fem_dmake_othinc = fem_first_dmake==1 & (fem_secnd_dmake==1 | fem_secnd_dmake==15)

g joint_dmake_othinc = 1 if (fem_first_dmake==1 & fem_secnd_dmake==. ) | (fem_first_dmake==0 & fem_secnd_dmake==1)

g dmake_othinc = 1 if fem_dmake_othinc==1
replace dmake_othinc = 2 if male_dmake_othinc==1
replace dmake_othinc = 3 if joint_dmake_othinc==1

g f_dmake_othinc = dmake_othinc==1 | dmake_othinc==3

drop fem_first_dmake fem_secnd_dmake j1_4__0 j1_4__1 male_dmake_othinc fem_dmake_othinc joint_dmake_othinc f_mem* 

save "$TEMP\other_income.dta", replace
