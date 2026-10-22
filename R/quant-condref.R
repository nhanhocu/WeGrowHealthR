## Conditional growth references (Book 2 Ch 7, 15, 16, the conditional growth reference study (Ho 2026, medRxiv 2026.09.23.26363771)) -----------

#' Build a conditioning-window to target-age panel
#'
#' For each child, takes the visit nearest a preferred anchor age within the
#' conditioning window as the baseline, an optional second anchor for an
#' annualised slope, and the visit nearest each target age (within a
#' tolerance) as the outcome. This is the design of the conditional growth reference study (Ho 2026, medRxiv 2026.09.23.26363771). Children are
#' not dropped for lacking the second anchor.
#'
#' @param x Growth data with `haz` and `baz`.
#' @param window Conditioning window in years.
#' @param anchor,anchor2 Preferred baseline age and optional second anchor.
#' @param targets Target ages.
#' @param tol Tolerance around each target age.
#' @param outcome Outcome z-score (default `"haz"`).
#' @return One row per child and target age, with `baseline_age`,
#'   `baseline_haz`, `baseline_baz`, `haz_slope`, `target_nominal`,
#'   `target_age`, `target` (the outcome) and `followup`.
#' @examples
#' cp <- wgh_conditional_panel(growdat, targets = c(12, 15))
#' table(cp$target_nominal, cp$sex)
#' @export
wgh_conditional_panel <- function(x, window = c(5, 9), anchor = 6, anchor2 = 8, targets = c(12, 15, 18),
                                 tol = 1, outcome = "haz") {
  d <- .gd(x, c("id", "age", "sex"))
  d <- d[!is.na(d[[outcome]]), ]
  near <- function(z, a, t) {
    z <- z[abs(z$age - a) <= t, ]
    z <- z[order(z$id, abs(z$age - a)), ]
    z[!duplicated(z$id), ]
  }
  pool <- d[d$age >= window[1] & d$age <= window[2], ]
  b <- near(pool, anchor, diff(window) / 2)
  base <- tibble::tibble(id = b$id, sex = b$sex, site = if ("site" %in% names(b)) b$site else NA,
                         baseline_age = b$age, baseline_haz = b[[outcome]],
                         baseline_baz = if ("baz" %in% names(b)) b$baz else NA_real_)
  if (!is.null(anchor2)) {
    s2 <- near(pool, anchor2, diff(window) / 2)
    m <- match(base$id, s2$id)
    sa <- s2$age[m]; sh <- s2[[outcome]][m]
    ok <- !is.na(sa) & abs(sa - base$baseline_age) >= 0.75
    base$haz_slope <- ifelse(ok, (sh - base$baseline_haz) / (sa - base$baseline_age), NA_real_)
  }
  out <- .bind(lapply(targets, function(ta) {
    t <- near(d[d$age > window[2], ], ta, tol)
    m <- match(base$id, t$id)
    keep <- !is.na(m)
    dplyr::bind_cols(base[keep, ], tibble::tibble(target_nominal = ta, target_age = t$age[m[keep]],
                                                   target = t[[outcome]][m[keep]]))
  }))
  out$followup <- out$target_age - out$baseline_age
  out
}

#' Fit conditional growth references
#'
#' Quantile regression of the target-age z-score on the baseline features,
#' fitted separately by sex and target age over a grid of quantiles. The
#' predicted quantiles for a new child form a personalised growth reference.
#' Benchmarks fitted alongside: the unconditional reference (target
#' quantiles ignoring the baseline), a persistence model (baseline plus the
#' empirical distribution of change) and the WHO band (standard normal
#' quantiles).
#'
#' @param panel Output of [wgh_conditional_panel()].
#' @param formula Right-hand side of the conditional model.
#' @param taus Quantile grid (should include 0.05, 0.10, 0.25, 0.50, 0.75,
#'   0.90 and 0.95 for scoring).
#' @param forest Also fit a quantile random forest benchmark
#'   ([wgh_quantile_forest()], needs `ranger`), available in `predict()` as
#'   `type = "forest"`.
#' @return An object of class `wgh_condref`.
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(12, 15))
#' cr <- wgh_condref(cp)
#' cr
#' }
#' @export
wgh_condref <- function(panel, formula = ~ baseline_haz + baseline_baz + baseline_age,
                       taus = wgh_taus(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)), forest = FALSE) {
  .need("quantreg")
  taus <- wgh_taus(taus)
  vars <- all.vars(formula)
  cells <- split(panel, list(panel$sex, panel$target_nominal), drop = TRUE)
  models <- lapply(cells, function(z) {
    z <- as.data.frame(z[stats::complete.cases(z[, c("target", vars)]), ])
    if (nrow(z) < 30) return(NULL)
    f <- stats::update(formula, target ~ .)
    des <- .rq_design(f, transform(z, id = z$id))
    list(sex = as.character(z$sex[1]), target_nominal = z$target_nominal[1], design = des,
         coefs = .fit_rq_matrix(des$X, des$y, taus), n = nrow(z),
         uncond = stats::quantile(z$target, taus, names = FALSE),
         change = stats::quantile(z$target - z$baseline_haz, taus, names = FALSE))
  })
  models <- Filter(Negate(is.null), models)
  qrf <- if (forest) wgh_quantile_forest(panel, formula, taus) else NULL
  structure(list(models = models, taus = taus, formula = formula, forest = qrf), class = "wgh_condref")
}

