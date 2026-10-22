## Quantile regression with child-level cluster bootstrap (Book 2 Ch 4, the growth inequality study (Ho 2026, manuscript under review))

.rq_design <- function(formula, data) {
  mf <- stats::model.frame(formula, data)
  if (nrow(mf) != nrow(data)) .stop("Rows with missing values in model variables: remove them first.")
  tt <- stats::terms(mf)
  list(X = stats::model.matrix(tt, mf), y = as.numeric(stats::model.response(mf)),
       id = data$id, terms = tt, xlev = stats::.getXlevels(tt, mf),
       vars = intersect(all.vars(stats::delete.response(tt)), names(data)))
}
.grid_matrix <- function(design, newdata) {
  tt <- stats::delete.response(design$terms)
  for (nm in names(design$xlev)) if (nm %in% names(newdata)) newdata[[nm]] <- factor(newdata[[nm]], levels = design$xlev[[nm]])
  mf <- stats::model.frame(tt, newdata, xlev = design$xlev)
  stats::model.matrix(tt, mf)
}
.fit_rq_matrix <- function(X, y, taus) {
  B <- vapply(taus, function(t) as.numeric(quantreg::rq.fit(X, y, tau = t, method = "fn")$coefficients),
              numeric(ncol(X)))
  matrix(B, nrow = ncol(X), dimnames = list(colnames(X), sprintf("tau_%.3f", taus)))
}
## Reference values for variables not set by the user: first factor level,
## mean of numeric variables.
.base_grid <- function(data, vars, set = list()) {
  out <- list()
  for (v in vars) {
    if (!is.null(set[[v]])) { out[[v]] <- set[[v]]; next }
    z <- data[[v]]
    out[[v]] <- if (is.numeric(z)) mean(z, na.rm = TRUE) else
      (if (is.factor(z)) levels(z)[1] else sort(unique(as.character(z)))[1])
  }
  out
}
.slope_L <- function(design, data, exposure, ages, fixed = list()) {
  base <- .base_grid(data, design$vars, fixed)
  g <- as.data.frame(lapply(base, function(v) rep(v, length(ages))), stringsAsFactors = FALSE)
  if ("age" %in% names(g)) g$age <- ages
  g1 <- g; g0 <- g; g1[[exposure]] <- 1; g0[[exposure]] <- 0
  L <- .grid_matrix(design, g1) - .grid_matrix(design, g0)
  rownames(L) <- paste0("age_", ages)
  L
}

