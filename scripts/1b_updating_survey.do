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
keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc

*Updating population
clonevar  hhweight_orig=hhweight
foreach v in pondih hhweight {
	replace `v'=`v'*(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) // population growth 2019-2022
}



/*Previous computations uprating all income sources by inflation 
*Updating disposable income by inflation only (does not necesarily match growth in elec consumption) 
foreach v in yd_pc zref {
	replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
}
*/


*If we fix PNSF transfers to 2018 prices and uprate the net market income and the other transfers:
foreach v in yn_pc zref am_bourse_pc am_Cantine_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc am_BNSF_pc {
	replace `v'=`v'*(${inf_20})*(${inf_21})*(${inf_22}) // inflation 2019-2022
}


egen  double yd_pc2 = rowtotal(yn_pc am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc) 
replace yd_pc2=0 if yd_pc2==.
replace yd_pc = yd_pc2
drop yd_pc2
/*
We need new income deciles
rename yd_deciles_pc old_yd_deciles_pc
set seed 8932
_ebin yd_pc [aw=pondih], nq(10) gen(yd_deciles_pc) // Other option is quantiles but EPL use _ebin command 
recode yd_deciles_pc (0=.) // one case which should not be missing 
label var yd_pc "Baseline disposable income"
*/
tempfile output
save `output', replace 


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
	keep hhid prix_electricite consumption_electricite type_client prepaid  periodicite   consumption_DGP  s11q24a *_before   // prepaid_or s00q01 s00q02 s00q04 tranche1 tranche2 tranche3
	
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

*------------  Calibration stats 

foreach data in _before _after { 
	
	use `tmp_for_cal_stats', clear 
	gen tranche1_cons=0
	gen tranche2_cons=0
	gen tranche3_cons=0

	foreach payment in  0 1 {	
		
	if "`payment'"=="1" local freq_pay "pre"
	else if "`payment'"=="0" local freq_pay "pos"
	
			foreach type in 1 2  {
			
			if "`type'"=="1" local type_pay "dpp"
			else if "`type'"=="1" local type_pay "dmp"
					
					replace tranche1_cons=consumption_electricite`data' if consumption_electricite`data'<=${p_`type_pay'_`freq_pay'_t1} & consumption_DGP==0  & type_client==`type' & prepaid`data'==`payment'
					
					replace tranche2_cons=consumption_electricite`data' if consumption_electricite`data'<=${p_`type_pay'_`freq_pay'_t2} & consumption_electricite`data'>${p_`type_pay'_`freq_pay'_t1} &  consumption_DGP==0  & type_client==`type' & prepaid`data'==`payment'
					
					replace tranche3_cons=consumption_electricite`data' if consumption_electricite`data'>${p_`type_pay'_`freq_pay'_t2} &  consumption_DGP==0  & type_client==`type' & prepaid`data'==`payment'
					
			}
		
	}
	
	drop consumption_electricite 
	ren consumption_electricite`data' consumption_electricite 
	drop prepaid
	ren prepaid`data' prepaid
	foreach v in consumption_electricite tranche3_cons tranche2_cons tranche1_cons  {
		replace `v'=`v'*6/1000000
	}

	gen type=type_client ==1 if type_client!=. 
	gen subs=1 if consumption_electricite!=0
	gcollapse (sum) consumption_electricite tranche3_cons tranche2_cons tranche1_cons type subs (mean) prepaid [iw=hhweight`data']
		
	gen data="`data'"
	
	tempfile raw_data_stats`data'
	save `raw_data_stats`data'', replace
}

use `raw_data_stats_before'
append using `raw_data_stats_after'
tempfile calib_`scenario'
save `calib_`scenario'', replace


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


/*===============================================================================================
*----------------Spending data for indirect effects 

Note: Grossing spending by fuel and electricity subsidies of base year 
		We do it only considering indirect effects because direct effect is estimated using quantities
		The main idea is that for non energy goods: 
			Spendig would have been higher (inelastic consumers) in the abscense of subsidies
			That higher spending is our departure point 
 ==============================================================================================*/

*IO prices 
*Note: Values are hardcoded because it correspond to the survey's year

	import excel "$path_raw/IO_Matrix.xlsx", sheet("IO_aij") firstrow clear
		
		*Define fixed sectors 
		gen fixed=0
		replace fixed=1  if inlist( Secteur, 22, 32, 33, 34, 13)
		
		*Shock of fuel subsidies 
		local indfuel_sub_svy= $industryfuel_sub_svy
		
		local subsidy_firms_base = (${cost_firms_svy}-${tar_firms_svy})/${cost_firms_svy}  // use WB energy data for 2021 (similar to IMF 2021) (125.9-115.2)/125.9
		local share_elec_io_base $share_elec_io_base // Share of electricity in the IO sector 
		
		*Old code to delte ==>
		*local indfuel_sub_svy= (-1)*((675 - 655)/675)*0.93 + ((553 - 469)/553)*0.07 // This prices are computed using the cost structure function of 2019 evaluated at international and national prices of 2019. See sheet fuel_survey_reference 
		***//The cost structure of 2019 reports a selling price of 497 for Essence pirogue, not 469 as seen above.
		*local subsidy_firms_base = -(124.4-113.11)/124.4  // tariffs from Petra xls for 2020, weighted using IMF weights 
		*==>
		
		gen 	shock=`indfuel_sub_svy' if inlist(Secteur, 13) // fuel sector 
		replace shock=`subsidy_firms_base'*`share_elec_io_base' if Secteur==22
		
		dis " fuel `indfuel_sub_svy' elec `subsidy_firms_base'"
		
		replace shock=0  if shock==.
		*Indirect effects 
		costpush C1-C35, fixed(fixed) priceshock(shock) genptot(ptot_shock) genpind(pind_shock) fix
		keep Secteur pind_shock
	
	tempfile io_fuel_sv_yr
	save `io_fuel_sv_yr', replace
		
*Product sector X-Walk 
	import excel "$path_raw/prod_sect_Xwalk.xlsx", sheet("Xwalk") firstrow clear
	
		merge 1:m codpr using "$path_ceq/IO_percentage2_clean.dta", nogen 	// Adding weights for products that belong to multiple sectors  
	
		merge m:1 Secteur  using  `io_fuel_sv_yr',  nogen keep(matched) 		//Adding indirect subsidies 1	agriculture vivriere  8	fabrication de produits a base 15	fabrication de produits en cao, 18	fabrication de machines , 23	construction is not part of the consumption aggregate hence of the prod sector Xwalk 
		
		replace  pind_shock=pind_shock*pourcentage // to compute the weighted average by product as weighted average by sectors  
			
		collapse (sum) pind_shock, by(codpr)
	
	tempfile Xwalk_IO_est_fuel_yr
	save `Xwalk_IO_est_fuel_yr', replace 
	
*Indirect effects of subsidies 
	use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr.dta", clear 
		
		merge m:1 codpr using `Xwalk_IO_est_fuel_yr' , assert(matched using) keep(matched) nogen  
		
		*Spending in real prices of the simulated year 
		replace depan=depan*(1+${inf_20}/100)*(1+${inf_21}/100)*(1+${inf_22}/100)
		*Substracting indirect effects 
		gen depan_net_sub=depan/(1-pind_shock) //pind_shock debe ser positivo para que le reste correctamente al 1
		
		*Cleaning 
		keep hhid depan_net_sub codpr
		gcollapse (sum) depan_net_sub, by(hhid codpr) 
	
	tempfile depan_nosubsidy
	save `depan_nosubsidy', replace

	
exit 


/*Notes: exploring the cost push equivalences 



	/* Exercise scaling up consumption:
	Results much different from reality 
	T3 T2 T1 total 
	953.0446	597.6654	452.6704	2003.3804	
	0.475718241	0.298328465	0.225953294
	
	*42.99 percent is the kwh consumed by households according to Gov data given to energy practice World Bank for 2021 (IMF number is 43 percent)
	*4662 is GWH consumed in 2022 according to decree 2022-30
	egen Gwh_base=total(consumption_electricite*6*hhweight/1000000)
	sum Gwh_base
	*replace consumption_electricite=consumption_electricite*(0.4299*4662)/`r(mean)' // 4662 from  Decision 2022-30 and 3668 from Decision 2019-48 Commision du regulation du sector du electircite, since we change weights above this discounts already for population size 
	*/