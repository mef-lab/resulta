/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajando la base de datos de hogares
  
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


****************
* 1. Cleaning
****************
//*Revisar OTROS

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key e1* e2*

*PAREDES
*.........
/*
1  LADRILLO, BLOQUE O MATERIAL PREFABRICADO
2  MADERA, TABLA O TABLÓN
3  ADOBE O TAPIA PESADA
4  BAMBU
5  CAÑA, ESTERILLA, OTRO TIPO DE VEGETAL
6  CALAMINA
7  TELA, CARTÓN U OTRO DESECHABLES
8  SIN PAREDES

Anadir nuevo:
9  PIEDRA
10 QUINCHA
*/

*Actualmente
replace e1_4=2 if strpos(e1_4_otro, "CHONTA") //2  TABLA 
replace e1_4=3 if strpos(e1_4_otro, "LADRILLOS DE TIERRA") //3  ADOBE
replace e1_4=5 if strpos(e1_4_otro, "CAÑA DE PALMA CON BARRO") //5  CAÑA
replace e1_4=9 if strpos(e1_4_otro, "PIDRA") | strpos(e1_4_otro, "PIEDRA") | strpos(e1_4_otro, "piedra")  //9 PIEDRA

*2015
replace e2_4=1 if strpos(e2_4_otro, "TARRAJEI CEMENTO") //1 LADRILLO
replace e2_4=9 if strpos(e2_4_otro, "PIEDRA") //9 PIEDRA 
replace e2_4=10 if strpos(e2_4_otro, "BARRO CON BARAS DE MADERA") //10 QUINCHA (cana con barro) 

//*Nota: Hay varias opciones en OTROS como Tarrajeo (con yeso), puede ser pared de ladrillo o de adobe

*TECHO
*.......
/*
1  PLANCHA DE CEMENTO, CONCRETO U HORMIGÓN
2  TEJAS DE BARRO
3  TEJA DE ASBESTO O CEMENTO
4  CALAMINA
5  TEJA PLASTICA
6  PAJA O PALMA
7  MATERIAL DESECHO (tela, cartón, latas, plástico, otros)
*/

*Actualmente
replace e1_5 =1 if e1_5_otro=="LADRILLO"
replace e1_5 =3 if (e1_5_otro=="ESTERNIN" | e1_5_otro=="ETERNIT" | e1_5_otro=="ETHERNET") // Eternit=teja de cemento
replace e1_5 =4 if e1_5_otro=="ALUCIN" // las calaminas Aluzinc 
replace e1_5 =6 if e1_5_otro=="HICHO" | e1_5_otro=="ICHU" // ICHU = paja

*2015
replace e2_5 =6 if e2_5_otro=="BARA Y CARRIZO" //Carrizo es estera elaborada de caña
replace e2_5 =6 if e2_5_otro=="HICHO" | e2_5_otro=="ICHU" | e2_5_otro=="PAJA" | e2_5_otro=="ichu"

//*Nota: Las otras opciones de OTRO son no habia techo, la vivienda no estaba construida


*PISO
*.....
/*
1  TIERRA O ARENA
2  CEMENTO O GRAVILLA
3  MADERA, TABLA O TABLÓN
4  BALDOSÍN, LADRILLO
5  MARMOL
7  LOSETA (e1_6) | ALFOMBRA O TAPETE DE PARED A PARED (e2_6)

//Nota: Para la vivienda 2015, la opcion 7 tiene palabras diferentes
*/

*Actualmente
replace e1_6 = 7 if (e1_6_otro=="CERAMICA" |  e1_6_otro=="CERÁMICA" | e1_6_otro=="PORCELANATO") // Losetas son piezas de barros y de materiales tales como cerámica, piedra, mármol

*2015
//*Nota: la mayoria de OTRO son: no estaba construida, terreno libre


*INSTALACIONES SANITARIAS
*.........................
/*
1  INODORO CONECTADO A ALCANTARILLADO
2  INODORO CONECTADO A POZO SÉPTICO
3  INODORO SIN CONEXIÓN
4  LETRINA
6  NO TIENE SERVICIO SANITARIO (e1_8) | BAJAMAR (e2_8)
7  NO TIENE SERVICIO SANITARIO (e2_8)

Recodifique e2_8:
4  LETRINA O BAJAMAR
6  NO TIENE SERVICIO SANITARIO
*/

