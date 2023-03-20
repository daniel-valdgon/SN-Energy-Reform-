/*============================================================================================
 ======================================================================================

	Project:		VAT and Subsidies Tranche
	Author:			Andres 
	Creation Date:	Mar 9, 2023
	Modified:		
	
	Note: *Extra tables and graphs
============================================================================================
============================================================================================*/



/*===============================================================================================
*----------------Fuel 
 ==============================================================================================*/

*use `fuel_tmp_dta', clear
use "$path_ceq/2_pre_sim/08_subsidies_fuel.dta", clear   
keep hhid q_fuel q_pet_lamp q_butane

replace q_fuel=q_fuel*(${fuel_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
replace q_pet_lamp=q_pet_lamp*(${pet_lamp_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
replace q_butane=q_butane*(${butane_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	

merge 1:1  hhid using `output', keepusing(hhweight hhweight_orig pondih yd_deciles_pc) nogen // weight updated 

sum q_* [aw=hhweight]

*Plot share of households with positive spending in each fuel category

foreach combust in fuel pet_lamp butane{
    gen p_`combust' = (q_`combust'!=0)
} 

sum p_* [aw=pondih]



/****************************************
Let's check if the average increase in tariffs match the announcement:
	Sur la basse tension, au-delà de 150 KWh, il sera procédé à une hausse moyenne de 
	18,97 FCFA/KWh ; soit 16.62
 ******************************************/
 
use "$proj/data/temp/elec_tmp_scenario1.dta", clear
cap drop _merge
foreach var of varlist s11q24a - yd_deciles_pc{
    rename `var' `var'_s1
}

merge 1:1 hhid using "$proj/data/temp/elec_tmp_scenario2.dta", nogen

gen tariff_baseline_pkwh = (cost_elec_s1-subsidy_elec_direct_s1)/(6*consumption_electricite)

gen tariff_reform_pkwh = (cost_elec-subsidy_elec_direct)/(6*consumption_electricite)

gen increase = tariff_reform_pkwh-tariff_baseline_pkwh

bys type_client:sum increase [aw=pondih]

gen lnincrease=ln(increase)
kdensity lnincrease, xlabel(0 "1" .6931 "2" 1.609 "5" 2.303 "10" 2.9428 "18.97" /*2.996 "20"*/ 3.912 "50" 4.605 "100" 5.298 "200" 6.214 "500" 6.907 "1000" 7.6009025 "2000" 8.517 "5000") xline(2.9428) 

*The reported value in the reform seems to make sense. Now, as a percentage:

gen increase_pcnt = (tariff_reform_pkwh-tariff_baseline_pkwh)/tariff_baseline_pkwh

bys type_client:sum increase_pcnt [aw=pondih]

gen lnincrease_pcnt = ln(increase_pcnt+sqrt(increase_pcnt^2+1))
histogram increase_pcnt [fw=round(pondih)] if increase_pcnt>=0 & increase_pcnt<=1


br if increase_pcnt>1




/****************************************
Table/graph of tranches per decile 
******************************************/

local scenario 1

use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear

gen tranche3 = (tranche3_tool!=0 & tranche3_tool!=.)
gen tranche2 = (tranche2_tool!=0 & tranche2_tool!=. & tranche3==0)
gen tranche1 = (tranche1_tool!=0 & tranche1_tool!=. & tranche3==0 & tranche2==0)

/*Andres formula 
preserve 
	gen tranche_max = tranche1+2*tranche2+3*tranche3
	replace tranche_max = 4 if type_client==3 //DGP
	label def tranches 0 "No electricity spending" 1 "Tranche 1" 2 "Tranche 2" 3 "Tranche 3" 4 "DGP"
	label values tranche_max tranches
	
	tab tranche_max yd_deciles_pc [aw=pondih], mis matcell(tab_elec_tranches)
	
	clear
	svmat tab_elec_tranches
	
	export excel "$p_res/${namexls}.xlsx", sheet(tab_elec_tranches) first(variable) sheetreplace 
restore */

*Daniel's proposal 
*Andres agrees, this is better

	gen  tranche_gdp = type_client==3 //DGP
	collapse (mean) tranche1 tranche2 tranche3 tranche_gdp [aw=pondih], by(yd_deciles_pc)
	gen no_electr_sp=1-(tranche1+ tranche2 + tranche3 + tranche_gdp)
	
	foreach v in no_electr_sp tranche1  tranche2  tranche3  tranche_gdp {
		replace `v'=100*`v'
	}
	
	export excel "$p_res/${namexls}.xlsx", sheet(tab_elec_tranches) first(variable) sheetreplace 

















