/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"

Pendent: Find out why when uncomment
 merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$presim/07_dir_trans_PMT_educ_health.dta"
and comment the other merge does not work 


*********************************************************************************/

*global namexls	"PNBSF_reform"
*import excel "$p_res/${namexls}.xlsx", sheet("PNBSF_deps") first clear cellrange(B4)
global xls_sn "C:\Users\andre\Dropbox\Energy_Reform\results/SN_Sim_tool_V.xlsx"




**** PNBSF

import excel "$xls_sn", sheet(PNBSF_raw) first clear

levelsof departement, local(departement)
global departementPNBSF `departement'
foreach z of local departement {
	levelsof Beneficiaires if departement==`z', local(PNBSF_Beneficiaires`z')
	global PNBSF_Beneficiaires`z' `PNBSF_Beneficiaires`z''
	levelsof Montant if departement==`z', local(PNBSF_montant`z')
	global PNBSF_montant`z' `PNBSF_montant`z''
}


**** Cantine Scolaire

import excel "$xls_sn", sheet(Cantine_scolaire_raw) first clear

levelsof Region, local(region)
global regionCantine `region'
foreach z of local region {
	levelsof nombre_elevees if Region==`z', local(Cantine_Elevee`z')
	global Cantine_Elevee`z' `Cantine_Elevee`z''
	levelsof montant_cantine if Region==`z', local(Cantine_montant`z')
	global Cantine_montant`z' `Cantine_montant`z''
}

**** Bourse Universitaire

import excel "$xls_sn", sheet(Bourse_universitaire) first clear

levelsof Type, local(type) clean
global TypeBourseUniv `type'
foreach z of local type {
	levelsof Beneficiaires if Type=="`z'", local(Bourse_Beneficiaire`z')
	global Bourse_Beneficiaire`z' `Bourse_Beneficiaire`z''
	levelsof montant if Type=="`z'", local(Bourse_montant`z')
	global Bourse_montant`z' `Bourse_montant`z''
}

****  CMU

import excel "$xls_sn", sheet(CMU_raw) first clear

levelsof Programme, local(CMU) clean
global Programme_CMU `CMU'
foreach z of local CMU {
	levelsof Beneficiaires if Programme=="`z'", local(CMU_b_`z')
	global CMU_b_`z' `CMU_b_`z''
	levelsof Montant if Programme=="`z'", local(CMU_m_`z')
	global CMU_m_`z' `CMU_m_`z''
}

**** Education

import excel "$xls_sn", sheet(education_raw) first clear
levelsof Niveau, local(Niveau) clean
global Education `Niveau'
foreach z of local Niveau {
	levelsof Montant if Niveau=="`z'", local(Edu_montant`z')
	global Edu_montant`z' `Edu_montant`z''
}

**** Health 

import excel "$xls_sn", sheet(Sante_raw2) first clear

levelsof Programme, local(Programme) clean
global Sante `Programme'
foreach z of local Programme{
	levelsof Montant if Programme=="`z'", local(Montant_`z')
	global Montant_`z' `Montant_`z''
}










set seed 1234
use  "$presim/07_dir_trans_PMT.dta", replace // hh level dataset 1.7 mlln

/**********************************************************************************
*             1. Programme National de Bourses de Sécurité Familiale               *
**********************************************************************************/

levelsof departement, local(department)

foreach var of local department { 
	preserve
		keep if departement==`var'
		
		ren pmt_seed rannum
		*gen rannum= uniform()
		
		sort PMT rannum
		gen count_id=_n
	
		levelsof count_id, local(gente)
	
		gen count_PBSF_`var'=.
	
		*set seed 12345
	
		tempfile auxiliar_PNBSF_`var'
	
		foreach z of local gente {
			replace count_PBSF_`var'=hhweight if count_id==1
			replace count_PBSF_`var'= count_PBSF_`var'[`=`z'-1']+hhweight[`z'] if count_id==`z'
		}
	
		save `auxiliar_PNBSF_`var''
	restore
}

