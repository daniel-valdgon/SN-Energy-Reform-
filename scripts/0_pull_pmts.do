
/*===============================================================================================
	Define lists 
 ==============================================================================================*/

import excel using "$p_res/${namexls}.xlsx", clear first sheet(single_policy)
missings dropobs, force
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



foreach scenario in $numscenarios {
    
	*ALL THE PARAMETERS 
	foreach v in vatexempt_tra tariffs_pre_t1 tariffs_pre_t2 tariffs_pre_t3 ///
	tranche1_pre tranche2_pre tariffs_post_t1 tariffs_post_t2 tariffs_post_t3 ///
	tranche1_post tranche2_post cost dmp_pre_tar_t1 dmp_pre_tar_t2 dmp_pre_tar_t3 ///
	dmp_pre_tra_t1 dmp_pre_tra_t2 dmp_post_tar_t1 dmp_post_tar_t2 dmp_post_tar_t3 ///
	dmp_post_tra_t1 dmp_post_tra_t2 DGP_tar cost_firms tar_firms subsidy_firms share_elec_io ///
	mp_butane mp_pet_lamp mp_gasoil mp_ordinaire mp_pirogue mp_super mp_fuel mp_industryfuel ///
	sp_butane sp_pet_lamp sp_gasoil sp_ordinaire sp_pirogue sp_super sp_fuel sp_industryfuel ///
	margin_detaillant popgrowth_20 popgrowth_21 popgrowth_22 inf_20 inf_21 inf_22 elec_uprating gdp_22 ///
	iwf_butane iwf_pet_lamp iwf_gasoil iwf_ordinaire iwf_pirogue iwf_super ///
	hwf_gasoil hwf_ordinaire hwf_pirogue hwf_super ///
	mp19_butane mp19_pet_lamp mp19_gasoil mp19_ordinaire mp19_pirogue mp19_super ///
	sp19_butane sp19_pet_lamp sp19_gasoil sp19_ordinaire sp19_pirogue sp19_super sp19_fuel sp19_industryfuel ///
	butane_uprating pet_lamp_uprating gasoil_uprating ordinaire_uprating pirogue_uprating super_uprating fuel_uprating industryfuel_uprating ///
	butane_sub_svy pet_lamp_sub_svy gasoil_sub_svy ordinaire_sub_svy pirogue_sub_svy super_sub_svy fuel_sub_svy industryfuel_sub_svy cost_firms_svy tar_firms_svy ///
	share_elec_io_base PNBSF_transfer_increase PNBSF_benef_increase PMT_targeting_BSF subs_public_transport delayed_PNBSF tariffs_t1_no_socialt {
		global `v'_s`scenario' = ""
		levelsof `v' if scenario==`scenario', local(value)
		global `v'_s`scenario' = `value'
	}
	
	
	 
}

tempfile list_dta
save `list_dta', replace 
