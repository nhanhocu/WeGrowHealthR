## Linear quantile mixed models (Book 2 Ch 5)

.lqmm_fit_one <- function(tau, data, fixed, iter) {
  ladder <- list(list(method = "gs", LP_max_iter = iter),
                 list(method = "gs", LP_max_iter = iter * 4, LP_tol_ll = 1e-4, UP_max_iter = 40),
                 list(method = "df", LP_max_iter = iter * 4))
  log <- character(); best <- NULL
  for (step in seq_along(ladder)) {
    ctl <- do.call(lqmm::lqmmControl, ladder[[step]])
    warns <- character()
    fit <- tryCatch(withCallingHandlers(
      lqmm::lqmm(fixed = fixed, random = ~1, group = .grp, tau = tau, data = data, control = ctl, na.action = stats::na.omit),
      warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
      error = function(e) { log <<- c(log, paste0("step ", step, ": ", conditionMessage(e))); NULL })
    if (!is.null(fit)) {
      conv <- !any(grepl("converge", warns))
      if (length(warns)) log <- c(log, paste0("step ", step, ": ", unique(warns)))
      best <- list(fit = fit, step = step, method = ladder[[step]]$method, converged = conv, log = log)
      if (conv) return(best)
    }
  }
  best %||% list(fit = NULL, step = NA, method = NA, converged = FALSE, log = log)
}

#' Linear quantile mixed model over a grid of quantiles
#'
#' Fits `lqmm::lqmm()` with a random intercept per child at each quantile,
#' with a retry ladder (more iterations and a looser tolerance, then the
#' derivative-free optimiser) that moves to the next step whenever lqmm
#' reports non-convergence or fails, a convergence log, slopes of
#' the exposure at stated ages by contrast and a child-level cluster
#' bootstrap. Worker functions carry only what they need, which avoids the
#' gigabyte-sized parallel exports documented in the BMI and height-for-age distribution study (Ho 2026, medRxiv 2026.09.08.26362487).
#'
#' @inheritParams wgh_rq
#' @param iter Initial `LP_max_iter` (default from the run mode).
#' @return An object of class `wgh_lqmm` (like `wgh_rq`, with `fits` and a
#'   `convergence` table).
#' @examplesIf rlang::is_installed("lqmm")
#' \donttest{
#' d <- growdat[growdat$sex == "Male" & growdat$age >= 5, ]
#' d <- d[d$pid %in% names(which(table(d$pid) >= 3)), ]
#' f <- haz ~ splines::ns(age, df = 3) * baz
#' fit <- wgh_lqmm(d, f, taus = c(0.25, 0.5, 0.75), anchor_ages = c(7, 10, 13), B = 0)
#' fit$slopes
#' }
#' @export
wgh_lqmm <- function(x, formula, taus = wgh_taus("headline"), exposure = "baz",
                    anchor_ages = c(6, 9, 12, 15), fixed = list(), B = wgh_opt("B"),
                    iter = wgh_opt("lqmm_iter"), seed = 2026) {
  .need("lqmm")
  d <- as.data.frame(.gd(x, "id"))
  vars <- intersect(unique(c(all.vars(formula), "id")), names(d))
  d <- d[stats::complete.cases(d[, vars, drop = FALSE]), vars, drop = FALSE]
  formula <- .slim_formula(formula, d)
  d$.grp <- as.integer(factor(d$id))
  taus <- wgh_taus(taus)
  des <- .rq_design(formula, d)
  ## the quantile grid is fitted in parallel when a parallel plan is active
  fits <- .wgh_map(taus, function(t, data, fixed, iter) .lqmm_fit_one(t, data = data, fixed = fixed, iter = iter),
                   data = d, fixed = formula, iter = iter, seed = seed, packages = "lqmm")
  conv <- tibble::tibble(tau = taus, ok = vapply(fits, function(f) !is.null(f$fit), logical(1)),
                         converged = vapply(fits, `[[`, logical(1), "converged"),
                         ladder_step = vapply(fits, function(f) as.numeric(f$step), numeric(1)),
                         method = vapply(fits, function(f) as.character(f$method), character(1)),
                         messages = vapply(fits, function(f) paste(f$log, collapse = " | "), character(1)))
  cm <- vapply(fits, function(f) if (is.null(f$fit)) rep(NA_real_, ncol(des$X)) else as.numeric(stats::coef(f$fit)), numeric(ncol(des$X)))
  coefs <- matrix(cm, nrow = ncol(des$X), dimnames = list(colnames(des$X), sprintf("tau_%.3f", taus)))
  L <- if (exposure %in% des$vars) .slope_L(des, d, exposure, anchor_ages, fixed) else NULL
  boot <- NULL
  if (B > 0) {
    rows <- split(seq_len(nrow(d)), d$id)
    one <- function(b, d, rows, taus, formula, iter, p) {
      pick <- sample.int(length(rows), length(rows), replace = TRUE)
      bd <- d[unlist(rows[pick], use.names = FALSE), , drop = FALSE]
      bd$.grp <- rep(seq_along(pick), lengths(rows[pick]))
      vapply(taus, function(t) {
        f <- tryCatch(suppressWarnings(lqmm::lqmm(fixed = formula, random = ~1, group = .grp, tau = t, data = bd,
                                 control = lqmm::lqmmControl(LP_max_iter = iter * 4, LP_tol_ll = 1e-4))), error = function(e) NULL)
        if (is.null(f)) rep(NA_real_, p) else as.numeric(stats::coef(f))
      }, numeric(p))
    }
    draws <- .wgh_map(seq_len(B), one, d = d, rows = rows, taus = taus, formula = formula, iter = iter,
                     p = ncol(des$X), seed = seed, packages = "lqmm")
    draws <- Filter(function(m) !anyNA(m), draws)
    if (length(draws)) boot <- simplify2array(lapply(draws, function(m) { dimnames(m) <- dimnames(coefs); m }))
  }
  out <- structure(list(coefs = coefs, boot = boot, design = des, L = L, taus = taus, exposure = exposure,
                        anchor_ages = anchor_ages, formula = formula, data = d, fits = lapply(fits, `[[`, "fit"),
                        convergence = conv, n_children = length(unique(d$id)), n_obs = nrow(d),
                        B_ok = if (is.null(boot)) 0L else dim(boot)[3]), class = c("wgh_lqmm", "wgh_rq"))
  if (!is.null(L)) out$slopes <- wgh_slopes(out)
  if (!all(conv$converged)) .warn("Some quantiles did not converge cleanly. See {.field $convergence}.")
  out
}

#' @export
print.wgh_lqmm <- function(x, ...) {
  cli::cli_text("{.cls wgh_lqmm} (random intercept per child)")
  NextMethod()
}
