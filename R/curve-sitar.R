## SITAR growth curves and the pubertal spurt (Book 1 Ch 9, Book 2 Ch 8 to 10)

#' Fit a SITAR growth curve model safely
#'
#' Fits a SuperImposition by Translation And Rotation model with
#' `sitar::sitar()`, keeping every warning and returning `NULL` with the
#' error message rather than stopping, so competing specifications can be
#' compared (as `fit_sitar_safe()` did in the analysis code of Ho et al.
#' 2026, medRxiv 2026.07.26.26358986). Diagnostics are attached.
#'
#' @param x Growth data with `id` (or `pid`), `age` and `height`.
#' @param df Degrees of freedom of the mean spline.
#' @param fixed,random SITAR fixed and random effects, `"a + b + c"` or
#'   `"a + b + c + d"`.
#' @param age_range Ages to include.
#' @param min_visits Minimum visits per child.
#' @param sex Optional sex to restrict to.
#' @param label Label used in tables.
#' @param max_iter Maximum iterations of the optimiser.
#' @param retry If the fit fails, retry once with one fewer degree of freedom.
#' @param max_children Largest number of children used. SITAR fits on tens
#'   of thousands of children take hours, so by default the run mode sets
#'   the limit (1,000 children in `"dev"`, 10,000 in `"analysis"` and all
#'   children in `"publication"`). Use `Inf` for all children.
#' @param seed Random seed for choosing the children. The caller's random
#'   stream is restored.
#' @param max_time Longest fitting time in seconds. A model that does not
#'   converge in that time is stopped and returned as a failed fit with the
#'   reason, so a model comparison or flow never hangs. `Inf` for no limit.
#' @return An object of class `wgh_sitar` with `model` (the sitar fit or
#'   `NULL`), `warnings`, `label`, `data` and the fitting settings.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' fit
#' wgh_aphv(fit)
#' }
#' @export
wgh_fit_sitar <- function(x, df = wgh_opt("sitar_df"), fixed = "a + b + c", random = "a + b + c",
                         age_range = c(6, 18), min_visits = 3, sex = NULL, label = NULL, max_iter = 200,
                         retry = TRUE, max_children = wgh_opt("subsample"), seed = 2026, max_time = 900) {
  .need("sitar", "to fit SITAR models")
  d <- .gd(x, c("id", "age", "height"))
  if (!is.null(sex)) d <- d[d$sex == sex, , drop = FALSE]
  d <- d[d$age >= age_range[1] & d$age <= age_range[2] & !is.na(d$height), , drop = FALSE]
  nv <- table(d$id); d <- d[d$id %in% names(nv)[nv >= min_visits], , drop = FALSE]
  ids <- unique(d$id)
  if (is.finite(max_children) && length(ids) > max_children) {
    .local_seed(seed)
    d <- d[d$id %in% sample(ids, max_children), , drop = FALSE]
    .inform("SITAR fitted to a random {max_children} of {length(ids)} children (run mode {.val {wgh_mode()}}).")
  }
  d <- as.data.frame(d[order(d$id, d$age), c("id", "age", "height", intersect(c("sex", "site"), names(d)))])
  label <- label %||% paste0(if (!is.null(sex)) paste0(sex, " ") else "", age_range[1], "-", age_range[2], " ", gsub(" ", "", fixed))
  warns <- character()
  if (is.finite(max_time)) {
    setTimeLimit(elapsed = max_time, transient = TRUE)
    on.exit(setTimeLimit(elapsed = Inf), add = TRUE)
  }
  mod <- tryCatch(withCallingHandlers(
    sitar::sitar(x = age, y = height, id = id, data = d, df = df, fixed = fixed, random = random,
                 method = "ML", keep.data = TRUE,
                 control = nlme::nlmeControl(msMaxIter = max_iter, msMaxEval = 5 * max_iter, returnObject = TRUE)),
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
    error = function(e) { warns <<- c(warns, paste("ERROR:", conditionMessage(e))); NULL })
  setTimeLimit(elapsed = Inf)
  timed_out <- any(grepl("time limit", warns))
  if (timed_out) warns <- c(warns, paste("Stopped after", max_time, "seconds (max_time)."))
  if (is.null(mod) && retry && df > 3 && !timed_out) {
    .inform("SITAR fit failed with df = {df}; retrying with df = {df - 1}.")
    return(wgh_fit_sitar(d, df = df - 1, fixed = fixed, random = random, age_range = age_range,
                        min_visits = min_visits, label = paste0(label, " (df ", df - 1, ")"), max_iter = max_iter, retry = FALSE,
                        max_children = Inf, max_time = max_time))
  }
  structure(list(model = mod, warnings = unique(warns), label = label, data = tibble::as_tibble(d),
                 df = df, fixed = fixed, random = random, age_range = age_range,
                 n_children = length(unique(d$id)), n_obs = nrow(d)), class = "wgh_sitar")
}

#' @export
print.wgh_sitar <- function(x, ...) {
  cli::cli_text("{.cls wgh_sitar} {.val {x$label}}: {x$n_obs} visits from {x$n_children} children, df = {x$df}")
  if (is.null(x$model)) { cli::cli_alert_danger("Fit failed: {paste(x$warnings, collapse = ' | ')}"); return(invisible(x)) }
  pk <- tryCatch(wgh_aphv(x)$population, error = function(e) NULL)
  if (!is.null(pk)) cli::cli_text("Population APHV {round(pk$aphv, 2)} y, PHV {round(pk$phv, 2)} cm/y")
  if (length(x$warnings)) cli::cli_alert_warning("{length(x$warnings)} warning{?s} during fitting")
  print(wgh_sitar_diagnostics(x))
  invisible(x)
}

.sitar_model <- function(fit) {
  m <- if (inherits(fit, "wgh_sitar")) fit$model else fit
  if (is.null(m)) .stop("The SITAR model is missing (the fit failed).")
  m
}

## Population velocity curve on a grid, from sitar's own derivative
.sitar_velocity_curve <- function(fit, age_range = NULL, step = 0.01) {
  m <- .sitar_model(fit)
  ar <- age_range %||% (if (inherits(fit, "wgh_sitar")) fit$age_range else range(nlme::getData(m)$age))
  g <- seq(ar[1], ar[2], by = step)
  v <- as.numeric(stats::predict(m, newdata = data.frame(age = g), level = 0, deriv = 1))
  h <- as.numeric(stats::predict(m, newdata = data.frame(age = g), level = 0))
  tibble::tibble(age = g, height = h, velocity = v)
}

#' Age and velocity at peak height velocity
#'
#' Population APHV and PHV are read from the SITAR mean velocity curve
#' within the fitted age range. Individual APHV and PHV are computed for all
#' children at once from the random effects with the exact SITAR
#' relationship
#' \deqn{APHV_i = x_0 + b_0 + b_i + (APHV - x_0 - b_0) e^{-c_i}, \quad PHV_i = PHV e^{c_i},}
#' where \eqn{x_0} is the age offset and \eqn{b_0} the fixed timing effect.
#' This replaces both the per-child prediction loop of Book 1 Chapter 9 and
#' the approximation `APHV + b_i` used in the original code of the SITAR pubertal spurt study (Ho et al. 2026, medRxiv 2026.07.26.26358986), which ignores
#' intensity. Nothing is ever substituted when extraction fails: the
#' function stops with an error.
#'
#' @param fit A `wgh_sitar` object or a sitar model.
#' @param age_range Age range searched for the population peak (defaults to
#'   the fitting range).
#' @return A list with `population` (tibble with `aphv`, `phv`) and
#'   `individual` (tibble with `id`, `a`, `b`, `c`, `aphv`, `phv`).
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' wgh_aphv(fit)$population
#' }
#' @export
wgh_aphv <- function(fit, age_range = NULL) {
  .need("nlme")
  m <- .sitar_model(fit)
  vc <- .sitar_velocity_curve(fit, age_range)
  i <- which.max(vc$velocity)
  if (!length(i) || !is.finite(vc$velocity[i])) .stop("APHV could not be extracted from the velocity curve.")
  if (i == 1 || i == nrow(vc)) .warn("The velocity peak sits at the edge of the age range. APHV may be outside the data.")
  aphv <- vc$age[i]; phv <- vc$velocity[i]
  re <- nlme::ranef(m)
  fe <- nlme::fixef(m)
  b0 <- if ("b" %in% names(fe)) fe[["b"]] else 0
  x0 <- m$xoffset %||% 0
  rb <- if ("b" %in% names(re)) re$b else 0
  rc <- if ("c" %in% names(re)) re$c else 0
  ind <- tibble::tibble(id = rownames(re), a = if ("a" %in% names(re)) re$a else NA_real_, b = rb, c = rc,
                        aphv = x0 + b0 + rb + (aphv - x0 - b0) * exp(-rc), phv = phv * exp(rc))
  if ("d" %in% names(re)) ind$d <- re$d
  list(population = tibble::tibble(aphv = aphv, phv = phv), individual = ind)
}

#' Child-level SITAR effects ready to join to exposures
#'
#' Returns each child's size, timing and intensity with individual APHV and
#' PHV and with labels that state the direction of each effect. In SITAR a
#' negative `b` means earlier timing and a positive `c` means a faster, more
#' intense spurt. (The original code of the SITAR pubertal spurt study (Ho et al. 2026, medRxiv 2026.07.26.26358986) labelled negative `c` as a fast
#' spurt; use `legacy_c_labels = TRUE` only to reproduce that output.)
#'
#' @param fit A `wgh_sitar` object.
#' @param early_cut Timing (years relative to the population) below which a
#'   child is labelled early.
#' @param legacy_c_labels Reproduce the labelling of `c` in the original
#'   analysis code of Ho et al. (2026, medRxiv 2026.07.26.26358986).
#' @return A tibble with one row per child.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' eff <- wgh_sitar_effects(fit)
#' head(eff)
#' # Early timing (negative b) against faster tempo (positive c)
#' table(early = eff$early_timing, faster = eff$faster_tempo)
#' # The legacy labelling reverses the meaning of c
#' mean(wgh_sitar_effects(fit, legacy_c_labels = TRUE)$faster_tempo != eff$faster_tempo)
#' }
#' @export
wgh_sitar_effects <- function(fit, early_cut = 0, legacy_c_labels = FALSE) {
  ap <- wgh_aphv(fit)
  ind <- ap$individual
  ind$early_timing <- ind$b < early_cut
  ind$faster_tempo <- if (legacy_c_labels) ind$c < 0 else ind$c > 0
  ind$aphv_population <- ap$population$aphv
  if (inherits(fit, "wgh_sitar") && "sex" %in% names(fit$data))
    ind$sex <- fit$data$sex[match(ind$id, fit$data$id)]
  ind
}

#' Children and visits by age, and where the data thin out
#'
#' Counts children and visits in half-year bins and reports the first age
#' (after the peak density) at which the number of children falls below a
#' share of its peak. Mean curves are unreliable beyond that age and the
#' package trims velocity plots there (Ho et al. 2026, medRxiv 2026.07.26.26358986).
#' @param x Growth data.
#' @param by Grouping column (default `"sex"`).
#' @param bin Bin width in years.
#' @param share Threshold as a share of the peak count.
#' @return A tibble with counts by bin and an attribute `"sparse_from"`.
#' @examples
#' ad <- wgh_age_density(growdat)
#' attr(ad, "sparse_from")
#' @export
wgh_age_density <- function(x, by = "sex", bin = 0.5, share = 0.10) {
  d <- .gd(x, c("id", "age"))
  d$age_bin <- floor(d$age / bin) * bin
  out <- .bind(lapply(split(d, d[[by]]), function(z) {
    tab <- tapply(z$id, z$age_bin, function(i) length(unique(i)))
    vis <- table(z$age_bin)
    tibble::tibble(!!by := as.character(z[[by]][1]), age_bin = as.numeric(names(tab)),
                   children = as.integer(tab), visits = as.integer(vis[names(tab)]))
  }))
  sp <- vapply(split(out, out[[by]]), function(z) {
    pk <- which.max(z$children)
    after <- z[seq(pk, nrow(z)), ]
    low <- after$age_bin[after$children < share * max(z$children)]
    if (length(low)) min(low) else NA_real_
  }, numeric(1))
  attr(out, "sparse_from") <- sp
  out
}

#' Check SITAR random effects for non-identifiability
#'
#' Flags a model when any pair of random effects is correlated beyond a
#' threshold. In the SITAR pubertal spurt study (Ho et al. 2026, medRxiv 2026.07.26.26358986) an extended SITAR model fitted well but its `c`
#' and `d` effects correlated at 0.998, and it reversed which girls were
#' early maturers. The check works on both `sitar` and plain `nlme` objects
#' (the original helper silently returned "cannot evaluate" for nlme).
#' @param fit A `wgh_sitar`, sitar or nlme model.
#' @param max_abs_corr Threshold.
#' @return A list with `ok`, `max_abs_corr`, the pair and a `reason`.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' wgh_check_identifiable(fit)
#' }
#' @export
wgh_check_identifiable <- function(fit, max_abs_corr = 0.95) {
  .need("nlme")
  m <- if (inherits(fit, "wgh_sitar")) fit$model else fit
  if (is.null(m)) return(list(ok = FALSE, max_abs_corr = NA_real_, pair = NA_character_, reason = "model is NULL"))
  cm <- tryCatch({
    pd <- nlme::pdMatrix(m$modelStruct$reStruct)[[1]]
    stats::cov2cor(pd)
  }, error = function(e) NULL)
  if (is.null(cm) || length(cm) < 4) {
    re <- nlme::ranef(m)
    if (ncol(re) < 2) return(list(ok = TRUE, max_abs_corr = NA_real_, pair = NA_character_, reason = "single random effect"))
    cm <- stats::cor(re)
  }
  diag(cm) <- 0
  k <- which(abs(cm) == max(abs(cm)), arr.ind = TRUE)[1, ]
  r <- cm[k[1], k[2]]
  pair <- paste(rownames(cm)[k[1]], colnames(cm)[k[2]], sep = "-")
  ok <- abs(r) < max_abs_corr
  list(ok = ok, max_abs_corr = abs(r), pair = pair,
       reason = sprintf("%s random effects %s correlated at r = %.3f", if (ok) "OK:" else "Not identified:", pair, r))
}

#' Diagnostics of a SITAR fit
#' @param fit A `wgh_sitar` object.
#' @param tail_start Age from which the minimum velocity is checked.
#' @return A one-row tibble: label, convergence, AIC, BIC, residual SD,
#'   RMSE, random-effect SDs, minimum velocity after `tail_start`, maximum
#'   random-effect correlation and population APHV and PHV.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' wgh_sitar_diagnostics(fit)
#' }
#' @export
wgh_sitar_diagnostics <- function(fit, tail_start = NULL) {
  .need("nlme")
  m <- fit$model
  if (is.null(m)) return(tibble::tibble(model = fit$label, converged = FALSE))
  vc <- .sitar_velocity_curve(fit)
  ts <- tail_start %||% (fit$age_range[2] - 2)
  pk <- vc[which.max(vc$velocity), ]
  sds <- sqrt(diag(nlme::pdMatrix(m$modelStruct$reStruct)[[1]])) * m$sigma
  idf <- wgh_check_identifiable(fit)
  tibble::tibble(model = fit$label, converged = TRUE, n_children = fit$n_children,
                 AIC = stats::AIC(m), BIC = stats::BIC(m), sigma = m$sigma,
                 RMSE = sqrt(mean(stats::residuals(m)^2)),
                 sd_a = sds["a"] %||% NA_real_, sd_b = unname(sds["b"]), sd_c = unname(sds["c"]),
                 sd_d = if ("d" %in% names(sds)) unname(sds["d"]) else NA_real_,
                 min_velocity_tail = min(vc$velocity[vc$age >= ts]),
                 max_re_corr = idf$max_abs_corr, APHV = pk$age, PHV = pk$velocity)
}

#' Choose between competing SITAR specifications with a written rule
#'
#' Fits the candidate specifications and applies the selection rule of Ho et
#' al. (2026, medRxiv 2026.07.26.26358986): a model is acceptable only if it
#' converged, its mean velocity stays above `velocity_tol` in the
#' late-adolescent tail, its random effects are identifiable and its residual
#' error is no more than twice that of the best candidate. The first acceptable candidate is kept unless
#' a more complex candidate fitted to the same age window (BIC is not
#' comparable across windows) improves BIC by more than `bic_margin` while
#' leaving APHV and PHV stable. The reason for the choice is returned.
#'
#' @param x Growth data for one sex.
#' @param candidates Named list of argument lists for [wgh_fit_sitar()],
#'   ordered from simplest to most complex.
#' @param velocity_tol Minimum acceptable tail velocity (cm/year).
#' @param bic_margin BIC improvement required to prefer a more complex model.
#' @param aphv_tol,phv_tol Stability tolerances relative to the first model.
#' @return An object of class `wgh_sitar_selection` with `fits`, `table`
#'   (diagnostics, the criteria and `why_not`, the reasons a candidate was
#'   not acceptable), `selected` (name) and `reason`.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' sel <- wgh_sitar_select(boys, candidates = list(
#'   F1 = list(df = 4, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18)),
#'   F2 = list(df = 5, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18))))
#' sel$table
#' }
#' @export
wgh_sitar_select <- function(x, candidates = list(
  F1 = list(df = 4, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 16)),
  F2 = list(df = 4, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 15)),
  F3 = list(df = 4, fixed = "a + b + c + d", random = "a + b + c + d", age_range = c(6, 16))),
  velocity_tol = 0, bic_margin = 10, aphv_tol = 0.3, phv_tol = 0.5) {
  fits <- lapply(names(candidates), function(nm) do.call(wgh_fit_sitar, c(list(x = x, label = nm), candidates[[nm]])))
  names(fits) <- names(candidates)
  tab <- .bind(lapply(fits, wgh_sitar_diagnostics))
  tab$identifiable <- vapply(fits, function(f) isTRUE(wgh_check_identifiable(f)$ok), logical(1))
  tab$plausible_tail <- !is.na(tab$min_velocity_tail) & tab$min_velocity_tail >= velocity_tol
  ## a converged model whose residual error is far above the best one has not fitted the data
  tab$good_fit <- !is.na(tab$RMSE) & tab$RMSE <= 2 * min(tab$RMSE, na.rm = TRUE)
  tab$acceptable <- tab$converged & tab$identifiable & tab$plausible_tail & tab$good_fit
  tab$acceptable[is.na(tab$acceptable)] <- FALSE
  tab$why_not <- vapply(seq_len(nrow(tab)), function(i) {
    w <- c(if (!isTRUE(tab$converged[i])) "did not converge",
           if (isTRUE(tab$converged[i]) && !isTRUE(tab$identifiable[i])) "random effects not identifiable",
           if (isTRUE(tab$converged[i]) && !isTRUE(tab$plausible_tail[i])) "velocity falls below the tolerance in the tail",
           if (isTRUE(tab$converged[i]) && !isTRUE(tab$good_fit[i])) "residual error more than twice the best model")
    if (length(w)) paste(w, collapse = "; ") else ""
  }, "")
  ref <- tab[1, ]
  tab$stable <- abs(tab$APHV - ref$APHV) <= aphv_tol & abs(tab$PHV - ref$PHV) <= phv_tol
  ok <- which(tab$acceptable)
  if (!length(ok)) {
    sel <- names(fits)[1]
    reason <- paste0("No candidate met all criteria (", paste(paste0(names(fits), ": ", tab$why_not), collapse = "; "),
                     "). The first model is kept and its mean curve should be displayed only within the age range with adequate data.")
  } else {
    sel_i <- ok[1]
    same_window <- vapply(fits, function(f) identical(f$age_range, fits[[sel_i]]$age_range), logical(1))
    ## BIC is only comparable between models fitted to the same data window
    first_i <- sel_i
    better <- ok[ok > sel_i & same_window[ok] & tab$BIC[ok] < tab$BIC[sel_i] - bic_margin & tab$stable[ok]]
    if (length(better)) sel_i <- better[1]
    sel <- names(fits)[sel_i]
    skipped <- if (first_i > 1) paste0(" Not acceptable: ", paste(paste0(names(fits)[seq_len(first_i - 1)], " (",
                                       tab$why_not[seq_len(first_i - 1)], ")"), collapse = ", "), ".") else ""
    reason <- if (sel_i != first_i) paste0(sel, " improves BIC by more than ", bic_margin, " over ", names(fits)[first_i],
                                          " with stable APHV and PHV.")
    else if (sel_i == 1) paste0(sel, " is acceptable (tail velocity ", round(tab$min_velocity_tail[1], 2),
                                " cm/y, identifiable), so more complex models are not needed.")
    else paste0(sel, " is the first acceptable candidate.", skipped)
  }
  structure(list(fits = fits, table = tab, selected = sel, reason = reason), class = "wgh_sitar_selection")
}

