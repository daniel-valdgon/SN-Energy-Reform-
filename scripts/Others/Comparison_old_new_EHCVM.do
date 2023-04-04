
*Let's compare the old databases and the new ones

*I need a base of all households and a set of variables (different to hhid or menage) that identifies uniquely each household


	use "$data_sn/1_raw/s01_me_SEN2018.dta", clear
	gen hhid = grappe*1000+menage
	*br if inlist(hhid,360001,360009,4005,4008,28001,28007,478006,478010)
	replace s01q03c=. if s01q03c==999 | s01q03c==9999
	gen age=2019-s01q03c
	replace age=999 if age==.
	gen p=1
	recode s01q16 .=0
	recode s01q07 .=0
	bys hhid: egen ethnie = mean(s01q16)
	bys hhid: egen matrim = mean(s01q07)
	
	collapse (sum) p , by(vague grappe hhid s01q01 age ethnie matrim)
	
	gen grupo="F" if s01q01==2
	replace grupo="M" if s01q01==1
	replace grupo=grupo+"_"+string(age)
	keep vague grappe hhid p grupo ethnie matrim
	reshape wide p, i(vague grappe hhid ethnie matrim) j(grupo) string
	
	unique p* grappe ethnie matrim
	*209 variables, this set identifies uniquely each household
	rename hhid hhid_new
	
	tempfile new_hh
	save `new_hh', replace 
	
*****************************************
	
	use "$data_sn/s01_me_SEN2018.dta", clear
	assert hhid == grappe*1000+menage
	*br if inlist(hhid,360001,360009,4005,4008,28001,28007,478006,478010)
	replace s01q03c=. if s01q03c==999 | s01q03c==9999
	gen age=2019-s01q03c
	replace age=999 if age==.
	gen p=1
	recode s01q16 .=0
	recode s01q07 .=0
	bys hhid: egen ethnie = mean(s01q16)
	bys hhid: egen matrim = mean(s01q07)
	
	collapse (sum) p , by(vague grappe hhid s01q01 age ethnie matrim)
	
	gen grupo="F" if s01q01==2
	replace grupo="M" if s01q01==1
	replace grupo=grupo+"_"+string(age)
	keep vague grappe hhid p grupo ethnie matrim
	reshape wide p, i(vague grappe hhid ethnie matrim) j(grupo) string
	
	unique p* grappe ethnie matrim
	*209 variables, este set es unique
	
	merge 1:1 p* grappe ethnie matrim using `new_hh'
	
	gen menage_old = hhid-floor(hhid/100)*100
	gen menage_new = hhid_new-floor(hhid_new/100)*100
	
	tab menage*
	
************************************************
*THERE YOU HAVE IT! MENAGE IS DIFFERENT!!
	
	keep menage* hhid*
	label var hhid "Old hhid"
	label var menage_new "New menage"
	rename menage_new menage
	
	save "$data_sn/CORR_HHID_MENAGES.dta"





























