/*==============================================================================
DO FILE NAME: 		 active_comparator_simple_ratio.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 03/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This do file shows how to incorporate an active comparator 
					 in SCCS using the "simple ratio" approach, and accompanies 
					 the GSK/LSHTM white paper (placeholder - REF)
					 
REQUIREMENTS: 	 	 - the do file is set up using relative paths, the user should EITHER: 
					    -- manually change the wd using the cd statement before executing 
						-- open Stata from the dofile so that the wd is automatically set to the project directory (and remove the cd statement)
					 - because the do file uses local macros, it needs to be run in one go or Stata will throw an error
					 - data should be stored in a folder named data 
						-- [placeholder - simulate a small dataset for whitepaper and describe]
					 
OUTPUT CREATED:	    log file printed to the /log folder
					table_simple_ratio_$outcome.txt printed to the /output folder 

EDITS: 				updated variable names, simplified program structure (Mar 2022)
==============================================================================*/

/* HOUSEKEEPING===============================================================*/ 
clear 

* Open a log file
cap log close
log using "$logdir/active_comparator_simple_ratio_$suffix", replace t

* Read in data 
use "$datadir/sample_data.dta"

/* BASIC DATA MANAGEMENT=======================================================*/
* if the exposure has multiple levels, saving results can become cumbersome 
* use stata levelsof to run this through a loop 
* note, assumes that doi and comp have same number of levels - long term, will introduce error if not true 

levelsof($doi)
local numcat = `r(r)' - 1

/* UNADJUSTED ANALYSES========================================================*/
* Fit unadjusted conditional poisson models for drug of interest and comparator 

* DOI
* fit conditional poisson model (fixed effects poisson model based on patient ID)
* exponentiated to print to log
xtpoisson $outcome i.$doi, fe i(patient_id) offset(loginterval) irr 

* log scale to enable calculations 
xtpoisson $outcome i.$doi, fe i(patient_id) offset(loginterval) 
mat matrix_doi = r(table)

* save a result for each level as a Stata local macro variable to print to results later on 
forvalues i=1/`numcat' {

	* round and save exponentiated estimates for printing in a table later on
	local rr_doi_`i' = matrix_doi[1,`i'+1]
	local lcl_doi_`i' = matrix_doi[5,`i'+1]
	local ucl_doi_`i' = matrix_doi[6,`i'+1]
	local se_doi_`i' = matrix_doi[2,`i'+1]  

} 

* COMPARATOR 
* repeat for comparator drug 

xtpoisson outcome i.$comp, fe i(patient_id) offset(loginterval) irr
xtpoisson outcome i.$comp, fe i(patient_id) offset(loginterval) 
mat matrix_comp = r(table)

forvalues i=1/`numcat' {
	
	* round and save exponentiated estimates for printing in a table later on
	local rr_comp_`i' = matrix_comp[1,`i'+1]
	local lcl_comp_`i' = matrix_comp[5,`i'+1]
	local ucl_comp_`i' = matrix_comp[6,`i'+1]
	local se_comp_`i' = matrix_comp[2,`i'+1]  

} 


/* ADJUSTED ANALYSES==========================================================*/
* Repeat above adjusting for timevarying confounding 

* exponentiated to print to log
xtpoisson $outcome i.$doi $timevar, fe i(patient_id) offset(loginterval) irr 

* log scale to enable calculations 
xtpoisson $outcome i.$doi $timevar, fe i(patient_id) offset(loginterval) 
mat matrix_doi_adj = r(table)

* save a result for each level as a Stata local macro variable to print to results later on 
forvalues i=1/`numcat' {
	
	* round and save exponentiated estimates for printing in a table later on
	local rr_doi_adj_`i' = matrix_doi_adj[1,`i'+1]
	local lcl_doi_adj_`i' = matrix_doi_adj[5,`i'+1]
	local ucl_doi_adj_`i' = matrix_doi_adj[6,`i'+1]
	local se_doi_adj_`i' = matrix_doi_adj[2,`i'+1]  

} 

* COMPARATOR 
* repeat for comparator drug 

xtpoisson $outcome i.$comp $timevar, fe i(patient_id) offset(loginterval) irr 
xtpoisson $outcome i.$comp $timevar, fe i(patient_id) offset(loginterval) 
mat matrix_comp_adj = r(table)

forvalues i=1/`numcat' {
	
	* round and save exponentiated estimates for printing in a table later on
	local rr_comp_adj_`i' = matrix_comp_adj[1,`i'+1]
	local lcl_comp_adj_`i' = matrix_comp_adj[5,`i'+1]
	local ucl_comp_adj_`i' = matrix_comp_adj[6,`i'+1]
	local se_comp_adj_`i' = matrix_comp_adj[2,`i'+1]  

} 

/* SIMPLE RATIO===============================================================*/
 
