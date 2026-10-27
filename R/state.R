## States, transitions and multistate models (Book 2 Ch 12 and 13, the canalization study (Ho 2026, manuscript under review))

.band_labels <- c("Very low", "Low", "Middle", "High", "Very high")

#' Height-for-age bands
#'
#' Assigns each visit to one of five bands of a z-score, by default cut at
#' the 10th, 25th, 75th and 90th percentiles of the standard normal
#' distribution (Ho 2026, manuscript under review).
#' @param x Growth data.
#' @param var Z-score variable.
#' @param percentiles Cut points in percent.
#' @param labels Band labels.
#' @return `x` with an ordered factor `band` and its integer code `state`.
#' @examples
#' st <- wgh_states(growdat)
#' table(st$band)
#' @export
wgh_states <- function(x, var = "haz", percentiles = c(10, 25, 75, 90), labels = .band_labels) {
  d <- .gd(x, c("id", "age"))
  br <- c(-Inf, stats::qnorm(percentiles / 100), Inf)
  d$band <- cut(d[[var]], br, labels = labels, ordered_result = TRUE)
  d$state <- as.integer(d$band)
  .regd(x, d)
}

#' Transitions between consecutive visits
#'
#' Pairs each visit with the child's next visit when the interval lies
#' within limits and classifies the movement: persistence (same band),
#' catch-up (moving up from a band below the middle), catch-down (moving
#' down from a band above the middle) and movement toward the median.
#' @param x Output of [wgh_states()].
#' @param min_interval,max_interval Allowed interval between visits (years).
#' @return One row per transition with `from`, `to`, `interval` and
#'   indicator columns.
#' @examples
#' tr <- wgh_transitions(wgh_states(growdat))
#' mean(tr$persist)
#' @export
wgh_transitions <- function(x, min_interval = 0.5, max_interval = 2.5) {
  d <- .gd(x, c("id", "age", "state"))
  d <- d[!is.na(d$state), ]
  d <- d[order(d$id, d$age), ]
  nxt <- c(d$id[-1] == d$id[-nrow(d)], FALSE)
  i <- which(nxt)
  tr <- d[i, ]
  tr$to <- d$state[i + 1]; tr$from <- tr$state
  tr$age_next <- d$age[i + 1]; tr$interval <- tr$age_next - tr$age
  tr <- tr[tr$interval >= min_interval & tr$interval <= max_interval, ]
  mid <- 3
  tr$persist <- tr$to == tr$from
  tr$up <- tr$to > tr$from; tr$down <- tr$to < tr$from
  tr$catch_up <- tr$from < mid & tr$to > tr$from
  tr$catch_down <- tr$from > mid & tr$to < tr$from
  tr$toward_median <- (tr$from < mid & tr$to > tr$from) | (tr$from > mid & tr$to < tr$from)
  tr$from_band <- factor(.band_labels[tr$from], levels = .band_labels)
  tr$to_band <- factor(.band_labels[tr$to], levels = .band_labels)
  tibble::as_tibble(tr)
}

#' Transition matrices and canalization summaries
#' @param transitions Output of [wgh_transitions()].
#' @param by Grouping columns (for example `c("sex")`).
#' @param age_blocks Breaks of age blocks for the summary.
#' @return `wgh_transition_matrix()`: row-percent matrices in long form.
#'   `wgh_canalization_summary()`: persistence, catch-up and catch-down by
#'   group and age block.
#' @examples
#' tr <- wgh_transitions(wgh_states(growdat))
#' wgh_canalization_summary(tr, by = "sex")
#' @export
wgh_transition_matrix <- function(transitions, by = NULL) {
  .bind(lapply(.grp_split(transitions, by), function(z) {
    tab <- table(z$from_band, z$to_band)
    pct <- 100 * prop.table(tab, 1)
    .with_grp(z, by, tibble::tibble(from = rep(rownames(tab), ncol(tab)), to = rep(colnames(tab), each = nrow(tab)),
                                    n = as.vector(tab), row_pct = as.vector(pct)))
  }))
}