*Actualmente
replace e1_8 = 6 if strpos(e1_8_otro, "AIRE LIBRE") | strpos(e1_8_otro, "CAMPO")
replace e1_8 = 4 if e1_8_otro=="SILO"
replace e1_8 = 4 if strpos(e1_8_otro, "POZO") | strpos(e1_8_otro, "ciego")
//*Nota: Falta Biodigestores?

*2015
//*Recodificar:
replace e2_8=4 if e2_8==6
replace e2_8=6 if e2_8==7

replace e2_8 = 6 if strpos(e2_8_otro, "NO TENÍA") | strpos(e2_8_otro, "TERRENO")
replace e2_8 = 4 if strpos(e2_8_otro, "POZO") | strpos(e2_8_otro, "SILO") | strpos(e2_8_otro, "pozo")



*AGUA POTABLE
*.............
/*
1  DE TUBERIA (RED PUBLICA)
2  DE TUBERÍA (NO RED PUBLICA)
3  DE POZO NO PROTEGIDO
4  CAMIÓN CISTERNA, TANQUE,AGUATERO
5  DE POZO CON BOMBA
6  RÍO, ARROYO, ESTANQUE, LAGO,MANANTIAL, ACEQUIA, CANAL
7  DE CAÑO PÚBLICO, FUENTE, PILETA
8  AGUA EMBOTALLADA O EN BOLSA

*/

*Actualmente
replace e1_11 = 5 if strpos(e1_11_otro, "POZO") // POZO PROTEGIDO
replace e1_11 = 7 if strpos(e1_11_otro, "VECINO") | strpos(e1_11_otro, "SACA AGUA") | strpos(e1_11_otro, "OTRO BARRIO")  // Otro: de vecino, vecina, escuela

*2015
replace e2_11 = 7 if strpos(e2_11_otro, "VECINO") | strpos(e2_11_otro, "FAMILIAR") | strpos(e2_11_otro, "PADRES")

//*Nota: Opcion 3 y 5, ambos se refieren a POZO.


**********************
* 2. Rename variables
**********************

rename e1_4 wall_mat
rename e1_5 roof_mat
rename e1_6 floor_mat
rename e1_7 nr_rooms
rename e1_8 toilet_fac
rename e1_9 have_elec
rename e1_10 cook_fuel
rename e1_11 water_source

*Replace missing in 2015 
replace e2_4 = wall_mat if e2_4==.
replace e2_5 = floor_mat if e2_5==.
replace e2_6 = floor_mat if e2_6==.
replace e2_7 = nr_rooms if e2_7==.
replace e2_8 = toilet_fac if e2_8==.
replace e2_9 = have_elec if e2_9==.
replace e2_10 = cook_fuel if e2_10==.
replace e2_11 = water_source if e2_11==.

*Rename dwelling materials in 2015 (baseline)

rename e2_4 wall_mat_bl
rename e2_5 roof_mat_bl
rename e2_6 floor_mat_bl
rename e2_7 nr_rooms_bl
rename e2_8 toilet_fac_bl
rename e2_9 have_elec_bl
rename e2_10 cook_fuel_bl
rename e2_11 water_source_bl

**********************
* 3. Create variables
**********************

/* Smits and Steendijk, 2015:
Quality of water supply, of floor material and of toilet facility are measured with three
categories: (1) low quality, (2) middle quality, and (3) high quality

Water supply:
- high quality is bottled water or water piped into dwelling or premises;
- middle quality is public tap, protected well, tanker truck, etc.;
- low quality is unprotected well, spring, surface water, etc.

Toilet facility: 
- high quality is any kind of private flush toilet;
- middle quality is public toilet, improved pit latrine, etc.;
- low quality is traditional pit latrine, hanging toilet, or no toilet facility.

Floor quality:
- high quality is finished floor with parquet, carpet, tiles, ceramic etc.;
- middle quality is cement, concrete, raw wood, etc.
- low quality is none, earth, dung etc.
*/



*ENDLINE
g 		wall_score = 1 if wall_mat==5 | wall_mat==7 | wall_mat==8 // Barro, tierra, esteras
replace wall_score = 2 if wall_mat==2 | wall_mat==3 | wall_mat==10 // adobe, madera, quincha
replace wall_score = 3 if wall_mat==1 | wall_mat==6 | wall_mat==9 // ladrillo, cemento, calamina, piedra


