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

global path "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform"
global path_ceq 	"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\JTR\Energy_reform\data/raw"

*******************************Validation of andres an I code ***********
local onestep=1 // ==1 is to assing old and new beneficiaries in one step as ssugested by andres
	//==0 is assign first old an later new beneficiaries 
*******************************Validation of andres an I code ***********
global namexls	"PNBSF_reform_Andres"
import excel "$path/results/${namexls}.xlsx", sheet("PNBSF_deps") first clear cellrange(B4)
 
rename Nombredebénéficiares2018 Beneficiaires
rename Montantdutransfertparan Montant

drop if departement==. | RegionDepartement==" General"

egen _tot=total (Beneficiaires)
gen double share=Beneficiaires/_tot
keep departement share Beneficiaires Montant

tempfile deparments_dist
save `deparments_dist', replace 


import excel "$path/results/${namexls}.xlsx", sheet("Other_params") first clear
foreach var of varlist _all{
    global `var' = `var'[1]
}


*===============================================================================
*----------------1. Proxy mean Test Score
*===============================================================================

/*
This is already done in the main model, the output that I need is called 07_dir_trans_PMT.
This database already contains the PMT variable, which I need in order to assign observations to the program.
*/


	set seed 1234
	use  "$path/data/raw/2_pre_sim/07_dir_trans_PMT.dta", replace // hh level dataset 1.7 mlln

	merge m:1 departement using `deparments_dist'
	
	ren pmt_seed rannum
	keep departement hhid hhweight  rannum PMT Beneficiaires share  Montant

	tempfile new_PNBSF
	save `new_PNBSF', replace 

*new_beneficiaire_PNBSF

/*===============================================================================================
*----------------2. Baseline Income and population 
 ==============================================================================================*/

	use "$path_ceq/output.dta", clear 
	
/*------------------------------------------------
Uprating: Population growth, inflation, social programs 
------------------------------------------------*/
	
	*Keep variables 
	keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc

	*Updating population
	clonevar  hhweight_orig=hhweight
	foreach v in pondih hhweight {
		replace `v'=`v'*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
	}

	*Inflation 
	foreach v in yd_pc yn_pc zref am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc {
		replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
	}
	
	*Assingning old beneficiaries 
	merge 1:1 hhid using `new_PNBSF', nogen assert(master matched) 
	
	
	
	*Storing original variables 
	gen ben=am_BNSF_pc>0 & am_BNSF_pc!=.
	bysort departement (PMT rannum): gen initial_ben= sum(hhweight)
	
		//Assigning beneficiaries 
		gen _e1=abs(initial_ben-Beneficiaires)
		bysort departement: egen _e=min(_e1)
		gen _icum=initial_ben if _e==_e1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		drop _icum2_sd _icum _e _e1
			
	
	
	gen am_BNSF_pc_0=(Montant/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	// assert abs(am_BNSF_pc_0-am_BNSF_pc)<1 if am_BNSF_pc_0>0 & am_BNSF_pc_0!=.  // This does not work with the new methodology because of two observations for departement 93 113

	gen ind_BNSF=am_BNSF_pc_0>0 &  am_BNSF_pc_0!=.
	drop initial_ben
	
	gen ben_0 = am_BNSF_pc_0>0 & am_BNSF_pc_0!=.
	egen  double yd_pc_0 = rowtotal(yn_pc am_BNSF_pc_0 am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc)
	
apoverty yd_pc_0  [aw= pondih], varpl(zref)

	
/*=======================================================
		Assigning PNBSF policies 
=========================================================*/
*NO SE PUEDE USAR EN UN SOLO STEP PMT  Y LUEGO RANDOM SIN HACER EL TRUCO DE ANDRES	
	if `onestep'==1 {	
		gen exp_benef=(Beneficiaires*${PNBSF_benef_increase})
	}
	if `onestep'==0 {	
		gen exp_benef=round(Beneficiaires*(${PNBSF_benef_increase}-1))
	}
	
	*Geographical + PMT (method 2)
if `onestep'==0 {	
		
	bysort departement (PMT rannum): 	gen cum_t2= sum(hhweight) if ind_BNSF==0
}
if `onestep'==1 {	
		
	bysort departement (PMT rannum): 	gen cum_t2= sum(hhweight) 
}
		
			//Assigning beneficiaries 
			gen _e1=abs(cum_t2-exp_benef)
			bysort departement: egen _e=min(_e1)
			gen _icum=cum_t2 if _e==_e1
			bysort departement: egen exp_benef_i2=total(_icum)
			bysort departement: egen _icum2_sd=sd(_icum)
			*assert _icum2_sd!=0
			drop _icum2_sd _icum _e _e1
		
		gen am_BNSF_pc_2=(Montant/hhsize)*(cum_t2<=exp_benef_i2 ) //exp_benef 
		

		gen ben2=(am_BNSF_pc_2>0 | am_BNSF_pc_0>0 )
		
		if `onestep'==1 {	
		egen  double yd_pc_2 = rowtotal(yn_pc am_BNSF_pc_2 am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc)
		apoverty yd_pc_2 [aw= pondih], varpl(zref)
		ta ben2 [iw=hhweight]

		}

		if `onestep'==0 {	
		egen yd_pc_2= rowtotal(yd_pc_0 am_BNSF_pc_2)
		
		apoverty yd_pc_2 [aw= pondih], varpl(zref)
		ta ben2 [iw=hhweight]
		}


exit 	
	
	
	
	
	
	
	
	
	
	
	*Geographical (method 1)
		bysort departement (rannum): 		gen cum_t1= sum(hhweight) if ind_BNSF==0
			
			//Assigning beneficiaries 
			gen _e1=abs(cum_t1-exp_benef)
			bysort departement: egen _e=min(_e1)
			gen _icum=cum_t1 if _e==_e1
			bysort departement: egen exp_benef_i1=total(_icum)
			bysort departement: egen _icum2_sd=sd(_icum)
			*assert _icum2_sd!=0
			drop _icum2_sd _icum _e _e1
			
		gen am_BNSF_pc_1=(Montant/hhsize)*(cum_t1<=exp_benef_i1 ) //  
		
	if `onestep'==1 {	
		egen  double yd_pc_1 = rowtotal(yn_pc am_BNSF_pc_1 am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc)
	}
		


