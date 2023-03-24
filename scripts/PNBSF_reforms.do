/*============================================================================================
 ======================================================================================

	Project:   VAT and Subsidies Tranche
	Author:     Daniel 
	Creation Date:  Dec 15, 2022
	Modified:		
	
	Note: *Update population using WDI data growth rates 2019-2022
		   *Update disposable income by inflation 2019-2022 (conservative scenario) 
			other option was private pc consumption

			*Update Electricity consumption using real data on elec consumption 
			*Keep quantities of fuel consumed at same levels until having a better estimate of growth rate
============================================================================================
============================================================================================*/


/*===============================================================================================
*----------------0. Geographical and uprating parameters 
 ==============================================================================================*/

global namexls	"PNBSF_reform"

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

import excel "$p_res/${namexls}.xlsx", sheet("Other_params") first clear
foreach var of varlist _all{
    global `var' = `var'[1]
}





foreach targeting in 0 1{


	*===============================================================================
	*----------------1. Proxy mean Test Score
	*===============================================================================

	/*
	This is already done in the main model, the output that I need is called 07_dir_trans_PMT.
	This database already contains the PMT variable, which I need in order to assign observations to the program.
	*/

	*local targeting 0
	
	set seed 1234
	use  "$presim/07_dir_trans_PMT.dta", replace // hh level dataset 1.7 mlln

	ren pmt_seed rannum

	sort departement PMT rannum

	levelsof departement, local(department)

	foreach var of local department {
		gen count_PBSF_`var' = sum(hhweight) if departement==`var'
	}

	gen new_beneficiaire_PNBSF=0
	gen new_beneficiaire_PNBSF_menos=0


	if `targeting' == 1{
		levelsof departement, local(department)
		foreach var of local department { 
			replace new_beneficiaire_PNBSF=1 if count_PBSF_`var'<= ${PNBSF_Beneficiaires`var'}*${PNBSF_benef_increase} & departement==`var'
			*gen dif = abs(count_PBSF_`var'- ${PNBSF_Beneficiaires`var'}*${PNBSF_benef_increase})
			*replace new_beneficiaire_PNBSF=1 if dif<=dif[_n-1] & departement==`var'
			*drop dif
		} 
	}

	if `targeting' == 0{
		sort departement rannum
		levelsof departement, local(department)
		foreach var of local department { 
			replace new_beneficiaire_PNBSF=1 if count_PBSF_`var'<= ${PNBSF_Beneficiaires`var'} & departement==`var'
			*I want to modify the increase taking into account the households that were not included because of the discrete nature of hhweight
			sum count_PBSF_`var' if new_beneficiaire_PNBSF==1 & departement==`var'
			local hh_included = 0
			if r(N)!=0{
				local hh_included = r(max)
			}
			local hh_notincluded = ${PNBSF_Beneficiaires`var'}-`hh_included'
			dis "${PNBSF_Beneficiaires`var'} - `hh_included' = `hh_notincluded'"
			gen count_random = sum(hhweight) if departement==`var' & new_beneficiaire_PNBSF==0
			replace new_beneficiaire_PNBSF=1 if count_random<= ${PNBSF_Beneficiaires`var'}*(${PNBSF_benef_increase}-1)+`hh_notincluded' & departement==`var'
			drop count_random
		}
	}


	sum  new_beneficiaire_PNBSF [aw=hhweight]
	tab  new_beneficiaire_PNBSF [iw=hhweight]

	tab departement new_beneficiaire_PNBSF [iw=hhweight], mis

	keep departement hhid hhweight new_beneficiaire_PNBSF

	tempfile new_PNBSF
	save `new_PNBSF', replace 




	/*===============================================================================================
	*----------------2. Baseline Income and population 
	 ==============================================================================================*/

	use "$path_ceq/output.dta", clear 

	*Updating 
	keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc

	*Updating population
	clonevar  hhweight_orig=hhweight
	foreach v in pondih hhweight {
		replace `v'=`v'*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
	}

	*We fix transfers to 2018 prices and only uprate the net market income:
	foreach v in yn_pc zref {
		replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
	}
	egen  double yd_pc2 = rowtotal(yn_pc am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc) 
	replace yd_pc2=0 if yd_pc2==.
	replace yd_pc = yd_pc2
	drop yd_pc2

	label var yd_pc "Baseline disposable income"

	tempfile output
	save `output', replace 


	use `output', clear 

	*keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc


	merge 1:1 hhid using `new_PNBSF', nogen
	gen old_beneficiaire_PNBSF = (am_BNSF_pc>0)
	count if old_beneficiaire_PNBSF==1										//Every previous beneficiary...
	local old=r(N)
	count if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==1			//...should continue being one
	local new=r(N)
	assert `old'==`new'

	count if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==0
	dis "There are " r(N) " new beneficiaries of the PNBSF program"
	sum hhweight if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==0
	local hhs_newb = r(mean)*r(N)
	dis as result "There are " `hhs_newb' " new beneficiaries of the PNBSF program"


	gen am_new_pnbsf = 0
	replace am_new_pnbsf = ${PNBSF_transfer_increase} if old_beneficiaire_PNBSF==1
	replace am_new_pnbsf = ${PNBSF_transfer_increase}+100000 if old_beneficiaire_PNBSF==0 & new_beneficiaire_PNBSF==1
	*new disposable income:
	*clonevar yd_pc = yd_pc_before_mitigation 
	*replace yd_pc = yd_pc+am_new_pnbsf_pc
	
	*We need to redefine deciles based on the new disposable income
	rename yd_deciles_pc old_yd_deciles_pc
	sort yd_pc, stable 
	gen gens = sum(pondih)
	sum gens
	replace gens = gens/r(max)
	gen yd_deciles_pc = ceil(gens*10)
	drop gens
	tab yd_deciles_pc [iw=pondih]
	recode yd_deciles_pc (0=.)
	

	*Checking if everything makes sense
	*1. Department statistics
	preserve
		gen new_beneficiaries = hhweight * new_beneficiaire_PNBSF
		gen old_beneficiaries = hhweight * old_beneficiaire_PNBSF
		collapse (sum) *beneficiaries hhweight, by(departement)
		foreach var in new_beneficiaries old_beneficiaries hhweight{
			rename `var' `var'`targeting'
		}
		tempfile dep_stats_`targeting'
		save `dep_stats_`targeting'', replace 	
	restore

	*2. Percentage of households per decile
	preserve
		keep if new_beneficiaire_PNBSF == 1 & old_beneficiaire_PNBSF==0
		collapse (sum) hhweight, by(yd_deciles_pc)
		rename hhweight new_benefs_`targeting'
		tempfile deciles_`targeting'
		save `deciles_`targeting'', replace 	
	restore

	*3. Poverty and Inequality
	preserve
		keep if new_beneficiaire_PNBSF == 1 & old_beneficiaire_PNBSF==0
		collapse (sum) hhweight, by(yd_deciles_pc)
		rename hhweight new_benefs_`targeting'
		tempfile deciles_`targeting'
		save `deciles_`targeting'', replace 	
	restore






}

















*export statistics

use `dep_stats_0', clear
merge 1:1 departement using  `dep_stats_1'
export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_dep) first(variable) sheetreplace 



use `deciles_0', clear
merge 1:1 yd_deciles_pc using  `deciles_1'
export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_decile) first(variable) sheetreplace 
