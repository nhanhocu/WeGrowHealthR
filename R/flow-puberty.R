## Flows built on the SITAR pubertal spurt models ----------------------------

.sitar_inputs <- function(d, min_visits = 3) {
  list(Male = d[d$sex == "Male" & d$age >= 6 & d$age <= 18, ],
       Female = d[d$sex == "Female" & d$age >= 6 & d$age <= 16, ])
}

#' Flow: the pubertal growth spurt by SITAR (Ho et al. 2026, medRxiv 2026.07.26.26358986)
#'
#' Age-density check, a SITAR model for boys (6 to 18 years) and a
#' rule-based choice between three female specifications (6 to 16 years,
#' 6 to 15 years, and the SITAR-d extension), identifiability checks,
#' population APHV and PHV with cluster-bootstrap intervals (and the legacy
#' interval for comparison), individual effects with vectorised individual
#' APHV, links between prepubertal anthropometry and timing, and the
#' early-timing logistic model with its AUC. Pass the returned report as
#' `spurt` to the height prediction, velocity distribution, spurt duration
#' and growth phenotype flows, so the SITAR models are fitted only once.
#'
#' @inheritParams wgh_flow_secular_trends
#' @param ci_B Bootstrap replicates for the APHV and PHV intervals (each
#'   refits SITAR). Default 0 in dev mode and 50 otherwise.
#' @param select_female Run the three-model female selection (otherwise F1
#'   only). Default: `TRUE` except in dev mode.
#' @return A [wgh_report] whose `models` hold the SITAR fits and `tables`
#'   include `individual_effects`.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' # A small cohort with 14 school years of follow-up, so that both SITAR models are
#' # well identified and the SITAR fits take well under a minute. On short follow-up
#' # (such as growdat2_mini) the girls' model is barely identifiable and slow.
#' long <- wgh_simulate(2500, seed = 1, years = 2012:2025, missing_years = integer(),
#'                      dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9,
#'                      style = "book2")$visits
#' rep <- wgh_flow_pubertal_spurt(long, mode = "dev")
#' rep
#' rep$tables$population_aphv
#' }
#' @export
wgh_flow_pubertal_spurt <- function(x = NULL, mode = NULL, ci_B = NULL, select_female = NULL) {
  .need("sitar")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  ci_B <- ci_B %||% (if (wgh_mode() == "dev") 0L else 50L)
  select_female <- select_female %||% (wgh_mode() != "dev")
  tabs <- list(); figs <- list(); mods <- list(); diag <- list()
  si <- .sitar_inputs(d)
  fl <- wgh_sample_flow(d, "Ages 6 to 18 (boys) or 6 to 16 (girls)" = ~ (sex == "Male" & age >= 6 & age <= 18) | (sex == "Female" & age >= 6 & age <= 16),
                       "At least 3 visits" = wgh_min_visits(3))
  ad <- wgh_age_density(fl$data); tabs$age_density <- ad
  mods$sitar_male <- wgh_fit_sitar(si$Male, df = 5, age_range = c(6, 18), label = "Male 6-18 a+b+c")
  if (select_female) {
    sel <- wgh_sitar_select(si$Female)
    mods$sitar_female <- sel$fits[[sel$selected]]
    tabs$female_model_selection <- sel$table
    diag$female_selection_reason <- tibble::tibble(selected = sel$selected, reason = sel$reason)
  } else mods$sitar_female <- wgh_fit_sitar(si$Female, df = 4, age_range = c(6, 16), label = "F1")
  diag$identifiability <- .bind(lapply(mods, function(m) { r <- wgh_check_identifiable(m); tibble::tibble(model = m$label, ok = r$ok, max_abs_corr = r$max_abs_corr, pair = r$pair) }))
  tabs$model_diagnostics <- .bind(lapply(mods, wgh_sitar_diagnostics))
  ci <- .bind(lapply(names(mods), function(nm) {
    sx <- if (grepl("female", nm)) "Female" else "Male"
    r <- if (ci_B > 0) wgh_sitar_ci(mods[[nm]], B = ci_B) else wgh_sitar_ci(mods[[nm]], method = "legacy")
    dplyr::bind_cols(tibble::tibble(sex = sx), r)
  }))
  tabs$aphv_phv_population <- ci
  eff <- .bind(lapply(names(mods), function(nm) { e <- wgh_sitar_effects(mods[[nm]]); e$sex <- if (grepl("female", nm)) "Female" else "Male"; e }))
  tabs$individual_effects <- eff
  tabs$individual_summary <- .bind(lapply(split(eff, eff$sex), function(z) tibble::tibble(
    sex = z$sex[1], n = nrow(z), aphv_mean = mean(z$aphv), aphv_sd = stats::sd(z$aphv),
    phv_mean = mean(z$phv), phv_sd = stats::sd(z$phv), sd_b = stats::sd(z$b), sd_c = stats::sd(z$c),
    pct_early = 100 * mean(z$early_timing))))
  ## prepubertal anthropometry and timing
  base <- wgh_index_exposure(d, "baz", max_age = c(Male = 11, Female = 9), name = "pre")
  base <- base[!duplicated(base$id), c("id", "sex", "pre_value", "pre_age", "haz", "site")]
  names(base)[3] <- "baz_pre"
  hz <- wgh_index_exposure(d, "haz", max_age = c(Male = 11, Female = 9), name = "pre")
  base$haz_pre <- hz$pre_value[match(base$id, hz$id)]
  if ("year" %in% names(d)) { by <- d[!duplicated(d$id), ]; base$birth_year <- (by$year - floor(by$age))[match(base$id, by$id)] }
  link <- merge(eff, base[, setdiff(names(base), "sex")], by = "id")
  tabs$timing_models <- .bind(lapply(split(link, link$sex), function(z) {
    m <- stats::lm(b ~ baz_pre + haz_pre + pre_age + site + (if ("birth_year" %in% names(z)) birth_year else 0), data = z)
    co <- summary(m)$coefficients
    keep <- rownames(co) %in% c("baz_pre", "haz_pre", "birth_year")
    tibble::tibble(sex = z$sex[1], outcome = "timing b (years)", term = rownames(co)[keep], estimate = co[keep, 1],
                   lower = co[keep, 1] - 1.96 * co[keep, 2], upper = co[keep, 1] + 1.96 * co[keep, 2], p_value = co[keep, 4])
  }))
  tabs$early_timing_logistic <- .bind(lapply(split(link, link$sex), function(z) {
    m <- stats::glm(early_timing ~ baz_pre + haz_pre + pre_age + site, data = z, family = stats::binomial())
    p <- stats::fitted(m); y <- m$y
    auc <- (mean(rank(c(p[y == 1], p[y == 0]))[seq_len(sum(y == 1))]) - (sum(y == 1) + 1) / 2) / sum(y == 0)
    co <- summary(m)$coefficients; keep <- rownames(co) %in% c("baz_pre", "haz_pre")
    tibble::tibble(sex = z$sex[1], term = rownames(co)[keep], odds_ratio = exp(co[keep, 1]),
                   lower = exp(co[keep, 1] - 1.96 * co[keep, 2]), upper = exp(co[keep, 1] + 1.96 * co[keep, 2]),
                   p_value = co[keep, 4], auc = auc)
  }))
  vc <- .bind(lapply(names(mods), function(nm) { v <- .sitar_velocity_curve(mods[[nm]]); v$sex <- if (grepl("female", nm)) "Female" else "Male"; v }))
  sp <- attr(ad, "sparse_from")
  vc <- vc[is.na(sp[vc$sex]) | vc$age <= sp[vc$sex] + 0.5, ]
  figs$fig_velocity <- ggplot2::ggplot(vc, ggplot2::aes(.data$age, .data$velocity, colour = .data$sex)) +
    ggplot2::geom_line(linewidth = 1) + scale_colour_wgh_sex() + theme_wgh() +
    ggplot2::geom_vline(data = ci, ggplot2::aes(xintercept = .data$aphv, colour = .data$sex), linetype = 2) +
    ggplot2::labs(x = "Age (years)", y = "Height velocity (cm/year)", colour = NULL, title = "Mean height velocity (SITAR)")
  figs$fig_height <- ggplot2::ggplot(vc, ggplot2::aes(.data$age, .data$height, colour = .data$sex)) +
    ggplot2::geom_line(linewidth = 1) + scale_colour_wgh_sex() + theme_wgh() +
    ggplot2::labs(x = "Age (years)", y = "Height (cm)", colour = NULL)
  link$bmi_cat <- wgh_bmi_category(link$baz_pre, link$pre_age, thinness = FALSE)
  figs$fig_aphv_by_bmi <- ggplot2::ggplot(link, ggplot2::aes(.data$bmi_cat, .data$aphv, fill = .data$sex)) +
    ggplot2::geom_violin(alpha = 0.6) + ggplot2::geom_boxplot(width = 0.15, outlier.shape = NA) +
    ggplot2::facet_wrap(~sex, scales = "free_y") + scale_fill_wgh_sex() + theme_wgh(legend = "none") +
    ggplot2::labs(x = "Prepubertal BMI category", y = "Individual APHV (years)")
  rep <- wgh_report("Pubertal growth spurt by SITAR (Ho et al. 2026, medRxiv 2026.07.26.26358986)", tabs, figs, mods, diag, sample_flow = fl,
                   settings = list(mode = wgh_mode(), ci_B = ci_B), note = if (fd$simulated) .sim_note else NULL)
  rep$data <- d
  rep
}

