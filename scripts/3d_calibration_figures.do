
*Computing effects of the calibration 

*Load data and compute tranches using old pre-paid vs postpaid stats


use "$path_ceq/2_pre_sim/08_subsidies_elect.dta", clear   


/*-------------------------------------------------------------------------------------
Define tranches 
Note: The only difference between this code and the code of 2b should be the ariable used to define pre-paid vs post-paid
defined by the rename below this comment 
This analysis is hardcoded 
-------------------------------------------------------------------------------------*/	

ren prepaid_or prepaid 

gen tranche1_tool=.
gen tranche2_tool=.
gen tranche3_tool=.


	foreach payment in  0 1 {	
		
			if "`payment'"=="1" local type_pay "pre"
			else if "`payment'"=="0" local type_pay "post"
		
		*--> tranche 1
		
			/*DPP*/ replace tranche1_tool=${tranche1_`type_pay'} if consumption_electricite>=${tranche1_`type_pay'} & type_client==1 & prepaid==`payment'  // $MaxT1_DPP
			replace tranche1_tool=consumption_electricite if consumption_electricite<${tranche1_`type_pay'}  & type_client==1 & prepaid==`payment'
			
			/*DMP*/replace tranche1_tool=${dmp_`type_pay'_tra_t1} if consumption_electricite>=${dmp_`type_pay'_tra_t1} & type_client==2 & prepaid==`payment'
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
	

gen all=1 
collapse (sum)	