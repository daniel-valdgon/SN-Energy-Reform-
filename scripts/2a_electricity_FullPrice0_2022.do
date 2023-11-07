
/*=======================================================================================
=======================================================================================
=======================================================================================
Electricity 
=======================================================================================
=======================================================================================
=======================================================================================*/	
	
	use `elec_tmp_dta', clear 

/*-------------------------------------------------------------------------------------
Define tranches 
-------------------------------------------------------------------------------------*/	
	
	noi dis "{opt *************************************************************}"
	noi dis "{opt  Defining tranches scenario `scenario' with marginal tariffs }"
	noi dis "{opt *************************************************************}"

	gen tranches_tool=.
	gen tranche1_tool=.
	gen tranche2_tool=.
	gen tranche3_tool=.
	
	foreach payment in  0 1 {	
		
			if "`payment'"=="1" local type_pay "pre"
			else if "`payment'"=="0" local type_pay "post"
		
		*--> tranche sociale
		
			/*DPP*/ replace tranches_tool=${tranches_`type_pay'} if consumption_electricite>=${tranches_`type_pay'} & type_client==1 & prepaid==`payment'  // $MaxT1_DPP
			replace tranches_tool=consumption_electricite if consumption_electricite<${tranches_`type_pay'}  & type_client==1 & prepaid==`payment'
			
			/*DMP*/ replace tranches_tool=${dmp_`type_pay'_tra_ts} if consumption_electricite>=${dmp_`type_pay'_tra_ts} & type_client==2 & prepaid==`payment'
			replace tranches_tool=consumption_electricite if consumption_electricite<${dmp_`type_pay'_tra_ts} & type_client==2 & prepaid==`payment'
			
			replace tranches_tool=0 if tranches_tool==. & prepaid==`payment' // this should not happend
			dis "this should not happen?"
			
		*--> tranche 1
		
			/*DPP*/ replace tranche1_tool=${tranche1_`type_pay'}-${tranches_`type_pay'} if consumption_electricite>=${tranche1_`type_pay'} & type_client==1 & prepaid==`payment'  // $MaxT1_DPP
			replace tranche1_tool=consumption_electricite-${tranches_`type_pay'} if consumption_electricite<${tranche1_`type_pay'} & consumption_electricite>${tranches_`type_pay'} & type_client==1 & prepaid==`payment'
			
			/*DMP*/ replace tranche1_tool=${dmp_`type_pay'_tra_t1}-${dmp_`type_pay'_tra_ts} if consumption_electricite>=${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
			replace tranche1_tool=consumption_electricite-${dmp_`type_pay'_tra_ts} if consumption_electricite<${dmp_`type_pay'_tra_t1} & consumption_electricite>${dmp_`type_pay'_tra_ts} & type_client==2 & prepaid==`payment'
			
			replace tranche1_tool=0 if tranche1_tool==. & prepaid==`payment' // this should not happend 
			dis "this should not happen?"
		
		*--> tranche 2
		
			/*DPP*/ replace	tranche2_tool=${tranche2_`type_pay'}-${tranche1_`type_pay'} if consumption_electricite>=${tranche2_`type_pay'} & type_client==1 & prepaid==`payment'
			replace tranche2_tool=consumption_electricite-${tranche1_`type_pay'} if consumption_electricite<${tranche2_`type_pay'} & consumption_electricite>${tranche1_`type_pay'} & type_client==1  & prepaid==`payment'
			
			/*DMP*/ replace	tranche2_tool=${dmp_`type_pay'_tra_t2}-${dmp_`type_pay'_tra_t1} if consumption_electricite>=${dmp_`type_pay'_tra_t2} & type_client==2 & prepaid==`payment'
			replace tranche2_tool=consumption_electricite-${dmp_`type_pay'_tra_t1} if consumption_electricite<${dmp_`type_pay'_tra_t2} & consumption_electricite>${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
			
			replace tranche2_tool=0 if tranche2_tool==. & prepaid==`payment'
			dis "this should not happen?"
		*--> tranche 3
		
			/*DPP*/ replace tranche3_tool=consumption_electricite-${tranche2_`type_pay'} if consumption_electricite>=${tranche2_`type_pay'} & type_client==1 & prepaid==`payment'
			/*DMP*/ replace	tranche3_tool=consumption_electricite-${dmp_`type_pay'_tra_t2} if consumption_electricite>=${dmp_`type_pay'_tra_t2} & type_client==2 & prepaid==`payment'
			
			replace tranche3_tool=0 if tranche3_tool==. & prepaid==`payment'
			dis "this should not happen?"
	}
	
gen     tranche_elec_max = 3 if tranche3_tool !=0 & tranche3_tool !=.
replace tranche_elec_max = 2 if tranche2_tool !=0 & tranche2_tool !=. & tranche_elec_max==.
replace tranche_elec_max = 1 if tranche1_tool !=0 & tranche1_tool !=. & tranche_elec_max==.
replace tranche_elec_max = 0.5 if tranche1_tool !=. & tranche_elec_max==. 
replace tranche_elec_max = . if type_client==3 //Exclude DGP from the tranche system
replace tranche_elec_max = . if type_client==. //Exclude households without puissance info, that nonetheless do not consume electricity, even if we have info on prepaid/postpaid

/*-------------------------------------------------------------------------------------
Compute VAT collected 
-------------------------------------------------------------------------------------*/	
	
*Compute vat exemption for each tranche of consumption 
		
	gen vat_t3=.
	gen vat_t2=.
	gen vat_t1=.
	gen vat_ts=.
		
	foreach payment in  0 1 {	
			
			if "`payment'"=="1" local type_pay "pre"
			else if "`payment'"=="0" local type_pay "post"
		
		*--> DPP 
			replace vat_t3   =	 tranche3_tool  * ${tariffs_`type_pay'_t3} *0.18 if prepaid==`payment' & type_client==1
			replace vat_t2   =	 tranche2_tool	* ${tariffs_`type_pay'_t2} *0.18 if prepaid==`payment' & type_client==1
			replace vat_t1   =	 tranche1_tool	* ${tariffs_`type_pay'_t1} *0.18 if prepaid==`payment' & type_client==1
			replace vat_ts   =	 tranches_tool	* ${tariffs_`type_pay'_ts} *0.18 if prepaid==`payment' & type_client==1
		
		*--> DMP
			replace vat_t3   =	tranche3_tool * ${dmp_`type_pay'_tar_t3}*0.18 if prepaid==`payment' & type_client==2
			replace vat_t2   =	tranche2_tool * ${dmp_`type_pay'_tar_t2}*0.18 if prepaid==`payment' & type_client==2
			replace vat_t1   =	tranche1_tool * ${dmp_`type_pay'_tar_t1}*0.18 if prepaid==`payment' & type_client==2
			replace vat_ts   =	tranches_tool * ${dmp_`type_pay'_tar_ts}*0.18 if prepaid==`payment' & type_client==2
	}
	
	*--> DGP
		gen vat_dgp=consumption_electricite*${DGP_tar}*0.18 if type_client==3 
	
	*Adding the VAT exemptions: VAT is paid for households who consume tranche 3
	// 0=no exemptions, 1=social tranche, 2=T1, 3=T!&T2
	
	egen vat_elec=rowtotal(vat_ts vat_t1 vat_t2 vat_t3 vat_dgp)
	
	gen avg_price_elec = vat_elec/(0.18* consumption_electricite)
	scatter avg_price_elec consumption_electricite if consumption_electricite<=700, msize(tiny)
		
	if "${vatexempt_tra}"=="1" {
		replace vat_elec=0 if tranche_elec_max==0.5
	}
	if "${vatexempt_tra}"=="2" {
		replace vat_elec=0 	if tranche_elec_max==0.5 | tranche_elec_max==1
	}
	if "${vatexempt_tra}"=="3" {
		replace vat_elec=0 if tranche_elec_max==0.5 | tranche_elec_max==1 | tranche_elec_max==2
	}
	

	
	replace vat_elec=vat_elec*6 // electricity consumption was bimonthly 
	
/*-------------------------------------------------------------------------------------
	Subsidies-Direct  
-------------------------------------------------------------------------------------*/	
		
*Compute subsidy receive for each tranche of consumption
	gen subsidys=.
	gen subsidy1=.
	gen subsidy2=.
	gen subsidy3=.
	
	foreach payment in 0 1 {	
		
		if "`payment'"=="1" local type_pay "pre"
		else if "`payment'"=="0" local type_pay "post"
	
		*-->DPP
			replace subsidys=(${cost}-${tariffs_`type_pay'_ts})*tranches_tool if type_client==1 & prepaid==`payment'
			replace subsidy1=(${cost}-${tariffs_`type_pay'_t1})*tranche1_tool if type_client==1 & prepaid==`payment'
			replace subsidy2=(${cost}-${tariffs_`type_pay'_t2})*tranche2_tool if type_client==1 & prepaid==`payment'
			replace subsidy3=(${cost}-${tariffs_`type_pay'_t3})*tranche3_tool if type_client==1 & prepaid==`payment'
	
		*-->DMP : Note these policy values are fixed 
			replace subsidys=(${cost}-${dmp_`type_pay'_tar_ts})*tranches_tool if type_client==2 & prepaid==`payment'
			replace subsidy1=(${cost}-${dmp_`type_pay'_tar_t1})*tranche1_tool if type_client==2 & prepaid==`payment'
			replace subsidy2=(${cost}-${dmp_`type_pay'_tar_t2})*tranche2_tool if type_client==2 & prepaid==`payment'
			replace subsidy3=(${cost}-${dmp_`type_pay'_tar_t3})*tranche3_tool if type_client==2 & prepaid==`payment'
	}
	
	
	*-->DGP
	gen subsidydgp=(${cost}-${DGP_tar})*consumption_electricite if type_client==3 
	
	*Total subsidies 
	egen subsidy_elec_direct=rowtotal(subsidys subsidy1 subsidy2 subsidy3 subsidydgp)
	replace subsidy_elec_direct=subsidy_elec_direct*6 // electricity consumption recorded in tranches is bimonthly 
	
	*Cost (this is required for one graph in the slides)
	gen cost_elec = ${cost}*consumption_electricite*6
	
	*Social tranche: this is already included in the subsidies above, so I will calculate the amount that should be subtracted from the subsidy to get the "no-social-tranche subsidy of DPP-T1"
	gen social_tranche=0
	*replace social_tranche=(${tariffs_t1_no_socialt}-${tariffs_post_t1})*tranche1_tool if type_client==1 & prepaid==0
	*replace social_tranche=(${tariffs_t1_no_socialt}-${tariffs_pre_t1})*tranche1_tool if type_client==1 & prepaid==1
	
	tempfile vat_sub_tmp
	save `vat_sub_tmp'


/*-------------------------------------------------------------------------------------
	Subsidies-Indirect
-------------------------------------------------------------------------------------*/	
{    
	*IO prices 
	
	import excel "$path_ceq/IO_Matrix.xlsx", sheet("IO_aij") firstrow clear
		
		*Define fixed sectors 
		local thefixed 22 32 33 34 13 	
		gen fixed=0
		foreach var of local thefixed {
			replace fixed=1  if  Secteur==`var'
		}
		
		*Shock
		gen shock=$subsidy_firms*$share_elec_io if Secteur==22
		replace shock=0  if shock==.
	
		*Indirect effects 
		costpush C1-C35, fixed(fixed) priceshock(shock) genptot(ptot_shock) genpind(pind_shock) fix
		
	tempfile io_ind_sim
	save `io_ind_sim', replace
		
	*Product sector X-Walk 
	import excel "$path_ceq/prod_sect_Xwalk_2021.xlsx", sheet("Xwalk") firstrow clear
		keep codpr TVA formelle exempted
		drop if codpr==.
		
		merge 1:m codpr using "$path_ceq/IO_percentage_2021.dta", nogen // Adding weights for products in multiple sectors  
		
		merge m:1 Secteur  using  `io_ind_sim' , nogen //Adding IO estimates at product level (both products that belong to one sector and product that belong to multiple sectors)	
		
		drop if codpr==.
		replace ptot_shock=0  if ptot_shock==.
		replace  pind_shock=pind_shock*pourcentage // computing codpr weighted average for the indirect effect 
		
		collapse (sum) pind_shock , by(codpr)
	
	tempfile Xwalk_IO_est_ind_sim
	save `Xwalk_IO_est_ind_sim', replace 
	
	*Apply Indirect subsidies to net depan
	use `depan_nosubsidy', clear  // use "$path_ceq/05_purchases_hhid_codpr.dta", clear 
		
		merge m:1 codpr using `Xwalk_IO_est_ind_sim' , assert(matched using) keep(matched) nogen  
		
		gen subsidy_elec_indirect=pind_shock*depan_net_sub
		keep hhid subsidy_elec_indirect
		
		gcollapse (sum) subsidy_elec_indirect , by(hhid) // indirect doesnot have to be multiplied by 6
	
	tempfile elec_ind_sim
	save `elec_ind_sim', replace
		
}

	use `vat_sub_tmp', clear // vat and direct effect of subsidy 
	merge 1:1 hhid using `elec_ind_sim' // indirect effect subsidy 
	


/*-------------------------------------------------------------------------------------
	Subsidies Total
-------------------------------------------------------------------------------------*/	
	egen subsidy_elec=rowtotal(subsidy_elec_direct subsidy_elec_indirect) // indirect effect is over depan that is already annualized 
	
	preserve
		merge 1:1 hhid using `output', nogen
		save "$proj/data/temp/elec_tmp_scenario`scenario'.dta", replace
	restore
	
	keep hhid subsidy_elec_direct subsidy_elec_indirect subsidy_elec vat_elec cost_elec social_tranche

	tempfile elec_tmp_dta
	save `elec_tmp_dta', replace 

	
	

/*-------------------------------------------------------------------------------------
	Costs per deciles
-------------------------------------------------------------------------------------*/	
	/*
	clear
	use `elec_tmp_dta', clear
	merge 1:1 hhid using `output', nogen
	gen cost_elec_pc = cost_elec/hhsize
	gen share_cost_elec_pc = cost_elec_pc/yd_pc
	groupfunction [aw=pondih], mean (share_cost_elec_pc ) by(yd_deciles_pc) norestore
	
	export excel "$p_res/${namexls}.xlsx", sheet(elec_cost_deciles) first(variable) sheetreplace 
	*/
	
	
	
	

exit 

/*Test 
	frame copy default temp, replace 
	frame temp {
		
		gen t3=.
		gen t2=.
		gen t1=.
		
		replace t3=consumption_electricite if tranche3_tool!=0 & tranche3_tool!=.
		replace t2=consumption_electricite if tranche2_tool!=0 & tranche2_tool!=. & (tranche3_tool==. | tranche3_tool==0)
		replace t1=consumption_electricite if tranche1_tool!=0 & tranche1_tool!=. & (tranche2_tool==. | tranche2_tool==0) 
		
		gen consumption_electricite2=consumption_electricite
		replace consumption_electricite2=956 if consumption_electricite2>956
		gen cov=consumption_electricite>0
		gen tranche_1_customer=tranche2_tool==0 & tranche3_tool==0 &  consumption_electricite>0
		foreach v in t3 t2 t1 tranche3_tool tranche2_tool tranche1_tool consumption_electricite consumption_electricite2 { 
			replace `v'=`v'*6/1000000 
		
		}
		collapse (sum) t3 t2 t1  tranche_1_customer cov tranche3_tool tranche2_tool tranche1_tool consumption_electricite consumption_electricite2  [iw= hhweight] 
	}
	
	*/
