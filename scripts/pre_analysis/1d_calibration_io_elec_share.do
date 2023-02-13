
*This do-file can be runned separated from the rest of do-files its final ouput is meant to be inputed manually in the sheet of parameters. It will be updated to be put n the final excel 

*Load consumption data and estimate spending and purchases 
use "$path_ceq/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$path_ceq/ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* Keep al spendnig and also purhcases 
gen purchases=depan if inlist(modep,1)
collapse (sum) depan purchases [aw=hhweight], by(hhid codpr)

* First we need the correspondence  between the products on the Senegal database and COICOP 
merge m:1 codpr using "$path_ceq/correlation_COICOP_senegal.dta" ,  keepusing(coicop)  keep(matched) nogen //assert(matched using)

* We need the decile on consumption to then merge the deciles and products with the informality rate
merge m:1 hhid using "$path_ceq/ehcvm_conso_SEN2018_menage.dta" ,  keepusing(ndtet) assert(matched) nogen
rename  ndtet decile_expenditure
rename coicop product_code
merge m:1 decile_expenditure product_code using "$path_ceq/informality_final_senegal.dta" , assert(matched using) keep(matched) nogen // products with no infor in the survey 

*Share of inofrmality at household level as total informal purchases over total purchases 
gen electricity_io=depan if codpr==334
gen io_sec_22=depan if codpr==334 |  codpr==334 | codpr==303

*merge
merge m:1 hhid using "$path_ceq/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)
*gen pondih= hhweight*hhsize

gcollapse (sum) electricity_io io_sec_22 (first) hhweight hhsize, by(hhid)

gen s=electricity_io/io_sec_22
sum s [iw=hhweight], meanonly 

dis " Share of electricity in the IO-22 sector using consumption is `r(mean)'"