#' @rdname wgh_transition_matrix
#' @export
wgh_canalization_summary <- function(transitions, by = "sex", age_blocks = c(0, 5, 9, 13, 19)) {
  transitions$age_block <- cut(transitions$age, age_blocks, right = FALSE)
  .bind(lapply(.grp_split(transitions, c(by, "age_block")), function(z) {
    .with_grp(z, c(by, "age_block"), tibble::tibble(
      transitions = nrow(z), persistence = 100 * mean(z$persist),
      catch_up = 100 * sum(z$catch_up) / max(1, sum(z$from < 3)),
      catch_down = 100 * sum(z$catch_down) / max(1, sum(z$from > 3)),
      toward_median = 100 * mean(z$toward_median[z$from != 3])))
  }))
}

#' Conditional change scores
#'
#' Separates true catch-up from regression to the mean: the conditional
#' z-score is \eqn{(z_2 - r z_1) / \sqrt{1 - r^2}}, where `r` is the
#' correlation between the two measurements in the group.
#' @param transitions Output of [wgh_transitions()] (needs `haz` at both
#'   visits) or a data frame with `z1` and `z2`.
#' @param var Z-score variable.
#' @param x Growth data used to look up the second z-score.
#' @param by Groups within which `r` is estimated.
#' @return The input with columns `z1`, `z2`, `r` and `conditional_z`.
#' @examples
#' st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
#' tr <- wgh_transitions(st)
#' rt <- wgh_rtm(tr, growdat2_mini)
#' # Raw change against change conditional on the starting z-score
#' summary(rt$z2 - rt$z1)
#' summary(rt$conditional_z)
#' @export
wgh_rtm <- function(transitions, x = NULL, var = "haz", by = "sex") {
  t <- transitions
  if (!all(c("z1", "z2") %in% names(t))) {
    d <- .gd(x, c("id", "age"))
    t$z1 <- t[[var]]
    key <- paste(d$id, round(d$age, 4))
    t$z2 <- d[[var]][match(paste(t$id, round(t$age_next, 4)), key)]
  }
  out <- .bind(lapply(.grp_split(t, by), function(z) {
    r <- stats::cor(z$z1, z$z2, use = "complete.obs")
    z$r <- r; z$conditional_z <- (z$z2 - r * z$z1) / sqrt(1 - r^2)
    z
  }))
  out
}

#' Mixed models for catch-up, catch-down and persistence
#' @param transitions Output of [wgh_transitions()].
#' @param outcome Indicator column, for example `"catch_up"`.
#' @param covariates Fixed effects (character).
#' @param subset_from Restrict to transitions starting in these states (for
#'   example `1:2` for catch-up).
#' @return A list with the `glmer` fit and a tibble of odds ratios.
#' @examples
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
#'   tr <- wgh_transitions(st)
#'   gl <- wgh_transition_glmm(tr, "catch_up", covariates = c("sex", "age"), subset_from = 1:2)
#'   gl$odds_ratios
#' }
#' }
#' @export
wgh_transition_glmm <- function(transitions, outcome = "catch_up", covariates = c("sex", "age"), subset_from = NULL) {
  .need("lme4")
  d <- as.data.frame(transitions)
  if (!is.null(subset_from)) d <- d[d$from %in% subset_from, ]
  d$age <- d$age - 10
  f <- stats::as.formula(paste0("as.integer(", outcome, ") ~ ", paste(covariates, collapse = " + "), " + (1 | id)"))
  m <- lme4::glmer(f, data = d, family = stats::binomial(), control = lme4::glmerControl(optimizer = "bobyqa"))
  co <- summary(m)$coefficients
  list(model = m, odds_ratios = tibble::tibble(term = rownames(co), or = exp(co[, 1]),
                                               lower = exp(co[, 1] - 1.96 * co[, 2]), upper = exp(co[, 1] + 1.96 * co[, 2]),
                                               p_value = co[, 4]))
}

