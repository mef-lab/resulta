/********************************************
PROYECTO
  > Evaluación de impacto del Programa de Compensación para la Competitividad (AGROIDEAS)
  
OBJETIVO
  > Trabajar con la base de datos de crédito e inclusión financiera
  
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
* 1. Prepare variables
**************************

cd "$DATA/HOGAR"
use "rtahogar.dta", clear

keep interview__key l1_1-l1_6

*Cuenta Bancaria en instituciones formales
rename l1_1 bank_account // Actualmente cta de ahorro/credito en institucion formal

*Savings
*........
rename l1_1i have_savings // Tuvo ahorros en un banco o en otro lugar  
replace have_savings=0 if have_savings==99 | have_savings==. | have_savings==.a

rename l1_1ii__10 have_savings_formal // Ahorros en instituciones formales (banco comercial, cooperativa)
replace have_savings_formal=1 if l1_1ii__2==1   
replace have_savings_formal=0 if have_savings_formal==.


*Loans
*......
rename l1_2 loan_applied // Miembro del hogar solicito credito en los ultimos 12 meses 
replace loan_applied=0 if loan_applied==. | loan_applied==.a
 
g loan_applied_formal=(l1_2a__1==1 | l1_2a__2==1 | l1_2a__3==1 | l1_2a__7==1) // Banco, Microfinancieras, Cooperativas, e Institucion de credito agricola

*Numero Credito del sector formal
g nr_loan_formal_applied = l1_3
replace nr_loan_formal_applied=. if loan_applied_formal==0


*Loan: rejected and received ONLY FORMAL INSTITUTIONS 
*......................................................
g nr_loan_rejected = l1_4 // -99: no recuerda
g nr_loan_approved = l1_6 // -99: no recuerda

g loan_rejected = (l1_4>=1 & l1_4!=.) // 1 si alguna vez fue rechazado solo si solicito credito formal en los ultimos 12 meses 
replace loan_rejected = 1 if l1_4==-99 // Si no recuerda el nro de prestamos rechazados, se asume que al menos tuvo uno rechazado
replace loan_rejected = . if loan_applied_formal==0

g loan_approved = (l1_6>=1 & l1_6!=.) // 1 si al menos una vez recibio un prestamo solo si solicito credito formal en los ultimos 12 meses 
replace  loan_approved = 1 if l1_6==-999 // Si no recuerda el nro de prestamos aprobados, se asume que al menos tuvo uno aprobado
replace loan_approved = . if loan_applied_formal==0 

keep interview__key bank_account have_*  nr_* loan_* 

sort interview__key 
save "$TEMP\credit.dta", replace


