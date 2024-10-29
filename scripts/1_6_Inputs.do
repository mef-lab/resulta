/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con la base de costos de los insumos
  
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
* 1. Create Variables
***********************

cd "$DATA/HOGAR"
use "insumos.dta", clear

*Input expenditure by type
*..........................
//*Expenditure by input type, 
//*where [i] is planting material (seeds), organic fertilizer, chemical fertilizer, phytosanitary, labor, others (including hired equipment/animals)
//* i= SEEDS, LABOR_MALE LABOR_FEMALE FERT_O FERT_I PEST OTRO

g exp_input_SEEDS = b_costo if insumos__id ==1
g exp_input_LABOR_MALE = b_costo if insumos__id ==2
g exp_input_LABOR_FEMALE = b_costo if insumos__id ==3
g exp_input_FERT_O = b_costo if insumos__id ==4
g exp_input_FERT_I = b_costo if insumos__id ==5
g exp_input_PEST = b_costo if (insumos__id ==6 | insumos__id ==7 | insumos__id ==8) // Herbicidas, Insecticidas, Fungicidas
g exp_input_OTRO = b_costo if insumos__id ==99

  
*******************************
* 2. Save at the HH-crop level
*******************************

* Collapse at the interview__key r_crops__id level
collapse (sum) b_costo exp_input_* , by(interview__key r_crops__id)

sort interview__key  r_crops__id
save "$TEMP/inputs_cost.dta", replace 


