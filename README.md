# Using Active Comparators in SCSS
This repo contains generalisable code for using active comparators in SCCS in Stata. 
The aim is to extend this with code for R and SAS. Briefly, the programs are: 

   - active_comparator_sccs: this is the main do file, which calls the other programs. this is the only one that should need editing. 
   - active_comparator_simple ratio: implements active comparators using the simple ratio approach, calculates 95%CI and outputs results 
   - active_comparator_nested_regression: implements active comparators using nested regression models, outputs results 

Please get in touch with anna.schultze@lshtm.ac.uk for questions, or open an issue/PR for proposed extensions/bug fixes. 
