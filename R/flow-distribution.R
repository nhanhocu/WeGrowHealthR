## Flows for distributional, reference, state and explanation papers --------

.haz_formula <- function(knots = c(8, 11, 14), bk = c(5, 18.5), site = TRUE) {
  f <- paste0("haz ~ splines::ns(age, knots = c(", paste(knots, collapse = ", "), "), Boundary.knots = c(",
              paste(bk, collapse = ", "), ")) * baz", if (site) " + site" else "")
  stats::as.formula(f, env = new.env(parent = asNamespace("splines")))
}

.analytic_5_18 <- function(d, min_visits = 3) {
  wgh_sample_flow(d, "Ages 5 to 18" = ~ age >= 5 & age <= 18.5,
                 "Plausible z-scores" = ~ !is.na(haz) & !is.na(baz) & abs(haz) < 6 & abs(baz) < 6,
                 "At least 3 visits" = wgh_min_visits(min_visits))
}

#' Flow: BMI and the height-for-age distribution (Ho 2026, medRxiv 2026.09.08.26362487)
#'
#' Sex-stratified linear quantile mixed models of HAZ on BAZ with a natural
#' spline of age and site, BAZ slopes at stated ages by contrast with a
#' child-level bootstrap, tests of heterogeneity across quantiles and of the
#' sex difference, a mean mixed model for comparison, pooled quantile
#' regression and (optionally) qgam as sensitivity analyses, and crossing
#' checks.
#' @inheritParams wgh_flow_secular_trends
#' @param engine `"lqmm"` (Ho 2026, medRxiv 2026.09.08.26362487) or `"rq"` (faster pooled model).
#' @param sensitivity Run the qgam sensitivity analysis.
#' @param seed Random seed for the subsample of children drawn when the run
#'   mode limits the sample size. The caller's random stream is restored.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("lme4", "lqmm", "qgam", "quantreg"))
#' \donttest{
#' rep <- wgh_flow_distributional_height(growdat, mode = "dev", engine = "rq")
#' rep
#' plot(rep, 1)
#' }
#' @export
wgh_flow_distributional_height <- function(x = NULL, mode = NULL, engine = c("lqmm", "rq"), sensitivity = FALSE, seed = 2026) {
  engine <- match.arg(engine)
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  fl <- .analytic_5_18(d)
  a <- fl$data
  n_sub <- wgh_opt("subsample")
  ages <- c(6, 9, 12, 15)
  tabs <- list(); figs <- list(); mods <- list()
  .local_seed(seed)
  for (sx in .sexes) {
    z <- a[a$sex == sx, ]
    ids <- unique(z$id)
    if (is.finite(n_sub) && length(ids) > n_sub) z <- z[z$id %in% sample(ids, n_sub), ]
    f <- .haz_formula()
    mods[[sx]] <- if (engine == "lqmm") wgh_lqmm(z, f, taus = wgh_opt("taus"), anchor_ages = ages, B = min(wgh_opt("B"), 100))
                  else wgh_rq(z, f, taus = wgh_opt("taus"), anchor_ages = ages)
    .status_add(paste0("Quantile model (", engine, "), ", tolower(sx)), "ok")
    if (!requireNamespace("lme4", quietly = TRUE)) .skip(paste0("Mean mixed model, ", tolower(sx)), "package lme4 is not installed")
    if (requireNamespace("lme4", quietly = TRUE)) {
      lm <- wgh_fit_lmm(z, haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz + site)
      g <- expand.grid(age = ages, baz = c(0, 1)); g$site <- levels(factor(z$site))[1]; g$age_c <- g$age - 10
      p <- stats::predict(lm$fit, newdata = g, re.form = NA)
      mods[[paste0(sx, "_mean")]] <- lm
      tabs[[paste0("mean_model_slopes_", tolower(sx))]] <- tibble::tibble(sex = sx, age = ages, slope = p[g$baz == 1] - p[g$baz == 0])
    }
  }
  tabs$quantile_slopes <- .bind(lapply(.sexes, function(sx) dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(mods[[sx]]$slopes))), mods[[sx]]$slopes)))
  if (!is.null(mods$Male$boot) && !is.null(mods$Female$boot)) {
    tabs$heterogeneity <- .bind(lapply(.sexes, function(sx) .bind(lapply(ages, function(ag) {
      r <- .try(wgh_test_heterogeneity(mods[[sx]], ag), paste0("Heterogeneity test, ", tolower(sx), ", age ", ag))
      if (.is_err(r)) NULL else dplyr::bind_cols(tibble::tibble(sex = sx), r)
    }))))
    tabs$sex_difference <- .bind(lapply(ages, function(ag) {
      r <- .try(wgh_test_sex_difference(mods$Male, mods$Female, ag)$joint, paste("Sex difference test, age", ag))
      if (.is_err(r)) NULL else r
    }))
  } else .skip("Heterogeneity and sex difference tests", "no bootstrap draws (B = 0 or the bootstrap failed)")
  if (engine == "lqmm") tabs$convergence <- .bind(lapply(.sexes, function(sx) dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(mods[[sx]]$convergence))), mods[[sx]]$convergence)))
  tabs$crossing <- .bind(lapply(.sexes, function(sx) {
    g <- expand.grid(age = seq(5, 18, 0.5), baz = seq(-2, 3, 0.5)); g$site <- levels(factor(a$site))[1]
    P <- .grid_matrix(mods[[sx]]$design, g) %*% mods[[sx]]$coefs
    tibble::tibble(sex = sx, crossing_share = wgh_crossing(P))
  }))
  if (!sensitivity) .skip("qgam sensitivity analysis", "sensitivity = FALSE")
  if (sensitivity && !requireNamespace("qgam", quietly = TRUE)) .skip("qgam sensitivity analysis", "package qgam is not installed")
  if (sensitivity && requireNamespace("qgam", quietly = TRUE)) {
    tabs$qgam_sensitivity <- .bind(lapply(.sexes, function(sx) {
      r <- wgh_qgam_check(a[a$sex == sx, ], ages = ages, extra = "site"); dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(r))), r)
    }))
  }
  s <- tabs$quantile_slopes
  figs$fig_coefficient_functions <- ggplot2::ggplot(s, ggplot2::aes(.data$tau, .data$estimate, colour = .data$sex, fill = .data$sex)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
    (if ("lower" %in% names(s)) ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lower, ymax = .data$upper), alpha = 0.2, colour = NA)) +
    ggplot2::geom_line(linewidth = 0.9) + ggplot2::facet_wrap(~ .lab_num("Age", age), nrow = 1) +
    scale_colour_wgh_sex() + scale_fill_wgh_sex() + theme_wgh() +
    ggplot2::labs(x = "Quantile of HAZ", y = "HAZ change per BAZ unit", colour = NULL, fill = NULL)
  cl <- wgh_classify(a); cl$age_year <- floor(cl$age)
  sp <- stats::aggregate(haz ~ sex + age_year + bmi_status, data = cl, FUN = function(v) diff(stats::quantile(v, c(0.05, 0.95))))
  figs$fig_spread_by_bmi <- ggplot2::ggplot(sp, ggplot2::aes(.data$age_year, .data$haz, colour = .data$bmi_status)) +
    ggplot2::geom_line() + ggplot2::facet_wrap(~sex) + scale_colour_wgh_bmi() + theme_wgh() +
    ggplot2::labs(x = "Age (years)", y = "HAZ P95 minus P5", colour = NULL)
  wgh_report("BMI and the height-for-age distribution (Ho 2026, medRxiv 2026.09.08.26362487)", tabs, figs, mods, sample_flow = fl,
            settings = list(mode = wgh_mode(), engine = engine), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: growth inequality, the spread of height by BMI (Ho 2026, manuscript under review)
#'
#' Pooled quantile regression of HAZ on a natural spline of age by BAZ,
#' with a child-level cluster bootstrap, then P95 minus P5 and the
#' interquartile range by age and BAZ, the change in spread per BAZ unit,
#' the support rule and an empirical check of spread within BAZ bands.
#' @inheritParams wgh_flow_secular_trends
#' @param ages,baz_values Grid for the spread estimates.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' rep <- wgh_flow_growth_inequality(growdat, mode = "dev")
#' rep
#' }
#' @export
wgh_flow_growth_inequality <- function(x = NULL, mode = NULL, ages = c(6, 9, 12, 15), baz_values = c(-1, 0, 1, 2, 3)) {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  fl <- .analytic_5_18(d); a <- fl$data
  tabs <- list(); figs <- list(); mods <- list(); spr <- list(); chg <- list()
  for (sx in .sexes) {
    z <- a[a$sex == sx, ]
    m <- wgh_rq(z, .haz_formula(), taus = c(0.05, 0.25, 0.5, 0.75, 0.95), anchor_ages = ages)
    mods[[sx]] <- m
    dsp <- wgh_dispersion(m, ages = ages, exposure_values = baz_values)
    spr[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(dsp$spread))), dsp$spread)
    chg[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(dsp$change))), dsp$change)
  }
  sup <- wgh_support(a, "baz", ages = ages, exposure_values = baz_values, by = "sex")
  spread <- dplyr::left_join(.bind(spr), sup[, c("sex", "age", "baz", "n_local", "supported")], by = c("sex", "age", "baz"))
  tabs$spread <- spread; tabs$change_per_baz <- .bind(chg); tabs$support <- sup
  tabs$sample_size <- wgh_visit_summary(a, by = "sex")
  cl <- wgh_classify(a); cl$age_band <- floor(cl$age / 3) * 3
  tabs$empirical_check <- stats::aggregate(haz ~ sex + age_band + bmi_status, data = cl,
                                           FUN = function(v) diff(stats::quantile(v, c(0.05, 0.95))))
  ss <- spread[spread$supported, ]
  figs$fig_range90 <- ggplot2::ggplot(ss, ggplot2::aes(.data$baz, .data$range90, colour = factor(.data$age))) +
    (if ("range90_lower" %in% names(ss)) ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$range90_lower, ymax = .data$range90_upper), width = 0.1)) +
    ggplot2::geom_line() + ggplot2::geom_point() + ggplot2::facet_wrap(~sex) + scale_colour_wgh() + theme_wgh() +
    ggplot2::labs(x = "BMI-for-age z-score", y = "HAZ P95 minus P5", colour = "Age")
  figs$fig_iqr <- ggplot2::ggplot(ss, ggplot2::aes(.data$baz, .data$iqr, colour = factor(.data$age))) +
    ggplot2::geom_line() + ggplot2::geom_point() + ggplot2::facet_wrap(~sex) + scale_colour_wgh() + theme_wgh() +
    ggplot2::labs(x = "BMI-for-age z-score", y = "HAZ interquartile range", colour = "Age")
  wgh_report("Growth inequality: spread of height by BMI (Ho 2026, manuscript under review)", tabs, figs, mods, sample_flow = fl,
            settings = list(mode = wgh_mode()), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: conditional growth references (Ho 2026, medRxiv 2026.09.23.26363771)
#'
#' Conditioning-window to target-age panel, conditional quantile references
#' by sex and target age, child-level cross-validation and
#' leave-one-site-out validation against the unconditional, persistence and
#' WHO-band benchmarks (pinball loss, CRPS, WIS, coverage and width),
#' calibration by quantile, the conditional centile of every observed
#' target value with the share flagged below the 3rd or above the 97th
#' centile, and fan charts for two example children with their later
#' measurements.
#' @inheritParams wgh_flow_secular_trends
#' @param window,targets Conditioning window and target ages.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' rep <- wgh_flow_conditional_references(growdat, mode = "dev", window = c(5, 9), targets = c(10, 12))
#' rep
#' rep$tables$cv_scores
#' rep$tables$flags
#' }
#' @export
wgh_flow_conditional_references <- function(x = NULL, mode = NULL, window = c(5, 10), targets = c(12, 15)) {
  .need("quantreg")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  cp <- wgh_conditional_panel(d, window = window, targets = targets)
  tabs <- list(); figs <- list()
  tabs$panel_size <- as.data.frame(table(sex = cp$sex, target = cp$target_nominal, site = cp$site))
  tabs$table1 <- wgh_table1(cp, vars = c("baseline_age", "baseline_haz", "baseline_baz", "followup", "target"), by = "sex")
  cr <- wgh_condref(cp)
  tabs$coefficients_median <- .bind(lapply(cr$models, function(m) tibble::tibble(sex = m$sex, target = m$target_nominal,
                                                                                 term = rownames(m$coefs), estimate = m$coefs[, "tau_0.500"])))
  cv <- wgh_condref_cv(cp, folds = max(3, wgh_opt("folds")))
  tabs$cv_scores_by_fold <- cv
  num <- c("pinball", "crps", "wis", "coverage_50", "coverage_80", "coverage_90", "width_50", "width_80", "width_90")
  tabs$cv_scores <- stats::aggregate(cv[, num], by = list(model = cv$model, sex = cv$sex, target = cv$target), FUN = mean)
  if (length(unique(cp$site)) > 1) {
    lo <- wgh_condref_cv(cp, folds = "site")
    tabs$leave_one_site_out <- stats::aggregate(lo[, num], by = list(model = lo$model, site = lo$fold), FUN = mean)
  }
  P <- predict(cr, cp)
  ok <- stats::complete.cases(P)
  tabs$calibration <- wgh_calibration(cp$target[ok], P[ok, ], cr$taus, group = paste(cp$sex, cp$target_nominal)[ok])
  sc <- tabs$cv_scores
  figs$fig_scores <- ggplot2::ggplot(sc, ggplot2::aes(.data$model, .data$crps, fill = .data$model)) +
    ggplot2::geom_col() + ggplot2::facet_grid(sex ~ .lab_num("Target", target)) + scale_fill_wgh() + theme_wgh(legend = "none") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)) + ggplot2::labs(x = NULL, y = "CRPS (lower is better)")
  figs$fig_calibration <- ggplot2::ggplot(tabs$calibration, ggplot2::aes(.data$tau, .data$observed_share, colour = .data$group)) +
    ggplot2::geom_abline(linetype = 2) + ggplot2::geom_line() + ggplot2::geom_point() + scale_colour_wgh() + theme_wgh() +
    ggplot2::labs(x = "Nominal quantile", y = "Observed share below", colour = NULL)
  ## example children followed to the last target age, with their later measurements
  full <- names(which(table(cp$id) == length(targets)))
  ex <- cp[cp$target_nominal == min(targets) & cp$id %in% full, ]
  if (nrow(ex) < 2) ex <- cp[cp$target_nominal == min(targets), ]
  ex <- ex[order(ex$baseline_haz), ][c(max(1, round(nrow(ex) * 0.1)), max(1, round(nrow(ex) * 0.9))), ]
  later <- function(i) { z <- d[d$id == ex$id[i] & d$age > ex$baseline_age[i], c("age", "haz")]; if (nrow(z)) z else NULL }
  figs$fig_fan_low <- wgh_plot_fan(cr, ex[1, ], observed = later(1)) + ggplot2::labs(title = "Example child with low baseline HAZ")
  figs$fig_fan_high <- wgh_plot_fan(cr, ex[2, ], observed = later(2)) + ggplot2::labs(title = "Example child with high baseline HAZ")
  tabs$centiles <- wgh_condref_centile(cr, cp)
  tabs$flags <- stats::aggregate(cbind(below = cond_flag == "below", above = cond_flag == "above") ~ sex + target_nominal,
                                 data = tabs$centiles, FUN = function(z) round(100 * mean(z), 1))
  wgh_report("Conditional growth references (Ho 2026, medRxiv 2026.09.23.26363771)", tabs, figs, models = list(condref = cr),
            settings = list(mode = wgh_mode(), window = window, targets = targets), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: canalization, catch-up and catch-down (Ho 2026, manuscript under review)
#'
#' Height-for-age bands, consecutive-visit transitions, transition matrices
#' and canalization summaries by sex and age block, a continuous-time
#' multistate model with direction-shared covariate effects, its
#' plausibility check, transition probabilities, sojourn times and
#' observed versus expected prevalence, and mixed models for catch-up and
#' catch-down.
#' @inheritParams wgh_flow_secular_trends
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed(c("lme4", "msm"))
#' \donttest{
#' rep <- wgh_flow_canalization(growdat2_mini, mode = "dev")
#' rep
#' }
#' @export
wgh_flow_canalization <- function(x = NULL, mode = NULL) {
  .need("msm"); .need("lme4")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  st <- wgh_states(d[d$age >= 5, ])
  fl <- wgh_sample_flow(st, "Valid band" = ~ !is.na(state), "At least 2 visits" = wgh_min_visits(2))
  st <- fl$data
  tr <- wgh_transitions(st)
  pre <- wgh_index_exposure(st, "baz", max_age = c(Male = 11, Female = 9), name = "pre",
                           categories = function(b, a) wgh_bmi_category(b, a, thinness = FALSE))
  pre <- pre[!duplicated(pre$id), c("id", "pre_cat")]
  tabs <- list(bands = as.data.frame(table(sex = st$sex, band = st$band)))
  tabs$transition_matrix <- wgh_transition_matrix(tr, by = "sex")
  tabs$canalization <- wgh_canalization_summary(tr, by = "sex")
  md <- wgh_msm_data(st)
  md$sex <- factor(md$sex)
  ms <- wgh_msm(md, covariates = "sex")
  sm <- wgh_msm_summary(ms)
  tabs$msm_intensity_check <- sm$check
  tabs$msm_pmatrix_1y <- tibble::as_tibble(cbind(from = seq_len(nrow(sm$pmatrix)), as.data.frame(round(sm$pmatrix, 4))))
  tabs$msm_sojourn <- sm$sojourn
  tabs$msm_hazard_ratios <- sm$hazard_ratios
  tabs$msm_prevalence <- wgh_msm_prevalence(ms)
  tr2 <- merge(tr, pre, by = "id")
  gl_up <- wgh_transition_glmm(tr2, "catch_up", c("sex", "age", "pre_cat"), subset_from = 1:2)
  gl_dn <- wgh_transition_glmm(tr2, "catch_down", c("sex", "age", "pre_cat"), subset_from = 4:5)
  tabs$glmm_catch_up <- gl_up$odds_ratios; tabs$glmm_catch_down <- gl_dn$odds_ratios
  tm <- tabs$transition_matrix
  tm$from <- factor(tm$from, levels = .band_labels); tm$to <- factor(tm$to, levels = .band_labels)
  figs <- list(fig_transition_heatmap = ggplot2::ggplot(tm, ggplot2::aes(.data$to, .data$from, fill = .data$row_pct)) +
                 ggplot2::geom_tile(colour = "white") + ggplot2::geom_text(ggplot2::aes(label = round(.data$row_pct)), size = 3) +
                 ggplot2::facet_wrap(~sex) + ggplot2::scale_fill_viridis_c(option = "mako", direction = -1) + theme_wgh(legend = "right") +
                 ggplot2::labs(x = "Band at next visit", y = "Band at visit", fill = "Row %"))
  pv <- tabs$msm_prevalence
  figs$fig_prevalence_check <- ggplot2::ggplot(pv, ggplot2::aes(.data$time)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$expected), colour = "#0072B2") + ggplot2::geom_point(ggplot2::aes(y = .data$observed), colour = "#D55E00") +
    ggplot2::facet_wrap(~ .lab_num("Band", state), scales = "free_y") + theme_wgh() +
    ggplot2::labs(x = "Years since start of follow-up", y = "Prevalence (%)", caption = "Points: observed. Lines: expected from the model.")
  wgh_report("Canalization, catch-up and catch-down (Ho 2026, manuscript under review)", tabs, figs, models = list(msm = ms, glmm_up = gl_up$model, glmm_down = gl_dn$model),
            sample_flow = fl, settings = list(mode = wgh_mode()), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: growth phenotypes and later outcomes, growth side (Ho 2026, manuscript in preparation)
#'
#' Links growth phenotypes from [wgh_flow_growth_phenotypes()] to a later
#' outcome: representativeness of the linked sample, phenotype to outcome
#' models with bootstrap intervals, a dose-response model on a continuous
#' phenotype feature and a g-formula mediation of the timing effect through
#' late-adolescent BMI (only when `outcome_data` is supplied, since the
#' default outcome is itself defined from BMI). Clustering of later
#' multimorbidity is outside the scope of the package.
#' @inheritParams wgh_flow_height_prediction
#' @param phenotypes A report from [wgh_flow_growth_phenotypes()] (computed
#'   when `NULL`).
#' @param outcome_data One row per child with `id` and the outcome. When
#'   `NULL`, two outcomes are derived from visits at 15 years or older:
#'   `late_overweight_obesity` (any BAZ above +1) and `late_obesity` (any BAZ
#'   above +2).
#' @param outcome Outcome column (default `"late_overweight_obesity"`).
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
#' ph <- wgh_flow_growth_phenotypes(long, mode = "dev", spurt = spurt, G = 2:4)
#' rep <- wgh_flow_phenotype_outcomes(long, mode = "dev", phenotypes = ph)
#' rep
#' }
#' @export
wgh_flow_phenotype_outcomes <- function(x = NULL, mode = NULL, phenotypes = NULL, outcome_data = NULL,
                                        outcome = "late_overweight_obesity") {
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  spurt <- if (is.null(phenotypes)) .spurt_or_fit(NULL, x, mode) else NULL
  phenotypes <- phenotypes %||% wgh_flow_growth_phenotypes(x, spurt = spurt)
  fd <- .flow_visits(x, spurt); d <- fd$data
  user_outcome <- !is.null(outcome_data)
  if (is.null(outcome_data)) {
    late <- d[d$age >= 15 & !is.na(d$baz), ]
    outcome_data <- stats::aggregate(baz ~ id, data = late, FUN = max)
    outcome_data$late_obesity <- as.integer(outcome_data$baz > 2)
    outcome_data$late_overweight_obesity <- as.integer(outcome_data$baz > 1)
    names(outcome_data)[2] <- "baz_late_max"
  }
  first <- d[!duplicated(d$id), c("id", "site")]
  tabs <- list(); figs <- list(); res <- list(); dose <- list(); rep_t <- list(); med <- list()
  for (sx in .sexes) {
    cl <- phenotypes$models[[sx]]
    pf <- .pheno_frame(cl)
    linked <- pf$id %in% outcome_data$id
    rep_t[[sx]] <- tibble::tibble(sex = sx, phenotype = levels(pf$phenotype),
                                  all = as.integer(table(pf$phenotype)), linked = as.integer(table(pf$phenotype[linked])),
                                  pct_linked = round(100 * as.integer(table(pf$phenotype[linked])) / as.integer(table(pf$phenotype)), 1))
    od <- merge(outcome_data, first, by = "id")
    r <- wgh_link_outcome(cl, od, outcome, covariates = "site", B = min(wgh_opt("B"), 200))
    res[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(r))), r)
    dr <- wgh_link_outcome(cl, od, outcome, covariates = "site", exposure = "b", B = min(wgh_opt("B"), 200))
    dose[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(dr))), dr)
    if (user_outcome) {
      lt <- stats::aggregate(baz ~ id, data = d[d$age >= 15 & !is.na(d$baz), ], FUN = stats::median)
      names(lt)[2] <- "baz_late"
      mm <- merge(merge(cl$features[, c("id", "b")], od, by = "id"), lt, by = "id")
      if (nrow(mm) > 50) {
        m <- wgh_mediation(mm, "b", "baz_late", outcome, a = -1, a_star = 0, B = min(wgh_opt("B"), 100))
        med[[sx]] <- dplyr::bind_cols(tibble::tibble(sex = rep(sx, nrow(m))), m)
      }
    }
  }
  tabs$representativeness <- .bind(rep_t); tabs$phenotype_outcome <- .bind(res)
  tabs$dose_response_timing <- .bind(dose); tabs$mediation <- .bind(med)
  po <- tabs$phenotype_outcome
  if ("odds_ratio" %in% names(po))
    figs$fig_forest <- wgh_plot_forest(po, "term", "odds_ratio", "or_lower", "or_upper", colour = "sex", ref = 1, log = TRUE) +
      ggplot2::labs(x = paste("Odds ratio for", outcome))
  wgh_report("Growth phenotypes and later outcomes, growth side (Ho 2026, manuscript in preparation)", tabs, figs,
            settings = list(mode = wgh_mode(), outcome = outcome), note = if (fd$simulated) .sim_note else NULL)
}