#' @export
print.wgh_condref <- function(x, ...) {
  cli::cli_text("{.cls wgh_condref}: {length(x$models)} sex-by-target model{?s}, {length(x$taus)} quantiles")
  tab <- .bind(lapply(x$models, function(m) tibble::tibble(sex = m$sex, target = m$target_nominal, n = m$n)))
  print(tab)
  invisible(x)
}

#' Predict conditional quantiles for new children
#' @param object A `wgh_condref` object.
#' @param newdata Rows with `sex`, `target_nominal` and the baseline
#'   features.
#' @param type `"conditional"` (default), `"unconditional"`, `"persistence"`,
#'   `"who"` or `"forest"` (when the references were fitted with
#'   `forest = TRUE`).
#' @param ... Unused.
#' @return A matrix with one row per case and one column per quantile
#'   (rearranged to be monotone).
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
#' cr <- wgh_condref(cp)
#' # Predicted centiles at age 10 for the first three children
#' round(predict(cr, cp[cp$target_nominal == 10, ][1:3, ]), 2)
#' # The same children under the WHO and unconditional references
#' round(predict(cr, cp[cp$target_nominal == 10, ][1:3, ], type = "who"), 2)
#' }
#' @export
predict.wgh_condref <- function(object, newdata, type = c("conditional", "unconditional", "persistence", "who", "forest"), ...) {
  type <- match.arg(type)
  nd <- as.data.frame(newdata)
  if (type == "forest") {
    if (is.null(object$forest)) .stop("No quantile forest in this object. Refit with {.code wgh_condref(..., forest = TRUE)}.")
    return(predict(object$forest, nd))
  }
  P <- matrix(NA_real_, nrow(nd), length(object$taus), dimnames = list(NULL, sprintf("q%.3f", object$taus)))
  for (m in object$models) {
    k <- which(as.character(nd$sex) == m$sex & nd$target_nominal == m$target_nominal)
    if (!length(k)) next
    P[k, ] <- switch(type,
      conditional = wgh_rearrange(.grid_matrix(m$design, nd[k, , drop = FALSE]) %*% m$coefs),
      unconditional = matrix(m$uncond, length(k), length(object$taus), byrow = TRUE),
      persistence = outer(nd$baseline_haz[k], m$change, `+`),
      who = matrix(stats::qnorm(object$taus), length(k), length(object$taus), byrow = TRUE))
  }
  P
}

