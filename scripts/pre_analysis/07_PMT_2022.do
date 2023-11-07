/*

Main changes with respect the past 

// DV: important!!!!!!!!! before was this combination of variables that did not match perfectly( key interview__key interview__id id_menage grappe vague) we replace them by hhid and it works now


*/

tempfile section1
tempfile section11
tempfile section12
tempfile section15
tempfile section17
set seed 123456789

**********************************************************************

/*=================================================
=================================================
		1. Proxy mean Test Score 
=================================================
=================================================*/

/*------------------------------------------------
 `section1' :demographics by household level 
------------------------------------------------*/
 
	use "$path_raw1/s01_me_sen_2021.dta", clear
	merge m:1 vague grappe menage using "$path_raw1/s00_me_sen_2021.dta"
	
	*Definition 1: preload
	replace s01qpreload_age=. if s01qpreload_age==999 | s01qpreload_age==9999
	
	*Definition 2: age question
	replace s01q04a=. if s01q04a==999 | s01q04a==9999
	replace s01q04b=. if s01q04b==999 | s01q04b==9999
	
	*Definition 3: Based on date de naissance
	replace s01q03a=. if s01q03a==999 | s01q03a==9999
	replace s01q03b=. if s01q03b==999 | s01q03b==9999
	replace s01q03c=. if s01q03c==999 | s01q03c==9999
	
	gen date_survey_started = date(s00q23a,"YMD#hms")
	format date_survey_started %td
	gen age = date_survey_started-mdy(s01q03b,s01q03a,s01q03c)
	replace age=floor(age/365.25)
	replace age=0 if age==-1
	
	/*Analyses
	twoway (hist s01qpreload_age, disc) (hist s01q04a, color("60 255 0%55") disc) (hist age, color("255 60 0%39") disc), legend(position(1) ring(0) label(1 "Preload") label(2 "Age question")  label(3 "Using birth date"))
	sum s01qpreload_age s01q04a age
	graph matrix s01qpreload_age s01q04a age, msize(tiny)
	*/
	
	*Decide on an age variable to use for the simulation stage
	rename age age_birthdate
	
	gen age = s01q04a
	replace age = s01qpreload_age if age>=.
	replace age = age_birthdate if age>=.
	
	preserve
		keep grappe menage vague s01q00a age
		save "$presim/07_indiv_ages.dta", replace
	restore
	
	gen majeur_60=1 if age>59
	recode majeur_60 .=0
	
	gen jeune_15=1 if age<16
	recode jeune_15 .=0
	
	collapse (sum) majeur_60 jeune_15, by(grappe menage vague s00q02)
	
	save `section1'

/*------------------------------------------------
 `section11' : Access to utilities and housing
------------------------------------------------*/

	use "$path_raw1/s11_me_sen_2021.dta", clear
	
	gen eau_potable= (s11q21==1)
	
	gen assainissement=s11q57
		replace assainissement=8 if s11q57==.
	
	gen revetement_sol=s11q20
	
	gen eau_potable1= s11q26a 
	gen eau_potable2= s11q26b
	
	gen eclairage = s11q37
	replace eclairage = 8 if eclairage==.
	
	gen revetement_mur = s11q18
	
	gen toilette=1 if inlist(s11q54,1,2,3,4)
		replace toilette=2 if inlist(s11q54,5,6,7,8)
		replace toilette=3 if inlist(s11q54,9)
		replace toilette=4 if inlist(s11q54,10)
		replace toilette=5 if inlist(s11q54,11)
		replace toilette=6 if inlist(s11q54,12)
	
	gen nombre_pieces=s11q02
	
	collapse (mean) eau_potable assainissement revetement_sol eau_potable1 eau_potable2 eclairage revetement_mur toilette nombre_pieces  , by(menage grappe vague)
	
	save `section11' 

/*------------------------------------------------
 `section15' : Effectively received PNBSF
------------------------------------------------*/

	use "$path_raw1/s15_me_sen_2021.dta", clear
	keep if s15q01==12
	
	keep vague grappe menage s15q05
	
	rename s15q05 recu_PNBSF
	replace recu_PNBSF=0 if recu_PNBSF==. | recu_PNBSF==2
		
	save `section15'

/*------------------------------------------------
 `section12' : nombre_assets 
