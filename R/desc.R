## Descriptive epidemiology and trends (Book 1 Chapters 4 to 7) -------------

.grp_split <- function(d, by) {
  if (is.null(by) || !length(by)) return(list(All = d))
  key <- interaction(d[by], drop = TRUE, sep = " | ")
  split(d, key)
}
.grp_cols <- function(z, by) {
  if (is.null(by) || !length(by)) return(tibble::tibble())
  tibble::as_tibble(lapply(z[1, by, drop = FALSE], function(v) if (is.factor(v)) as.character(v) else v))
}
.with_grp <- function(z, by, res) {
  if (is.null(by) || !length(by) || !nrow(res)) return(tibble::as_tibble(res))
  dplyr::bind_cols(.grp_cols(z, by)[rep(1, nrow(res)), , drop = FALSE], res)
}
.fix_by <- function(d, by) {
  if (is.null(by)) return(by)
  ifelse(by == "hospitalcode" & !"hospitalcode" %in% names(d) & "site" %in% names(d), "site",
         ifelse(by == "yearvisit" & !"yearvisit" %in% names(d) & "year" %in% names(d), "year", by))
}

#' Cohort characteristics table
#'
#' Summarises variables by group: median (IQR) or mean (SD) for numeric
#' variables and n (%) for categorical ones, with a test of difference
#' between groups (Kruskal-Wallis or chi-square). Use [wgh_flextable()] to
#' format it for a manuscript.
#'
#' @param x Data. When `per_child = TRUE`, the first visit of each child is
#'   used.
#' @param vars Variables to summarise.
#' @param by Grouping variable (optional).
#' @param numeric_summary `"median"` or `"mean"`.
#' @param per_child Summarise one row per child (first visit).
#' @param digits Decimals.
#' @return A tibble with one row per variable level and one column per group.
#' @examples
#' wgh_table1(growdat, vars = c("age", "height", "baz", "site"), by = "sex")
#' @export
wgh_table1 <- function(x, vars, by = NULL, numeric_summary = c("median", "mean"),
                      per_child = FALSE, digits = 1) {
  numeric_summary <- match.arg(numeric_summary)
  d <- .gd(x, "id")
  by <- .fix_by(d, by); vars <- .fix_by(d, vars)
  if (per_child) d <- d[!duplicated(d$id), , drop = FALSE]
  groups <- if (is.null(by)) list(Overall = d) else c(list(Overall = d), split(d, d[[by]], drop = TRUE))
  f <- function(v) formatC(v, digits = digits, format = "f")
  rows <- list()
  rows[[1]] <- tibble::tibble(variable = "N", level = "", !!!stats::setNames(
    lapply(groups, function(g) format(if (per_child) nrow(g) else length(unique(g$id)), big.mark = ",")), names(groups)), p_value = NA_real_)
  for (v in vars) {
    z <- d[[v]]
    if (is.numeric(z)) {
      cell <- lapply(groups, function(g) {
        y <- g[[v]]
        if (numeric_summary == "median") paste0(f(stats::median(y, na.rm = TRUE)), " (", f(stats::quantile(y, 0.25, na.rm = TRUE)), ", ", f(stats::quantile(y, 0.75, na.rm = TRUE)), ")")
        else paste0(f(mean(y, na.rm = TRUE)), " (", f(stats::sd(y, na.rm = TRUE)), ")")
      })
      p <- if (!is.null(by)) tryCatch(stats::kruskal.test(d[[v]], factor(d[[by]]))$p.value, error = function(e) NA) else NA
      rows[[length(rows) + 1]] <- tibble::tibble(variable = v, level = if (numeric_summary == "median") "Median (IQR)" else "Mean (SD)",
                                                 !!!cell, p_value = p)
    } else {
      lv <- if (is.factor(z)) levels(droplevels(as.factor(z))) else sort(unique(stats::na.omit(z)))
      p <- if (!is.null(by)) tryCatch(suppressWarnings(stats::chisq.test(table(z, d[[by]]))$p.value), error = function(e) NA) else NA
      for (l in lv) {
        cell <- lapply(groups, function(g) {
          k <- sum(g[[v]] == l, na.rm = TRUE); paste0(format(k, big.mark = ","), " (", f(100 * k / sum(!is.na(g[[v]]))), ")")
        })
        rows[[length(rows) + 1]] <- tibble::tibble(variable = v, level = as.character(l), !!!cell,
                                                   p_value = if (l == lv[1]) p else NA_real_)
      }
    }
  }
  out <- dplyr::bind_rows(rows)
  if (is.null(by)) out$p_value <- NULL
  out
}

