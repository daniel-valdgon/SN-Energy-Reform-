
/*===============================================================================================
	Define lists 
 ==============================================================================================*/

import excel using "$p_res/${namexls}.xlsx", clear first sheet(single_policy)
drop if cost==.

foreach var of varlist _all {
	capture assert mi(`var')
	if !_rc {
		drop `var'
		dis "Dropping `var' because of missings"
	}
}

aorder
order scenario



foreach scenario in 1 2 3{
	*Parameters of Electricity 
	foreach v in vatexempt_tra cost ///
	tariffs_pre_t1 tariffs_pre_t2 tariffs_pre_t3 tranche1_pre tranche2_pre ///
	tariffs_post_t1 tariffs_post_t2 tariffs_post_t3 tranche1_post tranche2_post ///
	dmp_pre_tar_t1 dmp_pre_tar_t2 dmp_pre_tar_t3 dmp_pre_tra_t1 dmp_pre_tra_t2 ///
	dmp_post_tar_t1 dmp_post_tar_t2 dmp_post_tar_t3 dmp_post_tra_t1 dmp_post_tra_t2 DGP_tar cost_firms share_elec_io_base subsidy_firms {
		global `v'_s`scenario' = ""
		levelsof `v' if scenario==`scenario', local(value)
		global `v'_s`scenario' = `value'
	}
	
	//Note: global DGP_tar 114.58 // 2020 data: mean 115.54, sd 6.68 (excluding april because it was a complete outlier) paid by kwh in 2020 // 2022 data: mean 114.58, sd 2.27. Now included in the parameters 
	 
	*Parameters of Fuel 
	foreach v in mp_butane mp_pet_lamp mp_gasoil mp_fuel mp_pirogue mp19_butane mp19_pet_lamp mp19_gasoil mp19_pirogue mp19_fuel ///
	sp_butane sp_pet_lamp sp_gasoil sp_fuel sp_pirogue	margin_detaillant {
		global `v'_s`scenario' = ""
		levelsof `v' if scenario==`scenario', local(value)
		global `v'_s`scenario' = `value'
	}
	 
	*Other Parameters
	foreach v in popgrowth_20 popgrowth_21 popgrowth_22 inf_20 inf_21 inf_22 {
		global `v'_s`scenario' = ""
		levelsof `v' if scenario==`scenario', local(value)
		global `v'_s`scenario' = `value'
	}
}

tempfile list_dta
save `list_dta', replace 
