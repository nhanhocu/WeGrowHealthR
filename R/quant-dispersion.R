## Growth dispersion (Book 2 Ch 6, the growth inequality study (Ho 2026, manuscript under review)) ---------------------------------

#' Spread of the growth distribution by age and exposure
#'
#' From a fitted [wgh_rq()] (or [wgh_lqmm()]) model containing the 5th, 25th,
#' 75th and 95th percentiles, computes the P95 minus P5 range and the
#' interquartile range on a grid of ages and exposure values, the change in
#' spread per unit of exposure, and bootstrap intervals from the model's
#' cluster bootstrap. This is the core of the growth inequality study (Ho 2026, manuscript under review).
#'
#' @param object A `wgh_rq` object fitted with `taus` including 0.05, 0.25,
#'   0.75 and 0.95.
#' @param ages Ages of the grid.
#' @param exposure_values Exposure values of the grid (for example BMIZ -1
#'   to 3).
#' @param fixed Values of other model variables.
#' @param level Interval level.
#' @return A list with `spread` (P95-P5 and IQR by age and exposure with
#'   intervals) and `change` (change in spread per unit exposure by age).
#' @examples
#' \donttest{
#' d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#' f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#' fit <- wgh_rq(d, f, taus = c(0.05, 0.25, 0.5, 0.75, 0.95),
#'               anchor_ages = c(6, 9, 12, 15), B = 20)
#' disp <- wgh_dispersion(fit, ages = c(6, 12), exposure_values = c(0, 1, 2))
#' disp$change
#' }
#' @export
wgh_dispersion <- function(object, ages = c(6, 9, 12, 15), exposure_values = c(-1, 0, 1, 2, 3),
                          fixed = list(), level = 0.95) {
  need <- c(0.05, 0.25, 0.75, 0.95)
  if (!all(need %in% round(object$taus, 3))) .stop("The model needs quantiles 0.05, 0.25, 0.75 and 0.95.")
  base <- .base_grid(object$data, object$design$vars, fixed)
  grid <- expand.grid(age = ages, ex = exposure_values)
  g <- as.data.frame(lapply(base, function(v) rep(v, nrow(grid))), stringsAsFactors = FALSE)
  g$age <- grid$age; g[[object$exposure]] <- grid$ex
  X <- .grid_matrix(object$design, g)
  idx <- match(need, round(object$taus, 3))
  calc <- function(Bm) {
    P <- wgh_rearrange(X %*% Bm)[, idx, drop = FALSE]
    cbind(range90 = P[, 4] - P[, 1], iqr = P[, 3] - P[, 2])
  }
  est <- calc(object$coefs)
  sp <- tibble::tibble(age = grid$age, !!object$exposure := grid$ex, range90 = est[, 1], iqr = est[, 2])
  ## change in spread per unit exposure: slope of spread on exposure over the grid, by age
  ch_fun <- function(e) {
    vapply(ages, function(a) {
      k <- grid$age == a
      c(stats::coef(stats::lm(e[k, 1] ~ grid$ex[k]))[2], stats::coef(stats::lm(e[k, 2] ~ grid$ex[k]))[2])
    }, numeric(2))
  }
  ch <- ch_fun(est)
  change <- tibble::tibble(age = ages, range90_per_unit = ch[1, ], iqr_per_unit = ch[2, ])
  if (!is.null(object$boot)) {
    a <- (1 - level) / 2
    dr <- lapply(seq_len(dim(object$boot)[3]), function(b) calc(object$boot[, , b]))
    r90 <- sapply(dr, function(m) m[, 1]); iq <- sapply(dr, function(m) m[, 2])
    sp$range90_lower <- apply(r90, 1, stats::quantile, a); sp$range90_upper <- apply(r90, 1, stats::quantile, 1 - a)
    sp$iqr_lower <- apply(iq, 1, stats::quantile, a); sp$iqr_upper <- apply(iq, 1, stats::quantile, 1 - a)
    chd <- lapply(dr, ch_fun)
    c1 <- sapply(chd, function(m) m[1, ]); c2 <- sapply(chd, function(m) m[2, ])
    if (is.null(dim(c1))) { c1 <- matrix(c1, nrow = 1); c2 <- matrix(c2, nrow = 1) }
    change$range90_lower <- apply(c1, 1, stats::quantile, a); change$range90_upper <- apply(c1, 1, stats::quantile, 1 - a)
    change$iqr_lower <- apply(c2, 1, stats::quantile, a); change$iqr_upper <- apply(c2, 1, stats::quantile, 1 - a)
  }
  list(spread = sp, change = change)
}

#' Which combinations of age and exposure are supported by the data
#'
#' Counts observations near each grid point (within `age_window` years and
#' `exposure_window` units of exposure). the growth inequality study (Ho 2026, manuscript under review) reports spread only where
#' at least `min_n` observations support the estimate.
#' @param x Data.
#' @param exposure Exposure variable.
#' @param ages,exposure_values Grid.
#' @param age_window,exposure_window Half-widths of the neighbourhood.
#' @param min_n Minimum count to be supported.
#' @param by Optional grouping column (for example `"sex"`).
#' @return A tibble with counts and a logical `supported`.
#' @examples
#' wgh_support(growdat, "baz", ages = c(6, 10, 14), exposure_values = c(0, 2, 4))
#' @export
wgh_support <- function(x, exposure = "baz", ages = c(6, 9, 12, 15), exposure_values = c(-1, 0, 1, 2, 3),
                       age_window = 0.5, exposure_window = 0.25, min_n = 30, by = NULL) {
  d <- .gd(x, "age")
  .bind(lapply(.grp_split(d, by), function(z) {
    g <- expand.grid(age = ages, ex = exposure_values)
    g$n_local <- mapply(function(a, e) sum(abs(z$age - a) <= age_window & abs(z[[exposure]] - e) <= exposure_window, na.rm = TRUE),
                        g$age, g$ex)
    g$supported <- g$n_local >= min_n
    names(g)[2] <- exposure
    .with_grp(z, by, tibble::as_tibble(g))
  }))
}