apoverty yd_pc_0  [aw= pondih], varpl(zref)
local p_0= 	`r(head_1)'
apoverty yd_pc_1 [aw= pondih], varpl(zref)
local p_1= 	`r(head_1)'
apoverty yd_pc_2 [aw= pondih], varpl(zref)
local p_2= 	`r(head_1)'


dis "geo" 
dis `p_0'-`p_1'
dis "geo+pmt" 
dis `p_0'-`p_2'








exit 

separated to test the actual differences 



	*Retroactive payments 
		gen am_BNSF_pc_3=100000/hhsize if ind_BNSF==1
	
	*Benefit increase 
		gen am_BNSF_pc_4=40000/hhsize if ind_BNSF==1
	
	*Benefit increase + payments
	gen am_BNSF_pc_5=140000/hhsize if ind_BNSF==1
	



	
/*=======================================================
		Recompouting beneficiaries and income
=========================================================*/
	
	foreach targeting in  1 2 3 4 5 {
		
		gen ben_`targeting'=am_BNSF_pc_`targeting'>0 & am_BNSF_pc_`targeting'!=.
		
		egen  double yd_pc_`targeting' = rowtotal(yn_pc am_BNSF_pc_0 am_BNSF_pc_`targeting' am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc)
		replace yd_pc_`targeting'=0 if yd_pc_`targeting'==.
	}
	
	label var yd_pc 	"Disposable income"
	label var yd_pc_0 	"Baseline di uprated"
	label var yd_pc_1 	"Baseline di +  geo"
	label var yd_pc_2 	"Baseline di +  geo+ pmt"
	label var yd_pc_3 	"Baseline di +  previous payment"
	label var yd_pc_4 	"Baseline di +  increase"
	label var yd_pc_5	"Baseline di +  increase + previous payment"
	
	
	set seed 8932
	_ebin yd_pc_0 [aw=pondih], nq(10) gen(yd_deciles_pc_0) // Other option is quantiles but EPL use _ebin command 
	recode yd_deciles_pc_0 (0=.) // one case which should not be missing 
	
	drop rannum Beneficiaires Montant share
	
	tempfile data
	save `data', replace 
	
	preserve 
		sp_groupfunction [aw=pondih], gini(yd_pc*) theil(yd_pc*) poverty(yd_pc*) povertyline(zref)  by(all) 
		keep if measure=="fgt0" | measure=="gini"
		replace value=100*value
		export excel using "$path/results/${namexls}.xlsx", sheet(poverty_ineq)  sheetreplace  firstrow(var) 
	restore 
	
	
	preserve 
	collapse (sum) ben* [iw=hhweight], by(yd_deciles_pc_0)
		reshape long ben_ , i(yd_deciles_pc_0) j(simulation)
		label define simulation 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"  
		label value simulation simulation
		
		replace ben=ben/1000
		replace ben_=ben_/1000
		
		ren ben orig_ben
		export excel using "$path/results/${namexls}.xlsx", sheet(beneficiaries)  sheetreplace firstrow(var)


	restore 
	
	
	



*export statistics

use `dep_stats_0', clear
merge 1:1 departement using  `dep_stats_1'
export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_dep) first(variable) sheetreplace 



use `deciles_0', clear
merge 1:1 yd_deciles_pc using  `deciles_1'
export excel "$p_res/${namexls}.xlsx", sheet(benefs_by_decile) first(variable) sheetreplace 


use `sp_0', clear
append using  `sp_1'
export excel "$p_res/${namexls}.xlsx", sheet(stats) first(variable) sheetreplace 




