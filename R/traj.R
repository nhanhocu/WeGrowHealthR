## Longitudinal trajectories (Book 1 Chapter 8, the prepubertal BMI and height trajectory study (Ho et al. 2026, medRxiv 2026.07.26.26358003)) --------------------

#' Exposure at a prepubertal index age, attached to every visit of a child
#'
#' Picks one visit per child in an index window (for example the earliest
#' visit at or before 11 years in boys and 9 years in girls, the definition
#' used in the trajectory, pubertal spurt and height prediction studies) and
#' attaches its value of `var` (and
#' optionally a category) to the whole child record.
#'
#' @param x Growth data.
#' @param var Exposure variable, for example `"baz"`.
#' @param max_age Named vector of the latest index age by sex.
#' @param min_age Earliest age allowed for the index visit.
#' @param pick `"earliest"`, `"latest"` or `"nearest"` (to `max_age`).
#' @param categories Optional function turning the exposure value into a
#'   category, for example `wgh_bmi_category`.
#' @param name Prefix of the new columns.
#' @return `x` restricted to children with an index visit, with columns
#'   `<name>_value`, `<name>_age` and, when `categories` is given,
#'   `<name>_cat`.
#' @examples
#' ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
#' table(ix$index_cat[!duplicated(ix$pid)])
#' @export
wgh_index_exposure <- function(x, var = "baz", max_age = c(Male = 11, Female = 9), min_age = 5,
                              pick = c("earliest", "latest", "nearest"), categories = NULL, name = "index") {
  pick <- match.arg(pick)
  d <- .gd(x, c("id", "age", "sex"))
  mx <- unname(max_age[as.character(d$sex)])
  cand <- d[d$age >= min_age & d$age <= mx + 0.999 & !is.na(d[[var]]), , drop = FALSE]
  cand$.score <- switch(pick, earliest = cand$age, latest = -cand$age,
                        nearest = abs(cand$age - unname(max_age[as.character(cand$sex)])))
  cand <- cand[order(cand$id, cand$.score), ]
  first <- cand[!duplicated(cand$id), c("id", "age", var)]
  names(first) <- c("id", paste0(name, "_age"), paste0(name, "_value"))
  out <- merge(d, first, by = "id")
  if (!is.null(categories)) out[[paste0(name, "_cat")]] <- categories(out[[paste0(name, "_value")]], out[[paste0(name, "_age")]])
  out <- out[order(out$id, out$age), ]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' BMI category from a BMI-for-age z-score
#' @param baz BMI-for-age z-scores.
#' @param age Age in years (the cut-offs differ under 5 years).
#' @param thinness Include a thinness category.
#' @return A factor.
#' @examples
#' wgh_bmi_category(c(-2.5, 0, 1.5, 2.5), age = 8)
#' @export
wgh_bmi_category <- function(baz, age = 10, thinness = TRUE) {
  age <- rep_len(age, length(baz))
  ow <- ifelse(age < 5, 2, 1); ob <- ifelse(age < 5, 3, 2)
  lab <- ifelse(baz > ob, "Obesity", ifelse(baz > ow, "Overweight",
                ifelse(thinness & baz < -2, "Thinness", "Normal")))
  factor(lab, levels = c(if (thinness) "Thinness", "Normal", "Overweight", "Obesity"))
}

#' Change in exposure category between two index ages
#' @param x Growth data.
#' @param var Exposure (default `"baz"`).
#' @param ages Two ages; the visit nearest each (within `tol`) is used.
#' @param tol Tolerance in years.
#' @param categories Categorisation function.
#' @return One row per child with the two categories and a change group such
#'   as `"Normal to Overweight"` or `"Stable Obesity"`.
#' @examples
#' ch <- wgh_exposure_change(growdat, ages = c(7, 10))
#' table(ch$change)
#' @export
wgh_exposure_change <- function(x, var = "baz", ages = c(7, 10), tol = 1, categories = wgh_bmi_category) {
  d <- .gd(x, c("id", "age"))
  near <- function(a) {
    z <- d[abs(d$age - a) <= tol & !is.na(d[[var]]), ]
    z <- z[order(z$id, abs(z$age - a)), ]
    z <- z[!duplicated(z$id), c("id", "sex", "age", var)]
    z
  }
  a <- near(ages[1]); b <- near(ages[2])
  m <- merge(a, b[, c("id", "age", var)], by = "id", suffixes = c("_1", "_2"))
  m$cat_1 <- categories(m[[paste0(var, "_1")]], m$age_1)
  m$cat_2 <- categories(m[[paste0(var, "_2")]], m$age_2)
  m$change <- ifelse(m$cat_1 == m$cat_2, paste("Stable", m$cat_1), paste(m$cat_1, "to", m$cat_2))
  tibble::as_tibble(m)
}

#' Fit a linear mixed model for growth trajectories
#'
#' A wrapper around `lme4::lmer()` with growth-friendly defaults: a natural
#' spline of age, random intercept and slope by child, and an optimiser
#' setting that avoids the convergence failures common with large cohorts.
#' Generalises `fit_trajectory_model()` from Book 1 Chapter 8.
#'
#' @param x Growth data.
#' @param formula Fixed-effects formula, for example
#'   `haz ~ splines::ns(age, df = 3) * index_cat + site`.
#' @param random Random-effects term (character), by default a random
#'   intercept and slope on centred age.
#' @param center_age Centre age (years) for the random slope.
#' @param REML Use REML.
#' @return An object of class `wgh_lmm` holding the `lmerMod` fit.
#' @examplesIf rlang::is_installed("lme4")
#' \donttest{
#' ix <- wgh_index_exposure(growdat, "baz", categories = function(b, a) wgh_bmi_category(b, a, FALSE))
#' fit <- wgh_fit_lmm(ix[ix$age >= 5, ], haz ~ splines::ns(age, df = 3) * index_cat + sex)
#' fit
#' }
#' @export
wgh_fit_lmm <- function(x, formula, random = "(1 + age_c | id)", center_age = 10, REML = TRUE) {
  .need("lme4")
  d <- .gd(x, c("id", "age"))
  d$age_c <- d$age - center_age
  f <- stats::as.formula(paste(deparse(formula, width.cutoff = 500), "+", random))
  fit <- lme4::lmer(f, data = d, REML = REML,
                    control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5)))
  structure(list(fit = fit, formula = formula, random = random, center_age = center_age,
                 n_children = length(unique(d$id)), n_obs = nrow(d)), class = "wgh_lmm")
}

