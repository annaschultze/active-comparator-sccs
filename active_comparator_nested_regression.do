/*==============================================================================
DO FILE NAME: 		 active_comparator_nested_regression.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 03/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This do file shows how to incorporate an active comparator 
					 in SCCS using the "nested regression" approach, and accompanies 
					 the GSK/LSHTM white paper (placeholder - REF)
					 
REQUIREMENTS: 	 	 - the do file is set up using relative paths, the user should EITHER: 
					    -- manually change the wd using the cd statement before executing 
						-- open Stata from the dofile so that the wd is automatically set to the project directory (and remove the cd statement)
					 - because the do file uses local macros, it needs to be run in one go or Stata will throw an error
					 - data should be stored in a folder named data 
						-- [placeholder - simulate a small dataset for whitepaper and describe]
					 
OUTPUT CREATED:	    log file printed to the /log folder
					table_nested_regression_$outcome.txt printed to the /output folder 

EDITS: 				updated variable names, simplified program structure (Mar 2022)
==============================================================================*/

/* HOUSEKEEPING===============================================================*/ 
clear 

* Open a log file
cap log close
log using "$logdir/active_comparator_nested_regression_$suffix", replace t

* Read in data 
use "$datadir/sample_data.dta"

/* BASIC DATA MANAGEMENT=======================================================*/
* if the exposure has multiple levels, saving results can become cumbersome 
* use stata levelsof to run this through a loop 
* note, assumes that doi and comp have same number of levels - long term, will introduce error if not true 
* need extra step to extract local macro to ensure compatability with Stata14 

levelsof($doi), local(num)
local num2 : word count `num'
local numcat = `num2' - 1
di `numcat'

/* UNADJUSTED ANALYSES========================================================*/
* Fit unadjusted conditional poisson models for drug of interest and comparator 

* DOI
* fit conditional poisson model (fixed effects poisson model based on patient ID)
xtpoisson $outcome i.$doi, fe i(patient_id) offset(loginterval) irr 
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

* DOI 
xtpoisson $outcome i.$doi $timevar, fe i(patient_id) offset(loginterval) irr 
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
xtpoisson $outcome i.$comp $timevar, fe i(patient_id) offset(loginterval) irr 
mat matrix_comp_adj = r(table)

forvalues i=1/`numcat' {
	
	* round and save exponentiated estimates for printing in a table later on
	local rr_comp_adj_`i' = matrix_comp_adj[1,`i'+1]
	local lcl_comp_adj_`i' = matrix_comp_adj[5,`i'+1]
	local ucl_comp_adj_`i' = matrix_comp_adj[6,`i'+1]
	local se_comp_adj_`i' = matrix_comp_adj[2,`i'+1]  

} 

/* NESTED REGRESSION==========================================================*/
 
/* UNADJUSTED */  
xtpoisson $outcome i.$nested_anydrug i.$nested_anydrug#i.$nested_doi , fe i(patient_id) offset(loginterval) irr 
mat matrix_nested = r(table)

forvalues i=1/`numcat' {
	
	* determine the appropriate column number to extract
	* can be viewed using matrix list r(table)
	* when looking at this, it turns out that the rule below extracts the correct column
	* this is because interaction results start after numcat times 2, and then everyother column is empty 
	* note the construction of the doi is crucial here, and results should always be checked vs. the log to ensure correct cols selected
	local colnum = (`numcat' * 2) + ((`i' * 2) - 1)
	
	* round and save exponentiated estimates for printing in a table later on
	local nested_ratio_`i' = matrix_nested[1,`colnum']
	local nested_lcl_`i' = matrix_nested[5,`colnum']
	local nested_ucl_`i' = matrix_nested[6,`colnum']

} 

/* ADJUSTED */  
xtpoisson $outcome i.$nested_anydrug i.$nested_anydrug#i.$nested_doi $timevar, fe i(patient_id) offset(loginterval) irr 
mat matrix_nested_adj = r(table)

forvalues i=1/`numcat' {
	
	* determine the appropriate column number to extract
	local colnum = (`numcat' * 2) + ((`i' * 2) - 1)
	
	* round and save exponentiated estimates for printing in a table later on
	local nested_ratio_adj_`i' = matrix_nested_adj[1,`colnum']
	local nested_lcl_adj_`i' = matrix_nested_adj[5,`colnum']
	local nested_ucl_adj_`i' = matrix_nested_adj[6,`colnum']

} 

/* ADJUSTED */  

/* OUTPUT RESULTS ============================================================*/ 
*  this uses stata's file write functionality to write the results to a txt file 
*  note, the file write functionality writes by row of a table 

cap file close tablecontent
file open tablecontent using "$outdir/table_nested_regression_$suffix.txt", write text replace

file write tablecontent ("Table [x]: Active Comparator, Nested Regression") _n
file write tablecontent _tab ("Drug of interest") _tab _tab ("Comparator") _tab _tab _n 
file write tablecontent _tab ("Rate Ratio") _tab ("95%CI") _tab ("Rate Ratio") _tab ("95%CI") _tab ("Nested Ratio") _tab ("95%CI") _n 

file write tablecontent "UNADJUSTED" _n 
forvalues i=1/`numcat' {
	
	file write tablecontent ("`i'") _tab (round(`rr_doi_`i''),0.01) _tab (round(`lcl_doi_`i''),0.01) (" - ")  (round(`ucl_doi_`i''),0.01) _tab 
	file write tablecontent (round(`rr_comp_`i''),0.01) _tab (round(`lcl_comp_`i''),0.01) (" - ")  (round(`ucl_comp_`i''),0.01) _tab 
	file write tablecontent (round(`nested_ratio_`i''),0.01) _tab (round(`nested_lcl_`i''),0.01) (" - ")  (round(`nested_ucl_`i''),0.01) _tab _n	
	
}

file write tablecontent "ADJUSTED" _n 
forvalues i=1/`numcat' {
	
	file write tablecontent ("`i'") _tab (round(`rr_doi_adj_`i''),0.01) _tab (round(`lcl_doi_adj_`i''),0.01) (" - ")  (round(`ucl_doi_adj_`i''),0.01) _tab 
	file write tablecontent (round(`rr_comp_adj_`i''),0.01) _tab (round(`lcl_comp_adj_`i''),0.01) (" - ")  (round(`ucl_comp_adj_`i''),0.01) _tab 
	file write tablecontent (round(`nested_ratio_adj_`i''),0.01) _tab (round(`nested_lcl_adj_`i''),0.01) (" - ")  (round(`nested_ucl_adj_`i''),0.01) _tab _n	
	
}
 

* Close table output 
file close tablecontent

* Close log 
log close 
