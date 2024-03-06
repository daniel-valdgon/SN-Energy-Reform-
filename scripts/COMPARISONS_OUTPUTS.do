


*1=Baseline
*2=Reform

*A)	Minitool 2018 with low production cost
*B)	Minitool 2018 with high production cost

use "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - A1.dta" , clear
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_A1
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - A2.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_A2
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - B1.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_B1
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - B2.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_B2
}





*C)	Minitool 2021 with low production cost
*D)	Minitool 2021 with high production cost

use "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - C1.dta" , clear
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_C1
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - C2.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_C2
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - D1.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_D1
}

merge 1:1 hhid using "C:\Users\andre\Dropbox\Energy_Reform\data\output\simul_results_mitigation_MAIN - D2.dta" , nogen assert(3)
foreach var of varlist hhweight - all_fuel_pc{
	rename `var' `var'_D2
}