#' @export
print.wgh_lmm <- function(x, ...) {
  cli::cli_text("{.cls wgh_lmm}: {x$n_obs} visits from {x$n_children} children")
  cli::cli_text("Fixed: {deparse(x$formula, width.cutoff = 200)}; random: {x$random}")
  print(wgh_fit_stats(x))
  invisible(x)
}

#' @export
summary.wgh_lmm <- function(object, ...) summary(object$fit, ...)

#' Contrasts between groups at stated ages
#'
#' Estimated marginal means and pairwise contrasts from a fitted trajectory
#' model at chosen ages, using `emmeans`. Effects are reported at stated
#' ages because main effects in a spline-by-group model are the effects at
#' the lower boundary knot, a misreading documented in the program.
#' @param fit A `wgh_lmm` object or any model supported by `emmeans`.
#' @param specs Grouping variable, for example `"index_cat"`.
#' @param ages Ages at which to compare.
#' @param by Additional conditioning variable (for example `"sex"`).
#' @param adjust Multiplicity adjustment.
#' @return A list with `means` and `contrasts` tibbles.
#' @examples
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
#'   girls <- ix[ix$sex == "Female" & ix$age >= 5, ]
#'   fit <- wgh_fit_lmm(girls, haz ~ splines::ns(age, df = 3) * index_cat)
#'   wgh_contrasts(fit, "index_cat", ages = c(8, 12))$contrasts
#' }
#' }
#' @export
wgh_contrasts <- function(fit, specs, ages = c(8, 10, 12, 14), by = NULL, adjust = "holm") {
  .need("emmeans")
  m <- if (inherits(fit, "wgh_lmm")) fit$fit else fit
  ca <- if (inherits(fit, "wgh_lmm")) fit$center_age else 0
  em <- emmeans::emmeans(m, specs = c(specs, by), by = "age",
                         at = list(age = ages, age_c = ages - ca), lmer.df = "asymptotic")
  means <- tibble::as_tibble(as.data.frame(summary(em)))
  pr <- emmeans::contrast(em, method = "revpairwise", by = c("age", by), adjust = adjust)
  ct <- tibble::as_tibble(as.data.frame(summary(pr, infer = TRUE)))
  list(means = means, contrasts = ct)
}

#' Intraclass correlation and fit statistics of a mixed model
#' @param fit A `wgh_lmm` or `lmerMod` object.
#' @return `wgh_icc()`: the share of variance between children at the centre
#'   age. `wgh_fit_stats()`: a tibble with AIC, BIC, log-likelihood, residual
#'   SD and marginal and conditional R squared (Nakagawa and Schielzeth).
#' @examples
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   fit <- wgh_fit_lmm(growdat[growdat$age >= 5, ], haz ~ splines::ns(age, df = 3) + sex)
#'   wgh_icc(fit)
#'   wgh_fit_stats(fit)
#' }
#' }
#' @export
wgh_icc <- function(fit) {
  .need("lme4")
  m <- if (inherits(fit, "wgh_lmm")) fit$fit else fit
  vc <- as.data.frame(lme4::VarCorr(m))
  v_int <- vc$vcov[is.na(vc$var2) & vc$var1 == "(Intercept)"][1]
  v_res <- vc$vcov[vc$grp == "Residual"]
  v_int / (v_int + v_res)
}

