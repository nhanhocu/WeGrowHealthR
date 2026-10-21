## Internal helpers used across modules -------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

.need <- function(pkg, why = NULL) {
  rlang::check_installed(pkg, reason = why)
  invisible(TRUE)
}

.tbl <- function(x) tibble::as_tibble(x)

.as_df <- function(x) {
  if (inherits(x, "wgh_data")) x <- x$data
  as.data.frame(x, stringsAsFactors = FALSE)
}

.stop <- function(..., .envir = parent.frame()) cli::cli_abort(c(...), call = NULL, .envir = .envir)
.warn <- function(..., .envir = parent.frame()) cli::cli_warn(c(...), .envir = .envir)
.inform <- function(..., .envir = parent.frame()) if (!isTRUE(getOption("WeGrowHealthR.quiet"))) cli::cli_inform(c(...), .envir = .envir)

## Run a function over a list, in parallel when a future plan is active
## (see wgh_parallel()) and furrr is installed.
##
## Reproducibility: every element gets its own L'Ecuyer-CMRG random stream
## derived from `seed`, so results are identical whether the work runs
## sequentially or in parallel, and whatever the number of workers. The
## caller's random number state (kind and seed) is left unchanged.
##
## Lean workers: the function is re-attached to a small environment holding
## only the variables it uses, so that large objects in the calling frame are
## not copied to every worker (the "globals too large" failure of the
## original analysis scripts).
.wgh_map <- function(.x, .f, ..., seed = NULL, packages = NULL) {
  n <- length(.x)
  if (!n) return(list())
  seeds <- .stream_seeds(n, seed)
  .f <- .lean(.f)
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv()) else NULL
  old_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  if (.par_active()) {
    return(furrr::future_map(.x, .f, ..., .options = furrr::furrr_options(
      seed = seeds, packages = unique(c("WeGrowHealthR", packages)))))
  }
  lapply(seq_len(n), function(i) {
    assign(".Random.seed", seeds[[i]], envir = globalenv())
    .f(.x[[i]], ...)
  })
}

## Facet labels such as "Age 6", "Age 12" in numeric rather than alphabetical order
.lab_num <- function(prefix, x) { u <- sort(unique(x)); factor(paste(prefix, x), levels = paste(prefix, u)) }

## Packages among `pkgs` that are installed
.installed <- function(pkgs) pkgs[vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]

## Is a parallel future plan active?
.par_active <- function() {
  ok <- requireNamespace("furrr", quietly = TRUE) && requireNamespace("future", quietly = TRUE) &&
    !inherits(future::plan(), "sequential") && future::nbrOfWorkers() > 1
  if (!ok) return(FALSE)
  ## workers load the installed package, so a development copy loaded with
  ## pkgload cannot be used in parallel
  if (!length(find.package("WeGrowHealthR", lib.loc = .libPaths(), quiet = TRUE))) {
    if (!isTRUE(.wgh_state$warned_dev)) {
      .inform("WeGrowHealthR is not installed, so workers cannot load it. Running sequentially.")
      .wgh_state$warned_dev <- TRUE
    }
    return(FALSE)
  }
  TRUE
}

## One L'Ecuyer-CMRG stream per task, from `seed` (or from the caller's stream
## when `seed` is NULL). Leaves the caller's random number state unchanged.
.stream_seeds <- function(n, seed = NULL) {
  if (is.null(seed)) seed <- sample.int(.Machine$integer.max, 1)
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv()) else NULL
  old_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  s <- get(".Random.seed", envir = globalenv())
  out <- vector("list", n)
  for (i in seq_len(n)) { out[[i]] <- s; s <- parallel::nextRNGStream(s) }
  out
}

## Re-attach a closure to a minimal environment containing only the free
## variables it uses (searched up to the package namespace).
.lean <- function(f, depth = 0) {
  env <- environment(f)
  if (is.null(env) || identical(env, globalenv()) || isNamespace(env) || !requireNamespace("codetools", quietly = TRUE))
    return(f)
  vars <- codetools::findGlobals(f)
  new <- new.env(parent = asNamespace("WeGrowHealthR"))
  e <- env
  while (!identical(e, emptyenv()) && !isNamespace(e) && !identical(e, globalenv())) {
    for (v in vars) if (!exists(v, envir = new, inherits = FALSE) && exists(v, envir = e, inherits = FALSE)) {
      val <- get(v, envir = e)
      if (is.function(val) && !identical(val, f) && depth < 2) val <- .lean(val, depth + 1)
      assign(v, val, envir = new)
    }
    e <- parent.env(e)
  }
  environment(f) <- new
  f
}

