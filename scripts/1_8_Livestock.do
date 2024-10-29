*******************************************
* 	IMPACT ASSESSMENT - AGROIDEAS PERU 
*  	What: Livestock Production
*	File: r_livestock.dta
*******************************************

/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar bases de datos de producción ganadera
  
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

*************************
* 1. Create Variables
*************************

*De rtahogar.dta obtener el nombre de OTRO r_livestock__id
cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep if d2_1__99>0 & d2_1__99!=.
keep interview__key d2_otro 

sort interview__key 
tempfile r_livestock
save `r_livestock', replace


cd "$DATA/HOGAR"
use "r_livestock.dta", clear
//*Tres bienes pecuarios más importantes
sort interview__key 
merge interview__key  using `r_livestock'
drop _m

*Propiedad & Mantiene
*.....................
*Propiedad: son propiedad del hogar actualmente
*Mantiene: pero NO son de propiedad del hogar actualmente
egen nr_alpaca = rowtotal(d3 d4) if r_livestock__id==6 // ALPACA
egen nr_llama = rowtotal(d3 d4) if r_livestock__id==5 // LLAMA
egen nr_cow = rowtotal(d3 d4) if r_livestock__id==1 // VACUNOS (incluye BUEY, BECERRO)
egen nr_donk = rowtotal(d3 d4) if r_livestock__id==99 & (strpos(d2_otro, "ASNO") | strpos(d2_otro, "BURRO") | strpos(d2_otro, "BURRA") | strpos(d2_otro, "Burros") | strpos(d2_otro, "CABALLO") | strpos(d2_otro, "EQUINO") | strpos(d2_otro, "MULA") | strpos(d2_otro, "YEGUA"))  // BURRO / MULA / CABALLO
egen nr_sheep = rowtotal(d3 d4) if r_livestock__id==2 // OVINO 
egen nr_goat = rowtotal(d3 d4) if r_livestock__id==3 // CAPRINO
egen nr_pig = rowtotal(d3 d4) if r_livestock__id==4 // PORCINO (incluye jabali)
egen nr_ckn = rowtotal(d3 d4) if r_livestock__id==8 |  r_livestock__id==9 | r_livestock__id==10   // POLLO Y GALLINA, GALLOS
egen nr_dck = rowtotal(d3 d4) if r_livestock__id==11 // PATOS
egen nr_dove = rowtotal(d3 d4) if r_livestock__id==15 // CODORNICES (PALOMA)
egen nr_turk = rowtotal(d3 d4) if r_livestock__id==12 | r_livestock__id==13 // PAVO, GANSOS
egen nr_rabt = rowtotal(d3 d4) if r_livestock__id==17 // CONEJO, LIEBRE
egen nr_cuy = rowtotal(d3 d4) if r_livestock__id==7 //CUYES


*Solo propiedad
*...............
gen nr_cow_ownd = d3 if r_livestock__id==1
gen nr_cuy_ownd = d3 if r_livestock__id==7


*ENERO 2020 (PRE-COVID): Cuantos tenia
*......................................
gen nr_cow_2020 = d5 if r_livestock__id==1
gen nr_cuy_2020 = d5 if r_livestock__id==7


*INGRESOS POR VENTA DE GANADO ENTERO 
*....................................
//*en pie o vivo
g lstock_livesale_inc = d7 if d6==1 

*Ingreso por venta: vacuno y cuy ENTERO
g cow_livesale_inc = lstock_livesale_inc if r_livestock__id==1
g cuy_livesale_inc = lstock_livesale_inc if r_livestock__id==7


*INGRESOS POR VENTA DE GANADO SACRIFICADO
*.........................................
g lstock_deadsale_inc = d9 if d8==1 // sacrificado, en camal o su carne


*Ingreso por venta: vacuno y cuy SACRIFICADO
g cow_deadsale_inc = lstock_deadsale_inc if r_livestock__id==1
g cuy_deadsale_inc = lstock_deadsale_inc if r_livestock__id==7
	

*INGRESOS POR VENTA DE BS PECUARIOS VENDIDO
*...........................................
egen lstock_sale_inc= rowtotal(lstock_livesale_inc lstock_deadsale_inc)