#' Fan chart of a child's conditional reference
#'
#' Shows where a child is expected to be at each target age given what is
#' known about the child at baseline. The fan opens at the baseline
#' measurement (a single point, since that value is known) and widens to the
#' predicted 25th to 75th and 5th to 95th centile ranges at each target age.
#' For comparison it shows the WHO -2 to +2 SD band, which ignores the
#' child's history, and optionally the unconditional range of the cohort at
#' the same ages. Later measurements of the child can be overlaid to see
#' whether growth followed the expected course.
#'
#' @param object A `wgh_condref` object.
#' @param child A one-row data frame with `sex` and the baseline features
#'   used in the model (by default `baseline_age`, `baseline_haz` and
#'   `baseline_baz`), for example one row of [wgh_conditional_panel()].
#' @param targets Target ages to show (default all fitted target ages).
#' @param observed Optional data frame of the child's later measurements
#'   with `age` and the outcome z-score column (`haz` by default) or
#'   `target`.
#' @param outcome Name of the outcome column in `observed`.
#' @param bands Outer and inner central ranges, as lower-tail
#'   probabilities (default 5 to 95 and 25 to 75).
#' @param show_who Show the WHO -2 to +2 SD band.
#' @param show_unconditional Show the cohort's unconditional range (dashed).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @section Next steps:
#' Use [wgh_condref_centile()] to turn an observed later value into a
#' conditional centile, and [wgh_plot_condref_calibration()] to check that
#' the predicted ranges have the coverage they claim.
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12, 14))
#' cr <- wgh_condref(cp)
#' child <- cp[cp$target_nominal == 10, ][1, ]
#' later <- growdat[growdat$pid == child$id & growdat$age > 9, c("age", "haz")]
#' wgh_plot_fan(cr, child, observed = later)
#' wgh_plot_fan(cr, child, observed = later, show_unconditional = TRUE, title = "Expected height path")
#' }
#' @export
wgh_plot_fan <- function(object, child, targets = NULL, observed = NULL, outcome = "haz",
                         bands = c(0.05, 0.25), show_who = TRUE, show_unconditional = FALSE, ...) {
  o <- .popts(...)
  child <- as.data.frame(child)[1, , drop = FALSE]
  sx <- as.character(child$sex)
  fitted_t <- sort(unique(unlist(lapply(object$models, function(m) if (m$sex == sx) m$target_nominal))))
  targets <- intersect(targets %||% fitted_t, fitted_t)
  if (!length(targets)) .stop("No fitted model for {sx} at the requested target ages.")
  nd <- child[rep(1, length(targets)), , drop = FALSE]
  nd$target_nominal <- targets
  tau <- object$taus
  qcol <- function(P, t) P[, which.min(abs(tau - t))]
  mk <- function(P) tibble::tibble(age = targets, lo1 = qcol(P, bands[1]), hi1 = qcol(P, 1 - bands[1]),
                                   lo2 = qcol(P, bands[2]), hi2 = qcol(P, 1 - bands[2]), q50 = qcol(P, 0.5))
  fan <- mk(predict(object, nd))
  b0 <- tibble::tibble(age = child$baseline_age, lo1 = child$baseline_haz, hi1 = child$baseline_haz,
                       lo2 = child$baseline_haz, hi2 = child$baseline_haz, q50 = child$baseline_haz)
  fan <- rbind(b0, fan)
  pc <- function(x) paste0(round(100 * x), "")
  p <- ggplot2::ggplot(fan, ggplot2::aes(.data$age))
  if (show_who) p <- p + ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = -2, ymax = 2, fill = "grey92") +
    ggplot2::geom_hline(yintercept = 0, colour = "grey75")
  p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo1, ymax = .data$hi1), fill = "#56B4E9", alpha = o$alpha %||% 0.35) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo2, ymax = .data$hi2), fill = "#0072B2", alpha = (o$alpha %||% 0.35) + 0.1) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50), colour = "#0072B2", linewidth = o$line_width %||% 1)
  if (show_unconditional) {
    un <- mk(predict(object, nd, type = "unconditional"))
    p <- p + ggplot2::geom_line(data = un, ggplot2::aes(y = .data$lo1), linetype = 2, colour = "grey30") +
      ggplot2::geom_line(data = un, ggplot2::aes(y = .data$hi1), linetype = 2, colour = "grey30")
  }
  p <- p + ggplot2::geom_point(data = b0, ggplot2::aes(.data$age, .data$q50), size = 3, shape = 21, fill = "white")
  if (!is.null(observed)) {
    ob <- as.data.frame(observed)
    yv <- if (outcome %in% names(ob)) outcome else "target"
    if ("target_age" %in% names(ob) && !"age" %in% names(ob)) ob$age <- ob$target_age
    ob <- ob[ob$age >= child$baseline_age, , drop = FALSE]
    if (nrow(ob) > 1) p <- p + ggplot2::geom_line(data = ob, ggplot2::aes(.data$age, .data[[yv]]), colour = "#D55E00", linetype = 3)
    p <- p + ggplot2::geom_point(data = ob, ggplot2::aes(.data$age, .data[[yv]]), colour = "#D55E00", size = o$point_size %||% 2.5)
  }
  cap <- paste0("White point: baseline. Blue: conditional ", pc(bands[2]), "-", pc(1 - bands[2]), "% and ",
                pc(bands[1]), "-", pc(1 - bands[1]), "% ranges.\n",
                paste(c(if (show_who) "Grey band: WHO -2 to +2 SD", if (show_unconditional) "dashed: unconditional range",
                        if (!is.null(observed)) "orange: observed"), collapse = ", "))
  p <- p + ggplot2::scale_x_continuous(breaks = seq(0, 20, 1)) +
    ggplot2::labs(x = "Age (years)", y = "Height-for-age z-score", caption = cap,
                  title = paste0("Conditional growth reference, ", tolower(sx)))
  .finish(p, o)
}

