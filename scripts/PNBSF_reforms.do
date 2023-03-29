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

clear all
macro drop _all 

if "`c(username)'"=="WB419055" {
	global path 		"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\results"
	global p_res 		"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\results"
	global path_ceq 	"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\data/raw"
	global presim 		"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\data\raw\2_pre_sim"
	global scripts 	"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\scripts"
	
	}
else {
global path "C:\Users\andre\Dropbox\Energy_Reform\results"
global p_res "C:\Users\andre\Dropbox\Energy_Reform/SN-Energy-Reform-/results"
}

run "$scripts/_ado/_ebin.ado"



global namexls	"PNBSF_reform_Andres"
 
*Let's import the department parameters as a database, to do the same thing as with the main tool
import excel "$p_res/${namexls}.xlsx", sheet("PNBSF_deps") first clear cellrange(B4)
rename Nombredebénéficiares2018 Beneficiaires
rename Montantdutransfertparan Montant
drop if departement==. | RegionDepartement==" General"
egen _tot=total (Beneficiaires)
gen double share=Beneficiaires/_tot
keep departement share Beneficiaires Montant
tempfile deparments_dist
save `deparments_dist', replace 

import excel "$p_res/${namexls}.xlsx", sheet("Other_params") first clear
foreach var of varlist _all{
    global `var' = `var'[1]
}


*===============================================================================
*----------------1. Create main database as in 1b_updating
*===============================================================================



use "$path_ceq/output.dta", clear 

*Updating 
keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc 

*Updating population
clonevar  hhweight_orig=hhweight
foreach v in pondih hhweight {
	replace `v'=`v'*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
}

*If we fix PNSF transfers to 2018 prices and uprate the net market income and the other transfers:
foreach v in yn_pc zref am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc {
	replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
}

*Include PMT data to exclude extra-households that should not be
merge 1:1 hhid using "$presim/07_dir_trans_PMT.dta", keepusing(PMT pmt_seed departement) nogen
rename pmt_seed rannum

merge m:1 departement using `deparments_dist', nogen

*Assigning PNBSF beneficiaries (approx. 300,551) using the "closest weight" algorithm
*0. Baseline
	bysort departement (PMT rannum): gen initial_ben= sum(hhweight)
	gen _e1=abs(initial_ben-Beneficiaires)
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	
	
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_0=(Montant/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*===============================================================================
*----------------2. New incomes as in 2c_mitigations
*===============================================================================


*1. Expansion of beneficiaries using PMT
	gen _e1=abs(initial_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert Beneficiaires_i==_icum if _icum!=.
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_1=(Montant/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*2. Expansion of beneficiaries using random
	gen PMT_trimmed = PMT
	replace PMT_trimmed=100 if am_BNSF_pc_0==0 //The number does not matter, it just has to be large enough 
	bysort departement (PMT_trimmed rannum): gen rand_ben= sum(hhweight) 
	gen _e1=abs(rand_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=rand_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_2=(Montant/hhsize)*(rand_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*3. Payment of delayed disbursements
	gen _e1=abs(initial_ben-Beneficiaires)
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_3=((2*Montant)/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*4. Increase in benefits from 100K to 140K  (Not need to assign again beneficiaries to risky/costly  to have twice the same procedure if not needed 
	gen _e1=abs(initial_ben-Beneficiaires)
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_4=((Montant+${PNBSF_transfer_increase})/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*5. Expansion of beneficiaries using PMT & transfer increase
	gen _e1=abs(initial_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_5=((Montant+${PNBSF_transfer_increase})/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*6. Expansion of beneficiaries using random & transfer increase
	gen _e1=abs(rand_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=rand_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_6=((Montant+${PNBSF_transfer_increase})/hhsize)*(rand_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i


*7. Expansion of beneficiaries using PMT & transfer increase & delayed disbursements
	gen _e1=abs(initial_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_7=((Montant+${PNBSF_transfer_increase})/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	replace am_BNSF_pc_7=am_BNSF_pc_7+(Montant/hhsize) if am_BNSF_pc_0!=0
	drop Beneficiaires_i


*8. Expansion of beneficiaries using random & transfer increase & delayed disbursements
	gen _e1=abs(rand_ben-(Beneficiaires*${PNBSF_benef_increase}))
	bysort departement: egen _e=min(_e1)
	gen _icum=rand_ben if _e==_e1
	bysort departement: egen Beneficiaires_i=total(_icum)
	bysort departement: egen _icum2_sd=sd(_icum)
	assert _icum2_sd!=0
	drop _icum2_sd _icum _e _e1
	gen am_BNSF_pc_8=((Montant+${PNBSF_transfer_increase})/hhsize)*(rand_ben<=Beneficiaires_i) // Beneficiaires 
	replace am_BNSF_pc_8=am_BNSF_pc_8+(Montant/hhsize) if am_BNSF_pc_0!=0
	drop Beneficiaires_i



forval i=0/8{
	egen  double yd_pc_`i' = rowtotal(yn_pc am_bourse_pc am_Cantine_pc am_BNSF_pc_`i' am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc) 
}


*We need new income deciles, which should be based on the baseline disposable income
rename yd_deciles_pc old_yd_deciles_pc
set seed 8932
_ebin yd_pc_0 [aw=pondih], nq(10) gen(yd_deciles_pc) // Other option is quantiles but EPL use _ebin command 
recode yd_deciles_pc (0=.) // one case which should not be missing 
label var yd_pc_0 "Baseline disposable income"
label var yd_pc_1 "Baseline + PMT"
label var yd_pc_2 "Baseline + Random"
label var yd_pc_3 "Baseline + Delayed"
label var yd_pc_4 "Baseline + Increase"
label var yd_pc_5 "Baseline + PMT + Increase"
label var yd_pc_6 "Baseline + Random + Increase"
label var yd_pc_7 "Baseline + PMT + Increase + Delayed"
label var yd_pc_8 "Baseline + Random + Increase + Delayed"

*===============================================================================
*----------------3. Outputs
*===============================================================================

*1. Department statistics
	preserve
		forval i=0/8{
			gen benefs_`i'=(am_BNSF_pc_`i'>0)
			replace am_BNSF_pc_`i'=. if am_BNSF_pc_`i'==0
		}
		
		collapse (sum) benefs_* am_BNSF_pc_* [iw=hhweight], by(departement)
		export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_dep) first(variable) sheetreplace
	restore

*2. Percentage of households per decile
	preserve
		forval i=0/8{
			gen benefs_`i'=(am_BNSF_pc_`i'>0)
		}
		forval i=1/8{
			gen new_benefs_`i'=benefs_`i'-benefs_0
		}
		collapse (sum) benefs_* new_benefs_* [iw=hhweight], by(yd_deciles_pc)
		export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_decile) first(variable) sheetreplace 
	restore

	*3. Poverty and Inequality
	preserve
		sp_groupfunction [aw=pondih], gini(yd_pc_*) theil(yd_pc_*) poverty(yd_pc_*) povertyline(zref)  by(all) 
		keep measure value variable
		reshape wide value, i(variable) j(measure) string
		export excel "$p_res/${namexls}.xlsx", sheet(stats) first(variable) sheetreplace 
	restore