preserve
clear 
foreach var of local department { 
	append using `auxiliar_PNBSF_`var''
	}

tempfile auxiliar_PNBSF
save `auxiliar_PNBSF'	//*save "$dta/auxiliar_PNBSF.dta", replace
restore

merge 1:1 hhid using `auxiliar_PNBSF' , nogen keepusing(count_PBSF*) // *merge 1:1 hhid using "$dta/auxiliar_PNBSF.dta", nogen keepusing(count_PBSF*)



gen beneficiaire_PNBSF=.
gen am_BNSF=.

levelsof departement, local(department)

foreach var of local department { 
	replace beneficiaire_PNBSF=1 if count_PBSF_`var'<= ${PNBSF_Beneficiaires`var'} & departement==`var'
	replace am_BNSF= ${PNBSF_montant`var'} if beneficiaire_PNBSF==1 & departement==`var'
} 


/**********************************************************************************
*                     2. Programme des Cantines Scolaires                          *
**********************************************************************************/

{

drop interview__key interview__id id_menage grappe vague
merge 1:m hhid  using  "$presim/07_educ.dta", nogen // not matched ae

/*------------------------------------------------
 Sorting beneficiaries within each region RANDOMLY

Notes: 
ben_pre_school==1 	attends pre-school, or primary & younger than 3,  and public
ben_primary==1		attends primary public school 
------------------------------------------------*/
*/

gen preandpri=(ben_pre_school== 1 | ben_primary==1)

levelsof region, local(region)
*Not here !: set seed 12345

foreach var of local region { 
	preserve
	keep if preandpri==1
	keep if region==`var'
	ren school_seed rannum
	*gen rannum= uniform()
	sort rannum
	gen count_id=_n

	levelsof count_id, local(gente)

	gen count_Cantine_`var'=.

	
	*set seed 12345

	tempfile auxiliar_Cantine_`var'

	foreach z of local gente{
		replace count_Cantine_`var'=hhweight if count_id==1
		replace count_Cantine_`var'= count_Cantine_`var'[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

save `auxiliar_Cantine_`var''
restore
}


preserve
clear 
foreach var of local region { 
	append using `auxiliar_Cantine_`var''
	}
	
*save "$dta/auxiliar_cantine.dta", replace

tempfile auxiliar_cantine
save `auxiliar_cantine'
restore


merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_cantine' , nogen keepusing(count_Cantine*) // *merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$dta/auxiliar_cantine.dta", nogen keepusing(count_Cantine*)

/*------------------------------------------------
Assigning benefits 
------------------------------------------------*/

gen beneficiaire_Cantine=.
gen am_Cantine=.

levelsof region, local(region)

foreach var of local region { 
	replace beneficiaire_Cantine=1 if count_Cantine_`var'<= ${Cantine_Elevee`var'} & region==`var'
	replace am_Cantine= ${Cantine_montant`var'} if beneficiaire_Cantine==1 & region==`var'
} 


