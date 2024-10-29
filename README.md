<h1 align="center">  Evaluación de Impacto del Programa de Compensaciones para la Competitividad (AGROIDEAS)</h1>

Este repositorio contiene información para la replica de la [evaluación de impacto del Programa de Compensaciones para la Competitividad](https://www.gob.pe/institucion/mef/informes-publicaciones/5338967-evaluacion-de-impacto-del-bono-familiar-habitacional) desarrollada por el equipo del Fondo Internacional de Desarrollo Agrícola (FIDA): Cristina Chiarella, Miguel Robles e Irina Valenzuela, asimismo estuvo supervisado por el equipo del Ministerio de Economía y Finanzas (MEF): Rafael Visa Flores y Richar Quispe Cuba. Explora otros repositorios [aquí](https://github.com/mef-lab).


## Resumen
Los resultados de la evaluación de impacto buscan proporcionar evidencia de la efectividad de AGROIDEAS en aspectos económicos y productivos. El horizonte temporal del estudio es del 2015 al 2022. La metodología utilizada es el Propensity Score Matching y estima el average treatment effect on the treated (ATET) de AGROIDEAS utilizando el modelo de ajuste de regresión ponderado por probabilidad inversa (IPWRA, por sus siglas en inglés) y se realizan comprobaciones de robustez utilizando el modelo de coincidencia de vecino más cercano (NNM, por sus siglas en inglés) y de la puntuación de propensión (PSM, por sus siglas en inglés). Los resultados económicos, muestran ausencia de evidencia de impactos de magnitud considerable en variables como ingresos brutos y netos totales, así como en diversas fuentes de ingresos agrícolas y activos del hogar. El programa sí muestra efectos positivos en el incremento de ingresos no agrícolas por cuenta propia de los beneficiarios en 31%; sin embargo, el análisis de heterogeneidad indica que el impacto positivo sobre los ingresos por cuenta propia se da únicamente en los beneficiarios con mayor tiempo de exposición al programa. En cuanto a resultados sobre indicadores productivos, destacan impactos positivos y sustanciales en el valor de producción de café en 61% y de cuyes en 44% en comparación del grupo contrafactual.

## Requerimientos de software
Stata (version 17)
Instalar los siguientes paquetes:
- ssc install psmatch2, replace
- ssc install kmatch
- ssc install moremata
- net install spost13_ado.pkg 
- net from http://personalpages.manchester.ac.uk/staff/mark.lunt 
- net install dm79.pkg // Install matselrc
- net install sg97_5.pkg // Install frmttable
- net from http://www.stata.com
- net cd users
- net cd vwiggins
- net install grc1leg

## Instrucciones para replicar

1. Click en el botón verde `Clonar o descargar` mostrará la lista de archivos en este folder para descargar una copia local de este repositorio.
1. En el folder `agroideas-fida/scripts`, verá un script maestro `0_Master` en Stata.
1. Corra el archivo de Stata `0_Master`. Este do-file creará todas las tablas y gráficos incluidos en la evaluación.

## Bases de insumo

Estas bases no están incluidas en este repositorio, debido a que contienen información confidencial y a que su tamaño supera los límites establecidos para el mismo.

|Descripción|Data|Institución proveedora|Nombre de archivos|Fecha de corte|
|:---:|:---:|:---:|:---:|:---:|
|CENAGRO|Sectores de Enumeración Agropecuaria (SEA)|INEI|Cenagro.dta|2012|
|Sistema de información en línea de Agroideas|OPAS elegibles y no elegibles |AGROIDEAS|Sil.dta|2015-2022|
|Encuesta de hogares de Agroideas|Información de las OPAS y Hogares|MEF|RTA_Peru_Hogar_final.dta|2023|


## Cómo contribuir
Si al revisar este código consideras que:

Has añadido alguna nueva funcionalidad con la que agregas valor para que más personas la reutilicen, has hecho más versátil la herramienta para que sea compatible con nuevas actualizaciones, has solucionado algún fallo existente, o simplemente has mejorado la interfaz de usuario o documentación del mismo.
Entonces te animamos a que devuelvas al repositorio los avances realizados.

Sigue los siguientes pasos para hacer una contribución a la herramienta digital:

- Haz un fork del repositorio. 
- Desarrolla la nueva funcionalidad o haz los cambios que creas que agregan valor a la herramienta
- Haz un "pull request" documentando detalladamente los cambios propuestos en el repositorio.

## Código de conducta 
Nosotros como contribuyentes y administradores nos comprometemos a hacer de la participación en nuestro proyecto y nuestra comunidad una experiencia libre de acoso para todos, independientemente de la edad, dimensión corporal, discapacidad, etnia, identidad y expresión de género, nivel de experiencia, nacionalidad, apariencia física, raza, religión, identidad u orientación sexual.

Antes de interactuar con Código para el Desarrollo y utilizar nuestros canales de comunicación te pedimos que revises nuestro [Código de Conducta](https://github.com/mef-lab/agroideas-fida/blob/main/CODE-OF-CONDUCT.md) para mantener este espacio lo más seguro que se pueda para sus participantes. 

## Disclaimer
Este repositorio contiene archivos para la replicación de las regresiones finales de la evaluación. Los archivos compartidos aquí no incluyen información personal, cumpliendo con la normativa vigente de protección de datos personales.

Solo se está considerando como bases de datos, la base ya consolidada, después de haber realizado todos los merge. Esto debido a la confidencialidad de la información de los productores agrarios. Se ha anonimizado los RUC, para proteger la información personal de los encuestados.

Si desea replicar el análisis utilizando la totalidad de los scripts, deberá solicitar las bases de datos con la información detallada sobre la trama y la fecha de corte. Estos detalles se encuentran especificados en [bases de insumos](https://github.com/mef-lab/agroideas-fida?tab=readme-ov-file#bases-de-insumo). Para obtener dicha información, deberá contactar a las instituciones correspondientes.

Agradecemos su interés en este proyecto y esperamos que estos recursos sean de utilidad.

## Contacto
En caso de tener alguna consulta escribir a mef_lab@mef.gob.pe.

## Licencia
Todo el contenido de este repositorio es publicado bajo la licencia del MIT por lo que los recursos aquí almacenados son de libre uso. Ver [Licencia](https://github.com/mef-lab/agroideas-fida/blob/main/LICENSE) para todos los detalles.

## 
<div class = "row">
  <div class = "column" style = "width:10%">
    <img src="https://github.com/mef-lab/agroideas-fida/blob/main/img/logo_mef.png" align = "left">

    
  </div>
  <div class = "column" style = "width:10%">
    <img src="https://github.com/mef-lab/agroideas-fida/blob/main/img/logo_mef_lab.png" align = "right">
  </div>
</div>
