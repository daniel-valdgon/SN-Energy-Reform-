
/* Notes: 
- Data on prices 
	*Pg 3-5 prices of *CANAL TTC from : "structure des prix des PP du 14 december 2019.pdf" 
	* Confirmed by https://senegal.opendataforafrica.org/ahrgyqb/prix-de-vente-aux-consommateurs-des-produits-p%C3%A9troliers
	
	It considers increase in price of super in Jun of 2019

-National Q of LPG  
	https://senpetrogaz.sn/2022/06/09/gaz-butane-un-produit-zero-taxe-au-senegal-sans-augmentation-de-prix-malgre-la-situation-mondiale-par-birame-sow

	*Q= 200,000 Tons in 2022
	la botella de 6 kg se vende a 2885 F
	la botella de 12,5 se vende a 6.250 F más barata que la de 6 kg en Malí, que supera los 6.300 Fcfa (ver la tabla anterior).
	
	*Q=164000 in 2018 (about 6000 for exports)
	Source: https://www.tresor.economie.gouv.fr/Articles/11e09942-7250-4626-8f4b-7d415d860a14/files/0363ad4a-a3ef-4b97-98fe-baab979150d3

-Take into account that prices change between 2018 and 2019 

*/ 


/**********************************************************************************
*            			1. Fuel subsidies 
**********************************************************************************/
 
use "$path_ceq/2_pre_sim/05_purchases_hhid_codpr_2021.dta", clear 
*merge m:1 hhid using "$path_raw/../../Dataout/Temp/hhsize.dta", keepusing (hhsize) nogen
merge m:1 hhid grappe menage using "$path_raw/../../Dataout/ehcvm_welfare_SEN_2021.dta", keepusing (hhsize hhweight) nogen

*
local super_carb		$sp19_super         //  Because 75 percent of the time of the survey was under 695. IN particular for 2018: 695, 2019: 695 April and May , 775 Jun and July local super_carb = (0.75*695+0.25*775) 

local ess_ord			$sp19_ordinaire     // local ess_ord = 665
local ess_pir			$sp19_pirogue      // local ess_pir 497 

local gasoil			$sp19_gasoil     // local gasoil = (0.75*595+0.25*655) 

local pet_lamp			$sp19_pet_lamp	      // price per litre local pet_lamp 410 
local butane			$sp19_butane     // price of gas for 9kg = very close to weighted price of 2.7, 6 and 9 kg dis (4285/9) " = `butane'" local butane = (4285/9)

local fuel				$sp19_fuel    //local fuel = 0.5*`super_carb'+ 0.5*`ess_ord'

*Survey quantities 
/*
gen q_fuel_super = depan*$share_spendind_super
gen q_gasoil 	 = depan*$share_spendind_gasoil
gen q_ordinarie	 = depan*$share_spendind_ordinari
*/ 

gen q_fuel=depan/`fuel' if inlist(codpr, 208, 209, 304) // 208	Carburant pour véhicule 209	Carburant pour motocyclette 304	Carburant pour groupe electrogène à usage domestique

gen q_pet_lamp=depan/`pet_lamp'  if inlist(codpr, 202)     // 202	Pétrole lampant =Kerosene
gen q_butane =depan/`butane'   if inlist(codpr, 303) // 303	Gaz domestique


collapse (sum) q_fuel q_pet_lamp q_butane , by(hhid) 
save "$presim/08_subsidies_fuel_2021.dta", replace



exit 




