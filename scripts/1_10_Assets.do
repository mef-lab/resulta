/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajando la base de datos de activos
      - Activos del hogar
	  - Activos productivos
  
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
***********************
* 1. ACTIVOS DEL HOGAR
***********************

cd "$DATA/HOGAR"
use "f_1.dta", clear

/*
1   JUEGO DE SALA-SILLAS TAPIZADAS-SOFÁS 
2	VENTILADOR 
3	MÁQUINA DE COSER 
4	PLANCHA (PARA LA ROPA) 
5	REFRIGERADOR 
6	COCINA DE LEÑA/CARBÓN 
7	COCINA DE QUEROSENO/PARAFINA 
8 	COCINA ELÉCTRICA/GAS 
9	RADIO 
10	EQUIPO DE SONIDO/GRABADORA 
11	TELEVISION / VCR / DVD 
12	ANTENA PARABOLICA / TELEVISIÓN POR CABL 
13	PANEL SOLAR 
14	GENERADOR ELÉCTRICO 
15	TELÉFONO CELULAR 
16	COMPUTADOR DE ESCRITORIO, PORTÁTIL O TA
*/

*Numero de activos del hogar: ACTUALMENTE
*..........................................
g nr_chair = house_asset_2022 	if f_1__id==1
replace nr_chair = 18 if nr_chair==200 // HH reported 200 sofas, will replace with next highest value: 18

g nr_fan = house_asset_2022 	if f_1__id==2
g nr_sewmac = house_asset_2022 	if f_1__id==3
g nr_iron = house_asset_2022 	if f_1__id==4
g nr_fridge = house_asset_2022 	if f_1__id==5
g nr_charstove = house_asset_2022 if f_1__id==6
g nr_parafstove = house_asset_2022 if f_1__id==7
g nr_gasstove = house_asset_2022 if f_1__id==8
g nr_radio = house_asset_2022 	if f_1__id==9
g nr_cdplyr = house_asset_2022 	if f_1__id==10
g nr_tv = house_asset_2022 		if f_1__id==11
g nr_satdsh = house_asset_2022 	if f_1__id==12
g nr_solpan = house_asset_2022 	if f_1__id==13
g nr_genrtr = house_asset_2022 	if f_1__id==14
g nr_phone = house_asset_2022 	if f_1__id==15
g nr_cpu = house_asset_2022 	if f_1__id==16

*Numero de activos del hogar: 2015
*..................................
g nr_chair_bl = house_asset_2015 	if f_1__id==1
replace nr_chair_bl = 18 if nr_chair_bl==200  

g nr_fan_bl = house_asset_2015 		if f_1__id==2
g nr_sewmac_bl = house_asset_2015 	if f_1__id==3
g nr_iron_bl = house_asset_2015 	if f_1__id==4
g nr_fridge_bl = house_asset_2015 	if f_1__id==5
g nr_charstove_bl = house_asset_2015 if f_1__id==6
g nr_parafstove_bl = house_asset_2015 if f_1__id==7
g nr_gasstove_bl = house_asset_2015 if f_1__id==8
g nr_radio_bl = house_asset_2015 	if f_1__id==9
g nr_cdplyr_bl = house_asset_2015 	if f_1__id==10
g nr_tv_bl = house_asset_2015 		if f_1__id==11
g nr_satdsh_bl = house_asset_2015 	if f_1__id==12
g nr_solpan_bl = house_asset_2015 	if f_1__id==13
g nr_genrtr_bl = house_asset_2015 	if f_1__id==14	
g nr_phone_bl = house_asset_2015 	if f_1__id==15
g nr_cpu_bl = house_asset_2015 		if f_1__id==16

collapse (max) nr_*, by(interview__key)

save "$TEMP\assets_1.dta", replace


***************************
* 2. ACTIVOS PRODUCTIVOS
***************************

cd "$DATA/HOGAR"
use "f_2.dta", clear

/*
1	AZADÓN DE MANO
2	GUADAÑA 
3	HACHA 
4	SIERRA 
5	PULVERIZADOR 
6	CUCHILLO PANGA / MACHETE 
7	HOZ 
8	BOMBA DE PEDAL
9	CARRO DE MANO/CARRETILLA 
10	CARRO DE BUEY 
11	ARADO DE BUEY 
12	TRACTOR 
13	ARADO DE TRACTORES 
14	BOMBA MOTORIZADA 
15	SECADORA MECÁNICA 
16	SECADORA SOLAR 
17	MOLINO DE GRANO 
18	GALPON 
19	ESTABLO 
20	CUARTO DE ALMACENAMIENTO 
21	GRANERO 
22	ESTANQUE DE PECES 
23	BICICLETA 
24	MOTOCICLETA 
25	CARRO / CAMIONETA 
27	MOTOSIERRA 
28	FUMIGADORA 
*/


