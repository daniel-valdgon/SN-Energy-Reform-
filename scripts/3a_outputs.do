
run "$p_scr/_ado/sp_groupfunction.ado"
run "$p_scr/_ado/groupfunction.ado"
run "$p_scr/_ado/costpush.ado"

local income yd   	// before I have a local here but it presented some problems 
local ind_transf 	subsidy_fuel_direct subsidy_fuel_indirect subsidy_fuel subsidy_elec_direct subsidy_elec_indirect subsidy_elec 
local ind_tax 		vat_elec vat_fuel
local ind_miti		am_new_pnbsf am_delayed_pnbsf social_tranche subs_public_transport am_pnbsf_transferinc am_pnbsf_newbenefs
local all_groups 	all_miti all_miti_noST all_policies_miti all_policies_noST all_policies all_tax all_subs_noST all_subs all_elec_noST all_elec all_fuel

local policies `ind_transf' `ind_tax' `ind_miti' `all_groups'
local pline zref // line_19 line_32 line_55



use `output', clear 

keep  hhid yd_deciles_pc yd_pc yn_pc hhsize pondih all zref hhweight am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc
merge 1:1 hhid using `fuel_tmp_dta', nogen 
merge 1:1 hhid using `elec_tmp_dta', nogen 

*Mitigation measure: new PNBSF policy
merge 1:1 hhid using `new_PNBSF', nogen


*Adding policies
egen all_subs			=rowtotal(subsidy_fuel subsidy_elec)
gen all_subs_noST		=subsidy_fuel+subsidy_elec-social_tranche
egen all_tax			=rowtotal(vat_elec vat_fuel)
gen all_elec			=subsidy_elec-vat_elec
gen all_elec_noST		=subsidy_elec-vat_elec-social_tranche
gen all_fuel			=subsidy_fuel-vat_fuel
gen all_policies		=all_subs-all_tax
gen all_policies_noST	=all_subs-all_tax-social_tranche
gen all_miti			=am_new_pnbsf+am_delayed_pnbsf+subs_public_transport+social_tranche
gen all_miti_noST		=am_new_pnbsf+am_delayed_pnbsf+subs_public_transport
gen all_policies_miti	=all_subs-all_tax+am_new_pnbsf+am_delayed_pnbsf+subs_public_transport

*Compute pc values 	
foreach var of local policies {
	gen `var'_pc= `var'/hhsize
	replace `var'=0 if `var'==.
}

*Define macros (globals) of pc variables (for vars and list of vars ex: policies_pc)
foreach x in income policies  {
	local `x'_pc
	foreach y of local `x' {
		local `x'_pc ``x'_pc' `y'_pc
	}
}
/*test : dis "`income_pc'" ,  dis "`policies_pc'" */



tempfile dta_pc
save `dta_pc', replace 

save "$p_o/${namexls}`scenario'.dta", replace 

*===============================================================================
		*1 Poverty 
