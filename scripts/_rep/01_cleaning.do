

*----------------------Load consumption 

use "C:\Users\wb419055\OneDrive - WBG\West Africa\Senegal\data\EHCVM\EHCVM_2021\Dataout\ehcvm_welfare_SEN_2021.dta", clear 

keep dtet hhweight hhsize

tempfile covs
save `covs'

*----------------------Compute quantities consumed 