## Set a seed for the rest of the calling function and restore the caller's
## random number state when that function exits, so that seeded calls do not
## change the user's random stream
.local_seed <- function(seed, envir = parent.frame()) {
  if (is.null(seed)) return(invisible(NULL))
  old <- if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) get(".Random.seed", envir = globalenv()) else NULL
  restore <- function() {
    if (is.null(old)) { if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv()) }
    else assign(".Random.seed", old, envir = globalenv())
  }
  do.call(on.exit, list(as.call(list(restore)), add = TRUE), envir = envir)
  set.seed(seed)
  invisible(NULL)
}


## Bind a list of data frames into a tibble, dropping NULLs
.bind <- function(lst, .id = NULL) {
  lst <- Filter(Negate(is.null), lst)
  if (!length(lst)) return(tibble::tibble())
  dplyr::bind_rows(lst, .id = .id)
}

## Safe tryCatch that records the message
.try <- function(expr, label = NULL) {
  warns <- character()
  r <- tryCatch(withCallingHandlers(expr, warning = function(w) {
    if (is.null(label)) return(invisible())
    warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error = function(e) {
    structure(list(message = conditionMessage(e), label = label), class = "wgh_error")
  })
  if (!is.null(label)) {
    if (inherits(r, "wgh_error")) .status_add(label, "failed", r$message)
    else .status_add(label, "ok", if (length(warns)) paste("warning:", paste(unique(warns), collapse = " | ")) else "")
  }
  r
}

## Model status log: each flow opens a log (via .with_mode), steps record
## "ok", "failed" or "skipped", and wgh_report() attaches the log
.status_push <- function() .wgh_state$status <- c(list(list()), .wgh_state$status)
.status_pop <- function() if (length(.wgh_state$status)) .wgh_state$status <- .wgh_state$status[-1]
.status_add <- function(step, status = c("ok", "failed", "skipped"), message = "") {
  status <- match.arg(status)
  st <- .wgh_state$status
  if (!length(st)) return(invisible(NULL))
  st[[1]][[length(st[[1]]) + 1]] <- list(step = step, status = status, message = message)
  .wgh_state$status <- st
  invisible(NULL)
}
.skip <- function(step, reason) .status_add(step, "skipped", reason)
.status_table <- function() {
  st <- .wgh_state$status
  if (!length(st) || !length(st[[1]])) return(tibble::tibble(step = character(), status = character(), message = character()))
  tibble::tibble(step = vapply(st[[1]], `[[`, "", "step"), status = vapply(st[[1]], `[[`, "", "status"),
                 message = vapply(st[[1]], `[[`, "", "message"))
}
.is_err <- function(x) inherits(x, "wgh_error")

## Percentile interval from a vector of draws
.pct_ci <- function(x, level = 0.95) {
  a <- (1 - level) / 2
  unname(stats::quantile(x, c(a, 1 - a), na.rm = TRUE))
}

.check_cols <- function(df, cols, fn = "this function") {
  miss <- setdiff(cols, names(df))
  if (length(miss)) .stop(paste0("{.fn ", fn, "} needs column(s) {.val ", paste(miss, collapse = ", "), "} which are missing."))
  invisible(TRUE)
}

## Sex label normalisation to "Male" / "Female"
.norm_sex <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x)) return(ifelse(x == 1, "Male", ifelse(x == 2, "Female", NA_character_)))
  lx <- tolower(trimws(x))
  out <- rep(NA_character_, length(x))
  out[lx %in% c("male", "m", "boy", "boys", "1", "nam")] <- "Male"
  out[lx %in% c("female", "f", "girl", "girls", "2", "nu", "n\u1eef")] <- "Female"
  out
}

.sexes <- c("Male", "Female")

## Give a formula a small environment holding only the non-data objects it
## references, so parallel workers do not receive a large calling frame.
.slim_formula <- function(formula, data) {
  old <- environment(formula) %||% globalenv()
  e <- new.env(parent = asNamespace("splines"))
  for (v in setdiff(all.vars(formula), names(data))) {
    if (exists(v, envir = old, inherits = TRUE)) assign(v, get(v, envir = old, inherits = TRUE), envir = e)
  }
  environment(formula) <- e
  formula
}

.axis_label <- function(v) {
  lab <- c(haz = "Height-for-age z-score", baz = "BMI-for-age z-score", waz = "Weight-for-age z-score",
           height = "Height (cm)", weight = "Weight (kg)", bmi = "BMI (kg/m2)", velocity = "Height velocity (cm/year)")
  if (v %in% names(lab)) lab[[v]] else v
}
