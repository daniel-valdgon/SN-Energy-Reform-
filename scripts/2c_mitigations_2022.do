*===============================================================================
		*1. Proxy mean Test Score
*===============================================================================


use `output', clear

*PARA ACTUALIZAR LO DE JAN Y PETRA NO NOS IMPORTA ESTO ASÍ QUE LO MATO Y PONGO TODO EN 0

foreach var in am_new_pnbsf am_delayed_pnbsf am_pnbsf_transferinc am_pnbsf_newbenefs{
	gen `var' = 0
}

keep hhid am_new_pnbsf am_delayed_pnbsf am_pnbsf_transferinc am_pnbsf_newbenefs

tempfile new_PNBSF
save `new_PNBSF', replace 