------------------------------------------------*/
	
	preserve
	use "$path_raw1/s12_me_sen_2021.dta", clear
	
	keep if inlist(s12q01,29,28,19,18,20,35,34,40,37,16,17)
	
	recode s12q02 2=0
	
	collapse (sum) s12q02  , by(vague grappe menage)
	
	rename s12q02 nombre_assets
	
	save `section12'
	restore

/*------------------------------------------------
 `section17' : possesions_bien_essentiels
------------------------------------------------*/

	preserve
	use "$path_raw1/s17_me_sen_2021.dta", clear
	
	keep if inlist(s17q01,2,3,7,9,10,11)
	
	recode s17q03 2=0
	replace s17q06=s17q05 if s17q06==.
	gen appartient_menage=s17q06*s17q03
	
	
	collapse (sum) appartient_menage  , by(vague grappe menage)
	
	gen possesions_elevage = (appartient_menage>0)
	
	save `section17'
	restore

/*------------------------------------------------
 Merging all data
------------------------------------------------*/

use "$path_raw2/ehcvm_welfare_SEN_2021.dta", clear
merge 1:1 vague grappe menage using `section15', nogen
merge 1:1 vague grappe menage using `section1', nogen
merge 1:1 vague grappe menage using `section11', nogen
merge 1:1 vague grappe menage using `section12', nogen
merge 1:1 vague grappe menage using `section17', nogen

gen log_cons_pc= log(dtot/hhsize)
gen piece_pc=nombre_pieces/hhsize

reg log_cons_pc majeur_60 jeune_15 i.eau_potable i.assainissement i.revetement_sol ///
	eau_potable1 eau_potable2 i.eclairage i.revetement_mur i.toilette piece_pc ///
	nombre_assets appartient_menage possesions_elevage

predict xb
rename xb PMT

*What if we want to predict the likelihood of being a PNBSF recipient?
logit recu_PNBSF log_cons_pc majeur_60 jeune_15 i.eau_potable i.assainissement i.revetement_sol ///
	eau_potable1 eau_potable2 i.eclairage i.revetement_mur i.toilette piece_pc ///
	nombre_assets appartient_menage possesions_elevage i.hgender hage i.hreligion

predict pr
rename pr PNBSF_propensity

sum PNBSF_propensity

*If we want to start assigning PNBSF to those that actually report it, we can modify the propensity like this:
replace PNBSF_propensity = PNBSF_propensity+recu_PNBSF

drop PMT
gen PMT=-PNBSF_propensity

/*------------------------------------------------
 Sorting individuals by within each department by PMT score
------------------------------------------------*/

rename s00q02 departement

*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================

gen pmt_seed= uniform()

save "$presim/07_PMT_2021.dta", replace



*==================================================================================
dis "==============         Defining benefits from education system		==========="
*==================================================================================

use "$path_raw1/s02_me_sen_2021.dta", clear
merge 1:1 vague grappe menage s01q00a using "$presim/07_indiv_ages.dta", nogen keep(1 3)

**** Identify students by level
*There is also info on 2020/2021 but because of Covid, I chose to use the next year
gen attend = 1 if  s02q12==1 // attend school during 2021-2022
gen pub_school = (inlist(s02q19,1,5,6))  // Gouvernement, Communauté et autres
gen pri_school = (inlist(s02q19,2,3,4))  // Privé