*Crear algunos ingresos específicos para la ganadería
g cow_sale_inc = lstock_sale_inc if r_livestock__id==1
g cuy_sale_inc = lstock_sale_inc if r_livestock__id==7

	
*VALOR DEL GANADO SACRIFICADO PARA CONSUMO DOMÉSTICO
*....................................................
g lstock_consval = d12 if d11==1
replace lstock_consval=. if d12==-99 // NO SE PUEDE ESTIMAR (124 observaciones)

*Valor para consumo domestico: vacuno y cuy
g cow_consval = lstock_consval if r_livestock__id==1
g cuy_consval = lstock_consval if r_livestock__id==7


//*Nota: A diferencia de los cultivos, en este caso no se puede calcular la mediana del precio de los bienes pecuarios porque no se pregunto sobre la cantidad (vivos/camal) que se vendio, sino solo el valor de ventas total.


*INGRESOS POR VENTA DE PRODUCTOS GANADEROS 
*..........................................
//*Nota: No se incluye cantidad producida de leche/huevos/mantequilla/etc, ni la cantidad de estos productos de animales destinados a la venta.
//*Solo se incluye el valor de ventas
g prod_inc = d15 if d14==1 //hogar vendió algún producto de su bien pecuario

g cow_prod_inc = prod_inc if r_livestock__id==1 
g cuy_prod_inc = prod_inc if r_livestock__id==7



*VALOR DEL PRODUCTO GANADERO PARA CONSUMO DOMÉSTICO
*....................................................
g prod_consval = d18 if d17==1
replace prod_consval=. if d18==-99 // NO SE PUEDE ESTIMAR (370 observaciones)

g cow_prod_consval = prod_consval if r_livestock__id==1 
g cuy_prod_consval = prod_consval if r_livestock__id==7



*VAL_LIV: VALOR DE PRODUCCION GANADERA
*......................................
//*IFAD: 
//*Valor total de (cantidad producida * Precio) y por tipo, donde [i] es venta de ganado vivo, ganado sacrificado (venta y consumo propio) y productos pecuarios (venta y consumo propio)
//*AGROIDEAS:
//*No se pregunto por los precios unitarios ni por la cantidad vendida, por lo tanto no se tiene datos de mediana de precios
//*Para el calculo del valor total de productos ganaderos, se suma el valor de ventas y el valor de autoconsumo enunciados directamente por los encuestadores

egen val_liv = rowtotal(lstock_livesale_inc  lstock_deadsale_inc lstock_consval prod_inc prod_consval)

g cow_val_liv = val_liv if r_livestock__id==1 
g cuy_val_liv = val_liv if r_livestock__id==7 


*...........................................
*BASELINE: N bienes pecuarios en ENERO 2015
*...........................................
gen nr_alpaca_bl = d13 if r_livestock__id==6 // ALPACA
gen nr_llama_bl = d13 if r_livestock__id==5 // LLAMA
gen nr_cow_bl = d13 if r_livestock__id==1 // VACUNOS (incluye BUEY, BECERRO)
gen nr_donk_bl = d13 if r_livestock__id==99 & (strpos(d2_otro, "ASNO") | strpos(d2_otro, "BURRO") | strpos(d2_otro, "BURRA") | strpos(d2_otro, "Burros") | strpos(d2_otro, "CABALLO") | strpos(d2_otro, "EQUINO") | strpos(d2_otro, "MULA") | strpos(d2_otro, "YEGUA"))  // BURRO / MULA / CABALLO
gen nr_sheep_bl = d13 if r_livestock__id==2 // OVINO 
gen nr_goat_bl = d13 if r_livestock__id==3 // CAPRINO
gen nr_pig_bl = d13 if r_livestock__id==4 // PORCINO (incluye jabali)
gen nr_ckn_bl = d13 if r_livestock__id==8 |  r_livestock__id==9 | r_livestock__id==10   // POLLO Y GALLINA, GALLOS
gen nr_dck_bl = d13 if r_livestock__id==11 // PATOS
gen nr_dove_bl = d13 if r_livestock__id==15 // CODORNICES (PALOMA)
gen nr_turk_bl = d13 if r_livestock__id==12 | r_livestock__id==13 // PAVO, GANSOS
gen nr_rabt_bl = d13 if r_livestock__id==17 // CONEJO, LIEBRE
gen nr_cuy_bl = d13 if r_livestock__id==7 //CUYES
//*Para -1:HOGAR AUN NO FORMADO , -2:NO RECUERDA, reemplazar con missing

