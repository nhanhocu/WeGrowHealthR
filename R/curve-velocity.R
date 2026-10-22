#' Per-child height velocity curves from a SITAR fit
#'
#' Evaluates every child's fitted velocity on a grid, either in chronological
#' age or in time relative to the child's own APHV (developmental time). By
#' default each child's curve is kept only within the ages that child was
#' observed (plus `extend` years), so curves are never read far outside the
#' data, a problem in the developmental-time panel of the original code of the pubertal velocity distribution study (Ho 2026, medRxiv 2026.09.04.26362313).
#'
#' @param fit A `wgh_sitar` object.
#' @param ids Children to include (default all).
#' @param time `"age"` (chronological) or `"aphv"` (years since own APHV).
#' @param grid Grid of ages or offsets.
#' @param observed_only Restrict each curve to the child's observed range.
#' @param extend Years allowed beyond the observed range.
#' @return A tibble with `id`, `age`, `time` (age or offset), `height` and
#'   `velocity`, and attribute `"aphv"`.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.1), observed_only = FALSE)
#' head(pan)
#' }
#' @export
wgh_velocity_panel <- function(fit, ids = NULL, time = c("age", "aphv"), grid = NULL,
                              observed_only = TRUE, extend = 0.5) {
  .need("nlme")
  time <- match.arg(time)
  m <- .sitar_model(fit)
  ind <- wgh_aphv(fit)$individual
  if (!is.null(ids)) ind <- ind[ind$id %in% ids, ]
  grid <- grid %||% (if (time == "age") seq(fit$age_range[1], fit$age_range[2], by = 0.1) else seq(-4, 4, by = 0.1))
  nd <- data.frame(id = rep(ind$id, each = length(grid)), g = rep(grid, times = nrow(ind)))
  nd$age <- if (time == "age") nd$g else nd$g + rep(ind$aphv, each = length(grid))
  if (observed_only) {
    rng <- tapply(fit$data$age, fit$data$id, range)
    lo <- vapply(rng[nd$id], `[`, 1, 1) - extend; hi <- vapply(rng[nd$id], `[`, 1, 2) + extend
    nd <- nd[nd$age >= lo & nd$age <= hi, ]
  }
  nd <- nd[nd$age >= fit$age_range[1] - extend & nd$age <= fit$age_range[2] + extend, ]
  ## Exact and vectorised: each child's curve is the population curve at the
  ## child's developmental age, t* = x0 + b0 + (t - x0 - b0 - b_i) exp(c_i),
  ## with velocity exp(c_i) times the population velocity at t*.
  fe <- nlme::fixef(m); x0 <- m$xoffset %||% 0
  b0 <- if ("b" %in% names(fe)) fe[["b"]] else 0
  k <- match(nd$id, ind$id)
  re <- nlme::ranef(m)
  ra <- if ("a" %in% names(re)) re$a[match(nd$id, rownames(re))] else 0
  rd <- if ("d" %in% names(re)) re$d[match(nd$id, rownames(re))] else 0
  tstar <- x0 + b0 + (nd$age - x0 - b0 - ind$b[k]) * exp(ind$c[k])
  span <- range(tstar, na.rm = TRUE) + c(-0.5, 0.5)
  g <- seq(span[1], span[2], by = 0.005)
  hp <- as.numeric(stats::predict(m, newdata = data.frame(age = g), level = 0))
  vp <- as.numeric(stats::predict(m, newdata = data.frame(age = g), level = 0, deriv = 1))
  nd$height <- ra + stats::approx(g, hp, tstar, rule = 2)$y + rd * (nd$age - x0)
  nd$velocity <- exp(ind$c[k]) * stats::approx(g, vp, tstar, rule = 2)$y + rd
  out <- tibble::tibble(id = nd$id, age = nd$age, time = nd$g, height = nd$height, velocity = nd$velocity)
  attr(out, "aphv") <- ind[, c("id", "aphv", "phv")]
  attr(out, "time") <- time
  out
}

