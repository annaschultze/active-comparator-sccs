/*==============================================================================
DO FILE NAME: 		 active_comparator_sccs.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 22/03/2022
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1

DESCRIPTION OF FILE: This do file runs both the simple ratio and nested regression and outputs the results  
					 It calls two separate do files, and inputs outcome and exposure variable names through global macros
					 This means you can use the dofiles for multiple different outcomes/exposures 
					
REQUIREMENTS: 	   - the dofiles need to live in your project directory 
				   - the do file is set up using relative paths, the user should EITHER: 
					    -- manually change the wd using the cd statement before executing 
						-- open Stata from the dofile so that the wd is automatically set to the project directory (and remove the cd statement)
					- the results are printed to different folders in a subfolder called "output" and logfiles to "log"
					    -- !!if you already have a folders called output and log in this wd containing something else, change this program!! 
						-- !!stata will not error if folders already exist, it will just add the results to those folders 
					- the data is assumed to live in a folder called wd/data. Change this if required. 
					- Stata version 14 or higher is recommended, as some functionality may not exist in earlier versions 
					    -- code was developed using Stata 17  
					 
OUTPUT CREATED:	    log file printed to the /log folder
					as specified in constituent dofiles 

EDITS: 				
==============================================================================*/

/* HOUSEKEEPING================================================================ 
note - you can change the working directory here as required, but you 
should not need to change it in the consitutent dofiles called by this 
program. 

if you want to read in data from elsewhere, or redirect the output, it is also 
enough to change that here as the constituent dofiles use the macro variables 
and no absolute file paths 
*/ 
clear 

* set working directory (note, update to match local requirements)
cd "/Users/schultzeanna/Documents/03_GSK/sccs/04_Code/active-comparator-sccs"

* speficy where the data lives 
global datadir "`c(pwd)'/data"

* Create required folders 
capture mkdir "`c(pwd)'/log"
capture mkdir "`c(pwd)'/output"

global logdir "`c(pwd)'/log"
global outdir "`c(pwd)'/output"

/* CALL PROGRAMS===============================================================*/ 


/* GLOBAL VARIABLES 
change these options depending on the structure of your dataset
the program requires the following inputs: 

   outcome - this is your outcome variable 
   doi - this is the variable denoting the drug of interest 
   comp - this is the varaiable denoting the comparator of interest 
   nested_anydrug - this is the variable denoting the risk level of EITHER drug 
                    of interest or the comparator 
   nested_doi - this variable denotes whether the risk level specified in 
                nested_anydrug belongs to drug of interest
   timevar - this is a list of your adjustment variables. Note these should be 
             specified as categorical with the i. prefix if you want them to 
			 be categorical. You can list more than one variable here. 

change the variables by changing the text within quotation marks. 

you can then call the programs as required. Note that outputs and logs are 
outputted using the "suffix" global option, so choose something unique for this. 

*/ 

* OUTCOME 1 
* set globals for outcome one 
global outcome "outcome"
global doi "class_FQ"
global comp "class_TMP"
global nested_anydrug "anydrug"
global nested_doi "doi"
global timevar "i.timevar"
global suffix "outcome"

* call dofiles for outcome one 
do "active_comparator_simple_ratio.do"
do "active_comparator_nested_regression.do"

* OUTCOME 2 etc 
* reset required globals for outcome two 
global outcome "retinal"
global suffix "retinal"

* call dofiles for outcome two 
do "active_comparator_simple_ratio.do"
do "active_comparator_nested_regression.do"













