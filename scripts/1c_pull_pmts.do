
/*===============================================================================================
	Define lists 
 ==============================================================================================*/

import excel using "$p_res/${namexls}.xlsx", clear first sheet(single_policy)
drop if cost==.

gen id_cod=1
aorder 
order id_cod 

*Parameters of Electricity 

	
	foreach v in vatexempt_tra cost ///
	tariffs_pre_t1 tariffs_pre_t2 tariffs_pre_t3 tranche1_pre tranche2_pre  ///
	tariffs_post_t1 tariffs_post_t2 tariffs_post_t3 tranche1_post tranche2_post  ///
	dmp_pre_tar_t1 dmp_pre_tar_t2 dmp_pre_tar_t3 dmp_pre_tra_t1 dmp_pre_tra_t2 ///
	dmp_post_tar_t1 dmp_post_tar_t2 dmp_post_tar_t3 dmp_post_tra_t1 dmp_post_tra_t2 DGP_tar cost_firm share_elec_io subsidy_firms {
		
		global `v' = ""
		levelsof `v' if id_cod==1, local (value)
		global `v' = `value'
	}
	
	//Note: global DGP_tar 114.58 // 2020 data: mean 115.54, sd 6.68 (excluding april because it was a complete outlier) paid by kwh in 2020 // 2022 data: mean 114.58, sd 2.27. Now included in the parameters 
	 
*Parameters of Fuel 
	foreach v in mp_butane mp_pet_lamp mp_gasoil mp_fuel mp_pirogue sp_butane sp_pet_lamp sp_gasoil sp_fuel sp_pirogue	margin_detaillant {
		
		global `v' = ""
		levelsof `v' if id_cod==1, local (value)
		global `v' = `value'
	}
	

tempfile list_dta
save `list_dta', replace 



exit 

/*codigo andres gallegos */


use `list_dta', clear 
count 
local N=`r(N)'

qui {

forvalues j= 1(1)`N' { //loop of policy sets 

/*-------------------------------------------------------------------------------------
Loading parameters for policy `j' 
-------------------------------------------------------------------------------------*/	

	noi dis "************************************"
	noi dis "loading scenario `j'"
	noi dis "************************************"

	use `list_dta' if id_cod==`j', clear  