
clear all
macro drop all
set more off, perm

// Note that scripts folder and project folder can be separated from each other. This gives flexibility for collaborators not needing to share datasets but only code
if "`c(username)'"=="andre" {
	global proj	"C:\Users\andre\Dropbox\Energy_Reform" // project folder
	*Prepare data on consumption 
	global path_raw "$proj/data/raw"
	global path_ceq "$proj/data/raw"
	global p_scr 	"$proj/SN-Energy-Reform-/scripts"
	*global p_res	"$proj/results"
	global p_res	"$proj/SN-Energy-Reform-/results"
} 


global p_o 		"$proj/data/output"
global p_pre 	"$proj/pre_analysis"
global presim	"$proj/data/raw/2_pre_sim"


use "$path_ceq/output.dta", clear 

global data_sn "C:\Users\andre\Dropbox\Energy_Reform\data\raw"


use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\s01_me_SEN2018.dta", clear
assert hhid == grappe*1000+menage
merge m:1 hhid using "$path_ceq/output.dta" , keepusing(yc_pc zref pondih poor_ref)

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s02_me_SEN2018.dta", gen(merged2)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s04_me_SEN2018.dta", gen(merged4)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s01_me_SEN2018.dta", gen(merged1)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s05_me_SEN2018.dta", gen(merged5)
rename menage menage_old
merge m:1 hhid using "$data_sn/CORR_HHID_MENAGES.dta", nogen
merge 1:1 grappe vague menage s01q00a using "$data_sn/1_raw/s06_me_SEN2018.dta", gen(merged6)

replace s01q03c=. if s01q03c==999 | s01q03c==9999
gen age=2018-s01q03c if vague==1
replace age=2019-s01q03c if vague==2
replace age= s01q04a if age==.

*We want two profiles:

*15-24 YO woman, rural, poor
gen profile1=(s01q01==2 & age>=15 & age<=24 & s00q04==2 & poor_ref==1)


*15-24 YO man, urban
gen profile2=(s01q01==1 & age>=15 & age<=24 & s00q04==1)


*Education
	gen yearsedu=s02q31 if s02q29==1
	replace yearsedu=s02q31+3 if s02q29==2
	replace yearsedu=s02q31+8 if s02q29==3
	replace yearsedu=s02q31+8 if s02q29==4
	replace yearsedu=s02q31+12 if s02q29==5
	replace yearsedu=s02q31+12 if s02q29==6
	replace yearsedu=s02q31+15 if s02q29==7
	replace yearsedu=s02q31+15 if s02q29==8
	replace yearsedu=0 if yearsedu==.

*employment status
	*gen wage_earner=(s04q39>=1 & s04q39<=6)
	*gen self_employ=(s04q39>=9 & s04q39<=10)
	recode s04q06 2=0
	recode s04q07 2=0
	recode s04q08 2=0
	recode s04q09 2=0
	egen working=rowtotal(s04q06 s04q07 s04q08 s04q09)
	replace working=1 if working!=0

*family status
	rename s01q07 family_status
	gen single = (family_status == 1)
	gen married_m = (family_status == 2)
	gen married_p = (family_status == 3)
	gen u_libre = (family_status == 4)
	gen widow = (family_status == 5)
	gen divorced = (family_status == 6)
	gen separated = (family_status == 7)


*etat civil 
*(do they have id)
	gen acte_naissance = (s01q05==1)

*revenue
	gen double impa=s04q43 if s04q43_unite==2 //(4.43) Quel a été le salaire de [NOM] pour cet emploi (pour la période de temps considérée)? (Main salary)
	replace impa=s04q43*4 if s04q43_unite==1
	replace impa=s04q43/3 if s04q43_unite==3
	replace impa=s04q43/12 if s04q43_unite==4

	gen double impaes=s04q47 if s04q47_unite==2 // (4.46) [NOM] bénéficie-t-il d'autres avantages quelconques (indemnités de transport, indemnités de logement, etc. autres que la nourriture) non inclus dans le salaire dans le cadre de cet emploi? (In-kind payments)
	replace impaes=s04q47*4 if s04q47_unite==1
	replace impaes=s04q47/3 if s04q47_unite==3
	replace impaes=s04q47/12 if s04q47_unite==4

	egen impa_f=rowtotal(impa impaes)

	gen double inc1_a=impa_f*s04q32 // s04q32 Months with the jobs 

	* Secondary Employment Labor Income  (cash + In-Kind) 
	gen double isa=s04q60 if s04q60_unite==2
	replace isa=s04q60*4 if s04q60_unite==1
	replace isa=s04q60/3 if s04q60_unite==3
	replace isa=s04q60/12 if s04q60_unite==4

	gen double inc2_a=isa*s04q54
	replace inc2_a=isa*12 if s04q60_unite==. & isa!=.


