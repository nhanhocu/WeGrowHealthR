#' Clean a raw growth data export in one call
#'
#' The finished form of `clean_growth_data()` from Book 1 Chapter 2. It
#' standardises identifiers and sex codes, repairs unit errors that can be
#' detected with confidence (height in metres, weight in grams, swapped
#' height and weight), computes exact decimal age from dates when they are
#' present, removes exact duplicate visits, flags implausible values and
#' returns a log of every change.
#'
#' Repairs are conservative: a value is only changed when the error type is
#' unambiguous. Everything else is flagged, not altered.
#'
#' @param x A data frame or [wgh_data] object. Recognised columns: `pid` or
#'   `id`, `sex`, `age`, `dob`, `examdate`, `height`, `weight`.
#' @param repair_units Repair height in metres, weight in grams and swapped
#'   height and weight.
#' @param drop_duplicates Remove repeated child-date (or child-age) rows.
#' @param z_limit Absolute z-score at which values are flagged as
#'   implausible (after z-scores are computed).
#' @return A tibble with cleaned data, z-scores, a logical column
#'   `implausible`, and an attribute `"cleaning_log"`.
#' @examples
#' clean <- wgh_clean(growdat_raw)
#' attr(clean, "cleaning_log")
#' @export
wgh_clean <- function(x, repair_units = TRUE, drop_duplicates = TRUE, z_limit = 6) {
  d <- as.data.frame(if (inherits(x, "wgh_data")) x$data else x, stringsAsFactors = FALSE)
  idc <- intersect(c("pid", "id"), names(d))[1]
  log <- list()
  add <- function(step, n) log[[length(log) + 1]] <<- tibble::tibble(step = step, rows_affected = as.integer(n))
  ## identifiers
  old <- d[[idc]]; d[[idc]] <- trimws(as.character(d[[idc]]))
  add("Trimmed spaces in identifiers", sum(old != d[[idc]], na.rm = TRUE))
  ## sex
  sx <- .norm_sex(d$sex)
  add("Recoded sex values", sum(as.character(d$sex) != sx, na.rm = TRUE))
  d$sex <- factor(sx, levels = .sexes)
  ## conflicting sex within child: use the most common value
  mode_sex <- tapply(as.character(d$sex), d[[idc]], function(z) names(sort(table(z), decreasing = TRUE))[1])
  conf <- as.character(d$sex) != mode_sex[d[[idc]]]
  add("Resolved conflicting sex within child", sum(conf, na.rm = TRUE))
  d$sex <- factor(mode_sex[d[[idc]]], levels = .sexes)
  ## age from dates
  if (all(c("dob", "examdate") %in% names(d))) {
    d$dob <- as.Date(d$dob); d$examdate <- as.Date(d$examdate)
    if ("yearvisit" %in% names(d)) {
      ## examination dated in a different school year than recorded: trust the school year
      yr_exam <- as.integer(format(d$examdate, "%Y")) - (as.integer(format(d$examdate, "%m")) < 9)
      bad_year <- !is.na(yr_exam) & !is.na(d$yearvisit) & yr_exam != d$yearvisit
      d$examdate[bad_year] <- d$examdate[bad_year] + 365L * (d$yearvisit[bad_year] - yr_exam[bad_year])
      add("Corrected examination year from the school year", sum(bad_year))
    }
    a <- as.numeric(d$examdate - d$dob) / 365.25
    if (!"age" %in% names(d)) d$age <- a else {
      ch <- !is.na(a) & (is.na(d$age) | abs(a - d$age) > 0.01)
      d$age[ch] <- a[ch]
      add("Recomputed age from dates", sum(ch))
    }
  }
  if (repair_units && all(c("height", "weight") %in% names(d))) {
    h <- suppressWarnings(as.numeric(d$height)); w <- suppressWarnings(as.numeric(d$weight))
    m <- !is.na(h) & h > 0.4 & h < 2.3
    h[m] <- h[m] * 100; add("Height in metres converted to cm", sum(m))
    g <- !is.na(w) & w > 1000
    w[g] <- w[g] / 1000; add("Weight in grams converted to kg", sum(g))
    sw <- !is.na(h) & !is.na(w) & h < w & h < 100 & w > 60 & d$age > 3
    tmp <- h[sw]; h[sw] <- w[sw]; w[sw] <- tmp
    add("Swapped height and weight restored", sum(sw))
    d$height <- h; d$weight <- w
  }
  if (drop_duplicates) {
    key <- if ("examdate" %in% names(d)) paste(d[[idc]], d$examdate) else paste(d[[idc]], round(d$age, 3))
    dup <- duplicated(key)
    add("Duplicate visits removed", sum(dup))
    d <- d[!dup, , drop = FALSE]
  }
  d <- d[order(d[[idc]], d$age), , drop = FALSE]
  if ("height" %in% names(d) && "weight" %in% names(d)) d$bmi <- d$weight / (d$height / 100)^2
  d <- wgh_add_zscores(tibble::as_tibble(d), flag_limit = z_limit)
  fl <- intersect(c("haz_flag", "waz_flag", "baz_flag"), names(d))
  d$implausible <- if (length(fl)) Reduce(`|`, lapply(fl, function(f) d[[f]])) else FALSE
  ## digit slips: height jumps that reverse within a child
  if ("height" %in% names(d)) {
    jump <- .height_jump_flag(d[[idc]], d$age, d$height)
    d$implausible <- d$implausible | jump
    add("Height inconsistent with the child's own series (flagged)", sum(jump, na.rm = TRUE))
  }
  add("Rows flagged as implausible", sum(d$implausible, na.rm = TRUE))
  rownames(d) <- NULL
  out <- tibble::as_tibble(d)
  attr(out, "cleaning_log") <- .bind(log)
  out
}

