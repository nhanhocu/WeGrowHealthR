## Evaluation of probabilistic predictions (Book 2 Ch 15 and 16, the conditional growth reference study (Ho 2026, medRxiv 2026.09.23.26363771)) --

#' Child-level and site-level data splits
#'
#' Folds are formed from children, never from visits, so no child appears
#' in both training and test data. `folds = "site"` gives leave-one-site-out
#' splits for geographic validation.
#' @param x Data with `id` (or `pid`) and, for site splits, `site`.
#' @param folds Number of folds or `"site"`.
#' @param seed Random seed.
#' @return A named list of held-out child identifiers.
#' @examples
#' sp <- wgh_split(growdat, folds = 5)
#' lengths(sp)
#' @export
wgh_split <- function(x, folds = 5, seed = 2026) {
  d <- .gd(x, "id")
  if (identical(folds, "site")) {
    s <- d[!duplicated(d$id), ]
    return(lapply(split(s$id, as.character(s$site)), unique))
  }
  ids <- unique(d$id)
  .local_seed(seed)
  f <- sample(rep(seq_len(folds), length.out = length(ids)))
  stats::setNames(split(ids, f), paste0("fold", seq_len(folds)))
}

#' Check that features do not use information from the outcome period
#'
#' Two checks. With data, every child's latest feature age must be earlier
#' than the earliest outcome age. With windows only, the function reports
#' whether a feature window (for example the visits used to build growth
#' phenotypes) overlaps the target ages of a prediction model. The growth
#' phenotypes of Ho (2026, medRxiv 2026.09.05.26362315) used visits up to late
#' adolescence, so using them to predict height-for-age at 12, 15 and 18
#' years (as in the conditional reference and explainable prediction
#' studies) would leak outcome information.
#' @param feature_ages Data frame with `id` and `age` of feature visits, or a
#'   numeric range of the feature window.
#' @param outcome_ages Data frame with `id` and `age` of outcome visits, or a
#'   numeric vector of target ages.
#' @param tol Tolerance around target ages.
#' @return A list with `ok`, a message and, for data input, the offending
#'   children.
#' @examples
#' wgh_leakage_check(c(5, 18), c(12, 15, 18))
#' wgh_leakage_check(c(5, 9), c(12, 15, 18))
#' @export
wgh_leakage_check <- function(feature_ages, outcome_ages, tol = 1) {
  if (is.numeric(feature_ages) && is.numeric(outcome_ages)) {
    lo <- min(outcome_ages) - tol
    ok <- max(feature_ages) < lo
    hit <- outcome_ages[outcome_ages - tol <= max(feature_ages)]
    return(list(ok = ok, overlapping_targets = hit,
                message = if (ok) "No overlap between the feature window and the target ages." else
                  paste0("Leakage: the feature window reaches ", max(feature_ages), " y, overlapping target age(s) ",
                         paste(hit, collapse = ", "), ".")))
  }
  f <- stats::aggregate(age ~ id, data = as.data.frame(feature_ages), FUN = max)
  o <- stats::aggregate(age ~ id, data = as.data.frame(outcome_ages), FUN = min)
  m <- merge(f, o, by = "id", suffixes = c("_feature_max", "_outcome_min"))
  bad <- m[m$age_feature_max >= m$age_outcome_min, ]
  list(ok = nrow(bad) == 0, n_children = nrow(m), offending = tibble::as_tibble(bad),
       message = if (nrow(bad)) paste(nrow(bad), "children have feature visits at or after their outcome visit.") else
         "All feature visits precede the outcome.")
}

.pinball <- function(tau, obs, q) { d <- obs - q; mean(pmax(tau * d, (tau - 1) * d), na.rm = TRUE) }