#' Prepare panel data for a multistate model
#'
#' Removes children with a single visit, collapses visits too close
#' together, guarantees strictly increasing ages and reports the number of
#' observations in each state.
#' @param x Output of [wgh_states()].
#' @param min_gap Minimum gap between visits in years.
#' @return A tibble ordered by child and age with attribute `"state_counts"`.
#' @examples
#' st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
#' md <- wgh_msm_data(st)
#' head(md)
#' @export
wgh_msm_data <- function(x, min_gap = 0.25) {
  d <- .gd(x, c("id", "age", "state"))
  d <- d[!is.na(d$state), ]
  d <- wgh_dedup_visits(d, min_gap = min_gap)
  nv <- table(d$id); d <- d[d$id %in% names(nv)[nv >= 2], ]
  d <- d[order(d$id, d$age), ]
  out <- tibble::as_tibble(d)
  attr(out, "state_counts") <- table(d$state)
  out
}

#' Continuous-time multistate model of growth bands
#'
#' Fits a Markov multistate model (`msm`) to panel observations of
#' height-for-age bands. Transitions are allowed between adjacent bands
#' (default) or between all bands. Covariate effects can be constrained so
#' that all upward transitions share one effect and all downward
#' transitions another (`constraint = "direction"`, the canalization study (Ho 2026, manuscript under review)). The
#' likelihood is scaled automatically (`fnscale`) because large cohorts
#' give objectives in the hundreds of thousands.
#' @param data Output of [wgh_msm_data()].
#' @param covariates Covariate names.
#' @param transitions `"adjacent"` or `"full"`.
#' @param constraint `"direction"` or `"none"`.
#' @param age_origin Age subtracted from age to form the time scale
#'   (default: the youngest age, so expected prevalences start at the
#'   observed starting distribution).
#' @return An object of class `wgh_msm` with the `msm` fit.
#' @examples
#' \donttest{
#' if (requireNamespace("msm", quietly = TRUE)) {
#'   st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
#'   ms <- wgh_msm(wgh_msm_data(st), covariates = "sex")
#'   ms
#' }
#' }
#' @export
wgh_msm <- function(data, covariates = NULL, transitions = c("adjacent", "full"),
                   constraint = c("direction", "none"), age_origin = NULL) {
  .need("msm")
  transitions <- match.arg(transitions); constraint <- match.arg(constraint)
  d <- as.data.frame(data)
  age_origin <- age_origin %||% floor(min(d$age))
  d$time <- d$age - age_origin
  K <- max(d$state)
  Q <- matrix(0, K, K)
  for (i in seq_len(K)) for (j in seq_len(K)) if (i != j && (transitions == "full" || abs(i - j) == 1)) Q[i, j] <- 0.2
  Q0 <- msm::crudeinits.msm(state ~ time, subject = id, data = d, qmatrix = Q)
  cf <- if (length(covariates)) stats::as.formula(paste("~", paste(covariates, collapse = " + "))) else NULL
  cons <- NULL
  if (!is.null(cf) && constraint == "direction") {
    idx <- which(t(Q) > 0, arr.ind = TRUE)  # msm orders transitions row-wise
    from <- idx[, 2]; to <- idx[, 1]
    ord <- order(from, to); from <- from[ord]; to <- to[ord]
    pat <- ifelse(to > from, 1L, 2L)
    cons <- stats::setNames(rep(list(pat), length(covariates)), covariates)
    ## factor covariates expand into dummy names
    mm <- colnames(stats::model.matrix(cf, d))[-1]
    cons <- stats::setNames(rep(list(pat), length(mm)), mm)
  }
  ll0 <- tryCatch(abs(msm::msm(state ~ time, subject = id, data = d, qmatrix = Q0, fixedpars = TRUE)$minus2loglik), error = function(e) 1e4)
  fit <- msm::msm(state ~ time, subject = id, data = d, qmatrix = Q0, covariates = cf, constraint = cons,
                  gen.inits = FALSE, method = "BFGS", control = list(fnscale = max(1, ll0 / 2), maxit = 10000))
  structure(list(fit = fit, covariates = covariates, transitions = transitions, constraint = constraint, age_origin = age_origin,
                 n_children = length(unique(d$id)), n_obs = nrow(d)), class = "wgh_msm")
}

