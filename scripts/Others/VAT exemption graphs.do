
global path "C:\Users\andre\Dropbox\Energy_Reform"
global enquete "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw"
global data_sn "C:\Users\andre\Dropbox\Energy_Reform\data\raw"
global p_scr 	"$path/SN-Energy-Reform-/scripts"
global path_ceq "$path/data/raw"

local files : dir "$p_scr/_ado" files "*.ado"
foreach f of local files {
	display("`f'")
	qui: cap run "$p_scr/_ado/`f'"
}

*------------------------------------
* Load data on exemptions and formality from the Main tool
*------------------------------------

import excel "$path/results\SN_Sim_tool_V.xlsx", sheet("TVA_raw_ref") firstrow clear 
drop if codpr==.
tempfile products
save `products', replace 

*------------------------------------
* Consumption data
*------------------------------------

use "$enquete\ehcvm_conso_sen2018.dta" , clear

*use "$data_sn\Senegal_consumption_all_by_product.dta" , clear

merge m:1 codpr using `products', nogen keep(1 3)

tab exempted formelle, mis
tab modep, mis



*We only care about purchases, achats
gen purchases=depan if inlist(modep,1)

* First we need the correspondence  between the products on the Senegal database and COICOP 
merge m:1 codpr using "$data_sn\correlation_COICOP_senegal.dta" ,  keepusing(coicop)  keep(matched) nogen //assert(matched using)

* We need the decile on consumption to then merge the deciles and products with the informality rate
cap gen hhid = grappe*1000+menage
merge m:1 grappe menage using "$enquete\ehcvm_welfare_sen2018.dta" ,  keepusing(hhweight hhsize) assert(matched) nogen //Esto es para mi versión, comentarlo para lo de antes
merge m:1 hhid using "$data_sn\ehcvm_conso_SEN2018_menage.dta" ,  keepusing(ndtet dtet dtot hhweight hhsize) assert(matched) nogen
rename  ndtet decile_expenditure
rename coicop product_code
merge m:1 decile_expenditure product_code using "$data_sn\informality_final_senegal.dta" , assert(matched using) keep(matched) nogen // products with no infor in the survey 

gen dep_exempt = purchases*exempted

gen dep_informelle = purchases*share_informal_consumption

collapse (sum) depan purchases dep_exempt dep_informelle (mean) decile_expenditure dtet dtot, by(hhid hhweight hhsize)

gen pondih=hhweight*hhsize
gen depan_pc=depan/hhsize
_ebin depan_pc [aw=pondih], nq(10) gen(cons_decile_pc) // Other option is quantiles but EPL use _ebin command 


*Now, I need the total exempted consumption by decile, and the average informal consumption% by decile

gen dep_informelle_perc=dep_informelle*100/purchases

*La suma la debo ponderar por hhweight, y el porcentaje por pondih
gen dep_exempt_pond = dep_exempt*hhweight
gen dep_informelle_perc_pond = dep_informelle_perc*pondih
collapse (sum) dep_exempt_pond pondih dep_informelle_perc_pond , by(cons_decile_pc) //decile_expenditure  cons_decile_pc

