## Causal and mediation helpers (Book 2 Ch 14) -------------------------------

#' Exposure defined in a window that precedes the outcome
#'
#' Summarises an exposure over a window of ages that ends before the
#' outcome period, so that the exposure respects temporal order. Returns
#' one row per child.
#' @param x Growth data.
#' @param var Exposure variable.
#' @param window Age window of the exposure.
#' @param outcome_start Age at which the outcome period starts; the function
#'   stops if the window reaches it.
#' @param summary `"mean"`, `"first"`, `"last"` or `"max"`.
#' @return A tibble with `id`, `sex`, the exposure summary and the number of
#'   visits used.
#' @examples
#' ex <- wgh_exposure_window(growdat, "baz", window = c(6, 9), outcome_start = 12)
#' head(ex)
#' @export
wgh_exposure_window <- function(x, var = "baz", window = c(5, 9), outcome_start = NULL,
                               summary = c("mean", "first", "last", "max")) {
  summary <- match.arg(summary)
  if (!is.null(outcome_start) && window[2] >= outcome_start) .stop("The exposure window overlaps the outcome period.")
  d <- .gd(x, c("id", "age"))
  d <- d[d$age >= window[1] & d$age <= window[2] & !is.na(d[[var]]), ]
  d <- d[order(d$id, d$age), ]
  f <- switch(summary, mean = mean, first = function(z) z[1], last = function(z) z[length(z)], max = max)
  ag <- tapply(d[[var]], d$id, f); nv <- table(d$id)
  first <- d[!duplicated(d$id), ]
  tibble::tibble(id = names(ag), sex = first$sex[match(names(ag), first$id)],
                 !!paste0(var, "_", summary) := as.numeric(ag), n_visits = as.integer(nv[names(ag)]))
}

#' Mediation analysis with the parametric g-formula
#'
#' Estimates natural direct and indirect effects of an exposure on an
#' outcome through a mediator by Monte Carlo g-computation: the mediator
#' model is used to draw mediator values under exposure levels `a` and
#' `a_star`, and the outcome model predicts outcomes under the four
#' combinations. Confidence intervals come from a bootstrap over rows
#' (children). the pubertal velocity distribution study (Ho 2026, medRxiv 2026.09.04.26362313) used this to ask how much of the effect of
#' prepubertal BMI on pubertal velocity runs through timing.
#' @param data One row per child.
#' @param exposure,mediator,outcome Variable names.
#' @param covariates Confounders.
#' @param a,a_star Exposure levels compared (for example BAZ 1 versus 0).
#' @param mediator_family `"gaussian"` or `"binomial"`.
#' @param B Bootstrap replicates.
#' @param n_mc Monte Carlo draws per child.
#' @param seed Random seed.
#' @return A tibble with total, natural direct and natural indirect effects,
#'   the proportion mediated and bootstrap intervals.
#' @examples
#' set.seed(1); n <- 500
#' d <- data.frame(a = rnorm(n)); d$m <- 0.5 * d$a + rnorm(n); d$y <- 0.3 * d$a + 0.4 * d$m + rnorm(n)
#' wgh_mediation(d, "a", "m", "y", a = 1, a_star = 0, B = 50)
#' @export
wgh_mediation <- function(data, exposure, mediator, outcome, covariates = NULL, a = 1, a_star = 0,
                         mediator_family = c("gaussian", "binomial"), B = 200, n_mc = 20, seed = 2026) {
  mediator_family <- match.arg(mediator_family)
  d <- as.data.frame(data)
  d <- d[stats::complete.cases(d[, c(exposure, mediator, outcome, covariates)]), ]
  rhs_m <- paste(c(exposure, covariates), collapse = " + ")
  rhs_y <- paste(c(exposure, mediator, covariates), collapse = " + ")
  est <- function(dd) {
    mm <- stats::glm(stats::as.formula(paste(mediator, "~", rhs_m)), data = dd,
                     family = if (mediator_family == "gaussian") stats::gaussian() else stats::binomial())
    my <- stats::lm(stats::as.formula(paste(outcome, "~", rhs_y)), data = dd)
    sig <- if (mediator_family == "gaussian") stats::sigma(mm) else NA
    draw_m <- function(av) {
      nd <- dd[rep(seq_len(nrow(dd)), n_mc), ]; nd[[exposure]] <- av
      mu <- stats::predict(mm, nd, type = "response")
      nd[[mediator]] <- if (mediator_family == "gaussian") mu + stats::rnorm(length(mu), 0, sig) else stats::rbinom(length(mu), 1, mu)
      nd
    }
    ey <- function(av_y, av_m) { nd <- draw_m(av_m); nd[[exposure]] <- av_y; mean(stats::predict(my, nd)) }
    y11 <- ey(a, a); y10 <- ey(a, a_star); y00 <- ey(a_star, a_star)
    c(total = y11 - y00, nde = y10 - y00, nie = y11 - y10)
  }
  .local_seed(seed)
  e <- est(d)
  dr <- .wgh_map(seq_len(B), function(b, d) est(d[sample.int(nrow(d), replace = TRUE), ]), d = d, seed = seed + 1)
  dr <- do.call(cbind, dr)
  tibble::tibble(effect = c("Total effect", "Natural direct effect", "Natural indirect effect", "Proportion mediated"),
                 estimate = c(e, e[["nie"]] / e[["total"]]),
                 lower = c(apply(dr, 1, stats::quantile, 0.025), stats::quantile(dr["nie", ] / dr["total", ], 0.025)),
                 upper = c(apply(dr, 1, stats::quantile, 0.975), stats::quantile(dr["nie", ] / dr["total", ], 0.975)))
}
