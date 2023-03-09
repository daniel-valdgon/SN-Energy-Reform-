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
*----------------Income and population 
 ==============================================================================================*/

use "$path_ceq/output.dta", clear 

*Updating 
keep  hhid yd_deciles_pc yd_pc  hhsize pondih all zref hhweight

*Updating population
clonevar  hhweight_orig=hhweight
foreach v in pondih hhweight {
	replace `v'=`v'*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
}


*Updating disposable income by inflation only (does not necesarily match growth in elec consumption) 
foreach v in yd_pc zref {
	replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
}


tempfile output
save `output', replace 

/*

/*===============================================================================================
*----------------Electricity consumption 
 ==============================================================================================*/

use "$path_ceq/2_pre_sim/08_subsidies_elect.dta", clear    
	
*------------ Defining parameters for stats before and after ------------- 
*-> Prepaid 
	global p_dpp_pre_t1 300
	global p_dpp_pre_t2 500
	
	global p_dmp_pre_t1 100
	global p_dmp_pre_t2 600
	
	
*-> Postpaid 
	global p_dpp_pos_t1 150
	global p_dpp_pos_t2 250
	
	global p_dmp_pos_t1 50
	global p_dmp_pos_t2 300
		
*------------  saving variable to compute stats before the change 
clonevar consumption_electricite_before= consumption_electricite  
clonevar hhweight_before = hhweight  
clonevar prepaid_before = prepaid_o 
drop hhweight

	
*----------- Uprating 
	ren prepaid_woyofal prepaid 
	keep hhid prix_electricite consumption_electricite type_client prepaid  periodicite   consumption_DGP  s11q24a *before  // prepaid_or s00q01 s00q02 s00q04 tranche1 tranche2 tranche3
	
	merge 1:1  hhid using `output', keepusing(hhweight hhweight_orig) nogen // weight updated 
	
	
	replace consumption_electricite=consumption_electricite*(${elec_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	
	clonevar consumption_electricite_after =consumption_electricite 
	clonevar hhweight_after= hhweight 
	clonevar prepaid_after = prepaid 

	tempfile tmp_for_cal_stats
	save `tmp_for_cal_stats'
	
	drop *_before *_after
	
tempfile elec_tmp_dta
save `elec_tmp_dta', replace 


*/



/*===============================================================================================
*----------------Fuel 
 ==============================================================================================*/

use "$path_ceq/2_pre_sim/08_subsidies_fuel.dta", clear   
	keep hhid q_fuel q_pet_lamp q_butane
	
	replace q_fuel=q_fuel*(${fuel_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	replace q_pet_lamp=q_pet_lamp*(${pet_lamp_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	replace q_butane=q_butane*(${butane_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	
	tempfile fuel_tmp_dta
save `fuel_tmp_dta', replace 

merge 1:1  hhid using `output', keepusing(hhweight hhweight_orig) nogen // weight updated 

sum q_* [aw=hhweight]



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

gen tariff_baseline_pkwh = (cost_elec_s1-subsidy_elec_s1)/(6*consumption_electricite)

gen tariff_reform_pkwh = (cost_elec-subsidy_elec)/(6*consumption_electricite)

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

