#' @export
print.wgh_msm <- function(x, ...) {
  cli::cli_text("{.cls wgh_msm}: {x$transitions} transitions, {x$n_obs} observations from {x$n_children} children")
  print(wgh_msm_check(x))
  invisible(x)
}

#' Plausibility checks and summaries of a multistate model
#'
#' `wgh_msm_check()` flags baseline intensities that imply implausibly short
#' stays. The canalization study (Ho 2026, manuscript under review) met a
#' reference-profile intensity of 27 per year that broke the standard
#' errors. `wgh_msm_summary()` returns intensities,
#' one-year transition probabilities, mean sojourn times and hazard ratios.
#' `wgh_msm_prevalence()` compares observed and expected state prevalence.
#' @param object A `wgh_msm` object.
#' @param max_rate Largest plausible intensity per year.
#' @param t Time horizon (years) for transition probabilities.
#' @param times Times for the prevalence comparison.
#' @return Tibbles.
#' @examples
#' \donttest{
#' if (requireNamespace("msm", quietly = TRUE)) {
#'   st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
#'   ms <- wgh_msm(wgh_msm_data(st), covariates = "sex")
#'   wgh_msm_check(ms)
#'   s <- wgh_msm_summary(ms, t = 1)
#'   s$hazard_ratios
#'   wgh_msm_prevalence(ms)
#' }
#' }
#' @export
wgh_msm_check <- function(object, max_rate = 5) {
  .need("msm")
  q <- msm::qmatrix.msm(object$fit, ci = "none")
  q <- unclass(q)
  idx <- which(row(q) != col(q) & q > 0, arr.ind = TRUE)
  tibble::tibble(from = idx[, 1], to = idx[, 2], intensity = q[idx],
                 mean_years_before_move = 1 / q[idx], plausible = q[idx] <= max_rate)
}

#' @rdname wgh_msm_check
#' @export
wgh_msm_summary <- function(object, t = 1) {
  .need("msm")
  f <- object$fit
  P <- unclass(msm::pmatrix.msm(f, t = t, ci = "none"))
  soj <- msm::sojourn.msm(f)
  hr <- if (length(object$covariates)) tryCatch({
    h <- msm::hazard.msm(f)
    .bind(lapply(names(h), function(v) tibble::tibble(covariate = v, transition = rownames(h[[v]]),
                                                       hr = h[[v]][, 1], lower = h[[v]][, 2], upper = h[[v]][, 3])))
  }, error = function(e) NULL) else NULL
  list(pmatrix = P, sojourn = tibble::as_tibble(cbind(state = seq_len(nrow(soj)), soj)), hazard_ratios = hr,
       check = wgh_msm_check(object))
}

#' @rdname wgh_msm_check
#' @export
wgh_msm_prevalence <- function(object, times = NULL) {
  .need("msm")
  d <- object$fit$data$mf
  times <- times %||% stats::quantile(d$`(time)`, c(0.1, 0.3, 0.5, 0.7, 0.9), names = FALSE)
  pr <- msm::prevalence.msm(object$fit, times = times, ci = "none")
  obs <- pr$`Observed percentages`; exp <- pr$`Expected percentages`
  tibble::tibble(time = rep(times, ncol(obs)), state = rep(seq_len(ncol(obs)), each = length(times)),
                 observed = as.vector(obs), expected = as.vector(exp))
}