#' Flow: explainable individual growth prediction (Ho 2026, manuscript under review)
#'
#' Explains the conditional reference models of [wgh_flow_conditional_references()]
#' (Ho 2026, medRxiv 2026.09.23.26363771): exact SHAP
#' attributions for the median and outer quantiles by sex and target age
#' (analytic for these linear quantile models, identical to exact kernel
#' SHAP with an independent background), quantile-resolved importance with
#' bootstrap intervals, permutation importance as a check, rank stability
#' across folds and sites, an interaction term and waterfall explanations
#' of individual children.
#' @inheritParams wgh_flow_conditional_references
#' @param taus Quantiles explained.
#' @return A [wgh_report].
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' rep <- wgh_flow_explain_prediction(growdat, mode = "dev", window = c(5, 9), targets = c(10, 12))
#' rep
#' }
#' @export
wgh_flow_explain_prediction <- function(x = NULL, mode = NULL, window = c(5, 10), targets = c(12, 15),
                                       taus = c(0.1, 0.5, 0.9)) {
  .need("quantreg")
  old <- .with_mode(mode); on.exit(.restore_mode(old), add = TRUE)
  fd <- .flow_data(x); d <- fd$data
  if (!"baz" %in% names(d)) d <- .gd(wgh_add_zscores(d))
  cp <- wgh_conditional_panel(d, window = window, targets = targets)
  cp <- cp[stats::complete.cases(cp[, c("baseline_haz", "baseline_baz", "baseline_age", "target")]), ]
  feats <- c("baseline_haz", "baseline_baz", "baseline_age")
  form <- ~ baseline_haz + baseline_baz + baseline_age + baseline_haz:baseline_baz
  shap_rows <- list(); imp <- list(); perm <- list(); stab <- list(); inter <- list(); figs <- list()
  qfit <- function(z, tau) quantreg::rq(stats::update(form, target ~ .), tau = tau, data = z)
  pinloss <- function(tau) function(y, p) { u <- y - p; mean(pmax(tau * u, (tau - 1) * u)) }
  for (sx in .sexes) for (ta in targets) {
    z <- cp[cp$sex == sx & cp$target_nominal == ta, ]
    if (nrow(z) < 60) next
    for (tau in taus) {
      f <- qfit(z, tau)
      co <- stats::coef(f)
      sh <- wgh_shap_interaction(co, z, z)
      S <- sh$S[, feats, drop = FALSE]
      key <- paste(sx, ta, tau)
      shobj <- structure(list(S = S, X = as.data.frame(z[, feats]), baseline = mean(stats::predict(f, z)), method = "analytic SHAP"), class = "wgh_shap")
      sm <- wgh_shap_summary(shobj, B = min(wgh_opt("B"), 200))
      imp[[key]] <- dplyr::bind_cols(tibble::tibble(sex = sx, target = ta, tau = tau), sm)
      inter[[key]] <- tibble::tibble(sex = sx, target = ta, tau = tau, feature = colnames(sh$interaction),
                                     mean_abs_interaction = colMeans(abs(sh$interaction)))
      if (tau == 0.5) {
        pm <- wgh_permutation_importance(f, as.data.frame(z[, feats]), z$target, pred_fun = function(m, nd) {
          nd <- as.data.frame(nd); stats::predict(m, nd) }, loss = pinloss(tau))
        perm[[key]] <- dplyr::bind_cols(tibble::tibble(sex = sx, target = ta), pm)
        sp <- wgh_split(z, folds = 5)
        tb <- lapply(sp, function(ids) { ff <- qfit(z[!z$id %in% ids, ], tau)
          s2 <- wgh_shap_interaction(stats::coef(ff), z[z$id %in% ids, ], z[!z$id %in% ids, ])$S[, feats, drop = FALSE]
          r <- colMeans(abs(s2)); tibble::tibble(feature = names(r), rank = rank(-r)) })
        rs <- wgh_rank_stability(tb)
        stab[[key]] <- tibble::tibble(sex = sx, target = ta, scheme = "5 folds", mean_spearman = rs$mean_spearman,
                                      top_feature = rs$ranks$feature[1])
        if (sx == "Male" && ta == min(targets)) {
          figs$fig_waterfall_example <- wgh_plot_waterfall(shobj, row = which.min(z$baseline_haz)) +
            ggplot2::labs(title = paste("Explanation of a median prediction, boys, target", ta))
          figs$fig_beeswarm_example <- plot(shobj, "beeswarm")
        }
      }
    }
  }
  tabs <- list(importance = .bind(imp), permutation = .bind(perm), rank_stability = .bind(stab), interaction = .bind(inter))
  im <- tabs$importance
  figs$fig_quantile_resolved <- ggplot2::ggplot(im, ggplot2::aes(factor(.data$tau), .data$mean_abs_shap, fill = .data$feature)) +
    ggplot2::geom_col(position = "dodge") + ggplot2::facet_grid(sex ~ .lab_num("Target", target)) + scale_fill_wgh() + theme_wgh() +
    ggplot2::labs(x = "Quantile", y = "Mean |SHAP| (HAZ units)", fill = NULL)
  wgh_report("Explainable individual growth prediction (Ho 2026, manuscript under review)", tabs, figs,
            settings = list(mode = wgh_mode(), taus = taus), note = if (fd$simulated) .sim_note else NULL)
}
