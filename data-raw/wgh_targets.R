## Published patterns that the wgh_like preset is set to resemble.
## Values from the abstracts and main tables of the published papers.
## Bands are generous on purpose: resemblance, not replication.
library(tibble)
## Full citations: wgh_references()
sr <- "Ho et al. 2026, Sci Rep 16:7515"
p2 <- "Ho et al. 2026, medRxiv 2026.07.26.26358982"
p4a <- "Ho et al. 2026, medRxiv 2026.07.26.26358986"
p6 <- "Ho 2026, medRxiv 2026.09.08.26362487"
p9 <- "Ho 2026, medRxiv 2026.09.05.26362315"
wgh_targets <- tribble(
  ~target, ~sex, ~published, ~lower, ~upper, ~unit, ~source, ~tuned,
  "Visits at largest site (%)", "All", 67.6, 55, 75, "%", sr, TRUE,
  "Visits at smallest site (%)", "All", 7.4, 4, 14, "%", sr, TRUE,
  "Visits under 5 years (%)", "All", 22.7, 15, 30, "%", sr, TRUE,
  "Visits at ages 5 to 11 (%)", "All", 48.6, 38, 58, "%", sr, TRUE,
  "Visits in first year (%)", "All", 3.4, 1, 8, "%", sr, TRUE,
  "Overweight or obesity, 5 to 18 y (%)", "Male", 47.7, 42, 53, "%", sr, TRUE,
  "Overweight or obesity, 5 to 18 y (%)", "Female", 26.3, 21, 31, "%", sr, TRUE,
  "Obesity, 5 to 18 y (%)", "Male", 22.9, 18, 28, "%", sr, TRUE,
  "Obesity, 5 to 18 y (%)", "Female", 6.7, 4, 10, "%", sr, TRUE,
  "Overweight or obesity, under 5 (%)", "Male", 9.0, 5, 14, "%", sr, TRUE,
  "Overweight or obesity, under 5 (%)", "Female", 5.1, 2, 9, "%", sr, TRUE,
  "Stunting, 5 to 18 y (%)", "Male", 0.7, 0.2, 2, "%", sr, FALSE,
  "Stunting, 5 to 18 y (%)", "Female", 1.0, 0.2, 2.5, "%", sr, FALSE,
  "Stunting, under 5 (%)", "Male", 3.2, 1, 7, "%", sr, FALSE,
  "Stunting, under 5 (%)", "Female", 2.8, 1, 7, "%", sr, FALSE,
  "Change in obesity, first to last year (points)", "Male", -4.4, -9, -1, "points", p2, TRUE,
  "Change in obesity, first to last year (points)", "Female", -1.2, -4, 0.5, "points", p2, TRUE,
  "Median height at 18 y (cm)", "Male", 172, 170.5, 173.5, "cm", sr, TRUE,
  "Median height at 18 y (cm)", "Female", 160, 158.5, 161.5, "cm", sr, TRUE,
  "Population APHV (y)", "Male", 12.2, 11.7, 12.7, "years", p4a, TRUE,
  "Population APHV (y)", "Female", 9.2, 8.7, 9.7, "years", p4a, TRUE,
  "Population PHV (cm/y)", "Male", 9.3, 8.5, 10.1, "cm/year", p4a, TRUE,
  "Population PHV (cm/y)", "Female", 7.0, 6.3, 7.7, "cm/year", p4a, TRUE,
  "SD of timing (b)", "Male", 0.52, 0.40, 0.65, "years", p4a, TRUE,
  "SD of timing (b)", "Female", 1.02, 0.85, 1.20, "years", p4a, TRUE,
  "BAZ to HAZ slope, ages 5 to 11", "Male", 0.09, 0.02, 0.30, "HAZ per BAZ", p6, FALSE,
  "BAZ to HAZ slope, ages 5 to 11", "Female", 0.07, 0.02, 0.30, "HAZ per BAZ", p6, FALSE,
  "BAZ to HAZ slope, ages 16 to 18", "Male", -0.05, -0.30, 0.02, "HAZ per BAZ", p6, FALSE,
  "BAZ to HAZ slope, ages 16 to 18", "Female", -0.05, -0.30, 0.02, "HAZ per BAZ", p6, FALSE,
  "Tall-accelerated phenotype (%)", "Male", 4.2, 2, 7, "%", p9, TRUE,
  "Early-timing AUC, logistic model", "Male", 0.76, 0.65, 0.85, "AUC", p4a, FALSE,
  "Early-timing AUC, logistic model", "Female", 0.70, 0.60, 0.80, "AUC", p4a, FALSE
)
usethis::use_data(wgh_targets, overwrite = TRUE)
