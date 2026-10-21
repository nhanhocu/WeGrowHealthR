## Build the cdc_lms dataset: CDC 2000 growth charts LMS parameters
## (2 to 20 years) for height-for-age, weight-for-age and BMI-for-age, taken
## from the tables distributed with the cdcanthro package (GPL-3). The CDC
## growth charts are a work of the United States government.
e <- new.env()
load("/tmp/claude-0/ext/cdcanthro/data/cdc_ref_data.rda", envir = e)
x <- as.data.frame(e$cdc_ref_data)
sexlab <- ifelse(x$sexn == 1, "Male", "Female")
mk <- function(ind, l, m, s) data.frame(indicator = ind, sex = sexlab, age_mo = x$age,
                                       L = x[[l]], M = x[[m]], S = x[[s]], source = "CDC2000")
cdc_lms <- rbind(mk("hfa", "hl", "hm", "hs"), mk("wfa", "wl", "wm", "ws"), mk("bfa", "bl", "bm", "bs"))
cdc_lms <- cdc_lms[order(cdc_lms$indicator, cdc_lms$sex, cdc_lms$age_mo), ]
rownames(cdc_lms) <- NULL
usethis::use_data(cdc_lms, overwrite = TRUE, compress = "xz")