#' Conditional centile of an observed later measurement
#'
#' Locates each observed target value within its predicted conditional
#' distribution. A conditional centile near 50 means the child grew as
#' expected given the baseline. Values below the 3rd or above the 97th
#' centile flag growth that departs from the child's own expected course,
#' even when the child is still inside the WHO -2 to +2 SD band.
#'
#' @param object A `wgh_condref` object.
#' @param newdata Rows with `sex`, `target_nominal`, the baseline features
#'   and the observed `target`.
#' @param type Reference used (see [predict.wgh_condref()]).
#' @param flag Lower centile for flagging (the upper is `100 - flag`).
#' @return `newdata` with `cond_centile` (0 to 100), `cond_z` (the normal
#'   score of the centile) and `cond_flag` (`"below"`, `"within"`,
#'   `"above"`).
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12, 14))
#' cr <- wgh_condref(cp)
#' sc <- wgh_condref_centile(cr, cp)
#' table(sc$cond_flag)
#' # Children within the WHO band but outside their own expected range
#' flagged <- abs(sc$target) < 2 & sc$cond_flag != "within"
#' sc[flagged, c("id", "target_nominal", "target", "cond_centile")]
#' }
#' @export
wgh_condref_centile <- function(object, newdata, type = "conditional", flag = 3) {
  nd <- as.data.frame(newdata)
  P <- predict(object, nd, type = type)
  tau <- object$taus
  cen <- vapply(seq_len(nrow(nd)), function(i) {
    q <- P[i, ]; y <- nd$target[i]
    if (anyNA(q) || is.na(y)) return(NA_real_)
    zt <- stats::qnorm(tau); k <- length(q)
    ext <- function(i, j) zt[i] + (zt[j] - zt[i]) / max(q[j] - q[i], 1e-6) * (y - q[i])
    z <- if (y < q[1]) ext(1, 2) else if (y > q[k]) ext(k - 1, k) else stats::approx(q, zt, xout = y, ties = "ordered")$y
    stats::pnorm(z)
  }, 0)
  nd$cond_centile <- 100 * cen
  nd$cond_z <- stats::qnorm(pmin(pmax(cen, 1e-4), 1 - 1e-4))
  nd$cond_flag <- ifelse(is.na(cen), NA_character_, ifelse(100 * cen < flag, "below", ifelse(100 * cen > 100 - flag, "above", "within")))
  tibble::as_tibble(nd)
}