#' Hidden Markov model for misclassified growth bands
#'
#' Height bands observed at a single visit can be wrong because of
#' measurement error near a cut-off. This multistate model treats the true
#' band as hidden and allows each observation to be misclassified into an
#' adjacent band, which separates real movement between bands from
#' measurement noise (Book 2 Chapter 13).
#' @inheritParams wgh_msm
#' @param misclass Starting probability of misclassification into each
#'   adjacent band.
#' @return An object of class `wgh_hmm` (also `wgh_msm`) whose `misclassification`
#'   element holds the estimated misclassification matrix.
#' @examples
#' \donttest{
#' if (requireNamespace("msm", quietly = TRUE)) {
#'   # 1,000 children keep the example to well under a minute
#'   kids <- unique(growdat2_mini$pid)[1:1000]
#'   st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5 & growdat2_mini$pid %in% kids, ])
#'   hm <- wgh_hmm(wgh_msm_data(st))
#'   hm$misclassification
#' }
#' }
#' @export
wgh_hmm <- function(data, covariates = NULL, misclass = 0.05, age_origin = NULL) {
  .need("msm")
  d <- as.data.frame(data)
  age_origin <- age_origin %||% floor(min(d$age))
  d$time <- d$age - age_origin
  K <- max(d$state)
  Q <- matrix(0, K, K); E <- matrix(0, K, K)
  for (i in seq_len(K)) for (j in seq_len(K)) if (abs(i - j) == 1) { Q[i, j] <- 0.2; E[i, j] <- misclass }
  Q0 <- msm::crudeinits.msm(state ~ time, subject = id, data = d, qmatrix = Q)
  Q0[Q > 0] <- pmax(Q0[Q > 0], 0.05); diag(Q0) <- 0; diag(Q0) <- -rowSums(Q0)
  cf <- if (length(covariates)) stats::as.formula(paste("~", paste(covariates, collapse = " + "))) else NULL
  init <- as.numeric(table(factor(d$state[!duplicated(d$id)], levels = seq_len(K))))
  init <- (init + 1) / sum(init + 1)
  fit <- msm::msm(state ~ time, subject = id, data = d, qmatrix = Q0, ematrix = E, covariates = cf,
                  initprobs = init, method = "BFGS", control = list(fnscale = max(1, nrow(d)), maxit = 10000))
  em <- tryCatch(unclass(msm::ematrix.msm(fit, ci = "none")), error = function(e) NULL)
  structure(list(fit = fit, covariates = covariates, transitions = "adjacent", constraint = "none",
                 age_origin = age_origin, misclassification = em,
                 n_children = length(unique(d$id)), n_obs = nrow(d)), class = c("wgh_hmm", "wgh_msm"))
}