## Sison-Glaz simultaneous multinomial intervals (Sison and Glaz 1995),
## following the algorithm of May and Johnson (2000).
.sg_moments <- function(c, lambda) {
  a <- lambda + c; b <- max(lambda - c, 0)
  den <- if (b > 0) stats::ppois(a, lambda) - stats::ppois(b - 1, lambda) else stats::ppois(a, lambda)
  mu <- numeric(4)
  for (r in 1:4) {
    poisA <- if ((a - r) >= 0) stats::ppois(a, lambda) - stats::ppois(a - r, lambda) else stats::ppois(a, lambda)
    poisB <- if ((b - r - 1) >= 0) stats::ppois(b - 1, lambda) - stats::ppois(b - r - 1, lambda) else
      if ((b - 1) >= 0) stats::ppois(b - 1, lambda) else 0
    mu[r] <- lambda^r * (1 - (poisA - poisB) / den)
  }
  m1 <- mu[1]
  m2 <- mu[2] + mu[1] - mu[1]^2
  m3 <- mu[3] + mu[2] * (3 - 3 * mu[1]) + (mu[1] - 3 * mu[1]^2 + 2 * mu[1]^3)
  m4 <- mu[4] + mu[3] * (6 - 4 * mu[1]) + mu[2] * (7 - 12 * mu[1] + 6 * mu[1]^2) +
    mu[1] - 4 * mu[1]^2 + 6 * mu[1]^3 - 3 * mu[1]^4
  c(m1, m2, m3, m4 - 3 * m2^2, den)
}
.sg_prob <- function(c, x, n) {
  m <- t(vapply(x, function(l) .sg_moments(c, l), numeric(5)))
  s1 <- sum(m[, 1]); s2 <- sum(m[, 2]); s3 <- sum(m[, 3]); s4 <- sum(m[, 4])
  probn <- 1 / (stats::ppois(n, n) - stats::ppois(n - 1, n))
  z <- (n - s1) / sqrt(s2)
  g1 <- s3 / s2^1.5; g2 <- s4 / s2^2
  poly <- 1 + g1 * (z^3 - 3 * z) / 6 + g2 * (z^4 - 6 * z^2 + 3) / 24 +
    g1^2 * (z^6 - 15 * z^4 + 45 * z^2 - 15) / 72
  f <- poly * exp(-z^2 / 2) / sqrt(2 * pi)
  probn * prod(m[, 5]) * f / sqrt(s2)
}

#' Simultaneous confidence intervals for multinomial proportions
#'
#' Sison and Glaz intervals for the shares of several mutually exclusive
#' categories (for example thinness, normal, overweight and obesity), as
#' used in the secular trends study (Ho et al. 2026, Sci Rep 16:7515).
#' @param counts Integer counts per category.
#' @param level Confidence level.
#' @return A tibble with the estimate and simultaneous limits.
#' @examples
#' wgh_multinom_ci(c(Thin = 30, Normal = 520, Overweight = 250, Obese = 200))
#' @export
wgh_multinom_ci <- function(counts, level = 0.95) {
  x <- as.numeric(counts); n <- sum(x); p <- x / n
  pold <- 0; cc <- 1; pnew <- .sg_prob(cc, x, n)
  while (pnew <= level && cc < n) { pold <- pnew; cc <- cc + 1; pnew <- .sg_prob(cc, x, n) }
  delta <- (level - pold) / (pnew - pold)
  cu <- cc - 1
  lo <- pmax(0, p - cu / n); hi <- pmin(1, p + (cu + 2 * delta) / n)
  tibble::tibble(category = names(counts) %||% as.character(seq_along(x)), n = x, estimate = p,
                 lower = lo, upper = hi)
}

.wilson <- function(k, n, level = 0.95) {
  z <- stats::qnorm(1 - (1 - level) / 2); p <- k / n
  den <- 1 + z^2 / n; cen <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  cbind(cen - half, cen + half)
}

