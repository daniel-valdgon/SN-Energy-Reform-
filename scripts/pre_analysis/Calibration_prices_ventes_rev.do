if "`c(username)'"=="WB419055" {
	
	global proj	"C:/Users/WB419055/OneDrive - WBG/SenSim Tool/JTR/Energy_reform" // project folder
	
} 

	
import excel "$proj/data/raw/ventes_chiffres.xlsx", sheet("data") firstrow clear

    keep vente_energie_mwh type_consumer month month_2019 month_2020

    tostring vente_energie_mwh, replace
    destring month_2019, replace
    destring month_2020, replace

    tempfile ven_chi_tmp_dta
    save `ven_chi_tmp_dta', replace 

*Keep producers and domestic data

keep if type_consumer=="P_PPP" | type_consumer=="P_PMP" | type_consumer=="P_PGP" | type_consumer=="W_PMP" | type_consumer=="W_PPP" ///
| type_consumer=="MOYENNE TENSION" | type_consumer=="HAUTE TENSION" | type_consumer=="AGENT" |  type_consumer=="EP" ///
| type_consumer=="P_DPP" | type_consumer=="P_DMP" | type_consumer=="P_DGP" | type_consumer=="W_DPP" | type_consumer=="W_DMP" ///
| type_consumer=="BASSE TENSION"

reshape wide month_2019 month_2020, i(month type_consumer) j(vente_energie_mwh) string

*Removing months with missing values 

bysort month (month_20190) : drop if missing(month_20190[_N]) 
bysort month (month_20200) : drop if missing(month_20200[_N]) 


// Abril, mayo, junio, sept, Oct, Nov y Dec seems to be data from 2020 rather than 2021

rename month_20190 chiffres_KCFA_20
rename month_20200 chiffres_KCFA_21

rename month_20191 ventes_MWh_20
rename month_20201 ventes_MWh_21


collapse (sum  ) chiffres*  ventes* , by(type_consumer) // do the sum for one of them in excel to verify 

replace type_consumer="basse tension" if  type_consumer=="P_PPP" | type_consumer=="P_PMP" ///
										| type_consumer=="P_PGP" | type_consumer=="W_PMP" | ///
										type_consumer=="W_PPP" | type_consumer=="AGENT" |  type_consumer=="EP"

replace type_consumer="domestic" if  	type_consumer=="P_DPP" | type_consumer=="P_DMP" | ///
										type_consumer=="P_DGP" | type_consumer=="W_DPP" ///
										| type_consumer=="W_DMP"

collapse (sum  ) chiffres*  ventes* , by(type_consumer)


*Gen tariffs of 2022

gen tariffs21= chiffres_KCFA_21/ventes_MWh_21

egen tot_ven_21=total(ventes_MWh_21) if type_consumer!="domestic" & type_consumer!="BASSE TENSION"

gen weight21=ventes_MWh_21/tot_ven_21
replace weight21=. if type_consumer=="domestic"
replace weight21=. if type_consumer=="BASSE TENSION"

gen ventes_GWh_21=ventes_MWh_21/1000
keep tariffs21 weight type_consumer ventes_GWh_21 chiffres_KCFA_21

egen total_21_tariff=total(tariffs21*weight21)
replace ventes_GWh_21=ventes_GWh_21/(10/12) // to control we drop two months 



export excel "$proj/data/raw/ventes_chiffres.xlsx", sheet(results_WB2) first(variable) sheetreplace 