## Integration weights for the CRPS. CRPS = 2 * integral over tau in (0, 1)
## of the pinball loss. The loss is interpolated linearly between the grid
## quantiles and taken to fall linearly to zero at tau = 0 and tau = 1, and
## the integral of that interpolant is a weighted sum of the losses at the
## grid quantiles (trapezoid rule). Unlike an equal-weight mean, this stays
## close to the exact CRPS on unevenly spaced grids.
.crps_weights <- function(taus) {
  t <- sort(taus)
  if (any(t <= 0 | t >= 1)) .stop("Quantile levels must lie strictly between 0 and 1.")
  K <- length(t); tt <- c(0, t, 1)
  w <- (tt[3:(K + 2)] - tt[1:K]) / 2
  w[match(taus, t)]
}

#' Proper scores for quantile predictions
#'
#' Scores a matrix of predicted quantiles against observations: mean pinball
#' loss over the grid, the continuous ranked probability score (CRPS), the weighted
#' interval score built from the 50%, 80% and 90% central intervals and the
#' median, empirical coverage and mean width of those intervals, and the
#' absolute error of the median.
#'
#' The CRPS equals twice the integral of the pinball loss over all quantile
#' levels between 0 and 1. It is approximated with the trapezoid rule over
#' the supplied grid: the loss is interpolated linearly between adjacent
#' quantiles, and in the tails below the lowest and above the highest
#' quantile it is taken to fall linearly to zero. Each quantile is therefore
#' weighted by the spacing of its neighbours, so unevenly spaced grids such
#' as `c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)` are scored
#' correctly. Because the tails are approximated, the CRPS of a short grid is
#' a slight underestimate, and the same grid should be used for every model
#' being compared. `pinball` is the plain mean over the grid.
#' @param obs Observed values.
#' @param qmat Matrix of predicted quantiles (one column per quantile).
#' @param taus The quantiles of the columns.
#' @return A one-row tibble.
#' @examples
#' set.seed(1); y <- rnorm(200)
#' taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
#' Q <- matrix(qnorm(taus), 200, 7, byrow = TRUE)
#' wgh_score(y, Q, taus)
#' @export
wgh_score <- function(obs, qmat, taus) {
  taus <- round(taus, 3)
  pin <- vapply(seq_along(taus), function(k) .pinball(taus[k], obs, qmat[, k]), numeric(1))
  col <- function(t) { j <- which(taus == round(t, 3)); if (length(j)) qmat[, j] else NULL }
  out <- tibble::tibble(pinball = mean(pin), crps = 2 * sum(.crps_weights(taus) * pin))
  med <- col(0.5)
  out$mae_median <- if (!is.null(med)) mean(abs(obs - med), na.rm = TRUE) else NA_real_
  lv <- list(c(0.25, 0.75), c(0.10, 0.90), c(0.05, 0.95))
  is_terms <- list(); alphas <- numeric()
  for (l in lv) {
    lo <- col(l[1]); hi <- col(l[2])
    nm <- round(100 * (l[2] - l[1]))
    if (is.null(lo) || is.null(hi)) { out[[paste0("coverage_", nm)]] <- NA_real_; out[[paste0("width_", nm)]] <- NA_real_; next }
    out[[paste0("coverage_", nm)]] <- mean(obs >= lo & obs <= hi, na.rm = TRUE)
    out[[paste0("width_", nm)]] <- mean(hi - lo, na.rm = TRUE)
    a <- 1 - (l[2] - l[1]); alphas <- c(alphas, a)
    is_terms[[length(is_terms) + 1]] <- (hi - lo) + (2 / a) * (lo - obs) * (obs < lo) + (2 / a) * (obs - hi) * (obs > hi)
  }
  out$wis <- if (!is.null(med) && length(is_terms) == 3) {
    K <- 3
    mean((0.5 * abs(obs - med) + Reduce(`+`, Map(function(t, a) t * a / 2, is_terms, alphas))) / (K + 0.5), na.rm = TRUE)
  } else NA_real_
  out
}