foreach i in alpaca llama cow donk sheep goat pig ckn dck dove turk rabt cuy {
	replace nr_`i'_bl = . if d13==-1 | d13==-2 
}


//*Nota: A diferencia de los cultivos, en este caso no se puede calcular el GASTO EN INSUMOS GANADEROS porque no se pregunto


*....................
*TOMA DE DECISIONES
*...................
*Fusionar el género de los miembros para identificar a quienes toman decisiones sobre ingresos
merge m:1 interview__key using "$TEMP\member_gender_HH.dta" 
drop if _m==2
drop _m

*Sobre la ganancia de ventas de bien pecuario vivo o sacrificado: d10__0 y d10__1
*Sobre productos pecuarios que no sea carne (leche,queso,etc): d19__0 y d19__1

foreach i in d10 d19{
    g fem_first_dmake_`i' = (`i'__0==1 & f_mem1==1) | (`i'__0==2 & f_mem2==1) | (`i'__0==3 & f_mem3==1) | (`i'__0==4 & f_mem4==1) | (`i'__0==5 & f_mem5==1) | (`i'__0==6 & f_mem6==1) | (`i'__0==7 & f_mem7==1) | (`i'__0==8 & f_mem8==1) 
	replace fem_first_dmake_`i' = . if `i'__0==.
	
	g fem_secnd_dmake_`i' = 15 if `i'__1==.a //differentiating missing second decisionmaker
replace fem_secnd_dmake_`i' = 1 if (`i'__1==1 & f_mem1==1) | (`i'__1==2 & f_mem2==1) | (`i'__1==3 & f_mem3==1) | (`i'__1==4 & f_mem4==1) | (`i'__1==5 & f_mem5==1) | (`i'__1==6 & f_mem6==1) | (`i'__1==7 & f_mem7==1) | (`i'__1==8 & f_mem8==1) 

	g male_dmake_`i'= fem_first_dmake_`i'==0 & fem_secnd_dmake_`i'!=1

	g fem_dmake_`i' = fem_first_dmake_`i'==1 & (fem_secnd_dmake_`i'==1 | fem_secnd_dmake_`i'==15)

	g joint_dmake_`i' = 1 if (fem_first_dmake_`i'==1 & fem_secnd_dmake_`i'==. ) | (fem_first_dmake_`i'==0 & fem_secnd_dmake_`i'==1)
}

*lstock: Tomador de decisiones en venta de bs pecuarios
g dmake_lstock = 1 if fem_dmake_d10==1
replace dmake_lstock = 2 if male_dmake_d10==1
replace dmake_lstock = 3 if joint_dmake_d10==1

g f_dmake_lstock = dmake_lstock==1 | dmake_lstock==3 //female decisionmaker
replace f_dmake_lstock=. if dmake_lstock==.

*prodliv: Tomador de decisiones en productos pecuarios que no es carne
//*Nota: d19 pregunta quien toma las decisiones sobre los productos pecuarios, pero no especifica que es sobre las ventas
g dmake_prodliv = 1 if fem_dmake_d19==1
replace dmake_prodliv = 2 if male_dmake_d19==1
replace dmake_prodliv = 3 if joint_dmake_d19==1

g f_dmake_prodliv = dmake_prodliv==1 | dmake_prodliv==3 //female decisionmaker
replace f_dmake_prodliv=. if dmake_prodliv==.


//*Nota: d10 y d19 es para cada bien pecuario. Usualmente, el orden de personas en la toma de decisiones es el mismo, en otros casos, solo se responde por un solo bien pecuario, y los demas aparecen como missing. En dichos casos, solo se captura los primeros valores non-missing por hogar.
//*Hay pocas excepciones por las cuales, un mismo hogar da un orden de diferente para un bien pecuario y para otro, en dicho caso, solo se captura los valores del primer bien pecuario reportado (el mas importante) 


************************************
* 2. Save at the household level
************************************ 

collapse (sum) *_livesale_inc  *_deadsale_inc  *_sale_inc  *_consval prod_inc  *_prod_inc val_liv  *_val_liv (max) nr_*  (firstnm) dmake_*  f_dmake_*, by(interview__key)

save "$TEMP\livestock", replace 



  