.spurt_or_fit <- function(spurt, x, mode) {
  if (!is.null(spurt)) return(spurt)
  wgh_flow_pubertal_spurt(x, mode = mode, ci_B = 0, select_female = FALSE)
}

## Data for flows that build on the pubertal spurt report: use the same children
.flow_visits <- function(x, spurt) {
  if (!is.null(x)) return(.flow_data(x))
  if (!is.null(spurt$data)) return(list(data = spurt$data, simulated = !is.null(spurt$note)))
  .flow_data(NULL)
}

#' Flow: predicting late-adolescent height (Ho 2026, manuscript under review)
#'
#' Builds the prediction cohort from prepubertal visits, joins SITAR timing
#' and intensity from [wgh_flow_pubertal_spurt()] (never size), and benchmarks the
#' M0 to M8 model ladder on identical cross-validation folds, with
#' leave-one-site-out validation, a bootstrap comparison of the primary
#' mixed model with XGBoost, prediction intervals, calibration and
#' Bland-Altman plots, SHAP for XGBoost and an example individual prediction.
#' @inheritParams wgh_flow_secular_trends
#' @param spurt Optional report from [wgh_flow_pubertal_spurt()] on the same
#'   data (it is computed when `NULL`).
#' @param n_children Simulated cohort size when `x` is `NULL`. Late
#'   adolescent outcomes need long follow-up, so a large cohort is used.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("kernelshap", "lme4", "ranger", "sitar", "xgboost"))
#' \donttest{
#' rep <- wgh_flow_height_prediction(mode = "dev", n_children = 8000)
#' rep$tables$performance
#' }
#' @export
wgh_flow_height_prediction <- function(x = NULL, mode = NULL, spurt = NULL, n_children = 30000) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  simulated <- is.null(x)
  if (simulated && !is.null(spurt$data)) x <- spurt$data
  if (is.null(x)) x <- wgh_simulate(n_children, preset = "wgh_like", seed = 2026)$visits
  d <- .gd(x)
  spurt <- spurt %||% wgh_flow_pubertal_spurt(d, ci_B = 0, select_female = FALSE)
  eff <- spurt$tables$individual_effects
  pc <- wgh_prediction_cohort(d, sitar_effects = eff)
  tabs <- list(attrition = attr(pc, "attrition"))
  tabs$table1 <- wgh_table1(pc, vars = c("age_base", "height_base", "haz_base", "baz_base", "vel_short", "height_late", "bmi_cat_base", "site"), by = "sex")
  bm <- wgh_benchmark(pc, folds = max(5, wgh_opt("folds")))
  tabs$cv_performance <- bm$performance
  tabs$apparent_performance <- bm$apparent
  lo <- wgh_benchmark(pc, models = c("M0", "M5", "M7"), folds = "site")
  tabs$leave_one_site_out <- lo$performance
  tabs$m5_vs_m7_bootstrap <- wgh_compare_models(bm, "M5", "M7", B = 500)
  m5 <- bm$fits[["Male M5"]]
  tabs$m5_coefficients <- .bind(lapply(.sexes, function(sx) {
    f <- bm$fits[[paste(sx, "M5")]]; if (is.null(f) || !inherits(f, "lm")) return(NULL)
    co <- summary(f)$coefficients; ci <- stats::confint(f)[rownames(co), , drop = FALSE]
    tibble::tibble(sex = sx, term = rownames(co), estimate = co[, 1], lower = ci[, 1], upper = ci[, 2], p_value = co[, 4])
  }))
  tabs$prediction_intervals_m5 <- .bind(lapply(.sexes, function(sx) {
    f <- bm$fits[[paste(sx, "M5")]]; z <- pc[pc$sex == sx, ]
    if (is.null(f)) return(NULL)
    zz <- .prep_bench(z, z)
    pi <- wgh_prediction_interval(f, zz)
    tibble::tibble(sex = sx, n = nrow(z), mean_width = mean(pi$width), coverage = mean(z$height_late >= pi$lower & z$height_late <= pi$upper))
  }))
  figs <- list(fig_cv_rmse = plot(bm), fig_calibration_m5 = wgh_plot_calibration(bm, "M5"),
               fig_bland_altman_m5 = wgh_plot_bland_altman(bm, "M5"))
  pr <- bm$predictions[!is.na(bm$predictions$predicted), ]
  figs$fig_obs_pred_all <- ggplot2::ggplot(pr, ggplot2::aes(.data$predicted, .data$observed, colour = .data$sex)) +
    ggplot2::geom_abline(linetype = 2) + ggplot2::geom_point(alpha = 0.4, size = 0.8) + ggplot2::facet_wrap(~model) +
    scale_colour_wgh_sex() + theme_wgh() + ggplot2::labs(x = "Predicted (cm)", y = "Observed (cm)", colour = NULL)
  fx <- bm$fits[["Male M7"]]
  if (is.null(fx)) .skip("SHAP explanation of M7 (boys)", "model M7 was not fitted")
  else if (!requireNamespace("xgboost", quietly = TRUE)) .skip("SHAP explanation of M7 (boys)", "package xgboost is not installed")
  if (!is.null(fx) && requireNamespace("xgboost", quietly = TRUE)) {
    zb <- pc[pc$sex == "Male", ]; X <- .xgb_X(.prep_bench(zb, zb))
    for (cc in setdiff(fx$cols, colnames(X))) { X <- cbind(X, 0); colnames(X)[ncol(X)] <- cc }
    sh <- wgh_shap(fx$model, X[, fx$cols, drop = FALSE])
    tabs$shap_importance_m7_boys <- wgh_shap_summary(sh, B = 100)
    figs$fig_shap_beeswarm_m7_boys <- plot(sh, "beeswarm")
  }
  tabs$example_prediction <- wgh_predict_child(bm, pc[1, ], "M5")
  ## an example child with several prepubertal visits, shown on a growth chart
  npre <- table(d$id[floor(d$age) <= ifelse(d$sex == "Male", 11, 9)])
  exk <- pc[pc$id %in% names(npre)[npre >= 3], ]
  if (nrow(exk)) {
    ex <- exk[1, ]
    figs$fig_child_prediction <- wgh_plot_child_prediction(bm, ex, visits = d[d$id == ex$id, ], model = "M5")
    tabs$example_prediction <- attr(figs$fig_child_prediction, "prediction")
  }
  m6 <- bm$performance[bm$performance$model == "M6", ]
  if (nrow(m6) && any(m6$R2 > 0.9, na.rm = TRUE))
    .warn(c("M6 explains more than 90% of the variance.",
            i = "SITAR b and c were estimated with visits from the outcome window, so part of this performance is leakage. Treat M6 as an upper bound."))
  wgh_report("Late-adolescent height prediction (Ho 2026, manuscript under review)", tabs, figs, models = list(benchmark = bm, loso = lo),
            diagnostics = list(model_errors = tibble::tibble(model = names(bm$errors), error = unlist(bm$errors))),
            settings = list(mode = wgh_mode(), cohort_n = nrow(pc)), note = if (simulated) .sim_note else NULL)
}

