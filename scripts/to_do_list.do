


*Fuels 
//a. File 08_fuelsubsidies.do: Apply new q for fuels using your new weights
//b  2b_fuels.do VAT and direct: Be sure that each scenario is reading the composite mp composite sub price: for VAT and direct effect
//c. 2b_fuels.do Indirect: Be sure to load the composite subsidy  
//d  1d_fuels.do: Be sure to uprate the composite quantities in 1d (this code does not exist at all)


*Electricity 
// *a. Compute the subsidy for firms using the neww decree of 2022-54. Compute shares for each type of profesional (IMF)
// *b.	Petra does not give tranches therefore we need to use tranches 

*Pendent:
*Change the strategy to split fuels by splitting them at the very beggining: q_fuel_ord q_fuel_gasoil q_fuel_super
*Update the paramter of pre-paid customers
*Update the changes implemented 
*Adapt subsidies analysis to use expenditure rather than quantities 
	* See if it s consequential and fix 
	* Check if using Q or expenditure gives the same result (This rpevents the double increse in consumption)
	* It does matter if indirect effect of fuels is zero 








