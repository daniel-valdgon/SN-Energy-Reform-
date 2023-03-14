/*IMPORT GLOBALS
SEND THIS TO PULL PMTS WHENEVER WE ARE HAPPY WITH THESE MEASURES
*/


import excel "$p_res/${namexls}.xlsx", sheet("PNBSF_deps") first clear cellrange(B4)
 
rename Nombredebénéficiares2018 Beneficiaires
rename Montantdutransfertparan Montant

drop if departement==.
drop if RegionDepartement==" General"

levelsof departement, local(departement)
global departementPNBSF `departement'
foreach z of local departement {
	levelsof Beneficiaires if departement==`z', local(PNBSF_Beneficiaires`z')
	global PNBSF_Beneficiaires`z' `PNBSF_Beneficiaires`z''
	levelsof Montant if departement==`z', local(PNBSF_montant`z')
	global PNBSF_montant`z' `PNBSF_montant`z''
	
	*global PNBSF_Beneficiaires`z' = `PNBSF_Beneficiaires`z''*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
	*global PNBSF_montant`z' = `PNBSF_montant`z''*(${inf_20})*(${inf_21})*(${inf_22}) // population growth 2019-2022
  	
}


*===============================================================================
		*1. Proxy mean Test Score
*===============================================================================

/*
This is already done in the main model, the output that I need is called 07_dir_trans_PMT.
This database already contains the PMT variable, which I need in order to assign observations to the program.
*/


set seed 1234
use  "$presim/07_dir_trans_PMT.dta", replace // hh level dataset 1.7 mlln

/**********************************************************************************
*             1. Programme National de Bourses de Sécurité Familiale               *
**********************************************************************************/

levelsof departement, local(department)

foreach var of local department { 
	preserve
		keep if departement==`var'
		
		ren pmt_seed rannum
		*gen rannum= uniform()
		
		sort PMT rannum
		gen count_id=_n
	
		levelsof count_id, local(gente)
	
		gen count_PBSF_`var'=.
	
		*set seed 12345
	
		tempfile auxiliar_PNBSF_`var'
	
		foreach z of local gente {
			replace count_PBSF_`var'=hhweight if count_id==1
			replace count_PBSF_`var'= count_PBSF_`var'[`=`z'-1']+hhweight[`z'] if count_id==`z'
		}
	
		save `auxiliar_PNBSF_`var''
	restore
}

preserve
clear 
foreach var of local department { 
	append using `auxiliar_PNBSF_`var''
	}

tempfile auxiliar_PNBSF
save `auxiliar_PNBSF'	//*save "$dta/auxiliar_PNBSF.dta", replace
restore

merge 1:1 hhid using `auxiliar_PNBSF' , nogen keepusing(count_PBSF*) // *merge 1:1 hhid using "$dta/auxiliar_PNBSF.dta", nogen keepusing(count_PBSF*)



gen new_beneficiaire_PNBSF=0

levelsof departement, local(department)

foreach var of local department { 
	replace new_beneficiaire_PNBSF=1 if count_PBSF_`var'<= ${PNBSF_Beneficiaires`var'}*${PNBSF_benef_increase} & departement==`var'
} 

keep hhid hhweight new_beneficiaire_PNBSF

sum  new_beneficiaire_PNBSF [aw=hhweight]


tempfile new_PNBSF
save `new_PNBSF', replace 











