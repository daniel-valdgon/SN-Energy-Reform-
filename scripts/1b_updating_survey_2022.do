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

use "$path_raw/../../Dataout/ehcvm_conso_SEN_2021.dta", clear

keep if inlist(modep,1,2,3,4,5)

collapse (sum) depan, by(hhid grappe menage hhweight)

*merge 1:1 hhid grappe menage using "$path_raw/../../Dataout/Temp/hhsize.dta", keepusing (hhsize) nogen
merge 1:1 hhid grappe menage using "$path_raw/../../Dataout/ehcvm_welfare_SEN_2021.dta", nogen
*merge 1:1 hhid using "$path_raw/../../Dataout/ehcvm_welfare_1a_SEN_2021.dta", nogen
/*
gen la=ln(depan)
gen ld=ln(dtot)
gen dif=depan-dtot
gen ldif=la-ld
sum depan dtot dif ldif
twoway (kdensity la) (kdensity ld) 
kdensity ldif
twoway (scatter la ld, msize(tiny)) (line la la, sort), legend(off)
*/
gen yd_pc = dtot/hhsize
gen depan_pc = depan/hhsize
gen pondih = hhweight*hhsize

*We need new income deciles
set seed 8932
_ebin yd_pc [aw=pondih], nq(10) gen(yd_deciles_pc) // Other option is quantiles but EPL use _ebin command 
label var yd_pc "Baseline disposable income"

gen all=1

tempfile output
save `output', replace 


/*===============================================================================================
*----------------Electricity consumption 
 ==============================================================================================*/

use "$path_ceq/2_pre_sim/08_subsidies_elect_2021.dta", clear    
	
	ren prepaid_woyofal prepaid 
	keep hhid prix_electricite consumption_electricite type_client prepaid  periodicite   consumption_DGP  s11q23a   // prepaid_or s00q01 s00q02 s00q04 tranche1 tranche2 tranche3
	
	merge 1:1  hhid using `output', keepusing(hhweight) nogen // weight updated 
	
tempfile elec_tmp_dta
save `elec_tmp_dta', replace 


/*===============================================================================================
*----------------Fuel 
 ==============================================================================================*/

use "$path_ceq/2_pre_sim/08_subsidies_fuel_2021.dta", clear   
	keep hhid q_fuel q_pet_lamp q_butane
	
	*replace q_fuel=q_fuel*(${fuel_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	*replace q_pet_lamp=q_pet_lamp*(${pet_lamp_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	*replace q_butane=q_butane*(${butane_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	
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

	import excel "$path_ceq/IO_Matrix.xlsx", sheet("IO_aij") firstrow clear
		
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
	import excel "$path_ceq/prod_sect_Xwalk_2021.xlsx", sheet("Xwalk") firstrow clear
	
		merge 1:m codpr using "$path_ceq/IO_percentage_2021.dta", nogen 	// Adding weights for products that belong to multiple sectors  
	
		merge m:1 Secteur  using  `io_fuel_sv_yr',  nogen keep(matched) 		//Adding indirect subsidies 1	agriculture vivriere  8	fabrication de produits a base 15	fabrication de produits en cao, 18	fabrication de machines , 23	construction is not part of the consumption aggregate hence of the prod sector Xwalk 
		
		replace  pind_shock=pind_shock*pourcentage // to compute the weighted average by product as weighted average by sectors  
			
		collapse (sum) pind_shock, by(codpr)
	
	tempfile Xwalk_IO_est_fuel_yr
	save `Xwalk_IO_est_fuel_yr', replace 
	
*Indirect effects of subsidies 
	use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr_2021.dta", clear 
		
		merge m:1 codpr using `Xwalk_IO_est_fuel_yr' , assert(matched using) keep(matched) nogen  
		
		*Spending in real prices of the simulated year 
		*replace depan=depan*(1+${inf_20}/100)*(1+${inf_21}/100)*(1+${inf_22}/100)
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