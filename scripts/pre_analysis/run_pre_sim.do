/*============================================================================================
 ======================================================================================

	Project:   		VAT and Subsidies Tranche
	Author: 	    Daniel Valderrama 
	Creation Date:  Dec 15, 2022
	Modified:		
	
	Note: 
	Pendent: compute weighted average for DGP 
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
global proj "C:\Users\andre\Dropbox\Energy_Reform" // project folder
*Prepare data on consumption
global path_raw "$proj/data/raw"
global path_ceq "$proj/data/raw"
*global path_ceq  "C:/Users/WB419055/OneDrive - WBG/SenSim Tool/Senegal_tool/Senegal_tool/01. Data"
} 


global p_res	"$proj/results"
global p_o 		"$proj/data/output"
global p_pre 	"$proj/pre_analysis"
global p_scr 	"$proj/scripts"
global presim	"$proj/data/raw/2_pre_sim"


local debug "single_policy"

*===============================================================================
// Run necessary ado files
*===============================================================================
		
local files : dir "$p_scr/_ado" files "*.ado"
foreach f of local files {
	display("`f'")
	qui: cap run "$p_scr/_ado/`f'"
}

foreach adof in apoverty ftools ereplace {
cap ssc install `adof'

}


*08 Indirect taxes
include "$p_scr/pre_analysis/08_subsidies_elect.do"

include "$p_scr/pre_analysis/08_fuel_subsidies.do"