#' Pooled quantile regression with a child-level cluster bootstrap
#'
#' Fits quantile regressions at several quantiles on one fixed design matrix
#' (so every bootstrap replicate uses the same spline basis), resamples
#' children with all their visits to get honest uncertainty for repeated
#' measures, and reports the exposure slope at stated ages by contrast. This
#' is the `rq_pipeline()` of Book 2 Chapter 4 made general, and the engine
#' behind the growth inequality study's dispersion analysis.
#'
#' Write spline knots into the formula (for example
#' `splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18))`) so
#' the basis does not change between replicates.
#'
#' @param x Growth data (one sex at a time, or include sex in the formula).
#' @param formula Model formula, for example
#'   `haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18)) * baz + site`.
#' @param taus Quantiles (rounded with [wgh_taus()]).
#' @param exposure Exposure whose slope is reported.
#' @param anchor_ages Ages at which slopes are reported.
#' @param fixed Values for other model variables in the slope contrasts
#'   (default: first factor level and the mean of numeric variables).
#' @param B Bootstrap replicates (default from the run mode). `0` skips the
#'   bootstrap.
#' @param seed Random seed.
#' @return An object of class `wgh_rq` with `coefs` (one column per
#'   quantile), `boot` (array of bootstrap coefficient matrices), `slopes`
#'   (estimates, bootstrap SE and percentile intervals) and the design.
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#' f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#' fit <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(6, 9, 12, 15), B = 30)
#' fit
#' }
#' @export
wgh_rq <- function(x, formula, taus = wgh_taus("headline"), exposure = "baz",
                  anchor_ages = c(6, 9, 12, 15), fixed = list(), B = wgh_opt("B"), seed = 2026) {
  .need("quantreg")
  d <- .gd(x, c("id"))
  d <- as.data.frame(d)
  vars <- unique(c(all.vars(formula), "id"))
  d <- d[stats::complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), , drop = FALSE]
  formula <- .slim_formula(formula, d)
  taus <- wgh_taus(taus)
  des <- .rq_design(formula, d)
  coefs <- .fit_rq_matrix(des$X, des$y, taus)
  L <- if (!is.null(exposure) && exposure %in% des$vars) .slope_L(des, d, exposure, anchor_ages, fixed) else NULL
  boot <- NULL
  if (B > 0) {
    rows <- split(seq_along(des$id), des$id)
    one <- function(b, X, y, rows, taus) {
      pick <- sample.int(length(rows), length(rows), replace = TRUE)
      r <- unlist(rows[pick], use.names = FALSE)
      tryCatch(.fit_rq_matrix(X[r, , drop = FALSE], y[r], taus), error = function(e) NULL)
    }
    draws <- .wgh_map(seq_len(B), one, X = des$X, y = des$y, rows = rows, taus = taus, seed = seed, packages = "quantreg")
    draws <- Filter(Negate(is.null), draws)
    boot <- simplify2array(draws)
  }
  out <- structure(list(coefs = coefs, boot = boot, design = des, L = L, taus = taus, exposure = exposure,
                        anchor_ages = anchor_ages, formula = formula, data = d,
                        n_children = length(unique(d$id)), n_obs = nrow(d),
                        B_ok = if (is.null(boot)) 0L else dim(boot)[3]), class = "wgh_rq")
  if (!is.null(L)) out$slopes <- wgh_slopes(out)
  out
}

#' Exposure slopes at stated ages from a quantile model
#'
#' Slopes are computed by contrast (prediction at exposure 1 minus
#' prediction at exposure 0, other variables fixed), never by reading a
#' main-effect coefficient, which in a spline-by-exposure model is the slope
#' at the lower boundary knot only.
#' @param object A `wgh_rq` object.
#' @param ages Ages (default: the object's anchor ages).
#' @param fixed Values of other variables.
#' @param level Interval level.
#' @return A tibble with `age`, `tau`, `estimate`, `boot_se`, `lower`, `upper`.
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#' f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#' fit <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(6, 9, 12, 15), B = 20)
#' wgh_slopes(fit, ages = c(7, 13))
#' }
#' @export
wgh_slopes <- function(object, ages = NULL, fixed = list(), level = 0.95) {
  L <- if (is.null(ages) && length(fixed) == 0) object$L else
    .slope_L(object$design, object$data, object$exposure, ages %||% object$anchor_ages, fixed)
  ages <- ages %||% object$anchor_ages
  est <- L %*% object$coefs
  out <- tibble::tibble(age = rep(ages, times = length(object$taus)), tau = rep(object$taus, each = length(ages)),
                        estimate = as.vector(est))
  if (!is.null(object$boot)) {
    dr <- apply(object$boot, 3, function(Bm) as.vector(L %*% Bm))
    a <- (1 - level) / 2
    out$boot_se <- apply(dr, 1, stats::sd)
    out$lower <- apply(dr, 1, stats::quantile, a); out$upper <- apply(dr, 1, stats::quantile, 1 - a)
    attr(out, "draws") <- t(dr)
  }
  out
}

#' @export
print.wgh_rq <- function(x, ...) {
  cli::cli_text("{.cls wgh_rq}: {length(x$taus)} quantile{?s}, {x$n_obs} visits from {x$n_children} children, {x$B_ok} bootstrap replicates")
  if (!is.null(x$slopes)) {
    s <- x$slopes; s$estimate <- round(s$estimate, 3)
    if ("lower" %in% names(s)) { s$lower <- round(s$lower, 3); s$upper <- round(s$upper, 3); s$boot_se <- round(s$boot_se, 3) }
    cli::cli_text("Slope of {.field {x$exposure}} by age and quantile:")
    print(s, n = 40)
  }
  invisible(x)
}

