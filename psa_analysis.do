* Setting up stata
clear all 
version 19 
capture log close
cd "/Users/julietbu/Downloads/ECON970/Final Project/output"
log using psa_analysis.log, replace

* Add row ids to each observation for merging. In package documentation for this replication dataset, original authors refer to these files as parallel interim datasets created directly from the RCT pipeline, meaning they are aligned row-by-row.
* Edit datasets for merging, eliminating duplicate variables in FTA, NCA, and NVCA datasets already existing in PSA dataset.
use "/Users/julietbu/Downloads/ECON970/Final Project/data/FTAdata.dta", clear
rename Y Y_FTA
ds
local fta_vars `r(varlist)'
generate rowid = _n
drop Z D Sex White 
save FTAdata_id, replace

use "/Users/julietbu/Downloads/ECON970/Final Project/data/NCAdata.dta", clear
generate rowid = _n
rename Y Y_NCA
foreach v of local fta_vars {    
            capture drop `v'  
}
save NCAdata_id, replace

use "/Users/julietbu/Downloads/ECON970/Final Project/data/NVCAdata.dta", clear
generate rowid = _n
rename Y Y_NVCA
foreach v of local fta_vars {    
            capture drop `v'  
}
save NVCAdata_id, replace

* Rename variables in PSA data for clarity, add variable to measure judicial-algorithmic agreement
use "/Users/julietbu/Downloads/ECON970/Final Project/data/PSAdata.dta", clear
generate rowid = _n
rename Z PSA_treatment
label variable PSA_treatment "Judge Exposure to PSA Score"
gen judge_decision = (D == 1 | D == 2)
label variable judge_decision "Judge Non-Monetary Release or Cash Bail/Detention Decision"
label variable DMF "PSA Release or Detention Recommendation"
generate agree = (judge_decision == DMF)
label variable agree "Judge-Algorithm Agreement"
generate judge_override = (judge_decision == 0 & DMF == 1)
label variable judge_override "Judge Decision of Release, Algorithm Decision of Bail or Detention"
save PSAdata_id, replace

* Create frame to merge PSA data with FTA, NCA, and NVCA
frame create PSAdata 
frame change PSAdata
use "/Users/julietbu/Downloads/ECON970/Final Project/output/PSAdata_id.dta"

* Merge with FTA
merge 1:1 rowid using "/Users/julietbu/Downloads/ECON970/Final Project/output/FTAdata_id.dta"
keep if _merge == 3
drop _merge

* Merge with NCA
merge 1:1 rowid using "/Users/julietbu/Downloads/ECON970/Final Project/output/NCAdata_id.dta"
keep if _merge == 3
drop _merge

* Merge with NVCA
merge 1:1 rowid using "/Users/julietbu/Downloads/ECON970/Final Project/output/NVCAdata_id.dta"
keep if _merge == 3
drop _merge

generate anyFlag = (Y_FTA == 1 | Y_NCA == 1 | Y_NVCA == 1)
label variable anyFlag "Any FTA, NCA, or NVCA Flag"
save master_PSA, replace

* Find proportions of release versus detention/cash bail for logit coefficient interpretation 
tab judge_decision if PSA_treatment == 1 

* Find proportions of override versus following the algorithm for logit coefficient interpretation 
tab judge_override if PSA_treatment == 1 

* When judges don't versus do use algorithm, how does their agreement with the algorithm differ? Evidence that judges' decisionmaking is influenced by the algorithm
table PSA_treatment, stat(mean agree)
ttest agree, by(PSA_treatment)

* How does the algorithms strictness, as measured by proportion of defendants detained versus released, compare to judge strictness? 
tab DMF
tab judge_decision if PSA_treatment == 0

* What demographic variables, if any, are correlated with a judges' decision to override the algorithm?
logit judge_override Sex White SexWhite Age /// 
	PendingChargeAtTimeOfOffense NCorNonViolentMisdemeanorCharge ViolentMisdemeanorCharge ViolentFelonyCharge ///
	NonViolentFelonyCharge PriorMisdemeanorConviction PriorFelonyConviction PriorViolentConviction ///
	PriorSentenceToIncarceration PriorFTAInPastTwoYears PriorFTAOlderThanTwoYears if PSA_treatment == 1
eststo clear
eststo m1
esttab m1 using "demographic_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Demographic Variables Correlated with Judicial Override of PSA")


* When judges are provided with the PSA output, do their release rates for different genders change? That is, does the PSA cause the judge to be more/less lenient for certain gender groups? 
logit judge_decision PSA_treatment##Sex ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age White SexWhite
eststo clear
eststo m1
esttab m1 using "gender_release_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Correlation of Gender with Judicial Release Decision by PSA Provision")


margins Sex, at(PSA_treatment=(0 1))
estpost margins Sex, at(PSA_treatment = (0 1))
eststo m_margins
esttab m_margins using "gender_release_margins_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Margin" "Std. Err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Marginal Change in Judge Decision by Sex at PSA_treatment = 0 and 1")


* When judges are provided with the PSA output, do their override rates for different genders change? That is, does the PSA cause the judge to be more/less likely to override for certain gender groups? 
logit judge_override PSA_treatment##Sex ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age White SexWhite
eststo clear
eststo m1
esttab m1 using "gender_override_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Correlation of Gender with Judicial Override Decision by PSA Provision")

margins Sex, at(PSA_treatment=(0 1))
estpost margins Sex, at(PSA_treatment = (0 1))
eststo m_margins
esttab m_margins using "gender_override_margins_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Margin" "Std. Err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Marginal Change in Judge Override by Sex at PSA_treatment = 0 and 1")

* When judges are provided with the PSA output, do their release rates for different races change? That is, does the PSA cause the judge to be more/less lenient for certain racial groups? 
logit judge_decision PSA_treatment##White ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age Sex SexWhite
eststo clear
eststo m1
esttab m1 using "race_release_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Correlation of Race with Judicial Release Decision by PSA Provision")
	
margins White, at(PSA_treatment=(0 1))
estpost margins White, at(PSA_treatment = (0 1))
eststo m_margins
esttab m_margins using "race_release_margins_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Margin" "Std. Err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Marginal Change in Judge Decision by Race at PSA_treatment = 0 and 1")

* When judges are provided with the PSA output, do their override rates for different races change? That is, does the PSA cause the judge to be more/less likely to override for certain racial groups? 
logit judge_override PSA_treatment##White ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age Sex SexWhite
eststo clear
eststo m1
esttab m1 using "race_override_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Correlation of Race with Judicial Override Decision by PSA Provision")
	
margins White, at(PSA_treatment=(0 1))
estpost margins White, at(PSA_treatment = (0 1))
eststo m_margins
esttab m_margins using "race_override_margins_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Margin" "Std. Err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Marginal Change in Judge Override by Race at PSA_treatment = 0 and 1")

* When judges are provided with the PSA output, do their release rates for different race/gender groups change? That is, does the PSA cause the judge to be more/less lenient for certain racial/gender groups? 
logit judge_decision PSA_treatment##SexWhite ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age White Sex
	
margins SexWhite, at(PSA_treatment=(0 1))

* When judges are provided with the PSA output, do their override rates for different race/gender groups change? That is, does the PSA cause the judge to be more/less likely to override for certain racial/gender groups? 
logit judge_override PSA_treatment##SexWhite ///
    FTAScore NCAScore NVCAFlag ///
    PriorMisdemeanorConviction PriorFelonyConviction ///
    PriorFTAInPastTwoYears PriorSentenceToIncarceration ///
    ViolentFelonyCharge ViolentMisdemeanorCharge ///
    Age White Sex
eststo clear
eststo m1
esttab m1 using "genderrace_override_logit_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Coefficient" "Std. err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Logit model: Correlation of Gender-Race with Judicial Override Decision by PSA Provision")
	
margins SexWhite, at(PSA_treatment=(0 1))
estpost margins SexWhite, at(PSA_treatment = (0 1))
eststo m_margins
esttab m_margins using "genderrace_override_margins_results.csv", replace ///
    cells("b(fmt(3)) se(fmt(3)) z(fmt(3)) p(fmt(3)) ci(fmt(3))") ///
    collabels("Margin" "Std. Err." "z" "P>|z|" "95% CI") ///
    label ///
    title("Marginal Change in Judge Override by Gender-Race at PSA_treatment = 0 and 1")


* Evaluating the accuracy of judge-alone versus algorithm-assisted decision making. Comparing accuracy of  judge-alone decision making to judge-assisted decision making. Comparing accuracy of judicial overrides to accuracy of algorithm alone. 
summarize anyFlag if PSA_treatment == 0 & judge_decision == 0
summarize anyFlag if PSA_treatment == 1 & judge_decision == 0
summarize anyFlag if PSA_treatment == 1 & judge_override == 1
summarize anyFlag if DMF == 0 & judge_decision == 0

summarize judge_decision if PSA_treatment == 0
summarize judge_decision if PSA_treatment == 1

keep if judge_decision == 0
ttest anyFlag, by(PSA_treatment)




