## Flows for the descriptive papers: Sci Rep 2026, the malnutrition trends study (Ho et al. 2026, medRxiv 2026.07.26.26358982), the prepubertal BMI and height trajectory study (Ho et al. 2026, medRxiv 2026.07.26.26358003) --------

.sim_note <- "Simulated data (wgh_like preset). Tables and figures resemble the published ones but are not findings."

## Data for a flow: the user's data, or a simulated cohort sized by mode
.flow_data <- function(x, n = c(dev = 8000, analysis = 30000, publication = 30000)) {
  if (!is.null(x)) return(list(data = .gd(x, c("id", "age", "sex")), simulated = FALSE, sim = NULL))
  sim <- wgh_simulate(n[[wgh_mode()]], preset = "wgh_like", seed = 2026)
  list(data = .gd(sim$visits, c("id", "age", "sex")), simulated = TRUE, sim = sim)
}
.with_mode <- function(mode) {
  .status_push()
  old <- list(mode = wgh_mode(), overrides = getOption("WeGrowHealthR.overrides", list()), changed = !is.null(mode))
  if (!is.null(mode)) {
    if (!mode %in% names(.wgh_modes)) .stop("{.arg mode} must be one of {.val {names(.wgh_modes)}}.")
    options(WeGrowHealthR.mode = mode)
  }
  old
}
.restore_mode <- function(old) {
  .status_pop()
  if (isTRUE(old$changed)) options(WeGrowHealthR.mode = old$mode, WeGrowHealthR.overrides = old$overrides)
}

