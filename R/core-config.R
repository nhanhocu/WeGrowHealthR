.wgh_modes <- list(
  dev = list(subsample = 1000L, taus = c(0.10, 0.25, 0.50, 0.75, 0.90), B = 10L,
             folds = 3L, sitar_df = 4L, lqmm_iter = 300L, shap_n = 100L, shap_bg = 50L),
  analysis = list(subsample = 10000L, taus = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95), B = 200L,
                  folds = 5L, sitar_df = 5L, lqmm_iter = 500L, shap_n = 500L, shap_bg = 100L),
  publication = list(subsample = Inf, taus = seq(0.05, 0.95, by = 0.05), B = 500L,
                     folds = 10L, sitar_df = 5L, lqmm_iter = 1000L, shap_n = 1000L, shap_bg = 200L)
)

#' Run modes: development, analysis and publication settings in one place
#'
#' Every script in the research program used a `RUN_MODE` switch with three
#' tiers. `wgh_config()` makes these tiers a package option. Heavy functions
#' read their defaults (subsample size, quantile grid, bootstrap replicates,
#' folds, iteration limits) from the active mode, and any argument passed
#' explicitly to a function overrides the mode.
#'
#' @param mode One of `"dev"` (minutes, for checking code), `"analysis"`
#'   (default) or `"publication"` (full grids and bootstraps).
#' @param ... Named values that override single settings of the mode, for
#'   example `B = 100`. Names are checked against the settings listed under
#'   `name`, and values are checked for type and range.
#' @return `wgh_config()` invisibly returns the previous configuration.
#'   `wgh_mode()` returns the active mode name and `wgh_opt()` one setting.
#' @examples
#' old <- wgh_config("dev")
#' wgh_opt("B")
#' wgh_opt("taus")
#' # Override single settings of a mode
#' wgh_config("dev", B = 50, folds = 5)
#' wgh_opt("B")
#' # A misspelled setting fails instead of being ignored
#' try(wgh_config("dev", b = 50))
#' wgh_config(old)
#' @export
wgh_config <- function(mode = c("analysis", "dev", "publication"), ...) {
  old <- list(mode = wgh_mode(), overrides = getOption("WeGrowHealthR.overrides", list()))
  if (is.list(mode)) {
    if (!is.character(mode$mode) || !mode$mode %in% names(.wgh_modes))
      .stop("A configuration list needs a {.field mode} of {.val {names(.wgh_modes)}}.")
    options(WeGrowHealthR.mode = mode$mode, WeGrowHealthR.overrides = .check_overrides(mode$overrides %||% list()))
    return(invisible(old))
  }
  mode <- match.arg(mode)
  options(WeGrowHealthR.mode = mode, WeGrowHealthR.overrides = .check_overrides(list(...)))
  .inform("WeGrowHealthR run mode: {.strong {mode}}")
  invisible(old)
}

## Validate setting overrides so that a typo (for example `b = 100`) fails
## loudly instead of being silently ignored
.check_overrides <- function(ov) {
  if (!length(ov)) return(list())
  ok <- names(.wgh_modes$dev)
  if (is.null(names(ov)) || any(names(ov) == ""))
    .stop("Overrides must be named, for example {.code wgh_config(\"dev\", B = 100)}.")
  bad <- setdiff(names(ov), ok)
  if (length(bad)) .stop(c("Unknown setting{?s}: {.arg {bad}}.", i = "Valid settings: {.arg {ok}}."))
  for (nm in names(ov)) {
    v <- ov[[nm]]
    if (nm == "taus") {
      if (!is.numeric(v) || !length(v) || any(is.na(v)) || any(v <= 0 | v >= 1))
        .stop("{.arg taus} must be numeric values strictly between 0 and 1.")
      ov$taus <- sort(unique(round(v, 3)))
    } else if (nm == "subsample") {
      if (!is.numeric(v) || length(v) != 1 || is.na(v) || v < 10)
        .stop("{.arg subsample} must be a single number of at least 10 (or {.code Inf} for all children).")
    } else {
      lo <- if (nm == "folds") 2 else 1
      if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < lo || v != round(v))
        .stop("{.arg {nm}} must be a single whole number of at least {lo}.")
      ov[[nm]] <- as.integer(v)
    }
  }
  ov
}

#' @rdname wgh_config
#' @export
wgh_mode <- function() getOption("WeGrowHealthR.mode", "analysis")

#' @rdname wgh_config
#' @param name Setting name: `subsample`, `taus`, `B`, `folds`, `sitar_df`,
#'   `lqmm_iter`, `shap_n` or `shap_bg`.
#' @export
wgh_opt <- function(name) {
  ov <- getOption("WeGrowHealthR.overrides", list())
  if (!is.null(ov[[name]])) return(ov[[name]])
  .wgh_modes[[wgh_mode()]][[name]]
}