#' Calibration of quantile predictions
#'
#' For each quantile, the share of observations below the predicted
#' quantile. A calibrated model gives shares close to the nominal levels.
#' @param obs,qmat,taus As in [wgh_score()].
#' @param group Optional grouping vector (for example site).
#' @return A tibble of observed shares by quantile (and group).
#' @examples
#' # Predicted quantiles from a normal model against observed values
#' set.seed(1)
#' obs <- rnorm(500)
#' taus <- c(0.1, 0.5, 0.9)
#' qmat <- matrix(qnorm(taus), 500, 3, byrow = TRUE)
#' wgh_calibration(obs, qmat, taus)
#' @export
wgh_calibration <- function(obs, qmat, taus, group = NULL) {
  g <- if (is.null(group)) rep("All", length(obs)) else as.character(group)
  .bind(lapply(split(seq_along(obs), g), function(ii) {
    tibble::tibble(group = g[ii[1]], tau = taus,
                   observed_share = vapply(seq_along(taus), function(k) mean(obs[ii] <= qmat[ii, k], na.rm = TRUE), numeric(1)),
                   n = length(ii))
  }))
}

#' Conformalised quantile intervals
#'
#' Split-conformal adjustment (conformalised quantile regression) of a
#' central interval: the interval is widened or narrowed by the
#' finite-sample quantile of conformity scores on a calibration set, which
#' guarantees marginal coverage under exchangeability.
#' @param obs_cal Observed values in the calibration set.
#' @param lo_cal,hi_cal Predicted interval limits in the calibration set.
#' @param lo_new,hi_new Predicted limits for new cases.
#' @param level Target coverage.
#' @return A tibble with adjusted limits and the adjustment.
#' @examples
#' set.seed(2); y <- rnorm(500)
#' ci <- wgh_conformal(y[1:250], rep(-1, 250), rep(1, 250), rep(-1, 250), rep(1, 250), level = 0.9)
#' mean(y[251:500] >= ci$lower & y[251:500] <= ci$upper)
#' @export
wgh_conformal <- function(obs_cal, lo_cal, hi_cal, lo_new, hi_new, level = 0.9) {
  s <- pmax(lo_cal - obs_cal, obs_cal - hi_cal)
  n <- sum(!is.na(s))
  k <- min(1, ceiling((n + 1) * level) / n)
  qh <- stats::quantile(s, k, na.rm = TRUE, names = FALSE, type = 1)
  tibble::tibble(lower = lo_new - qh, upper = hi_new + qh, adjustment = qh)
}

#' Proper scores for each prediction
#'
#' The row-level version of [wgh_score()]: one score per observation, so two
#' predictors can be compared observation by observation with
#' [wgh_paired_scores()].
#' @inheritParams wgh_score
#' @return A tibble with one row per observation: `pinball` (mean over the
#'   quantile grid), `crps` (the trapezoid approximation described in
#'   [wgh_score()]), `wis` (weighted
#'   interval score from the 50%, 80% and 90% intervals and the median, when
#'   those quantiles are in the grid), `abs_error` of the median, and
#'   `covered_90` and `width_90` of the 90% interval.
#' @examples
#' set.seed(1); y <- rnorm(5)
#' taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
#' wgh_score_rows(y, matrix(qnorm(taus), 5, 7, byrow = TRUE), taus)
#' @export
wgh_score_rows <- function(obs, qmat, taus) {
  taus <- round(taus, 3)
  qmat <- as.matrix(qmat)
  pin <- sapply(seq_along(taus), function(k) { d <- obs - qmat[, k]; pmax(taus[k] * d, (taus[k] - 1) * d) })
  pin <- matrix(pin, nrow = length(obs))
  col <- function(t) { j <- which(taus == round(t, 3)); if (length(j)) qmat[, j] else NULL }
  med <- col(0.5)
  out <- tibble::tibble(pinball = rowMeans(pin), crps = 2 * as.vector(pin %*% .crps_weights(taus)),
                        abs_error = if (!is.null(med)) abs(obs - med) else NA_real_)
  lv <- list(c(0.25, 0.75), c(0.10, 0.90), c(0.05, 0.95))
  terms <- list()
  for (l in lv) {
    lo <- col(l[1]); hi <- col(l[2])
    if (is.null(lo) || is.null(hi)) next
    a <- 1 - (l[2] - l[1])
    terms[[length(terms) + 1]] <- a / 2 * ((hi - lo) + (2 / a) * (lo - obs) * (obs < lo) + (2 / a) * (obs - hi) * (obs > hi))
  }
  out$wis <- if (!is.null(med) && length(terms) == 3) (0.5 * abs(obs - med) + Reduce(`+`, terms)) / 3.5 else NA_real_
  lo <- col(0.05); hi <- col(0.95)
  out$covered_90 <- if (!is.null(lo) && !is.null(hi)) obs >= lo & obs <= hi else NA
  out$width_90 <- if (!is.null(lo) && !is.null(hi)) hi - lo else NA_real_
  out
}