#' Prevalence with confidence intervals by any strata
#'
#' For a logical outcome (for example `obesity`) returns cases, total and
#' prevalence with Wilson, Clopper-Pearson or cluster-robust intervals by
#' group. For a categorical outcome (for example `bmi_status`) returns the
#' share of every category with Sison-Glaz simultaneous intervals.
#' Generalises `nutrition_prevalence_table()` from Book 1 Chapter 4.
#'
#' @param x Data, usually after [wgh_classify()].
#' @param outcome Name of a logical or categorical column.
#' @param by Grouping columns.
#' @param method `"wilson"` (default), `"clopper"`, `"cluster"` (accounts
#'   for repeated visits of the same child with a design-based standard
#'   error) or, for categorical outcomes, `"sison_glaz"`.
#' @param level Confidence level.
#' @return A tibble with `n`, `cases`, `prevalence` and limits, in percent.
#' @examples
#' cl <- wgh_classify(growdat)
#' wgh_prevalence(cl, "obesity", by = c("sex", "yearvisit"))
#' wgh_prevalence(cl[cl$age >= 5, ], "bmi_status", by = "sex")
#' @export
wgh_prevalence <- function(x, outcome, by = NULL, method = c("wilson", "clopper", "cluster", "sison_glaz"),
                          level = 0.95) {
  method <- match.arg(method)
  d <- .gd(x, "age")
  by <- .fix_by(d, by)
  y <- d[[outcome]]
  if (is.null(y)) .stop("Outcome {.field {outcome}} not found. Did you run {.fn wgh_classify}?")
  if (!is.logical(y)) {
    return(.bind(lapply(.grp_split(d[!is.na(d[[outcome]]), ], by), function(z) {
      tab <- table(factor(z[[outcome]], levels = if (is.factor(y)) levels(y) else sort(unique(y))))
      ci <- wgh_multinom_ci(tab, level)
      .with_grp(z, by, tibble::tibble(category = names(tab), n = sum(tab), cases = as.integer(tab),
                                                        prevalence = 100 * ci$estimate,
                                                        lower = 100 * ci$lower, upper = 100 * ci$upper))
    })))
  }
  .bind(lapply(.grp_split(d[!is.na(y), ], by), function(z) {
    k <- sum(z[[outcome]]); n <- nrow(z)
    ci <- switch(method,
      wilson = .wilson(k, n, level),
      sison_glaz = .wilson(k, n, level),
      clopper = matrix(as.numeric(stats::binom.test(k, n, conf.level = level)$conf.int), 1),
      cluster = {
        ## ratio estimator with child as cluster
        tk <- tapply(z[[outcome]], z$id, sum); tn <- tapply(z[[outcome]], z$id, length)
        p <- k / n; m <- length(tk)
        se <- sqrt(m / (m - 1) * sum((tk - p * tn)^2)) / n
        zq <- stats::qnorm(1 - (1 - level) / 2)
        cbind(max(0, p - zq * se), min(1, p + zq * se))
      })
    .with_grp(z, by, tibble::tibble(n = n, cases = k, prevalence = 100 * k / n,
                                                      lower = 100 * ci[1, 1], upper = 100 * ci[1, 2]))
  }))
}

