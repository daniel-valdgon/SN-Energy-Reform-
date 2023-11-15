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
use "$path_ceq/2_pre_sim/08_subsidies_fuel_2021.dta", clear   
keep hhid q_fuel q_pet_lamp q_butane
/*
replace q_fuel=q_fuel*(${fuel_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
replace q_pet_lamp=q_pet_lamp*(${pet_lamp_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
replace q_butane=q_butane*(${butane_uprating})/(${popgrowth_20})*(${popgrowth_21})*(${popgrowth_22}) //discounting population growth to do the uprating  
	*/

merge 1:1  hhid using `output', keepusing(hhweight pondih yd_deciles_pc) nogen // weight updated 

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
foreach var of varlist s11q23a - yd_deciles_pc{
    rename `var' `var'_s1
}

merge 1:1 hhid using "$proj/data/temp/elec_tmp_scenario2.dta", nogen

gen tariff_baseline_pkwh = (cost_elec_s1-subsidy_elec_direct_s1)/(6*consumption_electricite)

gen tariff_reform_pkwh = (cost_elec-subsidy_elec_direct)/(6*consumption_electricite)

gen increase = tariff_reform_pkwh-tariff_baseline_pkwh

bys type_client:sum increase [aw=pondih]

gen lnincrease=ln(increase)
*kdensity lnincrease, xlabel(0 "1" .6931 "2" 1.609 "5" 2.303 "10" 2.9428 "18.97" /*2.996 "20"*/ 3.912 "50" 4.605 "100" 5.298 "200" 6.214 "500" 6.907 "1000" 7.6009025 "2000" 8.517 "5000") xline(2.9428) 

*The reported value in the reform seems to make sense. Now, as a percentage:

gen increase_pcnt = (tariff_reform_pkwh-tariff_baseline_pkwh)/tariff_baseline_pkwh

bys type_client:sum increase_pcnt [aw=pondih]

gen lnincrease_pcnt = ln(increase_pcnt+sqrt(increase_pcnt^2+1))
*histogram increase_pcnt [fw=round(pondih)] if increase_pcnt>=0 & increase_pcnt<=1


*br if increase_pcnt>1




/****************************************
Table/graph of tranches per decile 
******************************************/