dis("Calculating ${Cantine_montant1}")
tempfile auxiliar_cantine_II
save `auxiliar_cantine_II' // *save "$dta/auxiliar_cantine.dta", replace

}


/**********************************************************************************
*            3. Bourse de L'education superieur  (Private and public)  			  *
**********************************************************************************/

/*------------------------------------------------
 Sorting PUBLIC tertiary  RANDOMLY

Notes: 
ben_tertiary==1 	attends public college
------------------------------------------------*/

{
preserve
		keep if ben_tertiary==1
		*gen rannum= uniform()
		ren ter_seed rannum
		sort rannum
		gen count_id=_n
	
		levelsof count_id, local(gente)
	
		gen count_bourse_public=.
	
		*set seed 12345
		
		tempfile auxiliar_bourse_public
	
		foreach z of local gente{
			replace count_bourse_public=hhweight if count_id==1
			replace count_bourse_public= count_bourse_public[`=`z'-1']+hhweight[`z'] if count_id==`z'
		}
	
	save `auxiliar_bourse_public'
restore

/*------------------------------------------------
 Sorting PRIVATE tertiary  RANDOMLY

Notes: 
ben_tertiary==1 	attends private college
------------------------------------------------*/

preserve
		keep if ben_tertiary_pri==1
		
		*gen rannum= uniform()
		ren ter2_seed rannum
		sort rannum
		gen count_id=_n
	
		levelsof count_id, local(gente)
	
		gen count_bourse_privee=.
	
		*set seed 12345

		tempfile auxiliar_bourse_privee
	
		foreach z of local gente{
			replace count_bourse_privee=hhweight if count_id==1
			replace count_bourse_privee= count_bourse_privee[`=`z'-1']+hhweight[`z'] if count_id==`z'
		}
	
	save `auxiliar_bourse_privee'
restore


merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_bourse_public' , nogen keepusing(count_bourse_public)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_bourse_privee' , nogen keepusing(count_bourse_privee)

gen beneficiaire_bourse=.
gen am_bourse=.

replace beneficiaire_bourse=1 if count_bourse_public<= ${Bourse_BeneficiairePublic} & ben_tertiary==1 
replace am_bourse= ${Bourse_montantPublic} if beneficiaire_bourse==1 & ben_tertiary==1 
replace beneficiaire_bourse=1 if count_bourse_privee<= ${Bourse_BeneficiairePrivee} & ben_tertiary_pri==1 
replace am_bourse= ${Bourse_montantPrivee} if beneficiaire_bourse==1 & ben_tertiary_pri==1 


}

/**********************************************************************************
*            				4. CMU
**********************************************************************************/

*merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$presim/07_dir_trans_PMT_educ_health.dta"

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s04_me_SEN2018.dta", gen(merged4)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s01_me_SEN2018.dta", gen(merged5) update
merge n:1 interview__key interview__id id_menage grappe vague  using "$data_sn/s00_me_SEN2018.dta", gen(merged6) keepusing(hhid) update
merge n:1 hhid  using "$data_sn/ehcvm_conso_SEN2018_menage.dta", gen(merged7) keepusing(hhweight) update
*Not here: set seed 12345


*test seed define in educ are still working 
gen cmu50_seed2=runiform()
mdesc cmu50_seed2 cmu50_seed



gen formal=1 if s04q38==1 // cotise-t-il à l'IPRES, au FNR ou à la Retraite Complém
replace formal=1 if inlist(s04q31,1,2,6) // Public employee or NGO 
replace formal=1 if s04q42==1 // receive payslip
recode formal .=0

gen formal_definitivo=formal // completely exhaustive dummy so not needed previous code

gen informal = .
replace informal = 1 if formal_definitivo==0 & s04q10==1 //  Parmi les réponses aux questions 4.06, 4.07, 4.08, 4.09 y en a-t-il une affirmative (employed)
  
gen formality = . 
replace formality = 1 if formal==1
replace formality = 0 if informal==1 
  
bys hhid: egen informalh=max(informal)
 
***Selecting beneficiaries

gen aux2 = 1 if informalh==1 & beneficiaire_PNBSF==1 & s01q02==1 // at least one informal hh member| PNBSF beneficiarie || household head
 
/*------------------------------------------------
CMU 50%
Assign random benefits to informal households
 not beneficiaries from PNBSF
Notes: 
------------------------------------------------*/
*set seed 264595 
preserve
	keep if informalh==1  & beneficiaire_PNBSF!=1 & s01q02==1 // at least one hh informal, do not receive PNBSF 
	
	*gen random=runiform()
	ren cmu50_seed random
	sort random
	gen count_id=_n

	gen count_CMU_50=.
	gen pondera= hhweight*hhsize	
	tempfile auxiliar_CMU_50
	
	levelsof count_id, local(households)

	foreach z of local households{
		replace count_CMU_50=pondera if count_id==1
		replace count_CMU_50= count_CMU_50[`=`z'-1']+pondera[`z'] if count_id==`z'
	}

	save `auxiliar_CMU_50'
restore

merge n:1 interview__key interview__id id_menage grappe vague  using `auxiliar_CMU_50' , nogen keepusing(count_CMU_50)
gen ben_CMU50i=1 if count_CMU_50 <=$CMU_b_CMU_parcial
recode ben_CMU50i .=0
bys hhid: egen ben_CMU50h = max(ben_CMU50i)
label var ben_CMU50h "Hhs beneficiary of 50% CMU contributions" // (DV) Only 32 observations!!!!!!!!!!!!