g 		roof_score = 1 if roof_mat==6 | roof_mat==7  // cana/estera, paja
replace roof_score = 2 if roof_mat==2 | roof_mat==3 | roof_mat==5 | roof_mat==99 // tejas, calamina de plastico, madera, otros
replace roof_score = 3 if roof_mat==1 | roof_mat==4 // cemento, calamina de hierro

g 		floor_score = 1 if  floor_mat==1 // tierra, arena
replace floor_score = 2 if  floor_mat==3 // Madera
replace floor_score = 3 if  floor_mat==2 | floor_mat==4 | floor_mat==5 | floor_mat==7 // Ladrillo, loseta, marmol, alfombra

g 		toilet_score = 1 if toilet_fac==6 | toilet_fac==4 // No tiene, letrina
replace toilet_score = 2 if toilet_fac==2 | toilet_fac==3 // inodoro conectado a pozo septico, inodoro sin conexion
replace toilet_score = 3 if toilet_fac==1 // inodoro conectado a alcantarillado

g 		fuel_score = 1 if cook_fuel ==8 | cook_fuel==2 | cook_fuel==5 | cook_fuel==6 | cook_fuel==7 // No cocina, lena, carbon, 
replace fuel_score = 2 if cook_fuel==3 | cook_fuel==4 // GLP, gas
replace fuel_score = 3 if cook_fuel==1 // electricidad

g 		water_score = 1 if water_source==3 | water_source==5 | water_source==6  // Pozo, rio 
replace water_score = 2 if water_source==4 | water_source==7 // Cisterna, cano piublico, pileta
replace water_score = 3 if water_source==1 | water_source==2 | water_source==8 // Tuberia (red y no red publica), agua embotellada 




*BASELINE
g 		wall_score_bl = 1 if wall_mat_bl==5 | wall_mat_bl==7 | wall_mat_bl==8 // Barro, tierra, esteras
replace wall_score_bl = 2 if wall_mat_bl==2 | wall_mat_bl==3 | wall_mat_bl==10 // adobe, madera, quincha
replace wall_score_bl = 3 if wall_mat_bl==1 | wall_mat_bl==6 | wall_mat_bl==9 // ladrillo, cemento, calamina, piedra


g 		roof_score_bl = 1 if roof_mat_bl==6 | roof_mat_bl==7  // cana/estera, paja
replace roof_score_bl = 2 if roof_mat_bl==2 | roof_mat_bl==3 | roof_mat_bl==5 | roof_mat_bl==99 // tejas, calamina de plastico, madera, otros
replace roof_score_bl = 3 if roof_mat_bl==1 | roof_mat_bl==4 // cemento, calamina de hierro

g 		floor_score_bl = 1 if  floor_mat_bl==1 // tierra, arena
replace floor_score_bl = 2 if  floor_mat_bl==3 // Madera
replace floor_score_bl = 3 if  floor_mat_bl==2 | floor_mat_bl==4 | floor_mat_bl==5 | floor_mat_bl==7 // Ladrillo, loseta, marmol, alfombra

g 		toilet_score_bl = 1 if toilet_fac_bl==6 | toilet_fac_bl==4 // No tiene, letrina
replace toilet_score_bl = 2 if toilet_fac_bl==2 | toilet_fac_bl==3 // inodoro conectado a pozo septico, inodoro sin conexion
replace toilet_score_bl = 3 if toilet_fac_bl==1 // inodoro conectado a alcantarillado

g 		fuel_score_bl = 1 if cook_fuel_bl ==8 | cook_fuel_bl==2 | cook_fuel_bl==5 | cook_fuel_bl==6 | cook_fuel_bl==7 // No cocina, lena, carbon, 
replace fuel_score_bl = 2 if cook_fuel_bl==3 | cook_fuel_bl==4 // GLP, gas
replace fuel_score_bl = 3 if cook_fuel_bl==1 // electricidad

g 		water_score_bl = 1 if water_source_bl==3 | water_source_bl==5 | water_source_bl==6  // Pozo, rio
replace water_score_bl = 2 if water_source_bl==4 | water_source_bl==7 // Cisterna, cano piublico, pileta
replace water_score_bl = 3 if water_source_bl==1 | water_source_bl==2 | water_source_bl==8 // Tuberia (red y no red publica), agua embotellada 

egen 	housing_score_bl = rowtotal(wall_score_bl roof_score_bl floor_score_bl toilet_score_bl fuel_score_bl water_score_bl)

keep interview__key wall_score* roof_score* floor_score* toilet_score* fuel_score* water_score* nr_rooms* have_elec*

save "$TEMP\housing.dta", replace