sum dep_exempt
local total = r(N)*r(mean)
replace dep_exempt=dep_exempt*100/`total'
replace dep_informelle_perc_pond=dep_informelle_perc_pond/pondih
drop pondih










use "$data_sn/Senegal_consumption_all_by_product.dta", clear
unique grappe menage vague codpr modep
rename depan depan_old
cap gen hhid = grappe*1000+menage
*rename menage menage_old																// Si comento estas dos líneas
*merge m:1 hhid using "$data_sn/CORR_HHID_MENAGES.dta", nogen							// obtengo la gráfica vieja sin corregir por hhid
merge m:1 grappe menage vague codpr modep using "$enquete\ehcvm_conso_sen2018.dta"

sort grappe menage vague codpr modep
br if _merge!=3

gen ld_new = ln(depan)
gen ld_old = ln(depan_old)

scatter ld_*, msize(vtiny) aspectratio(1) xtitle("Old ln(spending)") ytitle("New ln(spending)")

*scatter ld_* if round(depan,1000)!=round(depan_old,1000), msize(vtiny)

gen igual = ( abs(depan-depan_old)<0.5 )
gen dif = depan-depan_old
gen ldif=ln(abs(dif))*sign(dif)
tab codpr igual if _merge==3, mis
tab codpr _merge, mis
tab _merge igual, mis

*scatter ld_new ldif, msize(vtiny)
*twoway (scatter ld_old ldif, msize(vtiny)) (scatter ld_new ldif, msize(vtiny)), legend(off)

br if codpr==33 & igual!=1

collapse depan*, by(hhid)
gen ld_new = ln(depan)
gen ld_old = ln(depan_old)
scatter ld_*, msize(vtiny)  xtitle("Old ln(spending)") ytitle("New ln(spending)") aspectratio(1)










gen depan_dif = depan_old -depan



use "$enquete\ehcvm_conso_sen2018.dta" , clear
unique grappe menage vague codpr modep //No puedo usar menage, es la del problema
unique grappe vague codpr modep
gen purchase = 0
replace purchase = depan if modep==1
collapse (sum) depan purchase /*[iw=hhweight]*/, by (hhid codpr hhweight grappe menage vague)
replace hhweight = round(hhweight)
*si quiero bien
	*rename depan depan_new
*O si quiero al revés
	rename purchase depan_new
	rename depan purchase
unique grappe vague hhweight codpr
tempfile conso
save `conso', replace 

	use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr.dta", clear
	merge m:1 hhid using "$data_sn/CORR_HHID_MENAGES.dta", nogen
	rename hhid hhid_old
	rename hhid_new hhid
	merge 1:1 hhid codpr using `conso'
	
	gen ld_new = ln(depan_new)
	gen ld_old = ln(depan)

	scatter ld_*, msize(vtiny)


	
	
	
	
use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr.dta", clear
rename depan depan_05
merge m:1 hhid using "$path_ceq/output.dta", keepusing(dtot hhweight hhsize vague grappe menage dtet depan) nogen
rename depan depan_total
rename depan_05 depan_new //pa que pegue
bys hhid: egen depan_total2 = total(depan_new)
assert abs(depan_total-depan_total2)<1 if depan_total!=.
rename hhid hhid_old
merge 1:1 grappe vague hhweight codpr menage using `conso', keep(1 2) //Quedémonos con los que no pegan

tab codpr _merge
*Las categorías de 800 para arriba no estaban en la base vieja
drop if codpr>=800
*Ahora, el plan es generar una base de merge=1 y otra de merge=2, y ver si los puedo pegar con el valor de depan
br if codpr==15
unique codpr _merge grappe vague hhweight depan_new
duplicates tag codpr _merge grappe vague hhweight depan_new, gen(tag)
sort codpr grappe vague hhweight depan_new
br codpr hhid_old depan_new dtot hhweight vague hhsize grappe menage hhid purchase _merge if tag!=0
br codpr hhid_old depan_new dtot hhweight vague hhsize grappe menage hhid purchase _merge

order codpr grappe vague hhweight depan_new
tab tag _merge
*Podría quedarme con los no duplicados, pegar esos, y ver si con eso basta para identificar los cambios en hhid
keep if tag == 0
preserve 
	keep if _merge ==1
	drop hhid _merge
	rename menage menage_old
	tempfile old_hhids
	save `old_hhids', replace 
restore
keep if _merge ==2
drop  _merge hhid_old
merge 1:1 codpr grappe vague hhweight depan_new using `old_hhids' 

br hhid* menage*
keep if _merge==3

keep grappe hhid* menage*
sort grappe menage
duplicates drop















tab codpr _merge
*Las categorías de 800 para arriba no estaban en la base vieja


use "$path_ceq/output.dta", clear 
merge 1:1

rename depan depan_new
rename hhid hhid_old
merge 1:1 depan_new codpr hhweight using `conso'





















use "$enquete\ehcvm_conso_sen2018.dta", clear
gen ldepan = ln(depan)
hist ldepan, bin(100)











use "$enquete\ehcvm_welfare_sen2018.dta", clear




use "$path_ceq/output.dta", clear 
drop beneficiaire_Perfect_targetting
foreach var of varlist dtot-old_poor_pc{
	rename `var' `var'_o
}

merge 1:1 hhid using "$enquete\ehcvm_welfare_sen2018.dta"


















