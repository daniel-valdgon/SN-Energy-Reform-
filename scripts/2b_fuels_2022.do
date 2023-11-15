
/*=======================================================================================
Fuels  consumed by households are gasoil, Butane and Kerosene
Fuel consumed by IO sector are gasoil and pirogue
=======================================================================================*/	
	
	use `fuel_tmp_dta', clear 	

	
/*-------------------------------------------------------------------------------------
Compute VAT collected 
-------------------------------------------------------------------------------------*/	
	
	*Compute vat exemption for each tranche of consumption 
		
	gen vat_fuel=.
	gen vat_butane=.
	gen vat_pet_lamp=.
		
	foreach pdto in fuel pet_lamp butane {
		replace vat_`pdto' = 0.18 * (${sp_`pdto'}) * q_`pdto'  // VAT is paid over the price minus the margin_detaillant but I will continue to do it over the price until confirm
	}
	
	ren vat_fuel vat_fuel_det
	egen vat_fuel=rowtotal(vat_fuel_det vat_pet_lamp vat_butane)  
	
/*-------------------------------------------------------------------------------------
	Subsidies-Direct  
-------------------------------------------------------------------------------------*/	
		
	*Compute subsidy receive for each tranche of consumption 
	
	foreach pdto in fuel pet_lamp butane {
		gen sub_`pdto'	= .
		replace sub_`pdto'= (${mp_`pdto'}-${sp_`pdto'})*q_`pdto' 		
	}
	
	egen subsidy_fuel_direct=rowtotal(sub_fuel sub_pet_lamp sub_butane)  
	
	tempfile vat_sub_tmp_fuel
	save `vat_sub_tmp_fuel'

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
		gen shock=. 
		replace  shock=((${mp_industryfuel}-${sp_industryfuel})/${mp_industryfuel}) if inlist(Secteur, 13)
		replace shock=0  if shock==. // we assume that oil sector of the IO is mostly represented by fuel and that the consumption of super-carburant is mostly concentrated on the household sector 
	
		*Indirect effects 
		costpush C1-C35, fixed(fixed) priceshock(shock) genptot(ptot_shock) genpind(pind_shock) fix
		
	tempfile io_fuel
	save `io_fuel', replace
		
	*Product sector X-Walk 
	import excel "$path_ceq/prod_sect_Xwalk_2021.xlsx", sheet("Xwalk") firstrow clear
		keep codpr TVA formelle exempted
		drop if codpr==.
		
		merge 1:m codpr using "$path_ceq/IO_percentage_2021.dta", nogen // Adding weights for products in multiple sectors  
		
		merge m:1 Secteur  using  `io_fuel' , nogen //Adding IO estimates at product level (both products that belong to one sector and product that belong to multiple sectors)	
		
		drop if codpr==.
		replace ptot_shock=0  if ptot_shock==.
		replace  pind_shock=pind_shock*pourcentage // computing codpr weighted average for the indirect effect 
		
		collapse (sum) pind_shock, by(codpr)
	
	tempfile Xwalk_IO_est_fuel
	save `Xwalk_IO_est_fuel', replace 
	
	*Indirect effects of subsidies 
	use `depan_nosubsidy', clear // use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr.dta", clear 
	
		merge m:1 codpr using `Xwalk_IO_est_fuel' , assert(matched using) keep(matched) nogen  
		
		* 211	Transport urbain en bus
		* 213	Transport urbain en train
		* 214	Transport urbain/rural par voie fluviale
		* 215	Transport urbain/rural par traction animale
		* 212	Transport urbain/rural en moto-taxi
		* 407	Transport interlocalité par eau (bateau, pirogue, pinasse)
		
		gen subsidy_fuel_indirect=pind_shock*depan_net_sub
		assert subsidy_fuel_indirect!=.
		
		gen subs_public_transport=0
		
		if $subs_public_transport == 1{
			gen subsidy_fuel_indirect2=pind_shock*depan_net_sub if !inlist(codpr, 211, 212, 210 /*, 214, 407*/ )
			replace subsidy_fuel_indirect2=0 if subsidy_fuel_indirect2==.
			replace subs_public_transport = subsidy_fuel_indirect-subsidy_fuel_indirect2
			drop subsidy_fuel_indirect2
		}
		
		gcollapse (sum) subsidy_fuel_indirect subs_public_transport, by(hhid) 
	
	tempfile indirect_subsidy_fuel
	save `indirect_subsidy_fuel', replace
		
}

	use `vat_sub_tmp_fuel', clear 
	merge 1:1 hhid using `indirect_subsidy_fuel'
	


/*-------------------------------------------------------------------------------------
	Subsidies Total
-------------------------------------------------------------------------------------*/	
	egen subsidy_fuel=rowtotal(subsidy_fuel_direct subsidy_fuel_indirect)
	
/*-------------------------------------------------------------------------------------
	Id of policy evaluated 
-------------------------------------------------------------------------------------*/	
	
	keep hhid subsidy_fuel_direct subsidy_fuel_indirect subsidy_fuel vat_fuel subs_public_transport

	tempfile fuel_tmp_dta
	save `fuel_tmp_dta', replace  
	