.height_jump_flag <- function(id, age, h) {
  out <- rep(FALSE, length(h))
  idx <- split(seq_along(h), id)
  idx <- idx[lengths(idx) >= 3]
  for (ii in idx) {
    hh <- h[ii]; aa <- age[ii]
    for (k in seq_along(ii)) {
      ok <- setdiff(which(!is.na(hh)), k)
      if (length(ok) < 2 || is.na(hh[k])) next
      nb <- ok[order(abs(aa[ok] - aa[k]))][1:2]
      if (diff(aa[nb]) == 0) next
      slope <- diff(hh[nb]) / diff(aa[nb])
      pred <- hh[nb[1]] + slope * (aa[k] - aa[nb[1]])
      gap <- min(abs(aa[nb] - aa[k]))
      if (abs(hh[k] - pred) > 20 + 5 * gap) out[ii[k]] <- TRUE
    }
  }
  out
}

#' Exact decimal age, optionally corrected for preterm birth
#' @param dob,date Dates of birth and of measurement.
#' @param gestational_age Gestational age at birth in weeks. When supplied,
#'   age is corrected for prematurity up to `correct_until` years.
#' @param correct_until Age (years) up to which the correction is applied.
#' @return Age in years.
#' @examples
#' wgh_decimal_age(as.Date("2015-03-01"), as.Date("2023-09-20"))
#' wgh_decimal_age(as.Date("2023-01-01"), as.Date("2023-07-01"), gestational_age = 32)
#' @export
wgh_decimal_age <- function(dob, date, gestational_age = NULL, correct_until = 2) {
  a <- as.numeric(as.Date(date) - as.Date(dob)) / 365.25
  if (!is.null(gestational_age)) {
    corr <- pmax(40 - gestational_age, 0) * 7 / 365.25
    a <- ifelse(a < correct_until, a - corr, a)
  }
  a
}

#' Standard age groups and calendar periods
#' @param age Age in years.
#' @param breaks Group limits. The default gives the groups used in the
#'   papers: under 5, 5 to 10, 11 to 14 and 15 to 18 years.
#' @param labels Optional labels.
#' @param year Calendar or school year.
#' @param periods Named list of year ranges.
#' @return A factor.
#' @examples
#' table(wgh_age_bands(growdat$age))
#' table(wgh_add_period(growdat$yearvisit))
#' @export
wgh_age_bands <- function(age, breaks = c(0, 5, 11, 15, 19), labels = NULL) {
  if (is.null(labels)) {
    labels <- paste0(utils::head(breaks, -1), "-", utils::tail(breaks, -1) - 1, " y")
    if (breaks[1] == 0) labels[1] <- paste0("<", breaks[2], " y")
  }
  cut(age, breaks, labels = labels, right = FALSE)
}

#' @rdname wgh_age_bands
#' @export
wgh_add_period <- function(year, periods = list(`Pre-COVID` = 2018:2019, COVID = 2020:2021,
                                               `Post-COVID` = 2022:2030)) {
  out <- rep(NA_character_, length(year))
  for (p in names(periods)) out[year %in% periods[[p]]] <- p
  factor(out, levels = names(periods))
}

#' Flag biologically implausible values
#'
#' Applies the WHO rules for implausible z-scores (HAZ below -6 or above 6,
#' WAZ below -6 or above 5, BAZ below -5 or above 5) or the program's single
#' rule of an absolute z-score of 6 or more.
#' @param x Data with z-score columns.
#' @param rule `"who"` or `"program"`.
#' @return `x` with a logical column `biv` and one flag per z-score.
#' @examples
#' table(wgh_flag_biv(growdat)$biv)
#' @export
wgh_flag_biv <- function(x, rule = c("who", "program")) {
  rule <- match.arg(rule)
  d <- .gd(x, "age")
  lim <- if (rule == "who") list(haz = c(-6, 6), waz = c(-6, 5), baz = c(-5, 5)) else
    list(haz = c(-6, 6), waz = c(-6, 6), baz = c(-6, 6))
  d$biv <- FALSE
  for (z in names(lim)) {
    if (!z %in% names(d)) next
    f <- !is.na(d[[z]]) & (d[[z]] < lim[[z]][1] | d[[z]] > lim[[z]][2])
    d[[paste0(z, "_biv")]] <- f
    d$biv <- d$biv | f
  }
  .regd(x, d)
}