/*------------------------------------------------
*Plan Sésame " Sésame" offers to senegalese above 60 years old the right to free health care in the whole country 
*Household is beneficiary of CMU or from PNBSF, and older than 60 y/o
------------------------------------------------*/

*gen edad=2018-s01q03c //replaced by age
gen pben_sesame = 1 if (ben_CMU50h==1 | beneficiaire_PNBSF==1) & age >= 60

*NOt here : set seed 12345
preserve
	keep if pben_sesame ==1
	
	ren pben_sesame_seed  random
	*gen random=runiform()
	sort random
	gen count_id=_n

	levelsof count_id, local(people)

	gen count_plan_sesame=.

	tempfile auxiliar_plan_sesame
	
	foreach z of local people {
		replace count_plan_sesame=hhweight if count_id==1
		replace count_plan_sesame= count_plan_sesame[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

	save `auxiliar_plan_sesame'
restore

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_plan_sesame' , nogen keepusing(count_plan_sesame)
gen  ben_sesame=1 if count_plan_sesame <=$CMU_b_Plan_Sesame
gen  am_sesame= $CMU_m_Plan_Sesame if  ben_sesame==1 


/*------------------------------------------------
*Gratuité pour les moins de 5 ans free health care 
for children between 0 and 5 years old.

The health center is supposed to see the patient for free without any consultation fees
RANDOM 
------------------------------------------------*/

gen  pben_moins5=1 if (ben_CMU50h==1 | beneficiaire_PNBSF==1) & age<= 5

*Not here: set seed 12345
preserve
	keep if pben_moins5==1
	
	ren pben_moins5_seed  random
	*gen random=runiform()
	sort random
	gen count_id=_n

	levelsof count_id, local(people)

	gen count_moins5=.

	tempfile auxiliar_moins5
	
	foreach z of local people {
		replace count_moins5=hhweight if count_id==1
		replace count_moins5= count_moins5[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

	save `auxiliar_moins5'
restore

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_moins5' , nogen keepusing(count_moins5)
gen ben_moins5=1 if count_moins5<=$CMU_b_Soins_gratuit_enfants
gen am_moin5=$CMU_m_Soins_gratuit_enfants if ben_moins5==1

/*------------------------------------------------
*Gratuité de la césarienne This programme covers the fees of all 
deliveries in clinics and health centres and C-sections in 
regional and district hospitals for all women

RANDOM 
------------------------------------------------*/


gen child = 1 if s01q02==3 & age==1 
bys hhid: egen hh_child= max(child)
gen pben_cesarienne=1 if (ben_CMU50h==1  | beneficiaire_PNBSF==1) & hh_child==1 & s01q01==2 & (s01q02==1 | s01q02==2) & age<=40 // (DV it should be excluded gender in case mother died or mother is the household head)

*set seed 50

preserve
	keep if pben_cesarienne==1
	
	ren cesarienne_seed  random
	*gen random=runiform()
	sort random
	gen count_id=_n

	levelsof count_id, local(people)

	gen count_cesarienne=.

	tempfile auxiliar_cesarienne
	
	foreach z of local people{
		replace count_cesarienne=hhweight if count_id==1
		replace count_cesarienne= count_cesarienne[`=`z'-1']+ hhweight[`z'] if count_id==`z'
	}

	save `auxiliar_cesarienne'
	
restore

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_cesarienne' , nogen keepusing(count_cesarienne)


gen ben_cesarienne=1 if count_cesarienne<=$CMU_b_Cesariennes
gen am_cesarienne=$CMU_m_Cesariennes if ben_cesarienne==1


/*------------------------------------------------
***CMU 
	Subvention 100%
RANDOM 
------------------------------------------------*/

    
gen ben_CMU100i = 1 if (ben_cesarienne==1 | ben_sesame ==1) & beneficiaire_PNBSF==1 & ben_CMU50h!=1
bys hhid: egen pben_CMU100h = max(ben_CMU100i)

*Sorting 
*set seed 50
preserve
	keep if beneficiaire_PNBSF==1 & pben_CMU100h!=1 & s01q02==1
	
	ren cmu100_seed random
	*gen random=runiform()
	sort random
	gen count_id=_n

	levelsof count_id, local(households)

	gen count_CMU_100=.
	gen pondera=hhweight*hhsize

	tempfile auxiliar_CMU_100
	
	foreach z of local households{
		replace count_CMU_100=pondera if count_id==1
		replace count_CMU_100= count_CMU_100[`=`z'-1']+pondera[`z'] if count_id==`z'
	}

	save `auxiliar_CMU_100'
restore

merge n:1 interview__key interview__id id_menage grappe vague  using `auxiliar_CMU_100' , nogen keepusing(count_CMU_100)
 
 
sum ben_CMU100i [iw=hhweight] if (ben_cesarienne==1 | ben_sesame ==1) & beneficiaire_PNBSF==1 & ben_CMU50h!=1
local ben_CMU100i = `r(sum)' // population that is eligible for ben_CMU100i
global faltantes= $CMU_b_CMU_total - `ben_CMU100i'  // difference between total beneficiaries 

gen ben_CMU100i_2=1 if count_CMU_100 <=$faltantes
gen total_ben_CMU100i=ben_CMU100i
replace total_ben_CMU100i=ben_CMU100i_2 if total_ben_CMU100i!=1 // add new beneficiaries ben_CMU100i_2 to old beneficiaries

bys hhid: egen ben_CMU100h = max(total_ben_CMU100i)
label var ben_CMU100h "Hhs beneficiary of 100% CMU contributions" 

/*------------------------------------------------
***Amount of CMU100 and CMU 50 combined 
------------------------------------------------*/

gen     ben_CMUh =  .
replace ben_CMUh =  1 if (ben_CMU50h==1 | ben_CMU100h==1)
label var ben_CMUh "Hhs beneficiary of CMU contributions subsidy"
   
gen am_subCMU100 = $CMU_m_CMU_total if ben_CMU100h==1  
gen am_subCMU50  = $CMU_m_CMU_parcial if ben_CMU50h ==1  

gen     am_subCMU    = 0
replace am_subCMU = am_subCMU100 if am_subCMU100!=0 & am_subCMU100!=.
replace am_subCMU = am_subCMU50  if am_subCMU50!=0 & am_subCMU50!=.

****generates variables per capita 

egen am_CMU = rowtotal(am_sesame am_moin5 am_cesarienne)



    save "$presim/Direct_transfers_individ.dta", replace

collapse (mean) am_BNSF am_subCMU am_subCMU100 am_subCMU50 ///
		 (sum)  am_CMU am_sesame am_moin5 am_cesarienne am_Cantine am_bourse, by(hhid)

//am_BNSF am_subCMU am_subCMU100 am_subCMU50
//am_CMU am_sesame am_moin5 am_cesarienne am_Cantine am_bourse


    save "$presim/Direct_transfers.dta", replace

/*
tempfile Direct_transfers
save `Direct_transfers'



exit 

*Strategy of DV to defne ex-ante the random numbers, but it may be dangerus if not all observations are present. Still it does not work 
*gen random_cmu50=runiform()
*gen random_sesame=runiform()
*gen random_moins=runiform()
*gen random_cesa=runiform()
*gen random_cmu100=runiform()