#' Quantile grids that are safe to match
#'
#' `seq(0.05, 0.95, by = 0.05)` stores 0.7500000000000001 rather than 0.75,
#' so exact matching silently drops quantiles. This happened in the program
#' and in Book 2 Chapter 4. `wgh_taus()` rounds at source and can check that
#' the headline quantiles are present.
#'
#' @param which `"headline"` (5 quantiles), `"seven"`, `"grid19"`, `"mode"`
#'   (the active run mode's grid) or a numeric vector.
#' @param require Optional quantiles that must be present.
#' @return A sorted numeric vector rounded to 3 decimals.
#' @examples
#' wgh_taus("grid19")
#' 0.75 %in% wgh_taus("grid19")
#' @export
wgh_taus <- function(which = "headline", require = NULL) {
  t <- if (is.numeric(which)) which else switch(which,
    headline = c(0.05, 0.25, 0.50, 0.75, 0.95),
    seven = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95),
    grid19 = seq(0.05, 0.95, by = 0.05),
    mode = wgh_opt("taus"),
    .stop("Unknown quantile set {.val {which}}."))
  t <- sort(unique(round(t, 3)))
  if (any(t <= 0 | t >= 1)) .stop("Quantiles must lie strictly between 0 and 1.")
  if (!is.null(require)) {
    miss <- setdiff(round(require, 3), t)
    if (length(miss)) .stop("Required quantile(s) {miss} missing from the grid.")
  }
  t
}

#' Set up parallel workers with reproducible random streams
#'
#' A thin wrapper around `future::plan()`. When a parallel plan is active,
#' the heavy parts of the package run on several workers: bootstrap
#' replicates (quantile regression, quantile mixed models, SITAR intervals,
#' quantile models of child-level outcomes, mediation, phenotype outcome
#' links and cluster stability), the quantile grid of linear quantile mixed
#' models, and the cross-validation folds of the prediction benchmark and
#' the conditional references. Each task gets its own L'Ecuyer-CMRG random
#' stream derived from the function's `seed`, so the results are identical
#' whether the work runs sequentially or in parallel, and whatever the
#' number of workers.
#'
#' The function also raises the `future.globals.maxSize` option, because
#' growth data and fitted models often exceed the default limit of 500 MB.
#' The previous value is stored and restored when you return to sequential
#' processing with `workers = 1`. All arguments are checked before anything
#' is changed, so an invalid call leaves the plan and the option as they
#' were.
#'
#' @param workers Number of workers. `1` returns to sequential processing.
#' @param strategy `"multisession"` (default, separate R sessions, works on
#'   all platforms) or `"multicore"` (forked processes, faster to start but
#'   not available on Windows or inside RStudio).
#' @param max_size Largest size of data sent to each worker, in gigabytes.
#'   `NULL` leaves the `future.globals.maxSize` option unchanged.
#' @return The previous plan, invisibly, with the previous
#'   `future.globals.maxSize` value as attribute `globals_max_size`.
#' @section Next steps:
#' Check the set-up with [wgh_parallel_info()], run any bootstrap or flow as
#' usual, and return to sequential processing with `wgh_parallel(1)`. See
#' `vignette("parallel-computing")`.
#' @examples
#' \donttest{
#' if (requireNamespace("future", quietly = TRUE) && requireNamespace("furrr", quietly = TRUE)) {
#'   old <- wgh_parallel(2)
#'   wgh_parallel_info()
#'   f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
#'   d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
#'   par <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 20)
#'   wgh_parallel(1)                       # back to sequential, option restored
#'   seq <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 20)
#'   all.equal(par$slopes, seq$slopes)     # identical results
#' }
#' }
#' @export
wgh_parallel <- function(workers = max(1L, parallel::detectCores() - 1L),
                        strategy = c("multisession", "multicore"), max_size = 2) {
  .need("future"); .need("furrr")
  strategy <- match.arg(strategy)
  ## validate everything before changing any state
  if (!is.numeric(workers) || length(workers) != 1 || is.na(workers) || workers < 1)
    .stop("{.arg workers} must be a single number of at least 1.")
  if (!is.null(max_size) && (!is.numeric(max_size) || length(max_size) != 1 || is.na(max_size) || max_size <= 0))
    .stop("{.arg max_size} must be a positive number of gigabytes, or {.code NULL}.")
  workers <- as.integer(workers)
  prev_size <- getOption("future.globals.maxSize")
  old <- if (workers <= 1) future::plan("sequential") else
    future::plan(strategy, workers = workers)
  if (workers <= 1) {
    if (isTRUE(.wgh_state$size_changed)) {
      options(future.globals.maxSize = .wgh_state$size_before)
      .wgh_state$size_changed <- FALSE
    }
  } else if (!is.null(max_size)) {
    if (!isTRUE(.wgh_state$size_changed)) {
      .wgh_state$size_before <- prev_size
      .wgh_state$size_changed <- TRUE
    }
    options(future.globals.maxSize = max_size * 1024^3)
  }
  .inform("Parallel plan: {.val {if (workers <= 1) 'sequential' else strategy}} with {workers} worker{?s}.")
  invisible(structure(old, globals_max_size = prev_size))
}

#' Describe the current parallel set-up
#'
#' @return A one-row tibble with the active `future` plan, the number of
#'   workers, the number of cores on the machine, the
#'   `future.globals.maxSize` limit in gigabytes, and whether the package will
#'   run its heavy steps in parallel.
#' @examples
#' wgh_parallel_info()
#' @export
wgh_parallel_info <- function() {
  has <- requireNamespace("future", quietly = TRUE)
  ms <- getOption("future.globals.maxSize")
  cls <- if (has) class(future::plan()) else "sequential"
  known <- intersect(cls, c("multisession", "multicore", "cluster", "sequential", "callr"))
  tibble::tibble(plan = if (!has) "sequential (future not installed)" else if (length(known)) known[1] else cls[1],
                 workers = if (has) as.integer(future::nbrOfWorkers()) else 1L,
                 cores = parallel::detectCores(),
                 globals_max_size_gb = if (is.null(ms)) 0.5 else round(ms / 1024^3, 2),
                 parallel_active = .par_active())
}

## Package-level state (not exported)
.wgh_state <- new.env(parent = emptyenv())