#' Terminal digit preference in recorded measurements
#'
#' Measurers often round to whole or half centimetres. This function
#' tabulates the first decimal digit and tests it against a uniform
#' distribution, with a bar chart.
#' @param x A numeric vector of measurements, or data with column `var`.
#' @param var Column name when `x` is a data frame.
#' @return A list with the digit table, a chi-square test and a ggplot.
#' @examples
#' dp <- wgh_digit_preference(growdat$height)
#' dp$test
#' @export
wgh_digit_preference <- function(x, var = "height") {
  v <- if (is.data.frame(x)) x[[var]] else x
  v <- v[!is.na(v)]
  dig <- factor(round((v * 10) %% 10) %% 10, levels = 0:9)
  tab <- table(dig)
  test <- suppressWarnings(stats::chisq.test(tab))
  df <- data.frame(digit = names(tab), n = as.integer(tab))
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$digit, .data$n)) +
    ggplot2::geom_col(fill = "#56B4E9") +
    ggplot2::geom_hline(yintercept = sum(tab) / 10, linetype = 2) + theme_wgh() +
    ggplot2::labs(x = "Terminal (first decimal) digit", y = "Measurements",
                  caption = "Dashed line: expected count with no digit preference.")
  list(table = tab, test = test, plot = p)
}

#' Remove duplicate visits and guarantee increasing ages within a child
#' @param x Growth data.
#' @param min_gap Minimum gap in years between two visits of the same child.
#'   Visits closer than this are collapsed, keeping the first.
#' @return Data without duplicate child-age rows.
#' @examples
#' nrow(wgh_dedup_visits(rbind(growdat, growdat[1:5, ])))
#' @export
wgh_dedup_visits <- function(x, min_gap = 1 / 12) {
  d <- .gd(x, c("id", "age"))
  d <- d[order(d$id, d$age), , drop = FALSE]
  gap <- stats::ave(d$age, d$id, FUN = function(a) c(Inf, diff(a)))
  d <- d[gap >= min_gap, , drop = FALSE]
  .regd(x, d)
}

#' Summarise the visit pattern of a longitudinal cohort
#' @param x Growth data.
#' @param by Optional grouping column, such as `"sex"` or `"site"`.
#' @return A tibble with numbers of children and visits, visits per child,
#'   follow-up span and the median interval between visits.
#' @examples
#' wgh_visit_summary(growdat, by = "sex")
#' @export
wgh_visit_summary <- function(x, by = NULL) {
  d <- .gd(x, c("id", "age"))
  f <- function(z) {
    per <- table(z$id)
    span <- tapply(z$age, z$id, function(a) diff(range(a)))
    gaps <- unlist(tapply(z$age, z$id, function(a) diff(sort(a))))
    tibble::tibble(children = length(per), visits = nrow(z),
                   visits_per_child_mean = mean(as.numeric(per)),
                   visits_per_child_median = stats::median(as.numeric(per)),
                   pct_3plus_visits = 100 * mean(per >= 3),
                   span_median_y = stats::median(span),
                   interval_median_y = if (length(gaps)) stats::median(gaps) else NA_real_)
  }
  if (is.null(by)) return(f(d))
  .bind(lapply(split(d, d[[by]]), function(z) dplyr::bind_cols(tibble::tibble(!!by := as.character(z[[by]][1])), f(z))))
}

#' Join height-based and BMI-based panels of the same children
#' @param x,y Data frames with `id` (or `pid`) and `age`.
#' @param tol Maximum age difference (years) for two visits to be matched.
#' @return The rows of `x` with matched columns of `y`.
#' @examples
#' a <- growdat[, c("pid", "age", "height")]
#' b <- growdat[, c("pid", "age", "baz")]
#' head(wgh_merge_measures(a, b))
#' @export
wgh_merge_measures <- function(x, y, tol = 0.1) {
  a <- .gd(x, c("id", "age")); b <- .gd(y, c("id", "age"))
  a$.row <- seq_len(nrow(a))
  extra <- setdiff(names(b), names(a))
  bb <- b[, c("id", "age", extra), drop = FALSE]
  names(bb)[2] <- ".age_y"
  m <- merge(a[, c("id", "age", ".row")], bb, by = "id")
  m$.dist <- abs(m$age - m$.age_y)
  m <- m[m$.dist <= tol, , drop = FALSE]
  m <- m[order(m$.row, m$.dist), , drop = FALSE]
  m <- m[!duplicated(m$.row), , drop = FALSE]
  out <- cbind(a[m$.row, setdiff(names(a), ".row"), drop = FALSE], m[, extra, drop = FALSE])
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
