*===============================================================================
		*1. Proxy mean Test Score
*===============================================================================


use `output', clear

*There is one household with no information that messes up everything
*drop if hhid==.

cap drop initial_ben
bysort recu_PNBSF (PMT rannum): gen initial_ben= sum(hhweight)
replace initial_ben=. if recu_PNBSF==1

if $PMT_targeting_BSF == 1{
	gen _e1=abs(initial_ben-(264021.2*(${PNBSF_benef_increase}-1)))
	egen _e=min(_e1)
	gen _icum=initial_ben if _e==_e1
	egen Beneficiaires_i=total(_icum)
	egen _icum2_sd=sd(_icum)
	assert _icum2_sd==. //As it's constant within dept, sd should be missing.
	drop _icum2_sd _icum _e _e1
	gen new_am_BNSF_pc_0=((Montant+${PNBSF_transfer_increase})/hhsize)*(initial_ben<=Beneficiaires_i) // Beneficiaires 
	drop Beneficiaires_i
}

replace new_am_BNSF_pc_0=(Montant+${PNBSF_transfer_increase})/hhsize if recu_PNBSF==1


*Check if the assignment makes sense
gen old_beneficiaire_PNBSF = (am_BNSF_pc_0>0)
gen new_beneficiaire_PNBSF = (new_am_BNSF_pc_0>0)
count if old_beneficiaire_PNBSF==1										//Every previous beneficiary...
local old=r(N)
count if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==1			//...should continue being one
local new=r(N)
assert `old'==`new'
tab *_beneficiaire_PNBSF [iw=hhweight]

sum hhweight if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==0
local newben = r(mean)*r(N)
dis "There are " `newben' " new beneficiaries of the PNBSF program"



*The information that I need to send to the output is only the increase in the transfer, not in pc terms because that will be calculated there along with the other policies
gen am_new_pnbsf=(new_am_BNSF_pc_0-am_BNSF_pc_0)*hhsize
replace am_new_pnbsf=0 if am_new_pnbsf==.

*We want the pnbsf disaggregated in beneficiary expansion + transfer increase

gen am_pnbsf_newbenefs = 0
replace am_pnbsf_newbenefs = Montant if new_beneficiaire_PNBSF==1 & old_beneficiaire_PNBSF==0
gen am_pnbsf_transferinc = 0
replace am_pnbsf_transferinc = ${PNBSF_transfer_increase} if new_beneficiaire_PNBSF==1
assert round(am_new_pnbsf) == round(am_pnbsf_transferinc + am_pnbsf_newbenefs) //The total effect should be the sum of the two changes in the program

gen am_delayed_pnbsf = 0
if ${delayed_PNBSF} == 1 {
	replace am_delayed_pnbsf = 100000 if old_beneficiaire_PNBSF==1
}


keep hhid am_new_pnbsf am_delayed_pnbsf am_pnbsf_transferinc am_pnbsf_newbenefs

tempfile new_PNBSF
save `new_PNBSF', replace 





/*


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