#' Quantile models for one value per child
#'
#' Quantile regression of a child-level outcome (for example SITAR timing
#' `b`, intensity `c` or spurt duration) on an exposure, with a bootstrap
#' over children, as in the studies of pubertal velocity (Ho 2026, medRxiv
#' 2026.09.04.26362313) and spurt duration (Ho 2026, medRxiv 2026.09.09.26362696).
#' @param x A data frame with one row per child.
#' @param formula Model formula, for example `b ~ baz_pre + site`.
#' @param exposure Term whose coefficient is reported.
#' @param taus Quantiles.
#' @param B Bootstrap replicates.
#' @param seed Random seed.
#' @return A tibble with the exposure coefficient by quantile and intervals,
#'   and an OLS comparison row.
#' @examples
#' \donttest{
#' tr <- growdat2_mini_truth
#' base <- growdat2_mini[growdat2_mini$age < 9, ]
#' base <- aggregate(bmiz ~ pid, data = base, FUN = mean)
#' d <- merge(data.frame(pid = tr$pid, sex = tr$sex, b = tr$b_tempo), base, by = "pid")
#' # Is higher prepubertal BMI linked with earlier timing across the distribution?
#' wgh_scalar_quantiles(d, b ~ bmiz + sex, exposure = "bmiz", taus = c(0.1, 0.5, 0.9), B = 20)
#' }
#' @export
wgh_scalar_quantiles <- function(x, formula, exposure, taus = wgh_taus("headline"), B = wgh_opt("B"), seed = 2026) {
  .need("quantreg")
  d <- as.data.frame(x)
  d <- d[stats::complete.cases(d[, intersect(all.vars(formula), names(d)), drop = FALSE]), ]
  taus <- wgh_taus(taus)
  des <- .rq_design(formula, transform(d, id = seq_len(nrow(d))))
  j <- grep(paste0("^", exposure, "$"), colnames(des$X))
  if (!length(j)) .stop("Exposure term {.val {exposure}} not found among the model columns.")
  est <- .fit_rq_matrix(des$X, des$y, taus)[j, ]
  one <- function(b, X, y, taus, j) {
    r <- sample.int(nrow(X), replace = TRUE)
    tryCatch(.fit_rq_matrix(X[r, , drop = FALSE], y[r], taus)[j, ], error = function(e) rep(NA_real_, length(taus)))
  }
  dr <- .wgh_map(seq_len(B), one, X = des$X, y = des$y, taus = taus, j = j, seed = seed, packages = "quantreg")
  dr <- matrix(unlist(dr), nrow = length(taus))
  ols <- stats::lm(formula, data = d)
  ci <- stats::confint(ols)[exposure, ]
  dplyr::bind_rows(
    tibble::tibble(model = "quantile", tau = taus, estimate = est,
                   lower = apply(dr, 1, stats::quantile, 0.025, na.rm = TRUE),
                   upper = apply(dr, 1, stats::quantile, 0.975, na.rm = TRUE)),
    tibble::tibble(model = "OLS (mean)", tau = NA_real_, estimate = stats::coef(ols)[[exposure]],
                   lower = ci[[1]], upper = ci[[2]]))
}

#' GAMLSS scale model as a cross-check on quantile-based spread
#'
#' Fits a GAMLSS model in which both the mean and the standard deviation of
#' the outcome depend on age and the exposure, and reports the change in log
#' SD per unit exposure at stated ages. A positive value agrees with a
#' widening P95-P5 range in [wgh_dispersion()].
#' @param x Data.
#' @param outcome,exposure Variable names.
#' @param ages Ages at which the effect is reported.
#' @param df Spline degrees of freedom for age.
#' @return A tibble of log-SD effects by age and the fitted model as an
#'   attribute.
#' @examples
#' \donttest{
#' if (requireNamespace("gamlss", quietly = TRUE)) {
#'   d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#'   wgh_gamlss_scale(d, ages = c(6, 12))
#' }
#' }
#' @export
wgh_gamlss_scale <- function(x, outcome = "haz", exposure = "baz", ages = c(6, 9, 12, 15), df = 3) {
  .need(c("gamlss", "gamlss.dist"))
  d <- as.data.frame(.gd(x, "age"))
  d <- d[stats::complete.cases(d[, c(outcome, exposure, "age")]), c(outcome, exposure, "age")]
  names(d) <- c("y", "e", "age")
  kn <- stats::quantile(d$age, seq(0, 1, length.out = df + 1)[-c(1, df + 1)])
  bk <- range(d$age)
  d <- cbind(d, stats::setNames(as.data.frame(splines::ns(d$age, knots = kn, Boundary.knots = bk)), paste0("s", 1:df)))
  sf <- paste(paste0("s", 1:df), collapse = " + ")
  fit <- gamlss::gamlss(stats::as.formula(paste("y ~ (", sf, ") * e")),
                        sigma.formula = stats::as.formula(paste("~ (", sf, ") * e")),
                        family = gamlss.dist::NO(), data = d, trace = FALSE)
  co <- stats::coef(fit, what = "sigma")
  B <- splines::ns(ages, knots = kn, Boundary.knots = bk)
  eff <- co[["e"]] + as.vector(B %*% co[paste0("s", 1:df, ":e")])
  out <- tibble::tibble(age = ages, log_sd_per_unit = eff, sd_ratio_per_unit = exp(eff))
  attr(out, "model") <- fit
  out
}
