********************************************************************************
local z1: list sizeof global(dep_vars)
local z2: list sizeof global(method)

mata: //Matrices to store results
beta 	= J(`z1',`z2',"")
se 		= J(`z1',`z2',"")
star  	= J(`z1',`z2',0) 
number	= J(`z1',`z2',.)
cmean 	= J(`z1',`z2',"")
percent = J(`z1',`z2',"")
label 	= J(`z1',1,"")
trans 	= J(`z1',1,"")
end

forv i=1/`z1'  { //dependent variable
forv j=1/`z2' { //methods

local depvar `: word `i' of $dep_vars'
local method `: word `j' of $method'

local vartype $vartype

 if ("`method'"=="ipwra") {
	 xi: capture teffects `method' (`depvar' $outcomeeq $c_adicional) (treated $matching, probit)  , atet iterate(10) pstolerance(0)  //IPWRA
	}
	
else if ("`method'"=="ipwra_cluster") {
	 xi:capture teffects ipwra (`depvar' $outcomeeq $c_adicional ) (treated $matching, probit) , atet vce(cluster $cluster_id ) iterate(10) pstolerance(0)  //IPWRA 
	}
	
	
else if ("`method'"=="nnmatch") {
	 xi:capture teffects `method' (`depvar' $outcomeeq) (treated), nn(3) biasadj($matching) atet vce(robust)  //NN
	}
	
	
else if ("`method'"=="psmatch") {
	 xi:capture teffects `method' (`depvar') (treated $matching, probit), atet vce(robust) pstolerance(0)   //Psmatch
	}
	
	
	local k : var lab `depvar' //Variable labels
	mata: label[`i', 1] = st_local("k")
	mata: trans[`i', 1] = st_local("vartype")
	
	scalar N= e(N) //Number of observations
	mata: number[`i',`j'] = st_numscalar("N")
	
	mat results=r(table)
	local beta=results[1,1]
	local se=results[2,1]
	local pmean=results[1,2]
	local z = abs(results[3,1])
	
 if ("`vartype'"=="original") {
    local atet= (`beta'/`pmean')*100
	local mean= `pmean'
 }	
 
 if ("`vartype'"=="binary") {
    local atet= `beta'
	local mean= `pmean'
 }	 
	
 if ("`vartype'"=="log") {
local atet= ((exp(`beta' + `pmean') - exp(`pmean')) / exp(`pmean')) * 100
	local mean= exp(`pmean')
 }	 
 
 if ("`vartype'"=="arcsinh") {
    local atet= ((sinh(`beta' + `pmean') - sinh(`pmean')) / sinh(`pmean')) * 100
	local mean= sinh(`pmean')
 }	 

 	mata: beta[`i',`j'] = strofreal(`beta',"%05.2fc") //coefficient
	mata: se[`i',`j'] = strofreal(`se',"%05.3fc")  //standard error
	mata: cmean[`i',`j'] = strofreal(`mean',"%05.2fc")  //Control mean
	mata: percent[`i',`j'] = strofreal(`atet',"%05.2fc")  //ATET (%)
	mata: star[`i',`j'] = (`z' > invnormal(0.95)) + (`z' > invnormal(0.975)) + (`z' > invnormal(0.995)) 
 }
 }
 
 mata: star = star :* "*"
 mata: beta[.,.] = beta[.,.] :+ star[.,.]  // beta with stars
 mata: se[.,.] = "(" :+ se[.,.] :+ ")" // SE with bracket
 mata: percent[.,.] = percent[.,.] :+ star[.,.]  // ATET(%) with stars


mata
results = J(2*rows(beta),5+cols(beta), "")


for (i=1; i<=rows(beta); i++){
	j = 2*i - 1
	
	results[j,1] = label[i,1]
	results[j,2..cols(beta)+1]   = beta[i,.]
	results[j+1,2..cols(beta)+1] = se[i,.]
	results[j,cols(beta)+2] = percent[i,1]
	results[j,cols(beta)+3] = cmean[i,1]
	results[j,cols(beta)+4] = strofreal(number[i,1])
	results[j,cols(beta)+5] = trans[i,1]
	}
end

mata: table = "","(1)","(2)","(3)","(4)","(5)"   \  ///
		"", "IPWRA", "Percent", "Mean","Observation", "Transformation"    \ results
