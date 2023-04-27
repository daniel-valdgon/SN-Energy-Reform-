
clear all
*macro drop all
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
global data_sn "C:\Users\andre\Dropbox\Energy_Reform\data\raw"


use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\s01_me_SEN2018.dta", clear
assert hhid == grappe*1000+menage
merge m:1 hhid using "$path_ceq/output.dta" , keepusing(yc_pc yd_pc zref pondih poor_ref hhweight)

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

*Correct poverty definition
*hist lyd [fw=hhweight], xline(12.717) fc(blue%50)
cap drop poor_ref
gen poor_ref = (yd_pc<zref)

*We want two profiles:

gen profile0=(age>=15 & age<=24)

*15-24 YO woman, rural, poor
gen profile1=(s01q01==2 & age>=15 & age<=24 & s00q04==2 & poor_ref==1)

*15-24 YO man, urban
gen profile2=(s01q01==1 & age>=15 & age<=24 & s00q04==1)

*More profiles will be defined below



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
	sum s06q01__1 s06q01__2 s06q01__3 s06q01__4 s06q01__5 if profile1==1 |  profile2==1
	gen credit = (s06q05==1)
	
	
/*bourse familiale
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

	label define educlevel 1 "Pre-school" 2 "Primary" 3 "Secondary" 4 "Tertiary"

	gen ed_level_pri = . 
	replace ed_level_pri= 1 if ben_pre_school_pri==1
	replace ed_level_pri= 2 if ben_primary_pri==1
	replace ed_level_pri= 3 if ben_secondary_pri==1
	replace ed_level_pri= 4 if ben_tertiary_pri==1
	
	
	sum am_bourse am_Cantine am_BNSF am_subCMU am_sesame am_moin5 am_cesarienne
	
*health
*agropoles
*pole emploi
*employment services 
*etc…
*/
/*
use "$presim/Direct_transfers_individ.dta", clear
	rename beneficiaire_bourse ben_bourse
	rename beneficiaire_Cantine ben_Cantine
	rename beneficiaire_PNBSF ben_BNSF
	rename ben_CMUh ben_subCMU
	rename ben_moins5 ben_moin5
	foreach var in _bourse _Cantine _BNSF _subCMU _sesame _moin5 _cesarienne {
		sum am`var' if am`var'!=0
		sum am`var' if ben`var'==1 
	}
*/

merge 1:1 interview__key interview__id grappe vague id_menage s01q00a using "$presim/Direct_transfers_individ.dta", keepusing(beneficiaire_bourse beneficiaire_Cantine beneficiaire_PNBSF ben_CMUh ben_moins5 ben_sesame ben_cesarienne) gen(merged_secsoc)

rename beneficiaire_bourse ben_bourse
rename beneficiaire_Cantine ben_Cantine
rename beneficiaire_PNBSF ben_BNSF
rename ben_CMUh ben_subCMU
rename ben_moins5 ben_moin5



*Now, those in PNBSF
gen profile3=(age>=15 & age<=24 & ben_BNSF==1)

*15-24 YO woman, rural, poor
gen profile4=(s01q01==2 & age>=15 & age<=24 & s00q04==2 & poor_ref==1 & ben_BNSF==1)

*15-24 YO man, urban
gen profile5=(s01q01==1 & age>=15 & age<=24 & s00q04==1 & ben_BNSF==1)

gen total=1

