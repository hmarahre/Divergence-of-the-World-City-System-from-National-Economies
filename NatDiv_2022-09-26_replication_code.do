capture log close
log using NatDiv_2022-09-26_replication_code, replace text

//  program:   	replication file
//  project:   	Leffel, Ben, Marahrens, Helge and Arthur Alderson.
//				Forthcoming. "Divergence of the World City System from National
//				Economies." Global Networks.
//  author:     Helge Marahrens: 2022-09-26
//  from:		REGE_2021-09-13_models_WSP.do

* program setup
set more off, perm
version 16.0
clear all
macro drop _all
set linesize 80

// load data
import excel "NatDiv_2022-09-26_replication_data.xlsx", clear firstrow

// rename variables
rename pretty_name city
rename WSP_Art_new OWS
rename wsp2 NIDL_SE
rename cb3 NIDL_CC

// recode variables
gen id = _n

gen log_pop = log10(population)

foreach WSP_var in OWS NIDL_SE NIDL_CC {
	encode `WSP_var', generate(`WSP_var'_num)
	recode `WSP_var'_num (2=3) (3=2)
	label define `WSP_var'_num 1 "Core" 2 "Semiperiphery" 3 "Periphery", replace
	label values `WSP_var'_num `WSP_var'_num
}

foreach centrality of varlist outdegree closeness_bi betweenness_bi indegree {
	egen double `centrality'_rank = rank(`centrality'), track
}

encode position, generate(position_num)
gen high_status = position_num==1
gen isolate = position_num==2
gen isolated_clique = position_num==3
gen low_status = position_num==4
gen primary = position_num==5

// table 2
spearman outdegree closeness_bi betweenness_bi indegree
tabstat outdegree closeness_bi betweenness_bi indegree, statistics(min max mean median sd)

// table 3
foreach centrality of varlist outdegree closeness_bi betweenness_bi indegree {
	gsort -`centrality'
	list city `centrality' in 1/50
}

// markout missing values
mark nomiss
markout nomiss OWS_num NIDL_SE_num NIDL_CC_num
tab nomiss

// table 4-5
foreach centrality of varlist outdegree_rank closeness_bi_rank betweenness_bi_rank indegree_rank {
	foreach WSP_label of varlist OWS_num NIDL_SE_num NIDL_CC_num {
		reg `centrality' i.`WSP_label' log_pop if nomiss==1
	}
}

// table 6 & A1
foreach role of varlist primary isolate high_status low_status isolated_clique {
	foreach WSP_label of varlist OWS_num NIDL_SE_num NIDL_CC_num {
		logit `role' i.`WSP_label' log_pop if nomis==1 & singleton==0, or
	}
}

log close
exit