foreach scenario in $numscenarios{

	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear

	gen tranche3 = (tranche_elec_max==3)
	gen tranche2 = (tranche_elec_max==2)
	gen tranche1 = (tranche_elec_max==1)
	gen tranche_sociale = (tranche_elec_max==0.5)
	gen  tranche_gdp = type_client==3 //DGP

	collapse (mean) tranche_sociale tranche1 tranche2 tranche3 tranche_gdp [aw=pondih], by(yd_deciles_pc) fast
	gen no_electr_sp=1-(tranche_sociale + tranche1 + tranche2 + tranche3 + tranche_gdp)

	foreach v in no_electr_sp tranche_sociale tranche1  tranche2  tranche3  tranche_gdp {
		replace `v'=100*`v'
	}
	
	gen scenario = `scenario'
	
	tempfile elec1_`scenario'
	save `elec1_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec1_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(tab_elec_tranches) first(variable) sheetreplace 



/****************************************
Table/graph of cons groups per decile 
******************************************/

foreach scenario in $numscenarios{

	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear

	gen DPP_prep  = (type_client==1 & prepaid==1)
	gen DPP_postp = (type_client==1 & prepaid==0)
	gen DMP_prep  = (type_client==2 & prepaid==1)
	gen DMP_postp = (type_client==2 & prepaid==0)
	gen DGP       = (type_client==3)

	collapse (mean) DPP_prep DPP_postp DMP_prep DMP_postp DGP [aw=pondih], by(yd_deciles_pc) fast
	gen no_electr_sp=1-(DPP_prep + DPP_postp + DMP_prep + DMP_postp + DGP)

	foreach v in no_electr_sp DPP_prep DPP_postp DMP_prep DMP_postp DGP {
		replace `v'=100*`v'
	}

	gen scenario = `scenario'
	
	tempfile elec2_`scenario'
	save `elec2_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec2_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(tab_elec_cons_groups) first(variable) sheetreplace 




/****************************************
Table/graph of Total amounts per tranches
******************************************/

foreach scenario in $numscenarios{
	*local scenario 1
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear

	gen tranche3 = (tranche_elec_max==3)
	gen tranche2 = (tranche_elec_max==2)
	gen tranche1 = (tranche_elec_max==1)
	gen tranche_sociale = (tranche_elec_max==0.5)
	gen tranche_dgp = type_client==3 //DGP
	
	gen totalpaid_elec = consumption_electricite*avg_price_elec*6
	recode totalpaid_elec (.=0)

	collapse (sum) totalpaid_elec vat_elec subsidy_elec_direct subsidy_elec_indirect [aw=hhweight], by(tranche_elec_max tranche_dgp) fast
	
	foreach v in totalpaid_elec vat_elec subsidy_elec_direct subsidy_elec_indirect {
		replace `v'=`v'/1000000
	}
	
	gen scenario = `scenario'
	
	tempfile elec3_`scenario'
	save `elec3_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec3_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(tab_elec_Revenues) first(variable) sheetreplace 




/****************************************
Table/graph of avg. price distributions
******************************************/

foreach scenario in $numscenarios{
	*local scenario 1
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear

	gen tranche3 = (tranche_elec_max==3)
	gen tranche2 = (tranche_elec_max==2)
	gen tranche1 = (tranche_elec_max==1)
	gen tranche_sociale = (tranche_elec_max==0.5)
	gen tranche_dgp = type_client==3 //DGP
	
	
	
	gen totalpaid_elec = consumption_electricite*avg_price_elec/2 //Here we are interested in the monthly electricity cost per household
	recode totalpaid_elec (.=0)
	
	gen lnelec = ln(totalpaid_elec) //No me interesa la gente que no consume electricidad
	
	local nbins 60
	
	sum lnelec
	local rang = `r(max)'-`r(min)'
	local min = `r(min)'
	local wid = `rang'/`nbins'
	gen bins=0 if lnelec<.
	forval k=2/`nbins'{
		replace bins = bins+1 if lnelec>`min'+(`wid')*(`k'-1) & lnelec<.
	}
	tab bins
	
	collapse (sum) tranche_sociale tranche1 tranche2 tranche3 tranche_dgp [iw=pondih], by(bins) fast
	drop if bins==.
	tsset bins
	tsfill
	
	gen binlabel = `min'+`wid'*(bins+0.5)
	replace binlabel=round(exp(binlabel))
	
	
	foreach v of varlist tranche* {
		recode `v' (.=0)
	}
	
	graph bar (asis) tranche_sociale tranche1 tranche2 tranche3 tranche_dgp, over(binlabel, gap(0) label(angle(vertical))) stack legend(ring(0) position(10) label(1 "TS") label(2 "T1") label(3 "T2") label(4 "T3") label(5 "DGP"))
	
	gen scenario = `scenario'
	
	order scenario bins binlabel tranche_sociale tranche1 tranche2 tranche3 tranche_dgp
	
	tempfile elec4_`scenario'
	save `elec4_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec4_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(Distrb_elec_cost) first(variable) sheetreplace 




/****************************************
How do costs change compared to baseline
******************************************/

foreach scenario in 2 3 4{
	*local scenario 3
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear
	
	gen totalpaid_elec = consumption_electricite*avg_price_elec/2 //Here we are interested in the monthly electricity cost per household
	recode totalpaid_elec (.=0)
	
	keep hhid totalpaid_elec
	
	merge 1:1 hhid using "$proj/data/temp/elec_tmp_scenario1.dta", nogen
	
	gen basepaid_elec = consumption_electricite*avg_price_elec/2 //Here we are interested in the monthly electricity cost per household
	recode basepaid_elec (.=0)
	
	gen perc_change = (totalpaid_elec/basepaid_elec) -1
	
	
	collapse (min) min=perc_change (p10) p10=perc_change (p25) p25=perc_change (p50) p50=perc_change (p75) p75=perc_change (p90) p90=perc_change (max) max=perc_change (mean) mean=perc_change [iw=pondih], by(yd_deciles_pc) 
	
	
	gen scenario = `scenario'
	
	order scenario
	
	tempfile elec5_`scenario'
	save `elec5_`scenario'', replace
}

clear
foreach scenario in 2 3 4{
	append using `elec5_`scenario''
}

export excel "$p_res/${namexls}.xlsx", sheet(Perc_change_elec_spend) first(variable) sheetreplace 













/****************************************
Table of avg. price per group
******************************************/

foreach scenario in $numscenarios{
	*local scenario 1
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear
	drop if avg_price_elec==.
	replace prepaid=. if type_client==3 //We only want one group for DGP
	collapse (mean) avg_price_elec [iw=pondih], by(type_client prepaid) fast
	gen scenario = `scenario'
	tempfile elec6_`scenario'
	save `elec6_`scenario'', replace
	
	
	*Now, the same but average overall
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear
	drop if avg_price_elec==.
	replace type_client=4
	collapse (mean) avg_price_elec [iw=pondih], by(type_client) fast
	gen scenario = `scenario'
	tempfile elec6_all_`scenario'
	save `elec6_all_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec6_`scenario''
	append using `elec6_all_`scenario''
}

reshape wide avg_price_elec, i(type_client prepaid) j(scenario)

export excel "$p_res/${namexls}.xlsx", sheet(avg_elec_price) first(variable) sheetreplace 














/****************************************
Table of Affordability
******************************************/

foreach scenario in $numscenarios{
	*local scenario 1
	use "$proj/data/temp/elec_tmp_scenario`scenario'.dta", clear
	
	merge 1:1 hhid using `output', nogen keepusing(depan_pc)
	
	gen tranche3 = (tranche_elec_max==3)
	gen tranche2 = (tranche_elec_max==2)
	gen tranche1 = (tranche_elec_max==1)
	gen tranche_sociale = (tranche_elec_max==0.5)
	gen tranche_dgp = type_client==3 //DGP
	
	
	
	gen double totalpaid_elec = consumption_electricite*avg_price_elec*6 //Here we are interested in the annual electricity consumption per household
	recode totalpaid_elec (.=0)
	
	gen double elec_pc = totalpaid_elec/hhsize
	
	drop avg_price_elec
	//Assume that in baseline, yd_pc corresponds to this situation, and reform scenarios correspond to savings/expenses from baseline
	merge 1:1 hhid using "$proj/data/temp/elec_tmp_scenario1.dta", nogen keepusing(avg_price_elec)
	gen double elec_pc_baseline = consumption_electricite*avg_price_elec*6/hhsize
	recode elec_pc_baseline (.=0)
	
	gen new_yd_pc = yd_pc + elec_pc - elec_pc_baseline
	gen double new_depan_pc = depan_pc + elec_pc - elec_pc_baseline
	
	gen double share_elec = elec_pc*100/new_depan_pc
	
	collapse (mean) share_elec [iw=pondih], by(tranche_elec_max tranche_dgp) fast
	
	gen scenario = `scenario'
	tempfile elec7_`scenario'
	save `elec7_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec7_`scenario''
}

reshape wide share_elec, i(tranche*) j(scenario)

drop if tranche_elec_max==. & tranche_dgp==0


export excel "$p_res/${namexls}.xlsx", sheet(Affordability) first(variable) sheetreplace 





/*
`scenario'
 
use "$p_o/${namexls}.dta", clear
merge 1:1 hhid using "$proj/data/temp/elec_tmp_scenario4.dta", keepusing(tranche_elec_max consumption_electricite avg_price_elec type_client)

gen inc=yd_pc+all_policies_pc


sp_groupfunction [aw=pondih], gini(inc) poverty(inc) povertyline(zref)  by(all)
*/