#' Flow: prepubertal BMI and the distribution of pubertal velocity (Ho 2026, medRxiv 2026.09.04.26362313)
#'
#' Builds per-child velocity panels from the SITAR fits, in chronological
#' age and in years since each child's APHV, and models the velocity
#' distribution with quantile regression and a child-level bootstrap as a
#' function of prepubertal BAZ. Also fits quantile models of the scalar
#' SITAR timing and intensity, and an exploratory mediation of the BAZ
#' effect on PHV through timing.
#' @inheritParams wgh_flow_height_prediction
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("quantreg", "sitar"))
#' \donttest{
#' # A small cohort with 14 school years of follow-up, so that both SITAR models are
#' # well identified and the SITAR fits take well under a minute. On short follow-up
#' # (such as growdat2_mini) the girls' model is barely identifiable and slow.
#' long <- wgh_simulate(2500, seed = 1, years = 2012:2025, missing_years = integer(),
#'                      dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9,
#'                      style = "book2")$visits
#' spurt <- wgh_flow_pubertal_spurt(long, mode = "dev")
#' rep <- wgh_flow_velocity_distribution(long, mode = "dev", spurt = spurt)
#' rep
#' }
#' @export
wgh_flow_velocity_distribution <- function(x = NULL, mode = NULL, spurt = NULL) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  spurt <- .spurt_or_fit(spurt, x, mode)
  eff <- spurt$tables$individual_effects
  fd <- .flow_visits(x, spurt); d <- fd$data
  base <- wgh_index_exposure(d, "baz", max_age = c(Male = 11, Female = 9), name = "pre")
  base <- base[!duplicated(base$id), c("id", "pre_value")]; names(base)[2] <- "baz_pre"
  tabs <- list(); figs <- list()
  slopes <- list(); scal <- list(); med <- list()
  for (nm in c("sitar_male", "sitar_female")) {
    m <- spurt$models[[nm]]; sx <- if (nm == "sitar_male") "Male" else "Female"
    pan_age <- wgh_velocity_panel(m, time = "age", grid = seq(8, if (sx == "Male") 16 else 14, by = 0.5))
    pan_age <- merge(pan_age, base, by = "id")
    pan_age <- pan_age[stats::complete.cases(pan_age), ]
    f <- velocity ~ splines::ns(age, df = 3) * baz_pre
    rq <- wgh_rq(pan_age, f, taus = wgh_taus("headline"), exposure = "baz_pre",
                anchor_ages = if (sx == "Male") c(10, 12, 14) else c(8, 10, 12), B = min(wgh_opt("B"), 100))
    slopes[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(rq$slopes))), rq$slopes)
    e <- merge(eff[eff$sex == sx, ], base, by = "id")
    for (o in c("b", "c", "phv")) {
      r <- wgh_scalar_quantiles(e, stats::as.formula(paste(o, "~ baz_pre")), "baz_pre", B = min(wgh_opt("B"), 100))
      scal[[paste(sx, o)]] <- dplyr::bind_cols(tibble::tibble(sex = sx, outcome = o), r)
    }
    md <- wgh_mediation(e, "baz_pre", "b", "phv", a = 1, a_star = 0, B = min(wgh_opt("B"), 100))
    med[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(md))), md)
    pr <- wgh_velocity_panel(m, time = "aphv", grid = seq(-3, 3, by = 0.25))
    pr <- merge(pr, base, by = "id"); pr$bmi_group <- cut(pr$baz_pre, c(-Inf, 1, 2, Inf), labels = c("Normal", "Overweight", "Obesity"))
    figs[[paste0("fig_velocity_aphv_", tolower(sx))]] <- ggplot2::ggplot(pr[!is.na(pr$bmi_group), ], ggplot2::aes(.data$time, .data$velocity, colour = .data$bmi_group)) +
      ggplot2::stat_summary(fun = stats::median, geom = "line", linewidth = 1) + scale_colour_wgh() + theme_wgh() +
      ggplot2::labs(x = "Years from own APHV", y = "Median velocity (cm/year)", colour = "Prepubertal BMI", title = sx)
  }
  tabs$velocity_quantile_slopes <- .bind(slopes)
  tabs$scalar_quantiles <- .bind(scal)
  tabs$mediation_timing <- .bind(med)
  s <- tabs$velocity_quantile_slopes
  figs$fig_velocity_slopes <- ggplot2::ggplot(s, ggplot2::aes(.data$tau, .data$estimate, colour = .data$sex)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
    ggplot2::geom_pointrange(ggplot2::aes(ymin = .data$lower, ymax = .data$upper), position = ggplot2::position_dodge(0.03)) +
    ggplot2::facet_wrap(~ .lab_num("Age", age)) + scale_colour_wgh_sex() + theme_wgh() +
    ggplot2::labs(x = "Quantile of velocity", y = "Velocity change per BAZ unit (cm/year)", colour = NULL)
  wgh_report("Prepubertal BMI and the distribution of pubertal velocity (Ho 2026, medRxiv 2026.09.04.26362313)", tabs, figs,
            settings = list(mode = wgh_mode()), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: duration of the pubertal spurt (Ho 2026, medRxiv 2026.09.09.26362696)
#'
#' Velocity curves in years since each child's APHV on a fine grid, peak
#' width at 25, 50 and 75 percent of the spurt amplitude (and of PHV, the
#' legacy definition, to show its censoring), censoring flags, ordinary and
#' quantile regressions of duration on prepubertal BAZ adjusted for timing
#' and intensity, a sex-interaction test and functional PCA of the curves.
#' @inheritParams wgh_flow_height_prediction
#' @param seed Random seed for the subsample of curves used in the
#'   functional PCA. The caller's random stream is restored.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("fdapace", "quantreg", "sitar"))
#' \donttest{
#' # A small cohort with 14 school years of follow-up, so that both SITAR models are
#' # well identified and the SITAR fits take well under a minute. On short follow-up
#' # (such as growdat2_mini) the girls' model is barely identifiable and slow.
#' long <- wgh_simulate(2500, seed = 1, years = 2012:2025, missing_years = integer(),
#'                      dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9,
#'                      style = "book2")$visits
#' spurt <- wgh_flow_pubertal_spurt(long, mode = "dev")
#' rep <- wgh_flow_spurt_duration(long, mode = "dev", spurt = spurt)
#' rep
#' }
#' @export
wgh_flow_spurt_duration <- function(x = NULL, mode = NULL, spurt = NULL, seed = 2026) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  .local_seed(seed)
  spurt <- .spurt_or_fit(spurt, x, mode)
  eff <- spurt$tables$individual_effects
  fd <- .flow_visits(x, spurt); d <- fd$data
  base <- wgh_index_exposure(d, "baz", max_age = c(Male = 11, Female = 9), name = "pre")
  base <- base[!duplicated(base$id), c("id", "pre_value")]; names(base)[2] <- "baz_pre"
  feats <- list(); legacy <- list(); fpc <- list()
  for (nm in c("sitar_male", "sitar_female")) {
    m <- spurt$models[[nm]]; sx <- if (nm == "sitar_male") "Male" else "Female"
    pan <- wgh_velocity_panel(m, time = "aphv", grid = seq(-4, 4, by = 0.05), observed_only = FALSE)
    cf <- wgh_curve_features(pan); cf$sex <- sx; feats[[sx]] <- cf
    lg <- wgh_curve_features(pan, thresholds = 0.5, reference = "zero")
    legacy[[sx]] <- tibble::tibble(sex = sx, definition = c("amplitude (default)", "fraction of PHV (legacy)"),
                                   pct_left_censored = c(100 * mean(cf$censored_left_p50), 100 * mean(lg$censored_left_p50)),
                                   median_width = c(stats::median(cf$width_p50, na.rm = TRUE), stats::median(lg$width_p50, na.rm = TRUE)))
    if (!requireNamespace("fdapace", quietly = TRUE)) .skip(paste0("Functional PCA of velocity curves, ", tolower(sx)), "package fdapace is not installed")
    if (requireNamespace("fdapace", quietly = TRUE)) {
      ids <- unique(pan$id); if (length(ids) > 600) ids <- sample(ids, 600)
      fp <- .try(wgh_fpca_curves(pan[pan$id %in% ids, ]), paste0("Functional PCA of velocity curves, ", tolower(sx)))
      if (!.is_err(fp)) fpc[[sx]] <- tibble::tibble(sex = sx, component = seq_along(fp$variance_explained), cumulative_fve = fp$variance_explained)
    }
  }
  cf <- .bind(feats)
  dat <- merge(merge(cf, eff[, c("id", "b", "c", "aphv")], by = "id"), base, by = "id")
  dat$duration <- dat$width_p50
  tabs <- list(duration_features = cf, censoring = .bind(legacy), fpca_variance = .bind(fpc))
  tabs$duration_ols <- .bind(lapply(split(dat, dat$sex), function(z) {
    m0 <- stats::lm(duration ~ baz_pre, z); m1 <- stats::lm(duration ~ baz_pre + b + c, z)
    .bind(lapply(list(unadjusted = m0, adjusted_timing_intensity = m1), function(m) {
      co <- summary(m)$coefficients
      tibble::tibble(term = "baz_pre", estimate = co["baz_pre", 1], lower = co["baz_pre", 1] - 1.96 * co["baz_pre", 2],
                     upper = co["baz_pre", 1] + 1.96 * co["baz_pre", 2], p_value = co["baz_pre", 4])
    }), .id = "model") |> (\(t) dplyr::bind_cols(tibble::tibble(sex = rep(z$sex[1], nrow(t))), t))()
  }))
  tabs$duration_quantile <- .bind(lapply(split(dat, dat$sex), function(z) {
    r <- wgh_scalar_quantiles(z, duration ~ baz_pre + b + c, "baz_pre", B = min(wgh_opt("B"), 100))
    dplyr::bind_cols(tibble::tibble(sex = rep(z$sex[1], nrow(r))), r)
  }))
  si <- stats::lm(duration ~ baz_pre * sex + b + c, data = dat)
  co <- summary(si)$coefficients; k <- grep("baz_pre:sex", rownames(co))
  tabs$sex_interaction <- tibble::tibble(term = rownames(co)[k], estimate = co[k, 1], p_value = co[k, 4])
  figs <- list(fig_duration_by_bmi = ggplot2::ggplot(dat, ggplot2::aes(.data$baz_pre, .data$duration, colour = .data$sex)) +
                 ggplot2::geom_point(alpha = 0.25, size = 0.8) + ggplot2::geom_smooth(method = "lm", formula = y ~ x) +
                 scale_colour_wgh_sex() + theme_wgh() +
                 ggplot2::labs(x = "Prepubertal BAZ", y = "Spurt duration, width at 50% amplitude (years)", colour = NULL))
  wgh_report("Duration of the pubertal growth spurt (Ho 2026, medRxiv 2026.09.09.26362696)", tabs, figs,
            settings = list(mode = wgh_mode()), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: growth phenotypes by functional clustering (Ho 2026, medRxiv 2026.09.05.26362315)
#'
#' Sparse FPCA of HAZ trajectories combined with SITAR size, timing and
#' intensity, Gaussian mixtures by sex with BIC and ICL, phenotype naming,
#' neighbouring solutions, bootstrap stability, validation against
#' prepubertal BMI category and site, and linkage to late-adolescent HAZ.
#' Phenotypes are built from visits up to `max_age`; set it below any
#' target age before using phenotypes as predictors (see
#' [wgh_leakage_check()]).
#' @inheritParams wgh_flow_height_prediction
#' @param max_age Latest age used to build the phenotypes.
#' @param G Numbers of clusters tried.
#' @param features Clustering features: functional PC scores (`fpc1`,
#'   `fpc2`, ...) and SITAR effects (`a`, `b`, `c`). The default leaves out
#'   SITAR size `a`, which duplicates `fpc1` (overall level), and higher
#'   components, which mostly add noise.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("fdapace", "mclust", "sitar"))
#' \donttest{
#' # A small cohort with 14 school years of follow-up, so that both SITAR models are
#' # well identified and the SITAR fits take well under a minute. On short follow-up
#' # (such as growdat2_mini) the girls' model is barely identifiable and slow.
#' long <- wgh_simulate(2500, seed = 1, years = 2012:2025, missing_years = integer(),
#'                      dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9,
#'                      style = "book2")$visits
#' spurt <- wgh_flow_pubertal_spurt(long, mode = "dev")
#' rep <- wgh_flow_growth_phenotypes(long, mode = "dev", spurt = spurt, G = 2:4)
#' rep
#' }
#' @export
wgh_flow_growth_phenotypes <- function(x = NULL, mode = NULL, spurt = NULL, max_age = 18, G = 1:8,
                                       features = c("fpc1", "fpc2", "b", "c")) {
  .need("fdapace"); .need("mclust")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  spurt <- .spurt_or_fit(spurt, x, mode)
  eff <- spurt$tables$individual_effects
  fd <- .flow_visits(x, spurt); d <- fd$data
  tabs <- list(); figs <- list(); mods <- list(); stab <- list(); val <- list(); cen <- list(); link <- list()
  base <- wgh_index_exposure(d, "baz", max_age = c(Male = 11, Female = 9), name = "pre",
                            categories = function(b, a) wgh_bmi_category(b, a, thinness = FALSE))
  base <- base[!duplicated(base$id), c("id", "pre_cat", "site")]
  late <- d[d$age >= 15, ]; late <- stats::aggregate(haz ~ id, data = late, FUN = stats::median); names(late)[2] <- "haz_late"
  for (sx in .sexes) {
    fp <- wgh_fpca(d[d$sex == sx, ], age_range = c(5, max_age))
    feat <- merge(fp$scores, eff[eff$sex == sx, c("id", "a", "b", "c")], by = "id")
    vars <- intersect(features, names(feat))
    cl <- wgh_name_phenotypes(wgh_cluster(feat, vars = vars, G = G))
    mods[[sx]] <- cl
    cen[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(cl$centroids))), cl$centroids)
    st <- wgh_cluster_stability(cl, B = min(wgh_opt("B"), 50))
    stab[[sx]] <- tibble::tibble(sex = sx, G = cl$G, model = cl$model, ari_median = attr(st, "summary")[[1]],
                                 ari_lower = attr(st, "summary")[[2]], ari_upper = attr(st, "summary")[[3]])
    v <- .try(wgh_validate_phenotypes(cl, base, c("pre_cat", "site")), paste0("Phenotype validation, ", tolower(sx)))
    if (!.is_err(v)) val[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(v$tests))), v$tests)
    lk <- .try(wgh_link_outcome(cl, late, "haz_late", B = min(wgh_opt("B"), 100)), paste0("Phenotype and late HAZ link, ", tolower(sx)))
    if (!.is_err(lk)) link[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(lk))), lk)
    bt <- cl$bic; bt <- bt[is.finite(bt$value), ]
    figs[[paste0("fig_bic_", tolower(sx))]] <- ggplot2::ggplot(bt, ggplot2::aes(.data$G, .data$value, colour = .data$model)) +
      ggplot2::geom_line() + ggplot2::geom_point(size = 1) + theme_wgh(legend = "right") +
      ggplot2::labs(x = "Number of clusters", y = "BIC", colour = "Model", title = sx)
    figs[[paste0("fig_phenotypes_", tolower(sx))]] <- wgh_plot_phenotypes(cl, d[d$sex == sx, ]) + ggplot2::labs(subtitle = sx)
  }
  tabs$centroids <- .bind(cen); tabs$stability <- .bind(stab); tabs$validation <- .bind(val); tabs$late_haz_link <- .bind(link)
  tabs$leakage_note <- tibble::tibble(feature_window = paste(5, "to", max_age), message = wgh_leakage_check(c(5, max_age), c(12, 15, 18))$message)
  wgh_report("Growth phenotypes by functional clustering (Ho 2026, medRxiv 2026.09.05.26362315)", tabs, figs, mods,
            settings = list(mode = wgh_mode(), max_age = max_age), note = if (fd$simulated) .sim_note else NULL)
}
