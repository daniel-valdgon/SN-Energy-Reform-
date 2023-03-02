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
if "`c(username)'"=="WB419055" {
	global proj	"C:/Users/WB419055/OneDrive - WBG/SenSim Tool/JTR/Energy_reform" // project folder
	
	*Prepare data on consumption 
	global path_raw "$proj/data/raw"
	*global path_ceq "$proj/data/raw"
	global path_ceq  "C:/Users/WB419055/OneDrive - WBG/SenSim Tool/Senegal_tool/Senegal_tool/01. Data"
	
} 
if "`c(username)'"=="andre" {
	global proj	"C:\Users\andre\Dropbox\Energy_Reform" // project folder
	
	*Prepare data on consumption 
	global path_raw "$proj/data/raw"
	global path_ceq "$proj/data/raw"
	*global path_ceq  "C:/Users/WB419055/OneDrive - WBG/SenSim Tool/Senegal_tool/Senegal_tool/01. Data"
	
}


global p_res	"$proj/results"
global p_o 		"$proj/data/output"
global p_pre 	"$proj/pre_analysis"
global p_scr 	"$proj/scripts"

local debug "single_policy"

*===============================================================================
// Run necessary ado files
*===============================================================================
		
local files : dir "$p_scr/_ado" files "*.ado"
foreach f of local files {
	display("`f'")
	qui: cap run "$p_scr/_ado/`f'"
}

/*
*foreach adof in apoverty ftools gtools ereplace missings {
*	cap ssc install `adof'
}
*/

global namexls	"simul_results"
global numscenarios 1 2 3 4

/*===============================================================================================
	Pulling parameters 
 ==============================================================================================*/

include "$p_scr/0_pull_pmts.do" // The main difference of this code is that it takes all decimal points of parameters


*Running multiple scenarios 

foreach scenario in $numscenarios {

/*===============================================================================================
	Preparing data:
==============================================================================================*/
 
*Rename parameters to the correspondent scenario
include "$p_scr/1a_rename_pmts.do"


*Uprating
include "$p_scr/1b_updating_survey.do"

dsadsa

/*===============================================================================================
	Simulation 
 ==============================================================================================*/
*Electricity 
include "$p_scr/2a_electricity.do"


*Fuels 
include "$p_scr/2b_fuels.do" 


* Load CEQ data and compute parameters and and export into results 
include "$p_scr/3a_outputs.do" //Note: this produces a temfile per scenario

}

* Append all scenarios and export to Excel

clear
foreach scenario in $numscenarios{
	append using `theyd_deciles_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(stats) first(variable) sheetreplace 
exit 








































/*
*---| cargas tu policy dataset
*calculas en tu microdata y guardas resultados no mas , pegados de tu policy id_code: vat_1 vat_2 vat_3 + vat_total same for subsidies, hhid ...al cual le pegamos el disposable income 

*---| Luego un do-file que procese resultados 
*haces append de esos resultados

10 deciles (coverage)  X 3 tranches 
10 deciles reltaive incidence
10 deciles absolute incidence

Indicators: pobreza, gini and all, marginal values manually based on ...... disposable income 
 
Indicators collection





		