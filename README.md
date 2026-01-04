# dane-county-psa-analysis
Replication files for final research and data analysis project completed for ECON 970: Applying Economic Theory to the Law at Harvard University, Fall 2025.

# Overview
This project examines how judges utilize algorithmic risk assessment outputs in their pretrial detention decisions and what the implications of these behaviors are for accuracy and economic efficiency, using administrative court data from a randomized PSA provision experiment conducted in Dane County, Wisconsin, between 2017-2018. I use Stata to estimate logit regressions and analyze the effects of providing judges with PSA recommendations on judges' propensity to override the algorithm's recommendation in a more favorable direction for the defendant and the impact of PSA provision on judges' pretrial release versus detention decisions. The repository contains all files necessary to reproduce the empirical analysis and results presented in my final project.


# Data
- **Source:** E. Ben-Michael et al., “Replication Data for: Does AI help humans make better decisions?: Astatistical evaluation framework for experimental and observational studies.” Harvard Dataverse.https://doi.org/10.7910/DVN/KMM8WN. Deposited 30 August 2025.
- **Time period:** January 2017 - December 2018
- **Key variables:** *judge_override* - a binary measure of whether the judge disagreed with the algorithmic recommendation to release the defendant when the algorithm recommended detention; *judge_decision* - a binary measure of whether the judge ultimately decided to release (0) or detain (1) the defendant

The dataset used in this analysis is stored in `data/raw/`. The cleaned dataset is stored in `data/processed/`.

# Code
- `code/psa_analysis.do`: Main Stata do-file that runs the full analysis.
  The script cleans the data, generates all variables, and produces
  the regression output used in the paper.

# Output
- `output/psa_analysis.log`: Stata log file capturing all output generated
  by `psa_analysis.do`, including summary statistics and regression results.

# Paper
- `paper/Final Research Paper.pdf`: Final written report describing the research
  question, data, methodology, results, and conclusions.

# Author
Juliet Bu (Harvard College Class of 2027)  
Harvard University  
Department of Economics  
This project was completed as part of coursework and reflects independent student work.

