## Build the who_lms dataset from the WHO tables distributed in the anthro
## (WHO 2006 Child Growth Standards, 0 to 60 months) and anthroplus (WHO 2007
## Growth Reference, 60 to 228 months) packages. Ages are stored in months.
library(dplyr)
e6 <- asNamespace("anthro"); e7 <- asNamespace("anthroplus")
sexlab <- function(s) ifelse(s == 1, "Male", "Female")
d6 <- function(tab, ind) {
  x <- get(tab, e6)
  x <- x[x$age < 1826, ]                          # strictly below 60 months
  keep <- x$age %% 7 == 0 | x$age < 60            # weekly after the first two months
  x <- x[keep, ]
  tibble(indicator = ind, sex = sexlab(x$sex), age_mo = x$age / 30.4375,
         L = x$l, M = x$m, S = x$s, source = "WHO2006")
}
d7 <- function(tab, ind) {
  x <- get(tab, e7)
  tibble(indicator = ind, sex = sexlab(x$sex), age_mo = as.numeric(x$age),
         L = x$l, M = x$m, S = x$s, source = "WHO2007")
}
who_lms <- bind_rows(
  d6("growthstandards_lenanthro", "hfa"), d6("growthstandards_weianthro", "wfa"),
  d6("growthstandards_bmianthro", "bfa"),
  d7("hfa_growth_standards", "hfa"), d7("wfa_growth_standards", "wfa"),
  d7("bfa_growth_standards", "bfa")
) %>% arrange(indicator, sex, age_mo)
who_lms <- as.data.frame(who_lms)
usethis::use_data(who_lms, overwrite = TRUE, compress = "xz")
