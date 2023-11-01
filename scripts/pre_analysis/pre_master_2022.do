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

*Dataset for electricity 
include "$p_scr/pre_analysis/08_subsidies_elect_2022.do"

*Create purchases database
use "$path_raw/../../Dataout/ehcvm_conso_SEN_2021.dta", clear
keep if modep==1
collapse (sum) depan, by(hhid grappe menage hhweight codpr)
save "$path_ceq/2_pre_sim/05_purchases_hhid_codpr_2021.dta", replace 

*Dataset for fuel 
include "$p_scr/pre_analysis/08_fuel_subsidies_2022.do"

*Dataset for fuel 
import excel using "$p_res/${namexls}.xlsx", clear first sheet(IO_perc_long)
drop nompr
save "$path_ceq/IO_percentage_2021.dta", replace
