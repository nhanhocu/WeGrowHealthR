## Quantile random forests as a benchmark for conditional references (Book 2 Ch 15)

#' Quantile random forest for conditional growth predictions
#'
#' Fits a quantile regression forest (`ranger` with `quantreg = TRUE`) of the
#' target z-score on the baseline features, separately by sex and target
#' age, and predicts any quantile for new children. It is a flexible,
#' assumption-light benchmark for the linear conditional references of
#' [wgh_condref()]: if the forest does not predict better out of sample, the
#' simpler, interpretable model is preferred (Book 2 Chapter 15).
#'
#' @param panel Output of [wgh_conditional_panel()].
#' @param formula Right-hand side with the baseline features.
#' @param taus Quantiles to predict.
#' @param num.trees,min.node.size Forest settings passed to
#'   `ranger::ranger()`.
#' @param min_n Smallest number of children needed to fit a cell.
#' @param seed Random seed of the forests.
#' @return An object of class `wgh_qrf` with one forest per sex and target
#'   age. `predict()` returns a matrix of quantiles (one row per child,
#'   rearranged to be monotone).
#' @section Next steps:
#' Compare the forest with the conditional reference out of sample with
#' [wgh_condref_cv()] (`forest = TRUE`) or child by child with
#' [wgh_condref_compare()].
#' @examples
#' \donttest{
#' if (requireNamespace("ranger", quietly = TRUE)) {
#'   cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
#'   qrf <- wgh_quantile_forest(cp, num.trees = 200)
#'   qrf
#'   round(predict(qrf, cp[1:3, ]), 2)
#' }
#' }
#' @export
wgh_quantile_forest <- function(panel, formula = ~ baseline_haz + baseline_baz + baseline_age,
                                taus = wgh_taus(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)),
                                num.trees = 500, min.node.size = 5, min_n = 30, seed = 2026) {
  .need("ranger")
  taus <- wgh_taus(taus)
  vars <- all.vars(formula)
  f <- stats::update(formula, target ~ .)
  cells <- split(as.data.frame(panel), list(panel$sex, panel$target_nominal), drop = TRUE)
  models <- lapply(cells, function(z) {
    z <- z[stats::complete.cases(z[, c("target", vars)]), , drop = FALSE]
    if (nrow(z) < min_n) return(NULL)
    fit <- ranger::ranger(f, data = z[, c("target", vars)], quantreg = TRUE, num.trees = num.trees,
                          min.node.size = min.node.size, seed = seed, num.threads = 1)
    list(sex = as.character(z$sex[1]), target_nominal = z$target_nominal[1], fit = fit, n = nrow(z))
  })
  models <- Filter(Negate(is.null), models)
  structure(list(models = models, taus = taus, formula = formula, vars = vars), class = "wgh_qrf")
}

#' @export
print.wgh_qrf <- function(x, ...) {
  cli::cli_text("{.cls wgh_qrf}: {length(x$models)} sex-by-target quantile forest{?s}, {length(x$taus)} quantiles")
  print(.bind(lapply(x$models, function(m) tibble::tibble(sex = m$sex, target = m$target_nominal, n = m$n))))
  invisible(x)
}

#' @rdname wgh_quantile_forest
#' @param object A `wgh_qrf` object.
#' @param newdata Rows with `sex`, `target_nominal` and the baseline
#'   features.
#' @param ... Unused.
#' @export
predict.wgh_qrf <- function(object, newdata, ...) {
  nd <- as.data.frame(newdata)
  P <- matrix(NA_real_, nrow(nd), length(object$taus), dimnames = list(NULL, sprintf("q%.3f", object$taus)))
  for (m in object$models) {
    k <- which(as.character(nd$sex) == m$sex & nd$target_nominal == m$target_nominal &
                 stats::complete.cases(nd[, object$vars, drop = FALSE]))
    if (!length(k)) next
    q <- stats::predict(m$fit, nd[k, object$vars, drop = FALSE], type = "quantiles", quantiles = object$taus)$predictions
    P[k, ] <- wgh_rearrange(matrix(q, nrow = length(k)))
  }
  P
}