#' Calibration of conditional growth references
#'
#' For every quantile in the grid, the share of observed target values that
#' fall below the predicted quantile. A well calibrated reference lies on the
#' diagonal: 10% of children below the predicted 10th centile, 50% below the
#' median, and so on. Predictions are made out of fold when `folds` is set,
#' so the check is honest.
#'
#' @param panel Output of [wgh_conditional_panel()].
#' @param folds Number of child-level folds (`NULL` scores in sample).
#' @param types Reference types to compare (`"conditional"`,
#'   `"unconditional"`, `"persistence"`, `"who"`, `"forest"`).
#' @param formula,taus Passed to [wgh_condref()].
#' @param seed Random seed for the folds.
#' @param plot Return a plot (`TRUE`) or the table.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object, or a tibble with `model`, `sex`, `tau` and
#'   `observed_share`.
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12, 14))
#' wgh_plot_condref_calibration(cp, folds = 3)
#' }
#' @export
wgh_plot_condref_calibration <- function(panel, folds = 5, types = c("conditional", "unconditional", "who"),
                                         formula = ~ baseline_haz + baseline_baz + baseline_age,
                                         taus = wgh_taus(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)),
                                         seed = 2026, plot = TRUE, ...) {
  o <- .popts(...)
  pred_all <- function(tr, te) {
    cr <- wgh_condref(tr, formula, taus, forest = "forest" %in% types)
    .bind(lapply(types, function(ty) {
      P <- predict(cr, te, type = ty)
      ok <- stats::complete.cases(P) & !is.na(te$target)
      .bind(lapply(seq_along(cr$taus), function(j) tibble::tibble(model = ty, sex = as.character(te$sex[ok]), tau = cr$taus[j],
                                                                 below = te$target[ok] <= P[ok, j])))
    }))
  }
  if (is.null(folds)) long <- pred_all(panel, panel) else {
    sp <- wgh_split(panel, folds = folds, seed = seed)
    long <- .bind(lapply(sp, function(ids) pred_all(panel[!panel$id %in% ids, ], panel[panel$id %in% ids, ])))
  }
  tab <- stats::aggregate(below ~ model + sex + tau, data = long, FUN = mean)
  names(tab)[names(tab) == "below"] <- "observed_share"
  tab <- tibble::as_tibble(tab)
  if (!plot) return(tab)
  tab$model <- factor(tab$model, levels = types)
  p <- ggplot2::ggplot(tab, ggplot2::aes(.data$tau, .data$observed_share, colour = .data$model)) +
    ggplot2::geom_abline(linetype = 2, colour = "grey50") +
    ggplot2::geom_line(linewidth = o$line_width %||% 0.8) + ggplot2::geom_point(size = o$point_size %||% 2) +
    ggplot2::facet_wrap(~sex) + scale_colour_wgh() +
    ggplot2::scale_x_continuous(breaks = c(0.05, 0.25, 0.5, 0.75, 0.95), labels = c(5, 25, 50, 75, 95)) +
    ggplot2::scale_y_continuous(labels = function(v) round(100 * v)) +
    ggplot2::labs(x = "Predicted centile", y = "Observed share below (%)", colour = NULL,
                  title = "Calibration of growth references",
                  caption = if (is.null(folds)) "In-sample predictions." else paste0("Out-of-fold predictions, ", folds, " folds."))
  .finish(p, o)
}

#' Cross-validate conditional references with child-level or site-level folds
#'
#' Splits children into folds (or leaves one site out at a time), fits
#' [wgh_condref()] on the training part and scores the conditional model and
#' the benchmarks on the held-out part with [wgh_score()].
#' @param panel Output of [wgh_conditional_panel()].
#' @param folds Number of child-level folds, or `"site"` for
#'   leave-one-site-out.
#' @param formula,taus Passed to [wgh_condref()].
#' @param seed Random seed.
#' @param forest Also score a quantile random forest (`model = "forest"`,
#'   needs `ranger`).
#' @return A tibble of scores by fold, model, sex and target age. Lower
#'   CRPS and WIS are better, and `coverage_90` should be close to 0.90.
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
#' cv <- wgh_condref_cv(cp, folds = 3)
#' aggregate(cbind(crps, wis, coverage_90) ~ model, data = cv, FUN = mean)
#' }
#' @export
wgh_condref_cv <- function(panel, folds = 5, formula = ~ baseline_haz + baseline_baz + baseline_age,
                          taus = wgh_taus(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)), seed = 2026,
                          forest = FALSE) {
  types <- c("conditional", "unconditional", "persistence", "who", if (forest) "forest")
  sp <- wgh_split(panel, folds = folds, seed = seed)
  ## folds run in parallel when a parallel plan is active
  .bind(.wgh_map(seq_along(sp), function(k, panel, sp, formula, taus, types) {
    tr <- panel[!panel$id %in% sp[[k]], ]; te <- panel[panel$id %in% sp[[k]], ]
    cr <- wgh_condref(tr, formula, taus, forest = "forest" %in% types)
    .bind(lapply(types, function(type) {
      P <- predict(cr, te, type = type)
      .bind(lapply(split(seq_len(nrow(te)), list(te$sex, te$target_nominal), drop = TRUE), function(ii) {
        ok <- ii[stats::complete.cases(P[ii, , drop = FALSE])]
        if (length(ok) < 5) return(NULL)
        sc <- wgh_score(te$target[ok], P[ok, , drop = FALSE], cr$taus)
        dplyr::bind_cols(tibble::tibble(fold = names(sp)[k], model = type, sex = as.character(te$sex[ok[1]]),
                                        target = te$target_nominal[ok[1]], n = length(ok)), sc)
      }))
    }))
  }, panel = panel, sp = sp, formula = formula, taus = taus, types = types, seed = seed,
  packages = .installed(c("quantreg", "ranger"))))
}