*savings
	sum s06q01__1 s06q01__2 s06q01__3 s06q01__4 s06q01__5 if profile1==1
	gen credit = (s06q05==1)
	
	
*bourse familiale
*registre
*edu
	**** Identify students by level
	*C8 attend or not during 2010/2011
	gen attend = 1 if  s02q12==1 // attend school during 2017-2018
	gen pub_school=1 if  inlist(s02q09,1,5,6) // Public Francais and communautaire
	gen pri_school=1 if  inlist(s02q09,2,3,4)  // Privé religieux, non-rel, international

	*--------------Maternelle
	**Public
	gen     ben_pre_school= 0
	replace ben_pre_school= 1 if s02q14==1  & attend==1 & pub_school==1
	***Private
	gen     ben_pre_school_pri= 0
	replace ben_pre_school_pri= 1 if s02q14==1  & attend==1 & pri_school==1
	*--------------Primaire
	**Public
	gen ben_primary=0
	replace ben_primary= 1 if s02q14==2 & attend==1 & pub_school==1  // CI, CP, CE1, CE2, CM1, CM2
	replace ben_pre_school =1 if ben_primary==1 & age<=3 
	replace ben_primary= 0 if ben_primary==1 & age<=3 
	**Private
	gen ben_primary_pri=0
	replace ben_primary_pri= 1 if s02q14==2 & attend==1 & pri_school==1  // CI, CP, CE1, CE2, CM1, CM2
	replace ben_pre_school_pri =1 if ben_primary_pri==1 & age<=3 
	replace ben_primary_pri= 0 if ben_primary_pri==1 & age<=3 
	*--------------Secondaire 1 (Post Primaire) Général and Secondaire 1 (Post Primaire) Technique
	**Public
	gen ben_secondary_low=0
	replace ben_secondary_low=1 if s02q14==3 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
	replace ben_secondary_low=1 if s02q14==4 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
	**Private
	gen     ben_secondary_low_pri=0
	replace ben_secondary_low_pri=1 if s02q14==3 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
	replace ben_secondary_low_pri=1 if s02q14==4 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
	*--------------Secondaire 2 Général  and Secondaire 2 Technique
	**Public
	gen ben_secondary_up=0
	replace ben_secondary_up=1 if  s02q14==5 & attend==1 & pub_school==1  // 2nde 1ère Terminale
	replace ben_secondary_up=1 if  s02q14==6 & attend==1 & pub_school==1  // 2nde 1ère Terminale
	***Private
	gen ben_secondary_up_pri=0
	replace ben_secondary_up_pri=1 if s02q14==5 & attend==1 & pri_school==1  // 2nde 1ère Terminale
	replace ben_secondary_up_pri=1 if s02q14==6 & attend==1 & pri_school==1  // 2nde 1ère Terminale
	*--------------Combining into secondary and primary
	**Public
	gen     ben_secondary = 1 if (ben_secondary_low==1 | ben_secondary_up==1) & pub_school==1 
	replace ben_primary   = 1 if  ben_secondary==1 & age<=9
	replace ben_secondary = 0 if  ben_secondary==1 & age<=9
	***Private
	gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1
	replace ben_primary_pri   = 1 if  ben_secondary_pri==1 & age<=9
	replace ben_secondary_pri = 0 if  ben_secondary_pri==1 & age<=9
	*--------------Teritiary
	**Public
	gen     ben_tertiary=0
	replace ben_tertiary=1 if s02q14==7 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
	replace ben_tertiary=1 if s02q14==8 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
	***Private
	gen     ben_tertiary_pri=0
	replace ben_tertiary_pri=1 if s02q14==7 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+
	replace ben_tertiary_pri=1 if s02q14==8 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+

	*--------------Defining type of beneficiary ed_level
	gen ed_level = . 
	replace ed_level= 1 if ben_pre_school==1
	replace ed_level= 2 if ben_primary==1
	replace ed_level= 3 if ben_secondary==1
	replace ed_level= 4 if ben_tertiary==1

	label define educlevel 1 "Pre-school" 2 "Primary" 3 "Secondary" 4 "Terciary"

	gen ed_level_pri = . 
	replace ed_level_pri= 1 if ben_pre_school_pri==1
	replace ed_level_pri= 2 if ben_primary_pri==1
	replace ed_level_pri= 3 if ben_secondary_pri==1
	replace ed_level_pri= 4 if ben_tertiary_pri==1
	
	
	
	
*health
*agropoles
*pole emploi
*employment services 
*etc…


use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\s15_me_sen2018.dta" , clear
merge m:1 grappe menage using "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\ehcvm_welfare_sen2018.dta" , keepusing(hhweight hhsize)

tab s15q01
 




foreach var in working single married_m married_p u_libre widow divorced separated acte_naissance s06q01__1 s06q01__2 s06q01__3 s06q01__4 s06q01__5 credit





















