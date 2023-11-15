
global path "C:\Users\andre\Dropbox\Energy_Reform"
global enquete "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw"
global p_scr 	"$path/SN-Energy-Reform-/scripts"

local files : dir "$p_scr/_ado" files "*.ado"
foreach f of local files {
	display("`f'")
	qui: cap run "$p_scr/_ado/`f'"
}

*--------------------------------------------------------
* Household identification and Welfare indicator
*--------------------------------------------------------

use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\ehcvm_welfare_sen2018.dta" , clear
keep hhid grappe vague menage pcexp dtot dnal dali zae region milieu hhweight hhsize

*Note: in the tool, hhweight gets rounded to an integer

tempfile hh_ids
save `hh_ids', replace 

*------------------------------------
* Shock data
*------------------------------------

use "C:\Users\andre\Dropbox\Energy_Reform\data\raw\1_raw\s14_me_sen2018.dta" , clear

keep vague grappe menage s14q01 s14q02

rename s14q02 choc_
recode choc_ (2=0)
label def chocs 0 "Non" 1 "Oui"
label values choc_ chocs

reshape wide choc_, i( vague grappe menage ) j( s14q01 )

label var choc_101 "Maladie grave ou accident d'un membre du ménage"
label var choc_102 "Décès d'un membre du ménage"
label var choc_103 "Divorce, séparation"
label var choc_104 "Sécheresse/Pluies irrégulières"
label var choc_105 "Inondations"
label var choc_106 "Incendies"
label var choc_107 "Taux élevé de maladies des cultures"
label var choc_108 "Taux élevé de maladies des animaux"
label var choc_109 "Baisse importante des prix des produits agricoles"
label var choc_110 "Prix élevés des intrants agricoles"
label var choc_111 "Prix élevés des produits alimentaires"
label var choc_112 "Fin de transferts réguliers provenant d'autres ménages"
label var choc_113 "Perte importante du revenu non agricole du ménage  (autre que du fait d'un accident ou d'une maladie)"
label var choc_114 "Faillite d'une entreprise non agricole du ménage"
label var choc_115 "Perte importante de revenus salariaux  (autre que du fait d'un accident ou d'une maladie)"
label var choc_116 "Perte d'emploi salarié d'un membre "
label var choc_117 "Vol d'argent, de biens, de récolte ou de bétail"
label var choc_118 "Conflit Agriculteur/Eleveur"
label var choc_119 "Conflit armé/Violence/Insécurité"
label var choc_120 "Attaques acridiennes ou autres ravageurs de récolte"
label var choc_121 "Glissement de terrain"
label var choc_122 "Autre (à préciser)"

merge 1:1 vague grappe menage using `hh_ids', nogen

tempfile hh_shocks
save `hh_shocks', replace 

gen pondih=hhweight*hhsize

_ebin pcexp [aw=pondih], nq(5) gen(welfare_quintile) // Other option is quantiles but EPL use _ebin command 

*Generate statistics of shocks per quintile

egen demographique_idiosyncratique = rowmax(choc_101-choc_103)
egen economique_idiosyncratique = rowmax(choc_112-choc_117)
egen naturel_covariant = rowmax(choc_104-choc_108 choc_120 choc_121)
egen economique_covariant = rowmax(choc_109-choc_111)
egen violence_covariant = rowmax(choc_118-choc_119)
egen autre_covariant = rowmax(choc_122)
egen tous_chocs = rowmax(choc_*)


foreach var in demographique_idiosyncratique economique_idiosyncratique naturel_covariant economique_covariant violence_covariant autre_covariant tous_chocs{
	tab `var' welfare_quintile [iw=hhweight]
	tab `var' milieu [iw=hhweight]
}


tab tous_chocs welfare_quintile [iw=hhweight]
tab tous_chocs milieu [iw=hhweight]




