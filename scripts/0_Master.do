/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Código Maestro 
  
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

*/

*#########################################################
*PREPARACIÓN
*#########################################################
cls
clear all

*#########################################################
*DIRECTORIO
*#########################################################
* Richar's directory 
local user=c(username)
gl DRIVE "C:\Users\rquispe\Desktop\FIDA\Informe final\GITHUB"

*#########################################################
*GENERAL
*#########################################################
* Folders
gl DO		"$DRIVE\DO"
gl DATA		"$DRIVE\Bases"
gl TEMP		"$DRIVE\Table"

*#########################################################
*PARÁMETROS Y CONFIGURACIÓN
*#########################################################
*........................
* Install STATA programs
*........................
net install spost13_ado.pkg  //install fitstat 
*Matching
ssc install psmatch2, replace
ssc install kmatch
ssc install moremata

//*Install pbalchk
net from http://personalpages.manchester.ac.uk/staff/mark.lunt

net install dm79.pkg // Install matselrc
net install sg97_5.pkg // Install frmttable

//*Install grc1leg
net from http://www.stata.com
net cd users
net cd vwiggins
net install grc1leg

*..............
* Graph Format
*..............
grstyle init
grstyle set plain
grstyle set colo Set1, opacity(50): p#bar p#barline 
grstyle set intensity 30: bar


*#########################################################
*PROCESO
*#########################################################
/*
RESUMEN DE ANÁLISIS Y CARPETA DE ARCHIVOS DO
Hay carpetas separadas para el análisis de los datos a nivel de hogar, GIS y OPA.
- 0. Master.do: ejecuta todos los archivos do;

Para los datos del cuestionario de hogares, los archivos se estructuran de la siguiente manera:
- 1. Variable de 1_0_Prepare_dataset.do: 
Agregar versiones de la encuesta, fusiona los datos de las variables de tratamiento y las proveniente de AGROIDEAS;
*/
do "$DO\1_0_Prepare_dataset.do"


/*
- 1_1-1_15: limpieza y construcción variable para cada uno de los módulos del cuestionario de hogares, como parte de este,
todos los conjuntos de datos están reducidos al nivel de hogares;
*/
do "$DO\1_1_RTAHOGAR.do"
do "$DO\1_2_HH_member.do"
do "$DO\1_3_Employment.do"
do "$DO\1_4_Land.do"
do "$DO\1_5_Harvest_Land.do"
do "$DO\1_6_Inputs.do"
do "$DO\1_7_Crop_production.do"
do "$DO\1_8_Livestock.do"
do "$DO\1_9_Housing.do"
do "$DO\1_10_Assets.do"
do "$DO\1_11_Food.do"
do "$DO\1_12_Shocks.do"
do "$DO\1_13_Other_income.do"
do "$DO\1_14_Credit.do"
do "$DO\1_15_COVID.do"
/*
- 1_16: Variables geograficas y climaticas;
*/
do "$DO\1_16_GIS.do"

/*
- 2. Fusión y creación de variables: 
Se fusionan todos los conjuntos de datos específicos del módulo colapsados ​​al nivel de hogar 
Se construyen variables adicionales (incluidos índices de activos, total ingresos y diversidad de ingresos) para el análisis final. 
Se agregan todos los valores atípicos identificados en 1_1-1_15: outliers_all 
Se eliminan ingresos brutos igual a cero e outliers en ingresos netos
*/
do "$DO\2_Merging_variable_creation.do"

/*
- 3. Recorte del apoyo común: 
Se liminan observaciones atípicas (identificadas previamente) y se recorta el uno por ciento superior e inferior de la distribución del ingreso bruto 
Se asignan puntuaciones de propensión y los hogares se eliminan en función al soporte común. 
*/
do "$DO\3_Matching_csupport.do"


/*
- 4. Estimaciones: 
Estos archivos registran todos los indicadores de impacto y luego ejecutan los modelos de estimación de impacto.
Los resultados son exportados en la tabla: main_analysis_PSM_ATET.xlsx
*/
do "$DO\4_Regressions.do"


/*
- 5. Metodología para estimar y obtener los resultados del propensity Score Matching
*/
do "$DO\5. PSM_ATET.do"