#' @export
print.wgh_sitar_selection <- function(x, ...) {
  cli::cli_text("{.cls wgh_sitar_selection}: selected {.val {x$selected}}")
  cli::cli_text(x$reason)
  print(x$table[, c("model", "converged", "BIC", "min_velocity_tail", "max_re_corr", "APHV", "PHV", "acceptable")])
  invisible(x)
}

#' Bootstrap confidence intervals for population APHV and PHV
#'
#' Resamples children (all their visits together), refits the SITAR model
#' and recomputes APHV and PHV. This is a real cluster bootstrap. The SITAR pubertal spurt study (Ho et al. 2026, medRxiv 2026.07.26.26358986)
#' script labelled as a bootstrap CI an interval computed as the population
#' estimate plus or minus 1.96 times SD(individual APHV) divided by the square
#' root of n, which treats the spread of individual timing as sampling error;
#' `method = "legacy"` reproduces that interval for comparison.
#'
#' @param fit A `wgh_sitar` object.
#' @param B Bootstrap replicates (each refits the model, so keep it modest).
#' @param method `"bootstrap"` or `"legacy"`.
#' @param seed Random seed.
#' @param level Confidence level.
#' @return A tibble with estimates, limits and the number of successful
#'   replicates.
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' wgh_sitar_ci(fit, B = 5)
#' }
#' @export
wgh_sitar_ci <- function(fit, B = 50, method = c("bootstrap", "legacy"), seed = 2026, level = 0.95) {
  method <- match.arg(method)
  ap <- wgh_aphv(fit)
  if (method == "legacy") {
    ind <- ap$individual; n <- nrow(ind)
    z <- stats::qnorm(1 - (1 - level) / 2)
    pop_b <- ap$population$aphv + ind$b
    se_a <- stats::sd(pop_b) / sqrt(n); se_p <- stats::sd(ind$phv) / sqrt(n)
    return(tibble::tibble(method = "legacy (not a bootstrap)", aphv = ap$population$aphv,
                          aphv_lower = ap$population$aphv - z * se_a, aphv_upper = ap$population$aphv + z * se_a,
                          phv = ap$population$phv, phv_lower = ap$population$phv - z * se_p,
                          phv_upper = ap$population$phv + z * se_p, n_children = n, replicates = NA_integer_))
  }
  d <- fit$data
  ids <- unique(d$id); rows <- split(seq_len(nrow(d)), d$id)
  one <- function(b, d, rows, args) {
    pick <- sample(names(rows), length(rows), replace = TRUE)
    bd <- d[unlist(rows[pick], use.names = FALSE), ]
    bd$id <- rep(paste0(pick, "_", seq_along(pick)), lengths(rows[pick]))
    f <- do.call(wgh_fit_sitar, c(list(x = bd, min_visits = 1), args))
    if (is.null(f$model)) return(c(NA, NA))
    p <- tryCatch(wgh_aphv(f)$population, error = function(e) NULL)
    if (is.null(p)) c(NA, NA) else c(p$aphv, p$phv)
  }
  args <- list(df = fit$df, fixed = fit$fixed, random = fit$random, age_range = fit$age_range)
  draws <- .wgh_map(seq_len(B), one, d = d, rows = rows, args = args, seed = seed, packages = "sitar")
  m <- do.call(rbind, draws); ok <- stats::complete.cases(m)
  a <- (1 - level) / 2
  tibble::tibble(method = "cluster bootstrap", aphv = ap$population$aphv,
                 aphv_lower = stats::quantile(m[ok, 1], a), aphv_upper = stats::quantile(m[ok, 1], 1 - a),
                 phv = ap$population$phv, phv_lower = stats::quantile(m[ok, 2], a),
                 phv_upper = stats::quantile(m[ok, 2], 1 - a), n_children = length(ids), replicates = sum(ok))
}