#' Trend tests across calendar years or ordered groups
#'
#' * `"cochran_armitage"`: test for a linear trend in a proportion across
#'   ordered groups ([stats::prop.trend.test()]).
#' * `"mood_median"`: Mood's median test of equal medians across groups.
#' * `"median_slope"`: median (quantile) regression slope of a continuous
#'   variable on the ordered variable, with a rank-based confidence
#'   interval (requires `quantreg`).
#'
#' @param x Data.
#' @param outcome Logical column (Cochran-Armitage) or numeric column.
#' @param time Ordered variable such as `yearvisit`.
#' @param by Optional grouping columns; the test is run within each group.
#' @param type Test type.
#' @return A tibble with one row per group.
#' @examples
#' cl <- wgh_classify(growdat)
#' wgh_trend_test(cl[cl$age >= 5, ], "obesity", "yearvisit", by = "sex")
#' wgh_trend_test(growdat, "height", "yearvisit", type = "mood_median")
#' @export
wgh_trend_test <- function(x, outcome, time = "yearvisit", by = NULL,
                          type = c("cochran_armitage", "mood_median", "median_slope")) {
  type <- match.arg(type)
  d <- .gd(x, "age")
  by <- .fix_by(d, by); time <- .fix_by(d, time)
  .bind(lapply(.grp_split(d[!is.na(d[[outcome]]), ], by), function(z) {
    tm <- z[[time]]
    res <- switch(type,
      cochran_armitage = {
        k <- tapply(z[[outcome]], tm, sum); n <- tapply(z[[outcome]], tm, length)
        tt <- suppressWarnings(stats::prop.trend.test(k, n, score = as.numeric(names(k))))
        tibble::tibble(test = "Cochran-Armitage", statistic = unname(tt$statistic), df = 1, p_value = tt$p.value,
                       first = 100 * k[1] / n[1], last = 100 * k[length(k)] / n[length(n)])
      },
      mood_median = {
        med <- stats::median(z[[outcome]])
        tab <- table(z[[outcome]] > med, tm)
        tt <- suppressWarnings(stats::chisq.test(tab))
        mds <- tapply(z[[outcome]], tm, stats::median)
        tibble::tibble(test = "Mood median", statistic = unname(tt$statistic), df = unname(tt$parameter),
                       p_value = tt$p.value, first = mds[1], last = mds[length(mds)])
      },
      median_slope = {
        .need("quantreg")
        f <- quantreg::rq(stats::as.formula(paste(outcome, "~", time)), tau = 0.5, data = z)
        s <- summary(f, se = "rank")$coefficients
        tibble::tibble(test = "Median regression slope", statistic = s[2, 1], df = NA_real_, p_value = NA_real_,
                       first = s[2, 2], last = s[2, 3])
      })
    .with_grp(z, by, res)
  }))
}

#' Median with a distribution-free confidence interval
#' @param x Data.
#' @param var Numeric variable.
#' @param by Grouping columns.
#' @param level Confidence level.
#' @return A tibble with n, median and interval (order-statistic method).
#' @examples
#' wgh_median_ci(growdat[growdat$age >= 17.5, ], "height", by = "sex")
#' @export
wgh_median_ci <- function(x, var, by = NULL, level = 0.95) {
  d <- .gd(x, "age"); by <- .fix_by(d, by)
  .bind(lapply(.grp_split(d[!is.na(d[[var]]), ], by), function(z) {
    y <- sort(z[[var]]); n <- length(y)
    k <- stats::qbinom((1 - level) / 2, n, 0.5)
    lo <- y[max(1, k)]; hi <- y[min(n, n - k + 1)]
    .with_grp(z, by, tibble::tibble(n = n, median = stats::median(y), lower = lo, upper = hi))
  }))
}

#' Bootstrap difference in medians between groups
#'
#' Difference in the median of `var` between each level of `group` and a
#' reference level, with a percentile or BCa bootstrap interval that
#' resamples children (all visits of a child together).
#' @param x Data.
#' @param var Numeric variable.
#' @param group Grouping variable (for example `yearvisit` or a site).
#' @param ref Reference level (default: the first).
#' @param by Optional strata (for example `c("sex", "age_year")`).
#' @param B Bootstrap replicates (default from the run mode).
#' @param seed Random seed.
#' @return A tibble of differences with intervals.
#' @examples
#' d <- growdat[growdat$age >= 8 & growdat$age < 9, ]
#' wgh_median_diff(d, "height", "site", by = "sex", B = 50)
#' @export
wgh_median_diff <- function(x, var, group, ref = NULL, by = NULL, B = wgh_opt("B"), seed = 2026) {
  d <- .gd(x, "id"); by <- .fix_by(d, by); group <- .fix_by(d, group)
  .local_seed(seed)
  .bind(lapply(.grp_split(d[!is.na(d[[var]]), ], by), function(z) {
    g <- as.character(z[[group]])
    lv <- sort(unique(g)); ref0 <- ref %||% lv[1]
    meds <- tapply(z[[var]], g, stats::median)
    ids <- unique(z$id); rows <- split(seq_len(nrow(z)), z$id)
    draws <- replicate(B, {
      pick <- unlist(rows[sample(names(rows), length(rows), replace = TRUE)], use.names = FALSE)
      m <- tapply(z[[var]][pick], g[pick], stats::median)
      m[lv] - m[ref0]
    })
    draws <- matrix(draws, nrow = length(lv), dimnames = list(lv, NULL))
    res <- .bind(lapply(setdiff(lv, ref0), function(l) {
      ci <- .pct_ci(draws[l, ])
      tibble::tibble(level = l, reference = ref0, median = meds[[l]], median_ref = meds[[ref0]],
                     difference = meds[[l]] - meds[[ref0]], lower = ci[1], upper = ci[2])
    }))
    .with_grp(z, by, res)
  }))
}

