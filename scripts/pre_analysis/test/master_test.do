/*============================================================================================
 ======================================================================================

	Project:   VAT testing tool 
	Author:     Daniel 
	Creation Date:  Dec 15, 2022
	Modified:		
	
	Note: 
	Pendent: Compute weighted average for DGP 
			 Compute tranches distribution measure
			 Define indicators for set of policies 
	
============================================================================================
============================================================================================*/

/*===============================================================================================
	Setting user specific folder paths
 ==============================================================================================*/
 
clear all
macro drop all
set more off, perm

// Note that scripts folder and project folder can be separated from each other. This gives flexibility for collaborators not needing to share datasets but only code
if "`c(username)'"=="WB419055" {
	
	global proj	"C:/Users/WB419055/OneDrive - WBG/SenSim Tool/JTR/elec_policy_reform" // project folder
	
	*Prepare data on consumption 
	

}

global path_ceq  "$proj/data/raw"
global p_res		"$proj/results"
global p_o 			"$proj/data/output"
global p_pre 		"$proj/pre_analysis"
global p_scr 		"$proj/scripts"
global p_scr_test 	"$proj/scripts/test"

local debug "single_policy"


/*===============================================================================================
	Save manual computations 
 ==============================================================================================*/

import excel using "$path_ceq/simulated_household_survey.xlsx", sheet(simulated_survey2) firstrow clear 

egen total_vat=rowtotal(vat3_baseline vat2_baseline vat1_baseline)
keep hhid  tranche_1  tranche_2 tranche_3  vat1_baseline vat2_baseline vat3_baseline subvention_t1 subvention_t2 subvention_t3 total_subvention total_vat

*rename variables to compare 
ren tranche_1 tranche1_tool 
ren tranche_2 tranche2_tool 
ren tranche_3 tranche3_tool 
ren vat1_baseline vat_t1 
ren vat2_baseline vat_t2 
ren vat3_baseline vat_t3 
ren subvention_t1 subsidy1 
ren subvention_t2 subsidy2
ren subvention_t3 subsidy3
ren total_vat vat_elec
ren total_subvention subsidy_elec

*Manual 
foreach v in tranche1_tool  tranche2_tool tranche3_tool  vat_t1 vat_t2 vat_t3 subsidy1 subsidy2 subsidy3 subsidy_elec vat_elec {
rename `v' manual_`v'
}

drop if hhid==.
tempfile manual 
save `manual', replace 


/*===============================================================================================
	Save excel data as microdata 
 ==============================================================================================*/

import excel using "$path_ceq/simulated_household_survey.xlsx", sheet(simulated_survey2) firstrow clear 
drop if hhid==.
save "$path_ceq/output_manual.dta", replace    


/*===============================================================================================
	Run :  
 ==============================================================================================*/

//Load original do-file loaded from p_scr
include "$p_scr/1_c_policy_single.do"

//Load original do-file loaded from p_scr 
use "$path_ceq/output_manual.dta", clear   
	keep hhid consumption_electricite type_client prepaid yd_deciles_pc yd_pc // hhweight hhsize pondih all zref
	tempfile mdta
save `mdta', replace 
	
include "$p_scr/1_d_simulation.do" // not a special do-file inside p_scr_test because of the lone below 

save "$p_o/output_elec_sub_vat_1_simul_dta.dta", replace //

/*===============================================================================================
	Compute dif and produce report 
 ==============================================================================================*/


use "$p_o/output_elec_sub_vat_1_simul_dta.dta", clear // final resutls from algorithm 

merge 1:1 hhid using `manual'

foreach v in tranche1_tool tranche2_tool tranche3_tool vat_t3 vat_t2 vat_t1 vat_elec subsidy1 subsidy2 subsidy3 subsidy_elec {
	
	gen dif_`v'=round(`v')!=round(manual_`v')
	replace dif_`v'=dif_`v'*100 // to make from 0-100
}


gen all=1
collapse (mean) dif_*, by(all)

export excel using "$p_o/test.xlsx", sheet(test_results) first(var) replace 

shell ! "$p_o/test.xlsx"
 
exit 