#' Flow: secular trends, prevalence and regional differences (Ho et al. 2026, Sci Rep 16:7515)
#'
#' Reproduces the structure of the secular trends study (Ho et al. 2026, Sci Rep 16:7515) on overweight,
#' obesity and growth trends: cohort description, median height, weight and
#' BMI by age, sex and year with trend tests, first-to-last year and site
#' differences, GEE calendar trends by age group, WHO nutritional status
#' prevalence with simultaneous intervals and trend tests, and (when
#' `gamlss` is installed) LMS centile curves for the cohort.
#'
#' @param x Growth data with `height`, `weight` and `year`. When `NULL`, a
#'   simulated `wgh_like` cohort is generated.
#' @param mode Run mode (see [wgh_config()]); `NULL` keeps the current mode.
#' @param fit_lms Fit cohort LMS curves with gamlss.
#' @return A [wgh_report].
#' @examples
#' \donttest{
#' rep <- wgh_flow_secular_trends(mode = "dev", fit_lms = FALSE)
#' rep
#' rep$tables$prevalence_5_18
#' }
#' @export
wgh_flow_secular_trends <- function(x = NULL, mode = NULL, fit_lms = TRUE) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  d <- .gd(wgh_classify(d))
  d$age_group <- cut(d$age, c(0, 5, 11, 19), right = FALSE, labels = c("18 mo to 5 y", "5 to 10 y", "11 to 18 y"))
  d$age_year <- floor(d$age)
  tabs <- list(); figs <- list()
  tabs$table1_visits <- wgh_table1(d, vars = c("site", "age_group", "year"), by = "sex")
  meds <- wgh_median_ci(d[d$age >= 2, ], "height", by = c("sex", "age_year", "year"))
  tabs$median_height_by_age_year <- meds
  tabs$median_trend_tests <- .bind(lapply(c("height", "weight", "bmi"), function(v) {
    r <- wgh_trend_test(d[d$age >= 2, ], v, "year", by = c("sex", "age_year"), type = "mood_median")
    dplyr::bind_cols(tibble::tibble(measure = rep(v, nrow(r))), r)
  }))
  yrs <- sort(unique(d$year))
  fl <- d[d$year %in% range(yrs) & d$age >= 2, ]
  fl$year_f <- factor(fl$year)
  tabs$height_first_vs_last_year <- wgh_median_diff(fl, "height", "year_f", by = c("sex", "age_year"), B = min(wgh_opt("B"), 200))
  tabs$height_site_differences <- wgh_median_diff(d[d$age >= 2, ], "height", "site", by = c("sex", "age_year"), B = min(wgh_opt("B"), 200))
  gee <- .try(wgh_gee_trend(d[d$age >= 5, ], "height", age_group = "age_group", by = "sex"), "GEE calendar trend in height")
  if (!.is_err(gee)) tabs$gee_height_slopes <- gee$slopes
  older <- d[d$age >= 5, ]; young <- d[d$age < 5, ]
  tabs$prevalence_5_18 <- wgh_prevalence(older, "bmi_status", by = "sex", method = "sison_glaz")
  tabs$prevalence_under5 <- wgh_prevalence(young, "bmi_status", by = "sex", method = "sison_glaz")
  tabs$overweight_obesity_by_year <- wgh_prevalence(older, "overweight_obesity", by = c("sex", "year"))
  tabs$overweight_obesity_by_site <- wgh_prevalence(older, "overweight_obesity", by = c("sex", "site"))
  tabs$stunting_by_age_group <- wgh_prevalence(d, "stunting", by = c("sex", "age_group"))
  tabs$trend_tests <- .bind(lapply(c("overweight_obesity", "obesity", "stunting", "thinness"), function(o) {
    r <- wgh_trend_test(older, o, "year", by = "sex")
    dplyr::bind_cols(tibble::tibble(indicator = rep(o, nrow(r))), r)
  }))
  mh <- stats::aggregate(height ~ sex + age_year + year, data = d[d$age >= 2, ], FUN = stats::median)
  figs$fig_median_height <- ggplot2::ggplot(mh, ggplot2::aes(.data$age_year, .data$height, colour = factor(.data$year))) +
    ggplot2::geom_line() + ggplot2::facet_wrap(~sex) + ggplot2::scale_colour_viridis_d(name = "Year") + theme_wgh() +
    ggplot2::labs(x = "Age (years)", y = "Median height (cm)")
  figs$fig_prevalence_trend <- wgh_plot_prevalence(tabs$overweight_obesity_by_year, time = "year") +
    ggplot2::labs(title = "Overweight or obesity, 5 to 18 years")
  figs$fig_status_bars <- wgh_plot_status_bars(d, group = "age_group")
  mods <- if (.is_err(gee)) list() else list(gee_height = gee)
  if (fit_lms && !requireNamespace("gamlss", quietly = TRUE)) .skip("Cohort LMS height centiles", "package gamlss is not installed")
  if (!fit_lms) .skip("Cohort LMS height centiles", "fit_lms = FALSE")
  if (fit_lms && requireNamespace("gamlss", quietly = TRUE)) {
    lms <- .try(wgh_fit_lms(d[d$age >= 2 & d$age <= 18, ], "height", by = "sex"), "Cohort LMS height centiles")
    if (!.is_err(lms)) { mods$lms_height <- lms; tabs$lms_centiles_height <- wgh_centiles(lms, ages = 2:18); figs$fig_lms_centiles <- plot(lms) }
  }
  wgh_report("Secular trends, prevalence and regional differences (Ho et al. 2026, Sci Rep 16:7515)", tabs, figs, mods,
            settings = list(mode = wgh_mode(), n_children = length(unique(d$id)), n_visits = nrow(d)),
            note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: stunting, thinness, obesity and double burden (Ho et al. 2026, medRxiv 2026.07.26.26358982)
#'
#' Prevalence of each indicator by sex and year, Cochran-Armitage trend
#' tests, GEE logistic models of calendar trends within age groups,
#' individual and population double burden by site, and the main figures
#' (trend lines, stacked status bars, double burden heat map and odds ratio
#' forest plot).
#' @inheritParams wgh_flow_secular_trends
#' @return A [wgh_report].
#' @examples
#' rep <- wgh_flow_malnutrition_trends(growdat, mode = "dev")
#' rep
#' rep$tables$prevalence_by_year
#' plot(rep, 1)
#' @export
wgh_flow_malnutrition_trends <- function(x = NULL, mode = NULL) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  d <- .gd(wgh_classify(d))
  d$age_group <- wgh_age_bands(d$age, breaks = c(0, 5, 10, 15, 19))
  tabs <- list(); figs <- list()
  tabs$table1 <- wgh_table1(d, vars = c("age", "haz", "baz", "site", "age_group"), by = "sex", per_child = TRUE)
  ind <- c("stunting", "thinness", "overweight", "obesity")
  tabs$prevalence_by_year <- .bind(lapply(ind, function(o) {
    r <- wgh_prevalence(d, o, by = c("sex", "year")); dplyr::bind_cols(tibble::tibble(indicator = rep(o, nrow(r))), r)
  }))
  tabs$trend_tests <- .bind(lapply(ind, function(o) {
    r <- wgh_trend_test(d, o, "year", by = "sex"); dplyr::bind_cols(tibble::tibble(indicator = rep(o, nrow(r))), r)
  }))
  tabs$gee_odds_ratios <- .bind(lapply(ind, function(o) {
    r <- .try(wgh_gee_trend(d, o, age_group = "age_group", by = "sex")$slopes, paste("GEE calendar trend,", o))
    if (.is_err(r)) return(NULL)
    dplyr::bind_cols(tibble::tibble(indicator = rep(o, nrow(r))), r)
  }))
  dbm <- wgh_dbm(d, by = c("sex", "site", "year"))
  tabs$double_burden <- dbm$population
  tabs$median_by_site <- wgh_median_ci(d[d$age >= 5, ], "haz", by = c("sex", "site"))
  pv <- tabs$prevalence_by_year
  figs$fig_trends <- ggplot2::ggplot(pv, ggplot2::aes(.data$year, .data$prevalence, colour = .data$sex)) +
    ggplot2::geom_line(linewidth = 0.9) + ggplot2::geom_point() + ggplot2::facet_wrap(~indicator, scales = "free_y") +
    scale_colour_wgh_sex() + theme_wgh() + ggplot2::labs(x = NULL, y = "Prevalence (%)", colour = NULL)
  figs$fig_status_bars <- wgh_plot_status_bars(d, group = "year")
  dd <- dbm$population; dd$label <- paste(dd$sex, dd$site)
  figs$fig_dbm_heatmap <- wgh_plot_heatmap(dd, "year", "label", "dbm_individual", digits = 2)
  if (nrow(tabs$gee_odds_ratios)) {
    g <- tabs$gee_odds_ratios; g$row <- paste(g$indicator, g$age_group, sep = ", ")
    figs$fig_or_forest <- wgh_plot_forest(g, "row", "or_per_year", "or_lower", "or_upper", colour = "sex", ref = 1, log = TRUE) +
      ggplot2::labs(x = "Odds ratio per calendar year")
  }
  wgh_report("Stunting, thinness, obesity and double burden (Ho et al. 2026, medRxiv 2026.07.26.26358982)", tabs, figs,
            settings = list(mode = wgh_mode(), n_children = length(unique(d$id))), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: prepubertal BMI and the height trajectory (Ho et al. 2026, medRxiv 2026.07.26.26358003)
#'
#' Assigns each child a BMI category at a prepubertal index age, compares
#' HAZ between categories at milestone ages (Kruskal-Wallis and Dunn), fits
#' a mixed model of HAZ with a spline of age by index category, reports
#' contrasts at stated ages and the ICC, summarises BMI category change
#' between two index ages and repeats the main model in children with at
#' least four visits.
#' @inheritParams wgh_flow_secular_trends
#' @param index_age Latest index age by sex.
#' @param milestones Ages for group comparisons and contrasts.
#' @return A [wgh_report].
#' @examples
#' \donttest{
#' rep <- wgh_flow_index_trajectory(growdat, mode = "dev")
#' rep
#' plot(rep, 1)
#' }
#' @export
wgh_flow_index_trajectory <- function(x = NULL, mode = NULL, index_age = c(Male = 11, Female = 9),
                                     milestones = c(8, 10, 12, 14, 16)) {
  .need("lme4"); .need("emmeans")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  fl <- wgh_sample_flow(d, "Ages 5 to 18" = ~ age >= 5 & age <= 18.5, "At least 2 visits" = wgh_min_visits(2))
  ix <- wgh_index_exposure(fl$data, "baz", max_age = index_age, categories = function(b, a) wgh_bmi_category(b, a, thinness = FALSE))
  ix$index_cat <- droplevels(ix$index_cat)
  tabs <- list(); figs <- list()
  first <- ix[!duplicated(ix$id), ]
  tabs$index_category <- wgh_prevalence(wgh_classify(first), "bmi_status", by = "sex", method = "sison_glaz")
  kw <- wgh_compare_groups(ix, "haz", "index_cat", ages = milestones, by = "sex")
  tabs$kruskal_wallis <- kw$overall; tabs$dunn <- kw$pairwise
  tabs$median_haz <- wgh_median_ci(ix[abs(ix$age - round(ix$age)) < 0.5, ], "haz", by = c("sex", "index_cat"))
  fits <- list(); ct <- list()
  for (sx in .sexes) {
    z <- ix[ix$sex == sx, ]
    f <- wgh_fit_lmm(z, haz ~ splines::ns(age, df = 3) * index_cat + site)
    fits[[sx]] <- f
    cc <- wgh_contrasts(f, "index_cat", ages = milestones)
    ct[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(cc$contrasts))), cc$contrasts)
    tabs[[paste0("fit_stats_", tolower(sx))]] <- wgh_fit_stats(f)
  }
  tabs$contrasts <- .bind(ct)
  ch <- wgh_exposure_change(fl$data, ages = c(7, 10))
  tabs$bmi_change <- as.data.frame(table(sex = ch$sex, change = ch$change))
  sens <- ix[ix$id %in% names(which(table(ix$id) >= 4)), ]
  tabs$sensitivity_4plus_visits <- .bind(lapply(.sexes, function(sx) {
    z <- sens[sens$sex == sx, ]
    if (length(unique(z$id)) < 50) return(NULL)
    f <- wgh_fit_lmm(z, haz ~ splines::ns(age, df = 3) * index_cat + site)
    cc <- wgh_contrasts(f, "index_cat", ages = milestones)$contrasts
    dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(cc))), cc)
  }))
  figs$fig_trajectories <- wgh_plot_trajectories(ix, "haz", "index_cat", milestones = milestones)
  figs$fig_height_trajectories <- wgh_plot_trajectories(ix, "height", "index_cat")
  wgh_report("Prepubertal BMI and height trajectory (Ho et al. 2026, medRxiv 2026.07.26.26358003)", tabs, figs, models = fits, sample_flow = fl,
            settings = list(mode = wgh_mode(), index_age = index_age), note = if (fd$simulated) .sim_note else NULL)
}