#' Curve features of the pubertal spurt: peak width and duration
#'
#' For each child's velocity curve, finds the times at which velocity
#' crosses given levels on either side of the peak and reports the width
#' between them as a duration of the spurt (Ho 2026, medRxiv 2026.09.09.26362696).
#'
#' With `reference = "takeoff"` (default) the levels are fractions of the
#' spurt amplitude above the take-off velocity (the lowest velocity before
#' the peak): level = takeoff + fraction x (PHV - takeoff). With
#' `reference = "zero"` the levels are fractions of PHV itself, as in the
#' original code of the spurt duration study (Ho 2026, medRxiv 2026.09.09.26362696). Because prepubertal velocity is often above half of PHV,
#' the fraction-of-PHV definition frequently has no left crossing and the
#' duration degenerates to a censored value for most children. Crossings
#' that fall outside the curve are reported as censored, and curves whose
#' peak is at the edge of the grid are flagged as degenerate.
#'
#' @param panel Output of [wgh_velocity_panel()] (fine grid recommended).
#' @param thresholds Fractions.
#' @param reference `"takeoff"` or `"zero"`.
#' @return A tibble with one row per child: `phv`, `takeoff`, `peak_time`,
#'   and for each threshold the left and right crossing, the width and
#'   censoring flags, plus `degenerate`.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.05), observed_only = FALSE)
#' cf <- wgh_curve_features(pan)
#' summary(cf$width_p50)
#' # The legacy definition (fraction of peak velocity) is often censored
#' mean(wgh_curve_features(pan, thresholds = 0.5, reference = "zero")$censored_left_p50)
#' }
#' @export
wgh_curve_features <- function(panel, thresholds = c(0.25, 0.50, 0.75), reference = c("takeoff", "zero")) {
  reference <- match.arg(reference)
  rows <- lapply(split(panel, panel$id), function(z) {
    z <- z[order(z$time), ]
    k <- which.max(z$velocity); phv <- z$velocity[k]
    take <- if (k > 1) min(z$velocity[seq_len(k)]) else NA_real_
    out <- list(id = z$id[1], phv = phv, takeoff = take, peak_time = z$time[k],
                degenerate = k == 1 || k == nrow(z))
    for (th in thresholds) {
      lv <- if (reference == "zero") th * phv else take + th * (phv - take)
      left <- NA_real_; right <- NA_real_
      if (k > 1 && !is.na(lv)) {
        j <- utils::tail(which(z$velocity[seq_len(k)] < lv), 1)
        if (length(j)) left <- stats::approx(z$velocity[j:(j + 1)], z$time[j:(j + 1)], xout = lv)$y
      }
      if (k < nrow(z) && !is.na(lv)) {
        j <- which(z$velocity[k:nrow(z)] < lv)[1]
        if (!is.na(j)) { j <- j + k - 1; right <- stats::approx(z$velocity[(j - 1):j], z$time[(j - 1):j], xout = lv)$y }
      }
      tag <- paste0("p", round(100 * th))
      out[[paste0("left_", tag)]] <- left; out[[paste0("right_", tag)]] <- right
      out[[paste0("width_", tag)]] <- right - left
      out[[paste0("censored_left_", tag)]] <- is.na(left)
      out[[paste0("censored_right_", tag)]] <- is.na(right)
    }
    tibble::as_tibble(out)
  })
  .bind(rows)
}

#' Functional principal components of velocity curves
#'
#' A threshold-free description of curve shape, the robustness analysis of
#' the spurt duration study (Ho 2026, medRxiv 2026.09.09.26362696): functional PCA of the children's velocity curves on a common
#' grid using `fdapace`. The second component usually captures spurt width.
#' @param panel Output of [wgh_velocity_panel()].
#' @param max_k Maximum number of components.
#' @return A list with the `fdapace` fit, a tibble of scores per child and
#'   the variance explained.
#' @examples
#' \donttest{
#' if (requireNamespace("fdapace", quietly = TRUE)) {
#'   boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#'   fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#'   pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.1), observed_only = FALSE)
#'   fp <- wgh_fpca_curves(pan[pan$id %in% unique(pan$id)[1:150], ])
#'   fp$variance_explained
#' }
#' }
#' @export
wgh_fpca_curves <- function(panel, max_k = 4) {
  .need("fdapace")
  sp <- split(panel, panel$id)
  sp <- sp[vapply(sp, nrow, 1L) >= 5]
  Ly <- lapply(sp, function(z) z$velocity[order(z$time)])
  Lt <- lapply(sp, function(z) sort(z$time))
  fp <- fdapace::FPCA(Ly, Lt, optns = list(maxK = max_k, dataType = "Sparse", methodSelectK = max_k, verbose = FALSE))
  sc <- tibble::as_tibble(as.data.frame(fp$xiEst))
  names(sc) <- paste0("fpc", seq_len(ncol(sc)))
  list(fit = fp, scores = dplyr::bind_cols(tibble::tibble(id = names(sp)), sc),
       variance_explained = fp$cumFVE)
}