#' @export
predict.wgh_rq <- function(object, newdata, rearrange = TRUE, ...) {
  X <- .grid_matrix(object$design, as.data.frame(newdata))
  P <- X %*% object$coefs
  if (rearrange) P <- wgh_rearrange(P)
  P
}

#' Plot quantile regression slopes
#'
#' Shows how the association of the exposure with the outcome changes
#' across the outcome distribution (quantiles on the x axis) at each anchor
#' age. A flat line means the exposure shifts the whole distribution
#' equally. A rising line means it matters more for children in the upper
#' part of the distribution.
#' @param x A `wgh_rq` object from [wgh_rq()].
#' @param ages Anchor ages to show (default all).
#' @param ... Display options (see [wgh_plot_options()]); `show_ci = FALSE`
#'   hides the bootstrap bands.
#' @return A ggplot object.
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#' f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#' fit <- wgh_rq(d, f, taus = c(0.1, 0.25, 0.5, 0.75, 0.9), anchor_ages = c(6, 9, 12, 15), B = 30)
#' plot(fit)
#' plot(fit, ages = c(9, 12), show_ci = FALSE, y_label = "Change in HAZ per unit BAZ")
#' }
#' @export
plot.wgh_rq <- function(x, ages = NULL, ...) {
  o <- .popts(...)
  s <- x$slopes
  if (!is.null(ages)) s <- s[s$age %in% ages, ]
  p <- ggplot2::ggplot(s, ggplot2::aes(.data$tau, .data$estimate)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60")
  if ("lower" %in% names(s) && isTRUE(o$show_ci)) p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
                                                                            fill = "#56B4E9", alpha = o$alpha %||% 0.3)
  p <- p + ggplot2::geom_line(colour = "#0072B2", linewidth = o$line_width %||% 0.9) +
    ggplot2::geom_point(colour = "#0072B2", size = o$point_size %||% 1.4) +
    ggplot2::facet_wrap(~ .lab_num("Age", age), nrow = 1) +
    ggplot2::labs(x = "Quantile (tau)", y = paste("Slope of", x$exposure))
  .finish(p, o)
}

#' Tests across quantiles and between sexes
#'
#' `wgh_test_heterogeneity()` tests whether the exposure slope is equal at all
#' quantiles at one age (Wald test with the bootstrap covariance) and gives
#' the top-minus-bottom difference with a bootstrap interval.
#' `wgh_test_sex_difference()` compares the slopes of two independently
#' fitted models (girls minus boys) per quantile and jointly.
#' @param object,object_m,object_f `wgh_rq` objects with bootstrap draws
#'   (`object_m` boys, `object_f` girls).
#' @param age One anchor age.
#' @return Tibbles of test results.
#' @examplesIf rlang::is_installed("quantreg")
#' \donttest{
#' f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#' d <- growdat[growdat$age >= 5, ]
#' ages <- c(6, 9, 12, 15)
#' fm <- wgh_rq(d[d$sex == "Male", ], f, taus = c(0.1, 0.5, 0.9), anchor_ages = ages, B = 20)
#' ff <- wgh_rq(d[d$sex == "Female", ], f, taus = c(0.1, 0.5, 0.9), anchor_ages = ages, B = 20)
#' wgh_test_heterogeneity(ff, age = 9)
#' wgh_test_sex_difference(fm, ff, age = 9)$joint
#' }
#' @export
wgh_test_heterogeneity <- function(object, age) {
  s <- object$slopes; dr <- attr(s, "draws")
  if (is.null(dr)) .stop("The model has no bootstrap draws.")
  k <- which(s$age == age)
  beta <- s$estimate[k]; V <- stats::cov(dr[, k, drop = FALSE])
  m <- length(beta); C <- cbind(diag(m - 1), -1)
  dd <- C %*% beta
  stat <- as.numeric(t(dd) %*% solve(C %*% V %*% t(C)) %*% dd)
  tmb <- dr[, k[m]] - dr[, k[1]]
  tibble::tibble(age = age, chi_sq = stat, df = m - 1, p_value = stats::pchisq(stat, m - 1, lower.tail = FALSE),
                 top_minus_bottom = beta[m] - beta[1], lower = stats::quantile(tmb, 0.025), upper = stats::quantile(tmb, 0.975))
}