#' @rdname wgh_icc
#' @export
wgh_fit_stats <- function(fit) {
  .need("lme4")
  m <- if (inherits(fit, "wgh_lmm")) fit$fit else fit
  vf <- stats::var(as.vector(lme4::getME(m, "X") %*% lme4::fixef(m)))
  vc <- as.data.frame(lme4::VarCorr(m))
  vr <- vc$vcov[vc$grp == "Residual"]
  vre <- sum(vc$vcov[is.na(vc$var2) & vc$grp != "Residual"])
  tibble::tibble(AIC = stats::AIC(m), BIC = stats::BIC(m), logLik = as.numeric(stats::logLik(m)),
                 sigma = stats::sigma(m), R2_marginal = vf / (vf + vre + vr),
                 R2_conditional = (vf + vre) / (vf + vre + vr), ICC = wgh_icc(m))
}

#' Trajectories by group with tests at milestone ages
#' @param x Growth data.
#' @param y Outcome (for example `"haz"`).
#' @param group Grouping variable (for example an index BMI category).
#' @param facet Facet column.
#' @param milestones Ages at which Kruskal-Wallis tests are run and marked.
#' @param window Half-width of the age window for the tests.
#' @param ... Display options (see [wgh_plot_options()]); `show_ci = FALSE`
#'   removes the confidence bands.
#' @return A ggplot with LOESS curves by group and p-values at milestones.
#' @examples
#' ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
#' wgh_plot_trajectories(ix[ix$age >= 5, ], "haz", "index_cat", milestones = c(8, 12, 16))
#' wgh_plot_trajectories(ix[ix$age >= 5, ], "haz", "index_cat", show_ci = FALSE, legend = "right")
#' @export
wgh_plot_trajectories <- function(x, y, group, facet = "sex", milestones = NULL, window = 0.5, ...) {
  o <- .popts(...)
  d <- .gd(x, c("id", "age"))
  d <- d[!is.na(d[[y]]) & !is.na(d[[group]]), ]
  .local_seed(2026)  # thinning of very large data for plotting only, caller's stream restored
  dd <- if (nrow(d) > 20000) d[sample.int(nrow(d), 20000), ] else d
  p <- ggplot2::ggplot(dd, ggplot2::aes(.data$age, .data[[y]], colour = .data[[group]])) +
    ggplot2::geom_smooth(method = "loess", formula = y ~ x, se = isTRUE(o$show_ci), linewidth = o$line_width %||% 0.9) +
    ggplot2::facet_wrap(facet) + scale_colour_wgh() +
    ggplot2::labs(x = "Age (years)", y = .axis_label(y), colour = NULL)
  if (!is.null(milestones)) {
    tests <- wgh_compare_groups(d, y, group, ages = milestones, window = window, by = facet)$overall
    if (nrow(tests)) {
      tests$age <- as.numeric(tests$age)
      fp <- wgh_fmt_p(tests$p_value)
      tests$label <- ifelse(startsWith(fp, "<"), paste0("p", fp), paste0("p=", fp))
      p <- p + ggplot2::geom_vline(xintercept = milestones, linetype = 3, colour = "grey60") +
        ggplot2::geom_text(data = tests, ggplot2::aes(x = .data$age, y = Inf, label = .data$label),
                           inherit.aes = FALSE, vjust = 1.5, size = 2.8)
    }
  }
  .finish(p, o)
}

#' Rerun an analysis under alternative eligibility rules
#' @param x Data.
#' @param fun A function of the data returning a data frame of results.
#' @param variants Named list of functions, each restricting the data.
#' @return The results of `fun` for each variant, stacked with a `variant`
#'   column.
#' @examples
#' f <- function(d) data.frame(median_haz = median(d$haz, na.rm = TRUE))
#' wgh_sensitivity(growdat, f, list(all = identity,
#'   three_visits = function(d) d[d$pid %in% names(which(table(d$pid) >= 3)), ]))
#' @export
wgh_sensitivity <- function(x, fun, variants) {
  .bind(lapply(names(variants), function(v) {
    r <- tibble::as_tibble(fun(variants[[v]](x)))
    dplyr::bind_cols(tibble::tibble(variant = rep(v, nrow(r))), r)
  }))
}
