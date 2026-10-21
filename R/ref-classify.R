#' Classify nutritional status
#'
#' With `system = "who"` (default) the WHO cut-offs are applied: for
#' children under 5 years (WHO 2006 standards) BMI-for-age above 2 SD is
#' overweight and above 3 SD is obesity, and from 5 years (WHO 2007
#' reference) above 1 SD is overweight and above 2 SD is obesity. Thinness
#' is BMI-for-age below -2 SD (severe below -3 SD) and stunting is
#' height-for-age below -2 SD (severe below -3 SD).
#'
#' With `system = "cdc"` the CDC percentile rules for children aged 2 to 20
#' years are applied to z-scores computed against the CDC 2000 charts:
#' underweight below the 5th BMI percentile, overweight from the 85th to
#' below the 95th percentile and obesity at or above the 95th percentile.
#' Short stature is height below the 3rd percentile.
#'
#' @param x Data with `age`, `height`, `weight` (or existing `haz` and
#'   `baz` for the WHO system). Z-scores are computed when missing.
#' @param system `"who"` or `"cdc"`.
#' @return `x` with factor columns `height_status` and `bmi_status`, and
#'   logical indicators `stunting`, `severe_stunting`, `thinness`,
#'   `overweight` (overweight but not obese), `obesity`,
#'   `overweight_obesity` and, for the WHO system under 10 years,
#'   `underweight`. With the CDC system the z-scores used are stored in
#'   `haz_cdc` and `baz_cdc`.
#' @section Next steps:
#' Count and compare with [wgh_prevalence()], test trends with
#' [wgh_trend_test()] or [wgh_gee_trend()], and plot with
#' [wgh_plot_status_bars()] or [wgh_plot_prevalence()].
#' @examples
#' cl <- wgh_classify(growdat)
#' table(cl$bmi_status, cl$sex)
#' cdc <- wgh_classify(growdat[growdat$age >= 2, ], system = "cdc")
#' table(cdc$bmi_status, cdc$sex)
#' @export
wgh_classify <- function(x, system = c("who", "cdc")) {
  system <- match.arg(system)
  d <- .gd(x, c("age"))
  if (system == "cdc") {
    if (!"bmi" %in% names(d)) d$bmi <- d$weight / (d$height / 100)^2
    d$haz_cdc <- wgh_zscore(d$height, d$age, d$sex, "hfa", reference = "cdc")
    d$baz_cdc <- wgh_zscore(d$bmi, d$age, d$sex, "bfa", reference = "cdc")
    p_h <- stats::pnorm(d$haz_cdc); p_b <- stats::pnorm(d$baz_cdc)
    d$stunting <- p_h < 0.03
    d$severe_stunting <- d$haz_cdc < -3
    d$height_status <- factor(ifelse(is.na(p_h), NA, ifelse(p_h < 0.03, "Short stature",
                              ifelse(p_h > 0.97, "Tall", "Normal"))), levels = c("Short stature", "Normal", "Tall"))
    d$thinness <- p_b < 0.05
    d$obesity <- p_b >= 0.95
    d$overweight <- p_b >= 0.85 & !d$obesity
    d$overweight_obesity <- p_b >= 0.85
    d$bmi_status <- factor(ifelse(is.na(p_b), NA, ifelse(p_b < 0.05, "Underweight",
                           ifelse(p_b >= 0.95, "Obesity", ifelse(p_b >= 0.85, "Overweight", "Healthy weight")))),
                           levels = c("Underweight", "Healthy weight", "Overweight", "Obesity"))
    return(.regd(x, d))
  }
  if (!all(c("haz", "baz") %in% names(d))) d <- .gd(wgh_add_zscores(d), "age")
  u5 <- d$age < 5
  d$stunting <- d$haz < -2
  d$severe_stunting <- d$haz < -3
  d$height_status <- factor(ifelse(is.na(d$haz), NA, ifelse(d$haz < -3, "Severe stunting",
                            ifelse(d$haz < -2, "Stunting", ifelse(d$haz > 2, "Tall", "Normal")))),
                            levels = c("Severe stunting", "Stunting", "Normal", "Tall"))
  ow_cut <- ifelse(u5, 2, 1); ob_cut <- ifelse(u5, 3, 2)
  d$thinness <- d$baz < -2
  d$obesity <- d$baz > ob_cut
  d$overweight <- d$baz > ow_cut & !d$obesity
  d$overweight_obesity <- d$baz > ow_cut
  d$bmi_status <- factor(ifelse(is.na(d$baz), NA,
                         ifelse(d$baz < -3, "Severe thinness", ifelse(d$baz < -2, "Thinness",
                         ifelse(d$baz > ob_cut, "Obesity", ifelse(d$baz > ow_cut, "Overweight", "Normal"))))),
                         levels = c("Severe thinness", "Thinness", "Normal", "Overweight", "Obesity"))
  if ("waz" %in% names(d)) d$underweight <- ifelse(d$age < 10, d$waz < -2, NA)
  .regd(x, d)
}

#' Double burden of malnutrition
#'
#' Individual double burden is stunting together with overweight or obesity
#' in the same child at the same visit. Population double burden is defined
#' by the WHO thresholds: a group has a double burden when stunting (or
#' thinness) prevalence is at least `undernutrition_threshold` and
#' overweight or obesity prevalence is at least `overweight_threshold`.
#'
#' @param x Classified data (see [wgh_classify()]).
#' @param by Grouping columns for the population indicator.
#' @param undernutrition_threshold,overweight_threshold Prevalence
#'   thresholds in percent (WHO: 10 and 20).
#' @return A list with `individual` (data with column `dbm_individual`) and
#'   `population` (prevalences and a logical `dbm_population` by group).
#' @examples
#' cl <- wgh_classify(growdat)
#' wgh_dbm(cl, by = c("sex", "site"))$population
#' @export
wgh_dbm <- function(x, by = "sex", undernutrition_threshold = 10, overweight_threshold = 20) {
  d <- .gd(wgh_classify(x), "age")
  if (!is.null(by)) by <- .fix_by(d, by)
  d$dbm_individual <- d$stunting & d$overweight_obesity
  g <- if (is.null(by)) d else dplyr::group_by(d, dplyr::across(dplyr::all_of(by)))
  pop <- dplyr::summarise(g, n = dplyr::n(),
                          stunting = 100 * mean(.data$stunting, na.rm = TRUE),
                          thinness = 100 * mean(.data$thinness, na.rm = TRUE),
                          overweight_obesity = 100 * mean(.data$overweight_obesity, na.rm = TRUE),
                          dbm_individual = 100 * mean(.data$dbm_individual, na.rm = TRUE),
                          .groups = "drop")
  pop$dbm_population <- (pop$stunting >= undernutrition_threshold | pop$thinness >= undernutrition_threshold) &
    pop$overweight_obesity >= overweight_threshold
  list(individual = d, population = tibble::as_tibble(pop))
}