*The following numbers are for the descriptives of the 0/1 variables (first table in the datacut)
foreach var in working single married_m married_p u_libre widow divorced separated acte_naissance s06q01__1 s06q01__2 s06q01__3 s06q01__4 s06q01__5 credit ben_bourse ben_Cantine ben_BNSF ben_subCMU ben_moin5 ben_sesame ben_cesarienne total{
    forval prof = 0/5{
	    qui sum `var' [iw=hhweight] if profile`prof'==1 & `var'==1
		local cant`prof' = r(sum_w)
	}
	dis "`cant0' `cant1' `cant2' `cant3' `cant4' `cant5'"
}



*The following numbers are for the descriptives of the continuous variables (second table in the datacut)
forval prof = 0/5{
	sum yearsedu impa impaes s05q02 s05q04 s05q06 s05q08 s05q10 s05q12 s05q14 [iw=hhweight] if profile`prof'==1
}



















/*
use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\s15_me_sen2018.dta" , clear
merge m:1 grappe menage using "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\ehcvm_welfare_sen2018.dta" , keepusing(hhweight hhsize)

tab s15q01
 
*/

tab s01q36, mis //Has a cellphone136
rename s01q36 has_phone
tab1 s01q39__1 s01q39__2 s01q39__3 s01q39__4 s01q39__5 s01q39__6 s01q39__7 if age>14 & age<25, mis //Has access to internet139
gen has_internet = (s01q39__1==1 | s01q39__2==1 | s01q39__3 ==1 | s01q39__4 ==1 | s01q39__5 ==1 | s01q39__6 ==1 | s01q39__7==1 )

tab1 s02q01__1 s02q01__2 s02q01__3 if age>14 & age<25, mis //Can read in any language201abc
gen reads = (s02q01__1==1 | s02q01__2==1 | s02q01__3 ==1 )
replace reads=. if reads==0 &  (s02q01__1>=. | s02q01__2>=. | s02q01__3>=. )
tab1 s02q02__1 s02q02__2 s02q02__3 if age>14 & age<25, mis //Can write in any language202abc
gen writes = (s02q02__1==1 | s02q02__2==1 | s02q02__3 ==1 )
replace writes=. if writes==0 &  (s02q02__1>=. | s02q02__2>=. | s02q02__3>=. )

foreach var in s01q06 has_phone has_internet reads writes{
    forval prof = 0/5{
	    qui sum `var' [iw=hhweight] if profile`prof'==1 & `var'==1
		local cant`prof' = r(sum_w)
	}
	dis "`cant0' `cant1' `cant2' `cant3' `cant4' `cant5'"
}


*Checking unemployed variables
foreach var in /*s04q11 s04q12 s04q13 s04q14 s04q15 s04q16 s04q17 s04q18 s04q19*/ s04q20 s04q21 s04q22 s04q23 s04q24__1 s04q24__2 s04q24__3 s04q24__4 s04q24__5 s04q24__6 s04q24__7 s04q25 /*s04q26 s04q27 s04q06 s04q07 s04q08 s04q09*/ {
	*tab `var' s04q10 if age>14 & age<25, mis
	tab `var' working if age>14 & age<25, mis
}

gen totally_unemployed=(s04q14==2)
forval n=1/9{
	gen s04q16__`n' = (s04q16==`n')
}
gen premier_emploi=(s04q23==2)
gen jobsearching_or_ready = (s04q17==1|s04q19==1)
forval n=1/5{
	gen s04q25__`n' = (s04q25==`n')
}

foreach var of varlist s04q11 s04q13 s04q14 totally_unemployed s04q16__* jobsearching_or_ready s04q20 premier_emploi s04q24__* s04q25__* {
    forval prof = 0/5{
	    qui sum `var' [iw=hhweight] if profile`prof'==1 & `var'==1
		local cant`prof' = r(sum_w)
	}
	dis "`cant0' `cant1' `cant2' `cant3' `cant4' `cant5'"
}

recode s04q01 s04q02 s04q03 s04q04 s04q05 (9999=.)
forval prof = 0/5{
	sum s04q01 s04q02 s04q03 s04q04 s04q05 [iw=hhweight] if profile`prof'==1
}









decode s00q02, gen(ADM2_FR)
replace ADM2_FR=strproper(ADM2_FR)
tab ADM2_FR
replace ADM2_FR="Koumpentoum" if ADM2_FR=="Koupentoum"
replace ADM2_FR="Malem Hodar" if ADM2_FR=="Malem Hoddar"
replace ADM2_FR="Medina Yoroufoula" if ADM2_FR=="Medina Yoro Foulah"
replace ADM2_FR="Mbacke" if s00q02==33
replace ADM2_FR="Mbour" if s00q02==71
replace ADM2_FR="Nioro Du Rip" if ADM2_FR=="Nioro"
replace ADM2_FR="Tivaoune" if ADM2_FR=="Tivaouane"

preserve
	gen population = 1
	collapse (sum) profile0 profile1 profile2 profile3 profile4 profile5 population [iw=hhweight], by(ADM2_FR)
	list in 1/5
	merge 1:1 ADM2_FR using "${maps_sen}/DptsDB", nogen
	gen perc1524 = round(profile0*100/population,0.01)
	gen perc_prw = round(profile1*100/profile0, 0.1)
	gen perc_um = round(profile2*100/profile0, 0.1)
	egen cut_prw = cut(perc_prw), group(3) icodes
	egen cut_um = cut(perc_um), group(3) icodes
	tab cut_prw cut_um
	sort cut_prw cut_um
	egen grp_cut = group(cut_prw cut_um)
	bys cut_prw: sum perc_prw
	bys cut_um: sum perc_um
	list perc_prw perc_um cut* grp_cut in 1/15
	colorpalette ///
	 #e8e8e8 #dfb0d6 #be64ac ///
	 #ace4e4 #a5add3 #8c62aa ///
	 #5ac8c8 #5698b9 #3b4994 , nograph 
	local colors `r(p)'
	*scatter perc_prw perc_um
	*spmap grp_cut using "${maps_sen}/DptsCoord", id(_ID) osize(none ..) /*fcolor(Reds2)*/ fcolor("`colors'") clm(unique) legstyle(3) polygon(data("${maps_sen}/RegsCoord") ocolor(gray) osize(0.05) )
	spmap perc_prw using "${maps_sen}/DptsCoord", id(_ID) osize(none ..) fcolor(Greens2) clnumber(10) legstyle(3) polygon(data("${maps_sen}/RegsCoord") ocolor(gray/*black%75*/) osize(0.05) )
	*spmap perc_um using "${maps_sen}/DptsCoord", id(_ID) osize(none ..) fcolor(Reds2) clnumber(10) legstyle(3) polygon(data("${maps_sen}/RegsCoord") ocolor(gray) osize(0.05) )
restore




/*MAPS!!


*CÓMO CREAR ESTOS ARCHIVOS? IMPORTEMOS EL SHAPEFILE DE DPTOS COMO EJEMPLO
*ssc install shp2dta
dir C:\Users\andre\Dropbox\SenegalSHP\Shapefiles/
global maps_sen "C:\Users\andre\Dropbox\SenegalSHP\Shapefiles"
shp2dta using "${maps_sen}/sen_admbnda_adm2_1m_gov_ocha_20190426", database("${maps_sen}/DptsDB") coordinates("${maps_sen}/DptsCoord")
shp2dta using "${maps_sen}/sen_admbnda_adm1_1m_gov_ocha_20190426", database("${maps_sen}/RegsDB") coordinates("${maps_sen}/RegsCoord")

use "${maps_sen}/DptsDB", clear

*CÓMO HACER UN MAPA? PROCESAR LOS DATOS QUE QUIERO PARA TENER UNA BASE DE DATOS DE LA VARIABLE A GRAFICAR, CON LOS CÓDIGOS DE MUNICIPIOS.
*LUEGO, PEGAR LA VARIABLE A GRAFICAR A MpiosDB
*FINALMENTE, CORRER LA LÍNEA DE SPMAP CON MpiosCoord Y LOS PARÁMETROS DEL MAPA, CON EL ID id


*/







