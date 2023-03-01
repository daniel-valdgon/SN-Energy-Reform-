
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
	
	noi dis "************************************"
	noi dis " Defining tranches scenario `j'"
	noi dis "************************************"

	
	gen tranche1_tool=.
	gen tranche2_tool=.
	gen tranche3_tool=.
	
	foreach payment in  0 1 {	
		
			if "`payment'"=="1" local type_pay "pre"
			else if "`payment'"=="0" local type_pay "post"
		
		*--> tranche 1
		
			/*DPP*/ replace tranche1_tool=${tranche1_`type_pay'} if consumption_electricite>=${tranche1_`type_pay'} & type_client==1 & prepaid==`payment'  // $MaxT1_DPP
			replace tranche1_tool=consumption_electricite if consumption_electricite<${tranche1_`type_pay'}  & type_client==1 & prepaid==`payment'
			
			/*DMP*/ replace tranche1_tool=${dmp_`type_pay'_tra_t1} if consumption_electricite>=${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
			replace tranche1_tool=consumption_electricite if consumption_electricite<${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
			
			replace tranche1_tool=0 if tranche1_tool==. & prepaid==`payment' // this should not happend 
		 
		
		*--> tranche 2
		
			/*DPP*/ replace	tranche2_tool=${tranche2_`type_pay'}-${tranche1_`type_pay'} if consumption_electricite>=${tranche2_`type_pay'} & type_client==1 & prepaid==`payment'
			replace tranche2_tool=consumption_electricite-${tranche1_`type_pay'} if consumption_electricite<${tranche2_`type_pay'} & consumption_electricite>${tranche1_`type_pay'} & type_client==1  & prepaid==`payment'
			
			/*DMP*/ replace	tranche2_tool=${dmp_`type_pay'_tra_t2}-${dmp_`type_pay'_tra_t1} if consumption_electricite>=${dmp_`type_pay'_tra_t2} & type_client==2 & prepaid==`payment'
			replace tranche2_tool=consumption_electricite-${dmp_`type_pay'_tra_t1} if consumption_electricite<${dmp_`type_pay'_tra_t2} & consumption_electricite>${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
			
			replace tranche2_tool=0 if tranche2_tool==. & prepaid==`payment'
		
		*--> tranche 3
		
			/*DPP*/ replace tranche3_tool=consumption_electricite-${tranche2_`type_pay'} if consumption_electricite>=${tranche2_`type_pay'} & type_client==1 & prepaid==`payment'
			/*DMP*/ replace	tranche3_tool=consumption_electricite-${dmp_`type_pay'_tra_t2} if consumption_electricite>=${dmp_`type_pay'_tra_t2} & type_client==2 & prepaid==`payment'
			
			replace tranche3_tool=0 if tranche3_tool==. & prepaid==`payment'
	}
	
	

/*-------------------------------------------------------------------------------------
Compute VAT collected 
-------------------------------------------------------------------------------------*/	
	
*Compute vat exemption for each tranche of consumption 
		
	gen vat_t3=.
	gen vat_t2=.
	gen vat_t1=.
		
	foreach payment in  0 1 {	
			
			if "`payment'"=="1" local type_pay "pre"
			else if "`payment'"=="0" local type_pay "post"
		
		*--> DPP 
			replace vat_t3   =	 tranche3_tool  * ${tariffs_`type_pay'_t3} *0.18 if prepaid==`payment' & type_client==1
			replace vat_t2   =	 tranche2_tool	* ${tariffs_`type_pay'_t2} *0.18 if prepaid==`payment' & type_client==1
			replace vat_t1   =	 tranche1_tool	* ${tariffs_`type_pay'_t1} *0.18 if prepaid==`payment' & type_client==1
		
		*--> DMP
			replace vat_t3   =	tranche3_tool * ${dmp_`type_pay'_tar_t3}*0.18 if prepaid==`payment' & type_client==2
			replace vat_t2   =	tranche2_tool * ${dmp_`type_pay'_tar_t2}*0.18 if prepaid==`payment' & type_client==2
			replace vat_t1   =	tranche1_tool * ${dmp_`type_pay'_tar_t1}*0.18 if prepaid==`payment' & type_client==2
	}
	
	*--> DGP
		gen vat_dgp=consumption_electricite*${DGP_tar}*0.18 if type_client==3 
	
	*Adding the VAT exemptions: VAT is paid for households who consume tranche 3
		
	if "${vatexempt_tra}"=="00" {
		egen vat_elec=rowtotal(vat_t1 vat_t2 vat_t3 vat_dgp) if tranche3_tool>0
		replace vat_elec=0 if tranche3_tool==0
	}
	if "${vatexempt_tra}"=="01" {
		egen vat_elec=rowtotal(vat_t2 vat_t3 vat_dgp) if tranche3_tool>0
		replace vat_elec=0 	if tranche3_tool==0
		
		replace vat_t1=0 	if tranche3_tool>=0
	}
	if "${vatexempt_tra}"=="12" {
		egen vat_elec=rowtotal(vat_t3 vat_dgp) if tranche3_tool>0
		replace vat_elec=0 if tranche3_tool==0
		
		replace vat_t1=0 	if tranche3_tool>=0
		replace vat_t2=0 	if tranche3_tool>=0
	}
	
	replace vat_elec=vat_elec*6 // electricity consumption was bimonthly 
	
/*-------------------------------------------------------------------------------------
	Subsidies-Direct  
-------------------------------------------------------------------------------------*/	
		
*Compute subsidy receive for each tranche of consumption 
	gen subsidy1=.
	gen subsidy2=.
	gen subsidy3=.
	
	foreach payment in 0 1 {	
		
		if "`payment'"=="1" local type_pay "pre"
		else if "`payment'"=="0" local type_pay "post"
	
		*-->DPP
			replace subsidy1=(${cost}-${tariffs_`type_pay'_t1})*tranche1_tool if type_client==1 & prepaid==`payment'
			replace subsidy2=(${cost}-${tariffs_`type_pay'_t2})*tranche2_tool if type_client==1 & prepaid==`payment'
			replace subsidy3=(${cost}-${tariffs_`type_pay'_t3})*tranche3_tool if type_client==1 & prepaid==`payment'
	
		*-->DMP : Note this policy values are fixed 
			replace subsidy1=(${cost}-${dmp_`type_pay'_tar_t1})*tranche1_tool if type_client==2 & prepaid==`payment'
			replace subsidy2=(${cost}-${dmp_`type_pay'_tar_t2})*tranche2_tool if type_client==2 & prepaid==`payment'
			replace subsidy3=(${cost}-${dmp_`type_pay'_tar_t3})*tranche3_tool if type_client==2 & prepaid==`payment'
	}
	
	
	*-->DGP
	gen subsidygdp=(${cost}-${DGP_tar})*consumption_electricite if type_client==3 
	
	*Total subsidies 
	egen subsidy_elec_direct=rowtotal(subsidy1 subsidy2 subsidy3 subsidygdp)
	replace subsidy_elec_direct=subsidy_elec_direct*6 // electricity consumption recorded in tranches is bimonthly 
	
	tempfile vat_sub_tmp
	save `vat_sub_tmp'


/*-------------------------------------------------------------------------------------
	Subsidies-Indirect
-------------------------------------------------------------------------------------*/	
{    
	*IO prices 
	
	import excel "$path_raw/IO_Matrix.xlsx", sheet("IO_aij") firstrow clear
		
		*Define fixed sectors 
		local thefixed 22 32 33 34
		
		gen fixed=0
		foreach var of local thefixed {
			replace fixed=1  if  Secteur==`var'
		}
		
		*Shock
		gen shock=$subsidy_firms*$share_elec_io if Secteur==22
		replace shock=0  if shock==.
	
		*Indirect effects 
		costpush C1-C35, fixed(fixed) priceshock(shock) genptot(ptot_shock) genpind(pind_shock) 
		
	tempfile io_ind_sim
	save `io_ind_sim', replace
		
	*Product sector X-Walk 
	import excel "$path_raw/prod_sect_Xwalk.xlsx", sheet("Xwalk") firstrow clear
		keep codpr TVA formelle exempted
		drop if codpr==.
		
		merge 1:m codpr using "$path_ceq/IO_percentage2_clean.dta", nogen // Adding weights for products in multiple sectors  
		
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
	
	keep hhid subsidy_elec_direct subsidy_elec_indirect subsidy_elec vat_elec

	tempfile elec_tmp_dta
	save `elec_tmp_dta', replace 
	

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
