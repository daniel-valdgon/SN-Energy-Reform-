
/*===============================================================================================
	Rename globals of parameters for each `scenario'
 ==============================================================================================*/


use `list_dta', clear

	*Parameters of Electricity 
	foreach v in vatexempt_tra cost ///
	tariffs_pre_t1 tariffs_pre_t2 tariffs_pre_t3 tranche1_pre tranche2_pre ///
	tariffs_post_t1 tariffs_post_t2 tariffs_post_t3 tranche1_post tranche2_post ///
	dmp_pre_tar_t1 dmp_pre_tar_t2 dmp_pre_tar_t3 dmp_pre_tra_t1 dmp_pre_tra_t2 ///
	dmp_post_tar_t1 dmp_post_tar_t2 dmp_post_tar_t3 dmp_post_tra_t1 dmp_post_tra_t2 DGP_tar cost_firms share_elec_io subsidy_firms {
		global `v' = ${`v'_s`scenario'}
	}
	 
	*Parameters of Fuel 
	foreach v in mp_butane mp_pet_lamp mp_gasoil mp_fuel mp_pirogue ///
	sp_butane sp_pet_lamp sp_gasoil sp_fuel sp_pirogue	margin_detaillant {
		global `v' = ${`v'_s`scenario'}
	}
	
	*Other Parameters 
	foreach v in popgrowth_20 popgrowth_21 popgrowth_22 inf_20 inf_21 inf_22 {
		global `v' = ${`v'_s`scenario'}
	}