#' Plot a SITAR growth curve
#'
#' Draws the fitted mean height curve over the data, the mean velocity
#' curve with the age at peak height velocity (APHV) marked, or both side by
#' side.
#' @param x A `wgh_sitar` object from [wgh_fit_sitar()].
#' @param type `"velocity"`, `"height"` or `"both"`.
#' @param trim Stop the curve where the data become sparse.
#' @param show_data Show the observations behind the height curve.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object (a patchwork for `"both"`).
#' @examplesIf rlang::is_installed("sitar")
#' \donttest{
#' boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
#' fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
#' plot(fit)
#' plot(fit, type = "height", show_data = FALSE, line_width = 1.5)
#' }
#' @export
plot.wgh_sitar <- function(x, type = c("velocity", "height", "both"), trim = TRUE, show_data = TRUE, ...) {
  o <- .popts(...)
  type <- match.arg(type)
  vc <- .sitar_velocity_curve(x)
  if (trim) {
    sp <- attr(wgh_age_density(x$data, by = if ("sex" %in% names(x$data)) "sex" else "id"), "sparse_from")
    cut <- suppressWarnings(min(sp, na.rm = TRUE))
    if (is.finite(cut)) vc <- vc[vc$age <= cut + 0.5, ]
  }
  pk <- vc[which.max(vc$velocity), ]
  pv <- ggplot2::ggplot(vc, ggplot2::aes(.data$age, .data$velocity)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70") + ggplot2::geom_line(linewidth = o$line_width %||% 1, colour = "#0072B2") +
    ggplot2::geom_vline(xintercept = pk$age, linetype = 2) +
    ggplot2::annotate("text", x = pk$age, y = pk$velocity, label = paste0("APHV ", round(pk$age, 1), " y"),
                      hjust = -0.1, vjust = -0.5, size = 3.2) +
    ggplot2::labs(x = "Age (years)", y = "Height velocity (cm/year)", title = x$label)
  ph <- ggplot2::ggplot(vc, ggplot2::aes(.data$age, .data$height))
  if (show_data) ph <- ph + ggplot2::geom_point(data = x$data, ggplot2::aes(.data$age, .data$height),
                                                alpha = o$alpha %||% 0.05, size = o$point_size %||% 0.4)
  ph <- ph + ggplot2::geom_line(linewidth = o$line_width %||% 1, colour = "#0072B2") +
    ggplot2::labs(x = "Age (years)", y = "Height (cm)", title = x$label)
  pv <- .finish(pv, o); ph <- .finish(ph, o)
  if (type == "velocity") return(pv)
  if (type == "height") return(ph)
  if (requireNamespace("patchwork", quietly = TRUE)) return(patchwork::wrap_plots(ph, pv))
  pv
}