*--------------Maternelle
**Public
gen     ben_preschool_pub = 0
replace ben_preschool_pub = 1 if s02q14==1  & attend==1 & pub_school==1
**Private
gen     ben_preschool_pri = 0
replace ben_preschool_pri = 1 if s02q14==1  & attend==1 & pri_school==1
*--------------Primaire
**Public
gen 	ben_primary_pub = 0
replace ben_primary_pub = 1 	if s02q14==2 & attend==1 & pub_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_preschool_pub = 1 	if ben_primary_pub==1 & age<=3 
replace ben_primary_pub = 0 	if ben_primary_pub==1 & age<=3 
**Private
gen 	ben_primary_pri = 0
replace ben_primary_pri = 1 	if s02q14==2 & attend==1 & pri_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_preschool_pri = 1 	if ben_primary_pri==1 & age<=3 
replace ben_primary_pri = 0 	if ben_primary_pri==1 & age<=3 
*--------------Secondaire 1 (Post Primaire) Général and Secondaire 1 (Post Primaire) Technique
**Public
gen 	ben_secondary_low_pub=0
replace ben_secondary_low_pub=1 if s02q14==3 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low_pub=1 if s02q14==4 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
**Private
gen     ben_secondary_low_pri=0
replace ben_secondary_low_pri=1 if s02q14==3 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low_pri=1 if s02q14==4 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
*--------------Secondaire 2 Général  and Secondaire 2 Technique
**Public
gen 	ben_secondary_up_pub=0
replace ben_secondary_up_pub=1	if s02q14==5 & attend==1 & pub_school==1  // 2nde 1ère Terminale
replace ben_secondary_up_pub=1	if s02q14==6 & attend==1 & pub_school==1  // 2nde 1ère Terminale
**Private
gen 	ben_secondary_up_pri=0
replace ben_secondary_up_pri=1	if s02q14==5 & attend==1 & pri_school==1  // 2nde 1ère Terminale
replace ben_secondary_up_pri=1	if s02q14==6 & attend==1 & pri_school==1  // 2nde 1ère Terminale
*--------------Combining into secondary and primary
**Public
gen     ben_secondary_pub = 1 if (ben_secondary_low_pub==1 | ben_secondary_up_pub==1) & pub_school==1 
replace ben_primary_pub   = 1 if  ben_secondary_pub==1 & age<=9
replace ben_secondary_pub = 0 if  ben_secondary_pub==1 & age<=9
**Private
gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1
replace ben_primary_pri   = 1 if  ben_secondary_pri==1 & age<=9
replace ben_secondary_pri = 0 if  ben_secondary_pri==1 & age<=9
*--------------Tertiary (Post secondaire et Supérieur)
**Public
gen     ben_tertiary_pub=0
replace ben_tertiary_pub=1	if s02q14==7 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary_pub=1	if s02q14==8 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
**Private
gen     ben_tertiary_pri=0
replace ben_tertiary_pri=1	if s02q14==7 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary_pri=1	if s02q14==8 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+

*--------------Defining type of beneficiary ed_level
gen ed_level_pub = . 
replace ed_level_pub= 1 if ben_preschool_pub==1
replace ed_level_pub= 2 if ben_primary_pub==1
replace ed_level_pub= 3 if ben_secondary_pub==1
replace ed_level_pub= 4 if ben_tertiary_pub==1

label define educlevel 1 "Pre-school" 2 "Primary" 3 "Secondary" 4 "Terciary"

gen ed_level_pri = . 
replace ed_level_pri= 1 if ben_preschool_pri==1
replace ed_level_pri= 2 if ben_primary_pri==1
replace ed_level_pri= 3 if ben_secondary_pri==1
replace ed_level_pri= 4 if ben_tertiary_pri==1

*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================

gen school_seed= uniform()
gen ter_seed= uniform()
gen ter2_seed= uniform()

gen cmu50_seed=runiform()
gen pben_sesame_seed=runiform()
gen pben_moins5_seed=runiform()
gen cesarienne_seed=runiform()
gen cmu100_seed=runiform()

keep vague grappe menage s01q00a age-cmu100_seed

save "$presim/07_educ_seeds_2021.dta", replace

*==================================================================================
dis "============== Adding variables to define health system and labor status ==========="
*==================================================================================

use "$path_raw1/s04a_me_sen_2021.dta", clear
merge 1:1 vague grappe menage s01q00a using "$path_raw1/s04b_me_sen_2021.dta", nogen

gen cotise_pension = (s04q38==1)		// cotise-t-il à l'IPRES, au FNR ou à la Retraite Complém
gen emp_publiq = (inlist(s04q31,1,2,6)) // Public employee or NGO
gen bulletin_salaire = (s04q42==1)		// receive payslip

gen formal= (cotise_pension==1 | emp_publiq==1 | bulletin_salaire==1)

*(AGV) All these variables existed in the 2018 version and do not understand why they were created like this.
*I will leave them just in case, but hopefully I can come later and clean this part.

gen formal_definitivo=formal // completely exhaustive dummy so not needed previous code

gen informal = .
replace informal = 1 if formal_definitivo==0 & s04q10==1 //  Parmi les réponses aux questions 4.06, 4.07, 4.08, 4.09 y en a-t-il une affirmative (employed)
  
gen formality = . 
replace formality = 1 if formal==1
replace formality = 0 if informal==1 
  
bys vague grappe menage: egen informalh=max(informal)
 
*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================
*Note Seed were not working the sim do-file so they wil be generated here 

save "$presim/07_formal_employee_2021.dta", replace
	