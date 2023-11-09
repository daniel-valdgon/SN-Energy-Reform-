/*============================================================================================
 ======================================================================================

	Project:   		VAT and Subsidies Tranche
	Author: 	    Daniel Valderrama & Andres Gallegos
	Creation Date:  Feb 13, 2023
	Modified:		Feb 16, 2023
	
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

if "`c(username)'"=="wb419055" {
	
	global proj	"C:\Users\wb419055\OneDrive - WBG\West Africa\Senegal\Senegal_tool\Projects\01_Energy_reform" // project folder
	
	global p_scr 	"$proj/scripts"
	global p_res	"$proj/results"
	
	*Prepare data on consumption 
	global path_raw1 "C:/Users/wb419055/OneDrive - WBG/West Africa/Senegal/data/EHCVM/EHCVM_2021/Datain/Menage"
	global path_raw2 "C:/Users/wb419055/OneDrive - WBG/West Africa/Senegal/data/EHCVM/EHCVM_2021/Dataout"
	global path_raw  "C:/Users/wb419055/OneDrive - WBG/West Africa/Senegal/data/EHCVM/EHCVM_2021/Datain/Menage"
	
	
	global path_ceq "C:\Users\wb419055\OneDrive - WBG\West Africa\Senegal\JTR\Energy_reform/data/raw"
	global presim	"C:\Users\wb419055\OneDrive - WBG\West Africa\Senegal\JTR\Energy_reform/data/raw/2_pre_sim"
	
	global p_o 		"$proj/data/output"
	
} 

if "`c(username)'"=="andre" {
	
	global proj	"C:\Users\andre\Dropbox\Energy_Reform" // project folder
	
	*Prepare data on consumption 
	global path_raw "$proj/EHCVM2021/Datain/Menage"
	global path_raw1 "$proj/EHCVM2021/Datain/Menage"
	global path_raw2 "$proj/EHCVM2021/Dataout"
	global path_ceq  "$proj/data/raw"
	global p_scr 	 "$proj/SN-Energy-Reform-/scripts"
	*global p_res	 "$proj/results"
	global p_res	 "$proj/SN-Energy-Reform-/results"
	
	global p_o 		"$proj/data/output"
	global p_pre 	"$proj/pre_analysis"
	global presim	"$proj/data/raw/2_pre_sim"

	
} 




*===============================================================================
// Run necessary ado files
*===============================================================================

local files : dir "$p_scr/_ado" files "*.ado"
foreach f of local files {
	display("`f'")
	qui: cap run "$p_scr/_ado/`f'"
}

foreach f in missings gtools {
	cap which `f'
	if _rc ssc install `f'
	
}


cap log close
log using "$proj/docs/log_fullmodel.smcl", replace

/*
foreach adof in apoverty ftools gtools ereplace mdesc{
	cap ssc install `adof'
}
*/

*global namexls	"simul_results_New_SocialTranche_Reform2_p1"
*global namexls	"simul_results_New_SocialTranche_2022"
global namexls	"simul_results_2022_ReformMitigations"
*global namexls	"simul_results_VAT"
global numscenarios 1 2 3 4


/*===============================================================================================
	Pre-simulation
 ==============================================================================================*/

include "$p_scr/pre_analysis/pre_master_2022.do" // numscenarios needs to be run first because this do-file calls paramters 

/*===============================================================================================
	Load pmts 
 ==============================================================================================*/

include "$p_scr/0_pull_pmts.do" // we need to load parameters again because pre_simulation reset them 

*Running multiple scenarios
foreach scenario in $numscenarios {

/*===============================================================================================
		Preparing data:
 ==============================================================================================*/
	 
	*Rename parameters to the correspondent scenario
	*local scenario 1                                                 //Uncomment this to run tests renaming parameters for just one scenario
	include "$p_scr/1a_rename_pmts.do"


	*Uprating
	include "$p_scr/1b_updating_survey_2022.do" //include "$p_scr/1b_updating_survey_old.do"

/*===============================================================================================
		Simulation 
 ==============================================================================================*/

	*Electricity 
	include "$p_scr/2a_electricity_FullPrice${full_tariffs_elec}_2022.do"

	*Fuels 
	include "$p_scr/2b_fuels_2022.do" // include "$p_scr/2b_fuels_old.do" 
	
	*Mitigation policy 
	include "$p_scr/2c_mitigations_2022.do" // include "$p_scr/2b_fuels_old.do" 

	* Load CEQ data and compute parameters and and export into results 
	include "$p_scr/3a_outputs.do" //Note: this produces a tempfile per scenario

}

* Append all scenarios and export to Excel

clear
foreach scenario in $numscenarios{
	append using `theyd_deciles_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(stats) first(variable) sheetreplace 


/*===============================================================================================
	Calibration stats and other stats
 ==============================================================================================*/
/*
clear
foreach scenario in $numscenarios{
	append using `calib_`scenario''
}
export excel "$p_res/${namexls}.xlsx", sheet(calibdata) first(variable) sheetreplace 
*/


*Tables of electricity consumption type per decile 

*loop para tener esta tabla para cada scenario
include "$p_scr/3e_survey_totals.do" // include "$p_scr/2b_fuels_old.do" 

shell ! "$p_res/${namexls}.xlsx"




log close
translate "$proj/docs/log_fullmodel.smcl" "$proj/docs/log_fullmodel.pdf",replace
exit 





























		