#' @rdname wgh_test_heterogeneity
#' @export
wgh_test_sex_difference <- function(object_m, object_f, age) {
  sm <- object_m$slopes; sf <- object_f$slopes
  km <- which(sm$age == age); kf <- which(sf$age == age)
  dd <- sf$estimate[kf] - sm$estimate[km]
  V <- stats::cov(attr(sf, "draws")[, kf, drop = FALSE]) + stats::cov(attr(sm, "draws")[, km, drop = FALSE])
  stat <- as.numeric(t(dd) %*% solve(V) %*% dd)
  se <- sqrt(diag(V))
  list(by_tau = tibble::tibble(age = age, tau = sf$tau[kf], difference = dd, se = se, lower = dd - 1.96 * se, upper = dd + 1.96 * se),
       joint = tibble::tibble(age = age, chi_sq = stat, df = length(dd), p_value = stats::pchisq(stat, length(dd), lower.tail = FALSE)))
}

#' Quantile crossing and monotone rearrangement
#' @param P A matrix of predicted quantiles, one row per case and one column
#'   per increasing quantile.
#' @return `wgh_crossing()`: the share of rows that are out of order.
#'   `wgh_rearrange()`: the matrix with each row sorted (Chernozhukov,
#'   Fernandez-Val and Galichon).
#' @examples
#' P <- rbind(c(1, 2, 3), c(1, 3, 2))
#' wgh_crossing(P)
#' wgh_rearrange(P)
#' @export
wgh_crossing <- function(P) mean(apply(P, 1, is.unsorted))

#' @rdname wgh_crossing
#' @export
wgh_rearrange <- function(P) {
  out <- t(apply(P, 1, sort))
  if (ncol(P) == 1) out <- t(out)
  dimnames(out) <- dimnames(P)
  out
}

#' Smooth quantile regression sensitivity check
#'
#' Fits `qgam` models with a varying-coefficient smooth of the exposure by
#' age, `y ~ s(age) + s(age, by = exposure) + extra`, and reads exposure
#' slopes by contrast. The by-smooth contains the linear exposure term, so
#' a separate parametric exposure term is not added (it would not be
#' identified, a problem met in the BMI and height-for-age distribution study (Ho 2026, medRxiv 2026.09.08.26362487)).
#' @param x Data.
#' @param outcome,exposure Variable names.
#' @param taus Quantiles.
#' @param ages Ages for the slopes.
#' @param extra Additional parametric terms (character), for example `"site"`.
#' @param k Basis dimension.
#' @return A tibble of slopes by age and quantile.
#' @examples
#' \donttest{
#' if (requireNamespace("qgam", quietly = TRUE)) {
#'   d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#'   wgh_qgam_check(d, taus = 0.5, ages = c(6, 12), k = 5)
#' }
#' }
#' @export
wgh_qgam_check <- function(x, outcome = "haz", exposure = "baz", taus = c(0.1, 0.5, 0.9),
                          ages = c(6, 9, 12, 15), extra = NULL, k = 8) {
  .need("qgam"); .need("mgcv")
  d <- as.data.frame(.gd(x, "age"))
  d <- d[stats::complete.cases(d[, c(outcome, exposure, "age", extra)]), ]
  f <- stats::as.formula(paste0(outcome, " ~ s(age, k = ", k, ") + s(age, by = ", exposure, ", k = ", k, ")",
                                if (length(extra)) paste(" +", paste(extra, collapse = " + ")) else ""))
  .bind(lapply(taus, function(tau) {
    fit <- qgam::qgam(f, data = d, qu = tau)
    base <- .base_grid(d, c("age", exposure, extra))
    g <- as.data.frame(lapply(base, function(v) rep(v, length(ages))), stringsAsFactors = FALSE)
    g$age <- ages
    g1 <- g; g0 <- g; g1[[exposure]] <- 1; g0[[exposure]] <- 0
    tibble::tibble(age = ages, tau = tau,
                   estimate = as.numeric(stats::predict(fit, g1) - stats::predict(fit, g0)))
  }))
}