/* UNADJUSTED */ 
* note, one ratio and 95%CI is calculated per level of the exposure 
** note - these are created as variables as it was much easier to develop the code interactively
** in future versions i can replace with local macros (faster) but think it makes it harder to read ... 

forvalues i=1/`numcat' {
	
	* Calculate Ratio 
	gen simple_ratio_`i' = exp(`rr_doi_`i'')/exp(`rr_comp_`i'')

	* Calculate 95%CI for the Ratio 
	* square the standard errors (logscale) to get variance
	gen var_doi_`i' = `se_doi_`i''^2 
	gen var_comp_`i' = `se_comp_`i''^2 
	* sum the variance to get variance for the ratio 
	gen var_sum_`i' = var_doi_`i' + var_comp_`i'
	* square root to get standard error for the ratio 
	gen simple_ratio_se_`i' = sqrt(var_sum_`i')
	* times 1.96 to get an error factor 
	gen simple_ratio_ef_`i' = 1.96 * simple_ratio_se_`i'

	* generate upper and lower confidence limits 
	gen lcl_`i' = exp((log(simple_ratio_`i') - simple_ratio_ef_`i'))
	gen ucl_`i' = exp((log(simple_ratio_`i') + simple_ratio_ef_`i'))

} 

/* ADJUSTED */ 
* note, comments removed for brevity 

forvalues i=1/`numcat' {
	
	* Calculate Ratio 
	gen simple_ratio_adj_`i' = exp(`rr_doi_adj_`i'')/exp(`rr_comp_adj_`i'')

	* Calculate 95%CI for the Ratio 
	* square the standard errors (logscale) to get variance
	gen var_doi_adj_`i' = `se_doi_adj_`i''^2 
	gen var_comp_adj_`i' = `se_comp_adj_`i''^2 
	* sum the variance to get variance for the ratio 
	gen var_sum_adj_`i' = var_doi_adj_`i' + var_comp_adj_`i'
	* square root to get standard error for the ratio 
	gen simple_ratio_se_adj_`i' = sqrt(var_sum_adj_`i')
	* times 1.96 to get an error factor 
	gen simple_ratio_ef_adj_`i' = 1.96 * simple_ratio_se_adj_`i' 

	* generate upper and lower confidence limits 
	gen lcl_adj_`i' = exp((log(simple_ratio_adj_`i') - simple_ratio_ef_adj_`i'))
	gen ucl_adj_`i' = exp((log(simple_ratio_adj_`i') + simple_ratio_ef_adj_`i'))

} 

/* OUTPUT RESULTS ============================================================*/ 
*  this uses stata's file write functionality to write the results to a txt file 
*  note, the file write functionality writes by row of a table 

cap file close tablecontent
file open tablecontent using "$outdir/table_simple_ratio_$suffix.txt", write text replace

file write tablecontent ("Table [x]: Active Comparator, Simple Ratio") _n
file write tablecontent _tab ("Drug of interest") _tab _tab ("Comparator") _tab _tab _n 
file write tablecontent _tab ("Rate Ratio") _tab ("95%CI") _tab ("Rate Ratio") _tab ("95%CI") _tab ("Simple Ratio") _tab ("95%CI") _n 

file write tablecontent "UNADJUSTED" _n 
forvalues i=1/`numcat' {
	
	file write tablecontent ("`i'") _tab (round(exp(`rr_doi_`i''),0.01)) _tab (round(exp(`lcl_doi_`i''),0.01)) (" - ")  (round(exp(`ucl_doi_`i''),0.01)) _tab 
	file write tablecontent (round(exp(`rr_comp_`i''),0.01)) _tab (round(exp(`lcl_comp_`i''),0.01)) (" - ")  (round(exp(`ucl_comp_`i''),0.01)) _tab 
	file write tablecontent (round(simple_ratio_`i'),0.01) _tab (round(lcl_`i'),0.01) (" - ")  (round(ucl_`i'),0.01) _tab _n	
	
}

file write tablecontent "ADJUSTED" _n 
forvalues i=1/`numcat' {
	
	file write tablecontent ("`i'") _tab (round(exp(`rr_doi_adj_`i''),0.01)) _tab (round(exp(`lcl_doi_adj_`i''),0.01)) (" - ")  (round(exp(`ucl_doi_adj_`i''),0.01)) _tab 
	file write tablecontent (round(exp(`rr_comp_adj_`i''),0.01)) _tab (round(exp(`lcl_comp_adj_`i''),0.01)) (" - ")  (round(exp(`ucl_comp_adj_`i''),0.01)) _tab 
	file write tablecontent (round(simple_ratio_adj_`i'),0.01) _tab (round(lcl_adj_`i'),0.01) (" - ")  (round(ucl_adj_`i'),0.01) _tab _n	
	
}
 

* Close table output 
file close tablecontent

* Close log 
log close 