#' How many band changes are measurement error?
#'
#' Measurement error moves children across band cut-offs without any change
#' in growth. This function measures how much. It redraws each measured
#' height from the error-free height with a chosen measurement error SD,
#' rounds it to one decimal as a school scale would, recomputes HAZ with the
#' WHO reference, assigns bands and pairs consecutive visits, exactly as
#' [wgh_states()] and [wgh_transitions()] do. It then compares the measured
#' transitions with the error-free ones. Repeating this for several error SDs
#' shows how fast false transitions grow with measurement error (Book 2
#' Chapter 12).
#'
#' With simulated data the error-free height is known (`height_true` in the
#' truth file of a [wgh_simulate()] object). With real data it is not, and
#' the observed height is used as the reference: the result then shows how
#' many additional band changes a given amount of extra measurement error
#' would create, which is a lower bound for the real share.
#'
#' @param x A `wgh_sim` object from [wgh_simulate()], or growth data with
#'   `id` (or `pid`), `sex`, `age`, `height` and optionally `height_true`.
#' @param error_sds Measurement error SDs in cm to try.
#' @param percentiles,min_interval,max_interval Band cut-offs and the
#'   allowed interval between visits, as in [wgh_states()] and
#'   [wgh_transitions()].
#' @param attended_only For a `wgh_sim` object, use only the visits that were
#'   attended (the observed visit schedule).
#' @param seed Random seed for the redrawn measurement error.
#' @return A tibble with one row per error SD: `n_transitions`,
#'   `persistence_pct` (measured band unchanged), `observed_moves_pct`
#'   (measured band changed), `false_moves_pct` (share of measured changes in
#'   which the error-free band did not change) and `missed_moves_pct` (share
#'   of error-free changes not seen in the measured bands). Attribute
#'   `"by_band"` gives the false moves by starting band.
#' @section Next steps:
#' Report the expected share of false moves with any transition analysis
#' ([wgh_transition_matrix()], [wgh_canalization_summary()]), use
#' [wgh_rtm()] to separate regression to the mean from real catch-up, and
#' [wgh_hmm()] to model misclassification directly.
#' @examples
#' sim <- wgh_simulate(3000, seed = 3)
#' fm <- wgh_false_moves(sim, error_sds = c(0.5, 1, 1.5))
#' fm
#' attr(fm, "by_band")
#' # Real data: extra error on top of the recorded heights
#' wgh_false_moves(growdat, error_sds = c(0.5, 1))
#' @export
wgh_false_moves <- function(x, error_sds = c(0.5, 1, 1.5), percentiles = c(10, 25, 75, 90),
                            min_interval = 0.5, max_interval = 2.5, attended_only = TRUE, seed = 2026) {
  if (inherits(x, "wgh_sim")) {
    d <- as.data.frame(x$truth_visit)
    if (attended_only) d <- d[d$attended, , drop = FALSE]
    names(d)[names(d) == "pid"] <- "id"
    truth_known <- TRUE
  } else {
    d <- as.data.frame(.gd(x, c("id", "age", "sex", "height")))
    truth_known <- "height_true" %in% names(d)
    if (!truth_known) {
      d$height_true <- d$height
      .inform("No error-free height in the data. The recorded height is used as the reference, so the shares are lower bounds.")
    }
  }
  if (!is.numeric(error_sds) || any(error_sds < 0)) .stop("{.arg error_sds} must be non-negative numbers (cm).")
  d <- d[!is.na(d$height_true) & !is.na(d$age), c("id", "sex", "age", "height_true")]
  d <- d[order(d$id, d$age), ]
  br <- c(-Inf, stats::qnorm(percentiles / 100), Inf)
  band <- function(h) as.integer(cut(wgh_zscore(h, d$age, d$sex, "hfa"), br))
  true_band <- band(d$height_true)
  nxt <- which(c(d$id[-1] == d$id[-nrow(d)], FALSE))
  gap <- d$age[nxt + 1] - d$age[nxt]
  i <- nxt[gap >= min_interval & gap <= max_interval]
  .local_seed(seed)
  per <- lapply(error_sds, function(s) {
    meas <- band(round(d$height_true + stats::rnorm(nrow(d), 0, s), 1))
    ok <- !is.na(meas[i]) & !is.na(meas[i + 1]) & !is.na(true_band[i]) & !is.na(true_band[i + 1])
    j <- i[ok]
    moved <- meas[j] != meas[j + 1]; moved_t <- true_band[j] != true_band[j + 1]
    list(summary = tibble::tibble(error_sd_cm = s, n_transitions = length(j),
                                  persistence_pct = 100 * mean(!moved), observed_moves_pct = 100 * mean(moved),
                                  false_moves_pct = if (any(moved)) 100 * mean(!moved_t[moved]) else NA_real_,
                                  missed_moves_pct = if (any(moved_t)) 100 * mean(!moved[moved_t]) else NA_real_),
         by_band = tibble::tibble(error_sd_cm = s, from_band = factor(.band_labels[meas[j]], levels = .band_labels),
                                  moved = moved, false_move = moved & !moved_t))
  })
  out <- .bind(lapply(per, `[[`, "summary"))
  bb <- .bind(lapply(per, `[[`, "by_band"))
  attr(out, "by_band") <- .bind(lapply(split(bb, list(bb$error_sd_cm, bb$from_band), drop = TRUE), function(z)
    tibble::tibble(error_sd_cm = z$error_sd_cm[1], from_band = z$from_band[1], n_transitions = nrow(z),
                   observed_moves_pct = 100 * mean(z$moved),
                   false_moves_pct = if (any(z$moved)) 100 * mean(z$false_move[z$moved]) else NA_real_)))
  attr(out, "truth_known") <- truth_known
  out
}