#' Compare groups at chosen ages with Kruskal-Wallis and Dunn tests
#'
#' At each milestone age (taking visits within `window` years of it), tests
#' whether `var` differs between groups and runs Dunn's pairwise tests with
#' Holm correction.
#' @param x Data.
#' @param var Numeric outcome.
#' @param group Grouping variable (for example a BMI category at an index age).
#' @param ages Milestone ages.
#' @param window Half-width of the age window in years.
#' @param by Optional strata such as `"sex"`.
#' @param p_adjust Method passed to [stats::p.adjust()].
#' @return A list with `overall` (Kruskal-Wallis) and `pairwise` (Dunn).
#' @examples
#' cl <- wgh_classify(growdat)
#' cmp <- wgh_compare_groups(cl, "haz", "bmi_status", ages = c(8, 12), by = "sex")
#' cmp$overall
#' @export
wgh_compare_groups <- function(x, var, group, ages = NULL, window = 0.5, by = NULL, p_adjust = "holm") {
  d <- .gd(x, "age"); by <- .fix_by(d, by)
  sets <- if (is.null(ages)) list(all = d) else stats::setNames(lapply(ages, function(a) d[abs(d$age - a) <= window, ]), ages)
  ov <- list(); pw <- list()
  for (a in names(sets)) for (z in .grp_split(sets[[a]], by)) {
    z <- z[!is.na(z[[var]]) & !is.na(z[[group]]), ]
    g <- droplevels(factor(z[[group]]))
    if (nlevels(g) < 2) next
    kw <- stats::kruskal.test(z[[var]], g)
    meds <- tapply(z[[var]], g, stats::median)
    ov[[length(ov) + 1]] <- .with_grp(z, by, tibble::tibble(
      age = a, n = nrow(z), statistic = unname(kw$statistic), df = unname(kw$parameter), p_value = kw$p.value,
      medians = paste(names(meds), round(meds, 2), sep = ": ", collapse = "; ")))
    r <- rank(z[[var]]); N <- length(r)
    ties <- table(r); tc <- sum(ties^3 - ties) / (12 * (N - 1))
    mr <- tapply(r, g, mean); ng <- table(g)
    cmb <- utils::combn(levels(g), 2)
    dd <- .bind(lapply(seq_len(ncol(cmb)), function(j) {
      a1 <- cmb[1, j]; a2 <- cmb[2, j]
      se <- sqrt((N * (N + 1) / 12 - tc) * (1 / ng[[a1]] + 1 / ng[[a2]]))
      zz <- (mr[[a1]] - mr[[a2]]) / se
      tibble::tibble(group1 = a1, group2 = a2, z = zz, p_value = 2 * stats::pnorm(-abs(zz)))
    }))
    dd$p_adjusted <- stats::p.adjust(dd$p_value, p_adjust)
    pw[[length(pw) + 1]] <- .with_grp(z, by, dplyr::bind_cols(tibble::tibble(age = rep(a, nrow(dd))), dd))
  }
  list(overall = .bind(ov), pairwise = .bind(pw))
}