/*
HAND HOE................1
SLASHER.................2
AXE.....................3
SAW.....................4
SPRAYER.................5
PANGA KNIFE / MACHETE...6
SICKLE..................7
TREADLE PUMP............8
HAND CART/WHEELBARROW...9
OX CART.................10
OX PLOUGH...............11
TRACTOR.................12
TRACTOR PLOUGH..........13
MOTORISED PUMP..........14
MECHANICAL DRYER........15
SOLAR DRYER.............16
GRAIN MILL..............17
POULTRY HOUSE...........18
LIVESTOCK ENCLOSURE.....19
STORAGE HOUSE...........20
GRANARY.................21
FISH POND...............22
BICYCLE.................23
MOTORCYCLE..............24
CAR.....................25

chainsaw................27
fumigator...............28
*/

*Numero de activos: ACTUALMENTE
*...............................
g nr_hhoe = ag_asset_2022 if f_2__id==1
g nr_slshr = ag_asset_2022 if f_2__id==2 // segadora= guadana
g nr_axe = ag_asset_2022 if f_2__id==3
g nr_saw = ag_asset_2022 if f_2__id==4
g nr_spryr = ag_asset_2022 if f_2__id==5 // sprayer = pulverizador
g nr_machet = ag_asset_2022 if f_2__id==6
g nr_sckl = ag_asset_2022 if f_2__id==7
g nr_trdlpmp = ag_asset_2022 if f_2__id==8
g nr_hndcrt = ag_asset_2022 if f_2__id==9
g nr_oxcrt = ag_asset_2022 if f_2__id==10
g nr_oxplough = ag_asset_2022 if f_2__id==11
g nr_trac = ag_asset_2022 if f_2__id==12
g nr_trcplough = ag_asset_2022 if f_2__id==13
g nr_motpmp = ag_asset_2022 if f_2__id==14
g nr_mechdryr = ag_asset_2022 if f_2__id==15
g nr_soldryr = ag_asset_2022 if f_2__id==16
g nr_grainmll = ag_asset_2022 if f_2__id==17
g nr_plths = ag_asset_2022 if f_2__id==18
g nr_lstkhs = ag_asset_2022 if f_2__id==19
g nr_storehs = ag_asset_2022 if f_2__id==20
g nr_gran = ag_asset_2022 if f_2__id==21
g nr_pond = ag_asset_2022 if f_2__id==22
g nr_bike = ag_asset_2022 if f_2__id==23
g nr_mbike = ag_asset_2022 if f_2__id==24
g nr_car = ag_asset_2022 if f_2__id==25
g nr_chainsaw = ag_asset_2022 if f_2__id==27
g nr_fumig = ag_asset_2022 if f_2__id==28

*Numero de activos: 2015
*.........................
g nr_hhoe_bl = ag_asset_2015 if f_2__id==1
g nr_slshr_bl = ag_asset_2015 if f_2__id==2 // segadora= guadana
g nr_axe_bl = ag_asset_2015 if f_2__id==3
g nr_saw_bl = ag_asset_2015 if f_2__id==4
g nr_spryr_bl = ag_asset_2015 if f_2__id==5 // sprayer = pulverizador
g nr_machet_bl = ag_asset_2015 if f_2__id==6
g nr_sckl_bl = ag_asset_2015 if f_2__id==7
g nr_trdlpmp_bl = ag_asset_2015 if f_2__id==8
g nr_hndcrt_bl = ag_asset_2015 if f_2__id==9
g nr_oxcrt_bl = ag_asset_2015 if f_2__id==10
g nr_oxplough_bl = ag_asset_2015 if f_2__id==11
g nr_trac_bl = ag_asset_2015 if f_2__id==12
g nr_trcplough_bl = ag_asset_2015 if f_2__id==13
g nr_motpmp_bl = ag_asset_2015 if f_2__id==14
g nr_mechdryr_bl = ag_asset_2015 if f_2__id==15
g nr_soldryr_bl = ag_asset_2015 if f_2__id==16
g nr_grainmll_bl = ag_asset_2015 if f_2__id==17
g nr_plths_bl = ag_asset_2015 if f_2__id==18
g nr_lstkhs_bl = ag_asset_2015 if f_2__id==19
g nr_storehs_bl = ag_asset_2015 if f_2__id==20
g nr_gran_bl = ag_asset_2015 if f_2__id==21
g nr_pond_bl = ag_asset_2015 if f_2__id==22
g nr_bike_bl = ag_asset_2015 if f_2__id==23
g nr_mbike_bl = ag_asset_2015 if f_2__id==24
g nr_car_bl = ag_asset_2015 if f_2__id==25
g nr_chainsaw_bl = ag_asset_2015 if f_2__id==27
g nr_fumig_bl = ag_asset_2015 if f_2__id==28


collapse (max) nr_*, by(interview__key)

save "$TEMP\assets_2.dta", replace
