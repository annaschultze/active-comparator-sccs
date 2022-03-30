/*==============================================================================
DO FILE NAME: 		 active_comparator_sccs.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 22/03/2022
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1

DESCRIPTION OF FILE: This do file runs both the simple ratio and nested regression and outputs the results  
					 It calls two separate do files, and inputs outcome and exposure variable names through global macros
					 This means you can use the dofiles for multiple different outcomes/exposures 
					
REQUIREMENTS: 	   - the dofiles need to live in your project directory (ie, not the Stata subfolder created by this program)	
				   - the do file is set up using relative paths, the user should EITHER: 
					    -- manually change the wd using the cd statement before executing 
						-- open Stata from the dofile so that the wd is automatically set to the project directory (and remove the cd statement)
					- the results are printed to different folders in a subfolder called "Stata"
					    -- !!if you already have a folder called Stata in this wd containing something else, change this program!! 
					- the data is assumed to live in a folder called wd/data. Change this if required. 
					- Stata version 16 or higher is recommended, as some functionality may not exist in earlier versions 
						-- if you have an earlier version, you may need to adjust the code to output tables in particular 
					 
OUTPUT CREATED:	    log file printed to the /log folder
					as specified in constituent dofiles 

EDITS: 				
==============================================================================*/

/* HOUSEKEEPING===============================================================*/ 
clear 

* set working directory (note, update to match local requirements)
cd "/Users/schultzeanna/Documents/03_GSK/sccs/04_code"

* speficy where the data lives 
global datadir "`c(pwd)'/data"

* Create required folders 
capture mkdir "`c(pwd)'/Stata"
capture mkdir "`c(pwd)'/Stata/log"
capture mkdir "`c(pwd)'/Stata/output"

/* CALL PROGRAMS===============================================================*/ 
*  note, specify the exposure and outcome variable names as global macros here 

global outcome "outcome"
global doi "class_FQ"
global comp "class_TMP"
global nested_anydrug "anydrug"
global nested_doi "doi"

* timeupdated variables (note, a list should be ok here, note i. specification)
global timevar "i.timevar"

* OUTCOME 1 
do "active_comparator_simple_ratio.do"
do "active_comparator_nested_regression.do"

* OUTCOME 2 etc 