#' Compare growth references child by child
#'
#' Fits the references on part of the children and predicts the others
#' (child-level cross-validation, as in [wgh_condref_cv()]), scores every
#' held-out prediction with [wgh_score_rows()], and compares each reference
#' with a chosen reference by paired differences with a child-level
#' bootstrap ([wgh_paired_scores()]). This answers whether one reference is
#' better than another for the same children, with an honest interval, which
#' a comparison of average scores cannot (Book 2 Chapter 16).
#'
#' @inheritParams wgh_condref_cv
#' @param models References to compare: any of `"conditional"`,
#'   `"unconditional"`, `"persistence"`, `"who"` and `"forest"` (a quantile
#'   random forest, needs `ranger`).
#' @param reference The reference every model is compared with.
#' @param score `"crps"`, `"wis"`, `"pinball"` or `"abs_error"` (lower is
#'   better for all).
#' @param by Optional grouping, for example `c("sex", "target_nominal")`.
#' @param B Bootstrap replicates for the paired intervals.
#' @return A tibble with one row per model (and group): the mean scores of
#'   the model and the reference, the mean paired difference with its
#'   interval, the relative change and a p-value. A negative difference means
#'   the model scores better than the reference. The out-of-fold row-level
#'   scores are attached as attribute `"rows"`.
#' @examplesIf rlang::is_installed(c("quantreg", "ranger"))
#' \donttest{
#' cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
#' wgh_condref_compare(cp, models = c("conditional", "persistence"), reference = "who",
#'                     folds = 3, B = 200)
#' }
#' @export
wgh_condref_compare <- function(panel, models = c("conditional", "persistence", "unconditional"), reference = "who",
                                score = c("crps", "wis", "pinball", "abs_error"), by = NULL, folds = 5,
                                formula = ~ baseline_haz + baseline_baz + baseline_age,
                                taus = wgh_taus(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)),
                                B = 1000, seed = 2026) {
  score <- match.arg(score)
  types <- unique(c(models, reference))
  ok_types <- c("conditional", "unconditional", "persistence", "who", "forest")
  if (any(!types %in% ok_types)) .stop("Unknown reference type{?s}: {.val {setdiff(types, ok_types)}}.")
  panel <- as.data.frame(panel)
  panel$.row <- seq_len(nrow(panel))
  sp <- wgh_split(panel, folds = folds, seed = seed)
  rows <- .bind(.wgh_map(seq_along(sp), function(k, panel, sp, formula, taus, types) {
    tr <- panel[!panel$id %in% sp[[k]], ]; te <- panel[panel$id %in% sp[[k]], ]
    cr <- wgh_condref(tr, formula, taus, forest = "forest" %in% types)
    .bind(lapply(types, function(ty) {
      P <- predict(cr, te, type = ty)
      sc <- wgh_score_rows(te$target, P, cr$taus)
      dplyr::bind_cols(tibble::tibble(.row = te$.row, id = te$id, sex = as.character(te$sex),
                                      target_nominal = te$target_nominal, model = ty, fold = names(sp)[k]), sc)
    }))
  }, panel = panel, sp = sp, formula = formula, taus = taus, types = types, seed = seed,
  packages = .installed(c("quantreg", "ranger"))))
  wide <- function(ty) { z <- rows[rows$model == ty, ]; z[order(z$.row), ] }
  ref <- wide(reference)
  grp <- if (is.null(by)) list(all = seq_len(nrow(ref))) else split(seq_len(nrow(ref)), ref[, by, drop = FALSE], drop = TRUE)
  out <- .bind(lapply(setdiff(models, reference), function(m) {
    mm <- wide(m)
    .bind(lapply(names(grp), function(gn) {
      i <- grp[[gn]]
      r <- wgh_paired_scores(mm[[score]][i], ref[[score]][i], ref$id[i], B = B, seed = seed)
      g <- if (is.null(by)) NULL else ref[i[1], by, drop = FALSE]
      dplyr::bind_cols(tibble::tibble(model = m, reference = reference, score = score), g, r)
    }))
  }))
  attr(out, "rows") <- rows
  out
}