#' Paired comparison of two predictors, child by child
#'
#' Compares two sets of scores computed on the same observations (for
#' example the CRPS of a new and an established reference for the same
#' held-out children). The mean difference is estimated with a bootstrap
#' that resamples children, keeping all of a child's rows together, so
#' repeated targets of the same child are not treated as independent (Book 2
#' Chapter 16). Pairing removes the variation between children, so much
#' smaller differences can be detected than by comparing two mean scores.
#'
#' @param score_new,score_old Scores of the two predictors for the same
#'   rows. For scores where lower is better (CRPS, WIS, pinball loss), a
#'   negative difference favours `score_new`.
#' @param ids Child identifier of each row.
#' @param B Bootstrap replicates.
#' @param level Interval level.
#' @param seed Random seed.
#' @return A one-row tibble with the mean scores, `mean_diff` (new minus
#'   old), its percentile bootstrap interval (`lower`, `upper`),
#'   `relative_change_pct` (difference as a percentage of the old mean), a
#'   two-sided bootstrap `p_value`, and the numbers of rows and children.
#'
#' @details The interval is the main result and should be reported. The
#'   p-value tests a mean difference of zero with the centred bootstrap: the
#'   bootstrap differences are shifted to have mean zero, which imitates the
#'   sampling distribution under no difference, and the p-value is the share
#'   of shifted differences at least as large in absolute value as the
#'   observed one, `(1 + #{|d* - mean(d*)| >= |d|}) / (B + 1)`. It therefore
#'   never equals zero, and its smallest possible value is `1 / (B + 1)`, so
#'   use `B` of at least 1000 when small p-values matter. Simulations in the
#'   package tests check that it rejects at about the nominal rate when the
#'   two predictors are equally good and has high power for a clear
#'   difference.
#' @examples
#' set.seed(2)
#' ids <- rep(1:100, each = 2)
#' old <- rexp(200); new <- old * 0.9 + rnorm(200, 0, 0.05)
#' wgh_paired_scores(new, old, ids, B = 200)
#' @export
wgh_paired_scores <- function(score_new, score_old, ids, B = 1000, level = 0.95, seed = 2026) {
  if (length(score_new) != length(score_old) || length(ids) != length(score_new))
    .stop("{.arg score_new}, {.arg score_old} and {.arg ids} must have the same length.")
  ok <- !is.na(score_new) & !is.na(score_old)
  dif <- score_new[ok] - score_old[ok]
  g <- split(seq_along(dif), as.character(ids[ok]))
  s <- vapply(g, function(i) sum(dif[i]), 0); n <- lengths(g)
  so <- vapply(g, function(i) sum(score_old[ok][i]), 0)
  .local_seed(seed)
  boots <- vapply(seq_len(B), function(b) { i <- sample.int(length(s), replace = TRUE); sum(s[i]) / sum(n[i]) }, 0)
  a <- (1 - level) / 2
  md <- sum(s) / sum(n)
  tibble::tibble(mean_new = mean(score_new[ok]), mean_old = mean(score_old[ok]), mean_diff = md,
                 lower = unname(stats::quantile(boots, a)), upper = unname(stats::quantile(boots, 1 - a)),
                 relative_change_pct = 100 * md / (sum(so) / sum(n)),
                 p_value = (1 + sum(abs(boots - mean(boots)) >= abs(md))) / (B + 1),
                 n_rows = sum(n), n_children = length(s))
}
