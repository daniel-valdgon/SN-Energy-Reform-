

*---------------- Done
*Fuels 
//a. File 08_fuelsubsidies.do: Apply new q for fuels using your new weights
//b  2b_fuels.do VAT and direct: Be sure that each scenario is reading the composite mp composite sub price: for VAT and direct effect
//c. 2b_fuels.do Indirect: Be sure to load the composite subsidy  
//d  1d_fuels.do: Be sure to uprate the composite quantities in 1d (this code does not exist at all)


*Electricity 
// *a. Compute the subsidy for firms using the neww decree of 2022-54. Compute shares for each type of profesional (IMF)
// *b.	Petra does not give tranches therefore we need to use tranches 

*---------------- Pendent:

*Add coverage by tranche and by good figure in the tool (Coverage can change with policy scenario for electricity)

*Update of ppt for Jan
	*a. Run the tool with the excel main
	*b. Check that the tool rnew results match what I shared to Gabriela in the ppt on Friday
	*c. Update ppt with figures that are still missing (Absolute incidence in billions)
	
*Minor improvements: 	
	*-Change the strategy to split fuels by splitting them at the very beggining: q_fuel_ord q_fuel_gasoil q_fuel_super
	*-Update the paramter of pre-paid customers
	
	*-Adapt subsidies analysis to use expenditure rather than quantities 
	   *See if its consequential and fix  to use s/(1-s) rather than q. This would be better to have a spending completely affected by the netdown
		* Also it will allow to prepare the netdown and the gross up more properlty. Firts subsidies later VAT. I tiwll allow that in the future if a sector is not regulated, shocks to fuel subsidies increase the VAT collected in electricity via indirect effects.  

* Modification to examine policies:
	*-Separate fuels by butane, gasoline (super, premium), kerosene
	*-Separate electricity subsidies by subsidy tranche 1, trance 2 and tranche 3
	*-Estimate elasticities to policies: 
		*(not stochastic) but just a change up to 15 percent on each parameters 
			* tariff rates by tranche and pre-paid
			* prepaid policy
			* Size of tranches
			* each of the fuel prices 
			* Compensation policies : expansionof program, UCT, energy CT
			* Revenue neutral increases 
*Use Demand elasticities 
*Use forecasted growth rate for 2023 in everything, also in oil prices

*Prepare one pager on the increase of electricity tariffs. Share of subsidized electricity
*Search IO matrix

*Elasticities in Senegal 
	// https://reader.elsevier.com/reader/sd/pii/S014098831100106X?token=6B931CA4651B5EA105097274A3B27268F7713A51711A945F91CDAEC96E028B761B495FAFD3DB4C1933708BA3FB5A8666&originRegion=us-east-1&originCreation=20230309054705
	
	//propose which data do we need to measure elasticity

 






