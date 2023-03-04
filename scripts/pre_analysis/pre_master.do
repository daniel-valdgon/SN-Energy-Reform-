/*============================================================================================
 ======================================================================================

	Project:   		VAT and Subsidies 
	Author: 	    Daniel Valderrama 
	Creation Date:  Dec 15, 2022
	Modified:		
	
	Note: 
	
============================================================================================
============================================================================================*/

*Running pre-simulation scenario
include "$p_scr/0_pull_pmts.do" // This code imports all the parameters from Excel, but we only need a couple of them
local scenario 1
include "$p_scr/1a_rename_pmts.do" // This code removes the number of the scenario from the name of each parameter

*Dataset for subsidies 
include "$p_scr/pre_analysis/08_subsidies_elect.do"

include "$p_scr/pre_analysis/08_fuel_subsidies.do"