#' Calendar-time trends with generalised estimating equations
#'
#' Fits a GEE with child as the cluster (exchangeable correlation) for a
#' continuous or binary outcome on calendar year, optionally interacting with
#' age group, and reports the yearly change (or odds ratio per year) within
#' each age group. The model behind the GEE trend tables of the malnutrition trends study (Ho et al. 2026, medRxiv 2026.07.26.26358982) and the
#' secular trends study (Ho et al. 2026, Sci Rep 16:7515).
#'
#' @param x Data.
#' @param outcome Outcome column (numeric or logical).
#' @param year Calendar year column.
#' @param age_group Optional factor column; slopes are reported within each
#'   level. Use [wgh_age_bands()] to create one.
#' @param covariates Extra adjustment terms (character).
#' @param by Optional strata (each fitted separately), usually `"sex"`.
#' @param corstr Working correlation.
#' @param min_events For binary outcomes, age groups (and strata) with fewer
#'   events are skipped, because rare outcomes make GEE fail to converge.
#' @param maxit Maximum GEE iterations.
#' @return An object of class `wgh_gee` with the fits and a `slopes` table.
#' @examplesIf rlang::is_installed("geepack")
#' \donttest{
#' cl <- wgh_classify(growdat)
#' cl$age_group <- wgh_age_bands(cl$age)
#' tr <- wgh_gee_trend(cl[cl$age >= 5, ], "obesity", age_group = "age_group", by = "sex")
#' tr$slopes
#' }
#' @export
wgh_gee_trend <- function(x, outcome, year = "yearvisit", age_group = NULL, covariates = NULL,
                         by = "sex", corstr = "exchangeable", min_events = 10, maxit = 25) {
  .need("geepack")
  d <- .gd(x, "id"); by <- .fix_by(d, by); year <- .fix_by(d, year)
  binary <- is.logical(d[[outcome]])
  fits <- list(); slopes <- list()
  for (z in .grp_split(d, by)) {
    z <- z[stats::complete.cases(z[, c(outcome, year, age_group, covariates), drop = FALSE]), ]
    z <- z[order(z$id, z$age), ]
    z$.y <- as.numeric(z[[outcome]]); z$.yr <- z[[year]] - stats::median(z[[year]])
    if (!is.null(age_group)) {
      z[[age_group]] <- droplevels(factor(z[[age_group]]))
      if (binary) {
        ev <- tapply(z$.y, z[[age_group]], sum)
        sparse <- names(ev)[ev < min_events]
        if (length(sparse)) {
          .warn("Skipping age group(s) {paste(sparse, collapse = ', ')} with fewer than {min_events} events.")
          z <- z[!z[[age_group]] %in% sparse, ]
          z[[age_group]] <- droplevels(z[[age_group]])
        }
      }
    }
    if (binary && sum(z$.y) < min_events) next
    rhs <- if (is.null(age_group)) ".yr" else paste0(age_group, " / .yr")
    if (length(covariates)) rhs <- paste(rhs, "+", paste(covariates, collapse = " + "))
    if (!is.null(age_group)) rhs <- paste("0 +", rhs)
    f <- stats::as.formula(paste(".y ~", rhs))
    z$.cl <- as.integer(factor(z$id))
    fit <- geepack::geeglm(f, id = z$.cl, data = z, corstr = corstr,
                           family = if (binary) stats::binomial() else stats::gaussian(),
                           control = geepack::geese.control(maxit = maxit))
    key <- paste(unlist(.grp_cols(z, by)), collapse = " | ")
    fits[[if (nzchar(key)) key else "All"]] <- fit
    co <- summary(fit)$coefficients
    rows <- grep("\\.yr", rownames(co))
    est <- co[rows, "Estimate"]; se <- co[rows, "Std.err"]
    tab <- tibble::tibble(term = rownames(co)[rows], estimate = est, se = se,
                          lower = est - 1.96 * se, upper = est + 1.96 * se, p_value = co[rows, "Pr(>|W|)"])
    tab$age_group <- if (is.null(age_group)) "All" else sub(paste0("^", age_group), "", sub(":\\.yr$", "", tab$term))
    if (binary) { tab$or_per_year <- exp(tab$estimate); tab$or_lower <- exp(tab$lower); tab$or_upper <- exp(tab$upper) }
    slopes[[length(slopes) + 1]] <- .with_grp(z, by, tab)
  }
  structure(list(fits = fits, slopes = .bind(slopes), outcome = outcome, binary = binary),
            class = "wgh_gee")
}

#' @export
print.wgh_gee <- function(x, ...) {
  cli::cli_text("{.cls wgh_gee}: {if (x$binary) 'odds ratio' else 'change'} per calendar year in {.field {x$outcome}}")
  print(x$slopes, n = Inf)
  invisible(x)
}

#' @rdname wgh_gee_trend
#' @param object A `wgh_gee` object.
#' @export
wgh_trend_slopes <- function(object) object$slopes