*===============================================================================
	use `dta_pc', clear 
	
	*List of all new marginal contributiions
	local mc_income ""
	
	foreach var of local  ind_tax {
		gen inc_`var'=yd_pc-`var'_pc         // effect with the policy for indirect taxes
		local mc_income `mc_income' inc_`var'   //  Store varnames in list mc_income
	}
	foreach var in `ind_transf' `ind_miti' {
		gen inc_`var'=yd_pc+`var'_pc 		 // effect with the policy for subsidies
		local mc_income `mc_income' inc_`var'   // Store varnames in list mc_income
	}
		
		
	foreach var of local all_groups {
		
		if "`var'"=="all_tax" {
			gen inc_`var'=yd_pc-`var'_pc 		 // effect of all policies defined as subs-tax 
			local mc_income `mc_income' inc_`var'   // Store varnames in list mc_income
		}
		else {
		gen inc_`var'=yd_pc+`var'_pc 		 // effect of all policies defined as subs-tax 
		local mc_income `mc_income' inc_`var'   // Store varnames in list mc_income
		}
	}
		

	sp_groupfunction [aw=pondih], gini(`income_pc' `mc_income') theil(`income_pc' `mc_income') poverty(`income_pc' `mc_income') povertyline(`pline')  by(all) 
	gen yd_deciles_pc=0
	
tempfile poverty
save `poverty'

*===============================================================================
		*2 Netcash Position
*===============================================================================

use `dta_pc', clear 

	foreach x of local  ind_tax {
		gen share_`x'_pc= -`x'_pc/yd_pc 
		gen c_share_`x'_pc= -`x'_pc/yd_pc if `x'_pc>0 & `x'_pc!=. //conditional incidence
	}		
	foreach x in `ind_transf' `ind_miti' {
		gen share_`x'_pc= `x'_pc/yd_pc   
		gen c_share_`x'_pc= `x'_pc/yd_pc  if `x'_pc>0 //conditional incidence
	}
	foreach x of local all_groups {
		gen share_`x'_pc= `x'_pc/yd_pc   
		gen c_share_`x'_pc= `x'_pc/yd_pc  if `x'_pc>0 //conditional incidence
	}
	
	*Correction: all_tax should be negative
	replace share_all_tax_pc = -share_all_tax_pc
	replace c_share_all_tax_pc = -c_share_all_tax_pc 
	
	keep yd_deciles_pc share* c_share* pondih	
	tempfile net_cash_tmp
	save `net_cash_tmp'

*Unconditional net cash 
	groupfunction [aw=pondih], mean (share* ) by(yd_deciles_pc) norestore

	reshape long share_, i(yd_deciles_pc) j(variable) string
	gen measure = "netcash" 
	rename share_ value

	tempfile netcash_yd
	save `netcash_yd'

*Conditional net cash 
	use `net_cash_tmp', clear 
	
	groupfunction [aw=pondih], mean (c_share_* ) by(yd_deciles_pc) norestore

	reshape long c_share_, i(yd_deciles_pc) j(variable) string
	gen measure = "cond_netcash" 
	rename c_share_ value

	tempfile cond_netcash_yd
	save `cond_netcash_yd'


*===============================================================================
		*3 Social Protection measures 
*===============================================================================
	
* benefits, coverage beneficiaries by all	

use `dta_pc', clear 
	
	sp_groupfunction [aw=pondih], benefits(`policies_pc') mean(`policies_pc') coverage(`policies_pc') beneficiaries(`policies_pc')  by(all)
	gen yd_deciles_pc=0

tempfile theall
save `theall'

* benefits, coverage beneficiaries by deciles of disposable income 

use `dta_pc', clear 
	
	sp_groupfunction [aw=pondih], benefits(`policies_pc') mean(`policies_pc') coverage(`policies_pc') beneficiaries(`policies_pc')  by(yd_deciles_pc)
	
tempfile theyd_deciles
save `theyd_deciles', replace 
	
* generate absolute incidence indicators per decile
	use `theyd_deciles'
	append using `theall'
	keep if measure=="benefits"
	
	reshape wide value, i(measure _population yd_deciles_pc all) j(variable) string
	sort yd_deciles_pc
	foreach policy of local policies_pc{
		local totalpol = value`policy'[1]
		replace value`policy' = value`policy'/`totalpol'
	}
	reshape long
	replace measure = "ai"
	drop if all==1
	sort yd_deciles_pc
	
tempfile theai_deciles
save `theai_deciles', replace 


*===============================================================================
		*4 Compiling 
*===============================================================================
	
	*first deciles 
	use `theyd_deciles'
	append using `netcash_yd'
	append using `cond_netcash_yd'
	append using `theai_deciles'
	
	*second no deciles 
	append using `theall'
	append using `poverty'
	
	gen scenario = `scenario'
	gen concat = string(scenario)+"_"+variable +"_"+ measure +"_"+"_yd_"+string(yd_deciles_pc)
	order concat, first
	
	tempfile theyd_deciles_`scenario'
	save `theyd_deciles_`scenario'', replace 
	

*===============================================================================
		*5 Stats for slide
*===============================================================================

/*
use "$p_o/$namexls.dta", clear 
