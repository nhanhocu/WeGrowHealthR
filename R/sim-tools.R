#' Inject realistic data-entry errors into a clean growth dataset
#'
#' Turns a clean simulated dataset into a raw export of the kind Book 1
#' Chapter 2 teaches you to clean. Every injected error is logged, so the
#' cleaning can be checked against the truth.
#'
#' Error types: height entered in metres, weight entered in grams, height
#' and weight swapped, digit slips (an extra or dropped digit), duplicated
#' rows, inconsistent sex codes, stray spaces in identifiers, examination
#' dates with a wrong year and missing values.
#'
#' @param data A data frame from [wgh_simulate()] (`$visits`) or `growdat`.
#' @param rate Overall share of rows that receive one error (default 0.03).
#' @param seed Random seed.
#' @return The data with errors, with an attribute `"messiness_log"` (a
#'   tibble listing row, column, error type, original and new value). Columns
#'   are converted to character where a real export would hold text.
#' @examples
#' raw <- wgh_add_messiness(growdat, rate = 0.05, seed = 1)
#' head(attr(raw, "messiness_log"))
#' @export
wgh_add_messiness <- function(data, rate = 0.03, seed = 2024) {
  .local_seed(seed)
  d <- as.data.frame(data, stringsAsFactors = FALSE)
  d$sex <- as.character(d$sex)
  if ("site" %in% names(d)) d$site <- as.character(d$site)
  d <- d[, setdiff(names(d), c("haz", "waz", "baz", "bmiz", "bmi")), drop = FALSE]
  n <- nrow(d)
  types <- c("height_m", "weight_g", "swap", "digit", "sex_code", "id_space",
             "date_year", "missing_height", "missing_weight", "duplicate")
  k <- stats::rbinom(1, n, rate)
  rows <- sample.int(n, k)
  ty <- sample(types, k, replace = TRUE,
               prob = c(0.10, 0.08, 0.08, 0.14, 0.14, 0.08, 0.10, 0.10, 0.08, 0.10))
  log <- vector("list", k)
  d$pid <- as.character(d$pid)
  for (j in seq_len(k)) {
    i <- rows[j]; t <- ty[j]
    old <- NA_character_; col <- NA_character_; new <- NA_character_
    if (t == "height_m") { col <- "height"; old <- d$height[i]; d$height[i] <- round(d$height[i] / 100, 3) }
    if (t == "weight_g") { col <- "weight"; old <- d$weight[i]; d$weight[i] <- round(d$weight[i] * 1000) }
    if (t == "swap") { col <- "height/weight"; old <- paste(d$height[i], d$weight[i]); h <- d$height[i]; d$height[i] <- d$weight[i]; d$weight[i] <- h }
    if (t == "digit") { col <- "height"; old <- d$height[i]; d$height[i] <- if (stats::runif(1) < 0.5) d$height[i] + 100 else round(d$height[i] / 10, 1) }
    if (t == "sex_code") { col <- "sex"; old <- d$sex[i]; d$sex[i] <- if (d$sex[i] == "Male") sample(c("M", "male", "1", "Nam"), 1) else sample(c("F", "female", "2", "N\u1eef"), 1) }
    if (t == "id_space") { col <- "pid"; old <- d$pid[i]; d$pid[i] <- paste0(" ", d$pid[i], " ") }
    if (t == "date_year" && "examdate" %in% names(d)) { col <- "examdate"; old <- as.character(d$examdate[i]); d$examdate[i] <- d$examdate[i] + sample(c(-365L, 365L), 1) }
    if (t == "missing_height") { col <- "height"; old <- d$height[i]; d$height[i] <- NA }
    if (t == "missing_weight") { col <- "weight"; old <- d$weight[i]; d$weight[i] <- NA }
    if (t == "duplicate") { col <- "(row)"; old <- "" }
    if (!is.na(col) && col %in% names(d)) new <- as.character(d[[col]][i])
    log[[j]] <- tibble::tibble(row = i, pid = trimws(d$pid[i]), column = col, error = t,
                               original = as.character(old), injected = new)
  }
  dup <- rows[ty == "duplicate"]
  if (length(dup)) d <- rbind(d, d[dup, , drop = FALSE])
  d <- d[order(trimws(d$pid), if ("age" %in% names(d)) d$age else seq_len(nrow(d))), ]
  rownames(d) <- NULL
  out <- tibble::as_tibble(d)
  attr(out, "messiness_log") <- .bind(log)
  out
}

#' Simulate a small clinical dataset with sparse, irregular visits
#'
#' Clinic data differ from school data: few children, irregular visit
#' times, a wide age range from infancy and a reason for referral. The
#' dataset is used in Book 1 Part II and for broken-stick examples.
#'
#' @param n Number of children.
#' @param seed Random seed.
#' @return A tibble with `pid`, `sex`, `group`, `gestational_age` (weeks),
#'   `age` (chronological, years), `age_corrected`, `height`, `weight`, `bmi`
#'   and z-scores.
#' @examples
#' cc <- wgh_simulate_clinical_cases(30, seed = 1)
#' table(cc$group)
#' @export
wgh_simulate_clinical_cases <- function(n = 60, seed = 2024) {
  .local_seed(seed)
  sim <- wgh_simulate(n * 6, preset = "wgh_like", seed = seed + 1)
  s <- sim$settings
  kids <- sim$truth_child[sample.int(nrow(sim$truth_child), n), ]
  grp <- sample(c("Routine follow-up", "Short stature referral", "Obesity clinic", "Preterm follow-up"),
                n, replace = TRUE, prob = c(0.35, 0.25, 0.25, 0.15))
  ga <- ifelse(grp == "Preterm follow-up", round(stats::runif(n, 28, 36)), round(stats::rnorm(n, 39, 1)))
  ga <- pmin(pmax(ga, 24), 42)
  peaks <- sim$pop_peaks; mu <- stats::setNames(peaks$aphv, peaks$sex)
  rows <- lapply(seq_len(n), function(i) {
    k <- kids[i, ]
    nv <- sample(3:8, 1)
    start <- stats::runif(1, 0.3, 12)
    ages <- sort(start + cumsum(c(0, stats::rexp(nv - 1, 1 / 0.9))))
    ages <- ages[ages < 18.5]
    sx <- as.character(k$sex)
    tstar <- mu[[sx]] + (ages - mu[[sx]] - k$b_tempo) * exp(k$c_intensity)
    g <- stats::plogis((ages - (mu[[sx]] - 3.5)) / 0.8)
    tstar <- ages + (tstar - ages) * g
    age_corr <- pmax(ages - pmax(40 - ga[i], 0) / 52.18 * (ages < 2), 0.05)
    size <- k$a_size + switch(grp[i], `Short stature referral` = -8, `Preterm follow-up` = -1.5, 0)
    ht <- size + .mean_height(tstar - (ages - age_corr), sx, s)
    baz <- 0.4 + switch(grp[i], `Obesity clinic` = 2.4, 0) + 1.1 * k$u_adip + stats::rnorm(length(ages), 0, 0.25)
    lms <- wgh_reference("bfa", ages, sx)
    bmi <- .lms_value_who(baz, lms$L, lms$M, lms$S)
    tibble::tibble(pid = sprintf("K%03d", i), sex = factor(sx, levels = .sexes), group = grp[i],
                   gestational_age = ga[i], age = round(ages, 3), age_corrected = round(age_corr, 3),
                   height = round(.isotonic(ht + stats::rnorm(length(ages), 0, 0.4)), 1),  # non-decreasing
                   weight = round(bmi * (ht / 100)^2, 1))
  })
  d <- .bind(rows)
  d$bmi <- round(d$weight / (d$height / 100)^2, 2)
  d$haz <- round(wgh_zscore(d$height, d$age, d$sex, "hfa"), 3)
  d$waz <- round(wgh_zscore(d$weight, d$age, d$sex, "wfa"), 3)
  d$baz <- round(wgh_zscore(d$bmi, d$age, d$sex, "bfa"), 3)
  d
}

#' Check estimates against the simulation truth
#'
#' Compares child-level estimates (for example individual APHV from a SITAR
#' fit) or population estimates with the true values held in a `wgh_sim`
#' truth file, and reports bias, root mean squared error, correlation and,
#' when intervals are supplied, coverage.
#'
#' @param estimate A data frame with `pid` and an estimate column, or a
#'   numeric vector of population estimates.
#' @param truth A data frame with `pid` and the true value, usually
#'   `sim$truth_child`, or a numeric vector of true values.
#' @param est_col,truth_col Column names of the estimate and the truth.
#' @param lo,hi Optional interval columns in `estimate`.
#' @param by Optional grouping column present in both (for example `sex`).
#' @return A tibble of recovery statistics.
#' @examples
#' sim <- wgh_simulate(1500, seed = 3)
#' est <- data.frame(pid = sim$truth_child$pid,
#'                   aphv = sim$truth_child$aphv_true + rnorm(nrow(sim$truth_child), 0, 0.3))
#' wgh_truth_check(est, sim$truth_child, "aphv", "aphv_true")
#' @export
wgh_truth_check <- function(estimate, truth, est_col = "estimate", truth_col = "truth",
                           lo = NULL, hi = NULL, by = NULL) {
  if (is.numeric(estimate) && is.numeric(truth)) {
    return(tibble::tibble(estimate = estimate, truth = truth, bias = estimate - truth,
                          relative_bias = (estimate - truth) / truth))
  }
  e <- as.data.frame(estimate); t <- as.data.frame(truth)
  keep_t <- unique(c("pid", truth_col, by))
  m <- merge(e, t[, intersect(keep_t, names(t)), drop = FALSE], by = intersect(c("pid", by), names(e)))
  stat <- function(z) {
    err <- z[[est_col]] - z[[truth_col]]
    out <- tibble::tibble(n = nrow(z), bias = mean(err, na.rm = TRUE),
                          rmse = sqrt(mean(err^2, na.rm = TRUE)),
                          correlation = stats::cor(z[[est_col]], z[[truth_col]], use = "complete.obs"),
                          sd_estimate = stats::sd(z[[est_col]], na.rm = TRUE),
                          sd_truth = stats::sd(z[[truth_col]], na.rm = TRUE))
    if (!is.null(lo) && !is.null(hi))
      out$coverage <- mean(z[[truth_col]] >= z[[lo]] & z[[truth_col]] <= z[[hi]], na.rm = TRUE)
    out
  }
  if (is.null(by)) return(stat(m))
  .bind(lapply(split(m, m[[by]]), function(z) dplyr::bind_cols(tibble::tibble(!!by := z[[by]][1]), stat(z))))
}

#' Published patterns that the wgh_like preset is set to resemble
#'
#' Each row is one pattern from a published paper of the child growth research
#' program, with the published value, an acceptable band and its source.
#' The bands are deliberately generous: the simulated cohort is meant to
#' resemble the published results, so that analyses give similar tables and
#' figures, not to reproduce them.
#'
#' @format A tibble with columns `target`, `sex`, `published`, `lower`,
#'   `upper`, `unit`, `source` and `tuned` (whether the target was used when
#'   setting the preset, or kept out as an independent check).
#' @source Ho et al. (2026, Sci Rep 16:7515), Ho et al. (2026, medRxiv
#'   2026.07.26.26358982), Ho et al. (2026, medRxiv 2026.07.26.26358986), Ho
#'   (2026, medRxiv 2026.09.08.26362487) and Ho (2026, medRxiv
#'   2026.09.05.26362315). Full citations: [wgh_references()].
#' @examples
#' head(wgh_targets)
#' table(wgh_targets$source)
"wgh_targets"

#' Compare a simulated cohort with the published patterns
#'
#' Computes, for a `wgh_sim` object or its visit data, each pattern listed in
#' [wgh_targets] that can be computed without fitting models, and reports
#' whether it falls in the acceptable band. Patterns that need a fitted
#' model (for example SITAR APHV) are computed from the truth file when a
#' `wgh_sim` object is supplied.
#'
#' @param sim A `wgh_sim` object from [wgh_simulate()] or a visits data frame.
#' @param targets The targets table, by default [wgh_targets].
#' @return A tibble with the published and simulated value of each pattern
#'   and a `pass` column. The object has class `wgh_resemblance` and a plot
#'   method.
#' @examples
#' sim <- wgh_simulate(8000, seed = 11)
#' wgh_resemblance_report(sim)
#' @export
wgh_resemblance_report <- function(sim, targets = WeGrowHealthR::wgh_targets) {
  v <- if (inherits(sim, "wgh_sim")) sim$visits else tibble::as_tibble(sim)
  if (!"yearvisit" %in% names(v) && "schoolyear" %in% names(v)) v$yearvisit <- v$schoolyear
  if (!"baz" %in% names(v) && "bmiz" %in% names(v)) v$baz <- v$bmiz
  sexes <- as.character(v$sex)
  vals <- list()
  put <- function(target, sex, value) vals[[length(vals) + 1]] <<- tibble::tibble(target = target, sex = sex, simulated = value)
  site_share <- prop.table(table(v$site)) * 100
  put("Visits at largest site (%)", "All", max(site_share))
  put("Visits at smallest site (%)", "All", min(site_share))
  ag <- cut(v$age, c(0, 5, 11, Inf), right = FALSE)
  put("Visits at ages 5 to 11 (%)", "All", 100 * mean(ag == levels(ag)[2]))
  put("Visits under 5 years (%)", "All", 100 * mean(ag == levels(ag)[1]))
  yrs <- sort(unique(v$yearvisit))
  put("Visits in first year (%)", "All", 100 * mean(v$yearvisit == yrs[1]))
  for (sx in .sexes) {
    o <- v[sexes == sx & v$age >= 5, ]
    u <- v[sexes == sx & v$age < 5, ]
    put("Overweight or obesity, 5 to 18 y (%)", sx, 100 * mean(o$baz > 1, na.rm = TRUE))
    put("Obesity, 5 to 18 y (%)", sx, 100 * mean(o$baz > 2, na.rm = TRUE))
    put("Overweight or obesity, under 5 (%)", sx, 100 * mean(u$baz > 2, na.rm = TRUE))
    put("Stunting, 5 to 18 y (%)", sx, 100 * mean(o$haz < -2, na.rm = TRUE))
    put("Stunting, under 5 (%)", sx, 100 * mean(u$haz < -2, na.rm = TRUE))
    first <- o[o$yearvisit == yrs[1] | o$yearvisit == yrs[2], ]
    last <- o[o$yearvisit == max(yrs), ]
    put("Change in obesity, first to last year (points)", sx,
        100 * (mean(last$baz > 2, na.rm = TRUE) - mean(first$baz > 2, na.rm = TRUE)))
    a18 <- v[sexes == sx & v$age >= 17.5, ]
    put("Median height at 18 y (cm)", sx, stats::median(a18$height, na.rm = TRUE))
    mid <- v[sexes == sx & v$age >= 5 & v$age < 11, ]
    put("BAZ to HAZ slope, ages 5 to 11", sx, unname(stats::coef(stats::lm(haz ~ baz, data = mid))[2]))
    late <- v[sexes == sx & v$age >= 16, ]
    if (nrow(late) > 30) put("BAZ to HAZ slope, ages 16 to 18", sx, unname(stats::coef(stats::lm(haz ~ baz, data = late))[2]))
    if (inherits(sim, "wgh_sim")) {
      tc <- sim$truth_child[as.character(sim$truth_child$sex) == sx, ]
      pk <- sim$pop_peaks[sim$pop_peaks$sex == sx, ]
      put("Population APHV (y)", sx, pk$aphv)
      put("Population PHV (cm/y)", sx, pk$phv)
      put("SD of timing (b)", sx, stats::sd(tc$b_tempo))
      put("Tall-accelerated phenotype (%)", sx, 100 * mean(tc$phenotype == "Tall-accelerated"))
      cut <- if (sx == "Male") 11 else 9
      b <- v[sexes == sx & v$age >= 5 & floor(v$age) <= cut, ]
      b <- b[order(b$pid, b$age), ]; b <- b[!duplicated(b$pid), ]
      m <- merge(b, tc[, c("pid", "b_tempo")], by = "pid"); m$early <- m$b_tempo < 0
      m <- m[stats::complete.cases(m[, c("baz", "haz", "age")]), ]
      if (nrow(m) > 50) {
        f <- stats::glm(early ~ baz + haz + age, data = m, family = stats::binomial())
        p <- stats::fitted(f); y <- f$y
        put("Early-timing AUC, logistic model", sx,
            (mean(rank(c(p[y == 1], p[y == 0]))[seq_len(sum(y == 1))]) - (sum(y == 1) + 1) / 2) / sum(y == 0))
      }
    }
  }
  sim_tab <- .bind(vals)
  out <- dplyr::left_join(targets, sim_tab, by = c("target", "sex"))
  out$pass <- !is.na(out$simulated) & out$simulated >= out$lower & out$simulated <= out$upper
  out <- out[, c("target", "sex", "published", "lower", "upper", "simulated", "pass", "unit", "source", "tuned")]
  class(out) <- c("wgh_resemblance", class(out))
  out
}

#' @export
print.wgh_resemblance <- function(x, ...) {
  ok <- sum(x$pass, na.rm = TRUE); tot <- sum(!is.na(x$simulated))
  cli::cli_text("{.cls wgh_resemblance}: {ok} of {tot} computable patterns within their bands")
  y <- x; class(y) <- class(y)[-1]
  y$simulated <- round(y$simulated, 2)
  print(y[, c("target", "sex", "published", "lower", "upper", "simulated", "pass")], n = Inf)
  invisible(x)
}

#' Plot a resemblance report
#'
#' Places each simulated statistic within its acceptable band (0 is the
#' lower limit and 1 the upper limit). Blue dots are inside the band and
#' orange dots outside. Crosses mark the published value.
#' @param x A `wgh_resemblance` object from [wgh_resemblance_report()].
#' @param only_failed Show only the patterns outside their band.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' rr <- wgh_resemblance_report(wgh_simulate(8000, seed = 11))
#' plot(rr)
#' plot(rr, base_size = 9, point_size = 1.5)
#' @export
plot.wgh_resemblance <- function(x, only_failed = FALSE, ...) {
  o <- .popts(...)
  d <- x[!is.na(x$simulated), ]
  if (only_failed) d <- d[!d$pass, ]
  if (!nrow(d)) .stop("No patterns to show.")
  d$label <- paste0(d$target, " (", d$sex, ")")
  d$pos <- (d$simulated - d$lower) / (d$upper - d$lower)
  d$pub <- (d$published - d$lower) / (d$upper - d$lower)
  d$label <- factor(d$label, levels = rev(unique(d$label)))
  p <- ggplot2::ggplot(d, ggplot2::aes(y = .data$label)) +
    ggplot2::annotate("rect", xmin = 0, xmax = 1, ymin = -Inf, ymax = Inf, alpha = 0.12, fill = "#009E73") +
    ggplot2::geom_point(ggplot2::aes(x = .data$pub), shape = 4, size = o$point_size %||% 2.5) +
    ggplot2::geom_point(ggplot2::aes(x = .data$pos, colour = .data$pass), size = o$point_size %||% 2.5) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = "#0072B2", `FALSE` = "#D55E00")) +
    ggplot2::labs(x = "Position within the acceptable band (0 = lower, 1 = upper)",
                               y = NULL, colour = "Within band",
                               title = "Simulated cohort against published patterns",
                               caption = "Cross: published value. Dot: simulated value.")
  .finish(p, o)
}

#' Nudge preset settings toward the published patterns
#'
#' A light, guided calibration. It simulates a modest cohort, compares a few
#' patterns with [wgh_targets] and adjusts the settings that drive each
#' pattern most directly: the BMI-for-age mean and spread (overweight and
#' obesity), the under-5 adiposity shift, and attendance by age group. It
#' repeats this a few times. It is meant for the package maintainer and for
#' Book 2 Chapter 3 readers who want to build their own preset, not for
#' formal estimation.
#'
#' @param preset Starting preset name or settings list.
#' @param n_children Size of each trial cohort.
#' @param iterations Number of adjustment rounds.
#' @param seed Seed for the trial cohorts.
#' @return The adjusted settings list, with an attribute `"history"`.
#' @examples
#' \donttest{
#' s <- wgh_tune_preset("wgh_like", n_children = 6000, iterations = 2)
#' s$baz_mean
#' }
#' @export
wgh_tune_preset <- function(preset = "wgh_like", n_children = 15000, iterations = 3, seed = 99) {
  s <- if (is.list(preset)) preset else wgh_preset(preset)
  tg <- WeGrowHealthR::wgh_targets
  get_t <- function(target, sex) tg$published[tg$target == target & tg$sex == sex]
  hist <- list()
  for (it in seq_len(iterations)) {
    sim <- wgh_simulate(n_children, preset = s, seed = seed + it)
    v <- sim$visits
    for (sx in .sexes) {
      o <- v[v$sex == sx & v$age >= 5, ]
      u <- v[v$sex == sx & v$age < 5, ]
      p1 <- mean(o$baz > 1, na.rm = TRUE); p2 <- mean(o$baz > 2, na.rm = TRUE)
      t1 <- get_t("Overweight or obesity, 5 to 18 y (%)", sx) / 100
      t2 <- get_t("Obesity, 5 to 18 y (%)", sx) / 100
      ## implied normal mean and SD from the two exceedance shares
      sd_sim <- 1 / (stats::qnorm(1 - p2) - stats::qnorm(1 - p1))
      sd_tgt <- 1 / (stats::qnorm(1 - t2) - stats::qnorm(1 - t1))
      mu_sim <- 1 - stats::qnorm(1 - p1) * sd_sim
      mu_tgt <- 1 - stats::qnorm(1 - t1) * sd_tgt
      s$baz_mean[[sx]] <- s$baz_mean[[sx]] + (mu_tgt - mu_sim)
      s$baz_sd[[sx]] <- s$baz_sd[[sx]] * sd_tgt / sd_sim
      pu <- mean(u$baz > 2, na.rm = TRUE); tu <- get_t("Overweight or obesity, under 5 (%)", sx) / 100
      s$baz_under5_shift[[sx]] <- s$baz_under5_shift[[sx]] +
        (stats::qnorm(tu) - stats::qnorm(max(pu, 1e-3))) * s$baz_sd[[sx]]
      hist[[length(hist) + 1]] <- tibble::tibble(iteration = it, sex = sx, ow_ob = 100 * p1, ob = 100 * p2,
                                                 u5 = 100 * pu, baz_mean = s$baz_mean[[sx]], baz_sd = s$baz_sd[[sx]])
    }
    ag <- cut(v$age, c(0, 5, 11, Inf), right = FALSE)
    sh <- as.numeric(prop.table(table(ag)))
    tgt <- c(get_t("Visits under 5 years (%)", "All"), get_t("Visits at ages 5 to 11 (%)", "All"))
    tgt <- c(tgt, 100 - sum(tgt)) / 100
    adj <- log(tgt / sh)
    vals <- s$attend_age$values
    vals[1] <- vals[1] + adj[1]; vals[2] <- vals[2] + adj[2]; vals[3:length(vals)] <- vals[3:length(vals)] + adj[3]
    s$attend_age$values <- vals
  }
  attr(s, "history") <- .bind(hist)
  s
}

#' Download the frozen full-size teaching cohort
#'
#' The full growdat2 cohort used in Book 2 is generated once with
#' `wgh_simulate(30000, preset = "wgh_like", seed = 2026, style = "book2")`,
#' frozen and deposited in a public archive, so every reader gets identical
#' numbers whatever their R version. Until the deposit exists, or when
#' offline, the function regenerates the same cohort locally (which gives
#' identical data on the same R version).
#'
#' The download is written to a temporary file first and only moved to
#' `destfile` after it has been read successfully and, when `md5` is given,
#' its checksum has been verified. A failed or partial download therefore
#' never leaves a broken file behind. An existing `destfile` is replaced in
#' one rename. Where that is not possible (some Windows or network file
#' systems), the old file is first renamed to a backup, the new file is moved
#' in, and the backup is restored if that step fails, so the old file
#' survives any failure.
#'
#' @param url Archive URL of the frozen file (`.rds`). When `NULL` the cohort
#'   is regenerated.
#' @param destfile Where to store the downloaded file.
#' @param md5 Expected MD5 checksum of the file, as a string or as the
#'   (named) value returned by [tools::md5sum()]. Case and surrounding
#'   spaces are ignored. Strongly recommended when `url` is given. The
#'   defaults of `url` and `md5` can be set once with
#'   `options(WeGrowHealthR.growdat2_url = ..., WeGrowHealthR.growdat2_md5 = ...)`.
#' @param n_children,seed,preset Settings used when the cohort is
#'   regenerated. The defaults reproduce the frozen cohort.
#' @return The visit data as a tibble. Attribute `"provenance"` records
#'   whether the data were downloaded or regenerated, the source URL and
#'   checksum, the simulation settings and the package and R versions. When
#'   regenerated, the `wgh_sim` object is attached as attribute `"sim"`.
#' @section Next steps:
#' Check the cohort with [wgh_resemblance_report()] or run any flow on it,
#' for example [wgh_flow_secular_trends()].
#' @examples
#' # A small regenerated cohort (the default is 30000 children)
#' small <- wgh_download(url = NULL, n_children = 500)
#' attr(small, "provenance")
#' \donttest{
#' growdat2 <- wgh_download()
#' }
#' @export
wgh_download <- function(url = getOption("WeGrowHealthR.growdat2_url"), destfile = NULL,
                         md5 = getOption("WeGrowHealthR.growdat2_md5"),
                         n_children = 30000, seed = 2026, preset = "wgh_like") {
  prov <- list(package_version = as.character(utils::packageVersion("WeGrowHealthR")),
               r_version = paste(R.version$major, R.version$minor, sep = "."), time = format(Sys.time(), tz = "UTC", usetz = TRUE))
  if (!is.null(url)) {
    if (is.null(md5)) .warn("No {.arg md5} checksum given: the downloaded file cannot be verified.")
    md5 <- .norm_md5(md5)
    destfile <- destfile %||% file.path(tempdir(), "growdat2.rds")
    if (!dir.exists(dirname(destfile)) && !dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE))
      .stop("Cannot create the folder {.path {dirname(destfile)}}.")
    ## the temporary file sits next to the destination, so the final rename
    ## stays on one file system and is atomic
    tmp <- tempfile(pattern = ".wgh_download_", fileext = ".rds", tmpdir = dirname(destfile))
    on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
    out <- tryCatch({
      utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
      if (!is.null(md5) && !identical(.norm_md5(tools::md5sum(tmp)), md5))
        .stop("Checksum of the downloaded file does not match the expected value.")
      readRDS(tmp)
    }, error = function(e) e)
    if (!inherits(out, "error")) {
      if (!.replace_file(tmp, destfile))
        .stop(c("The verified download could not be written to {.path {destfile}}.",
                i = "Any existing file there was left unchanged."))
      attr(out, "provenance") <- c(list(source = "downloaded", url = url, md5 = .norm_md5(tools::md5sum(destfile)),
                                        md5_verified = !is.null(md5), file = destfile), prov)
      return(out)
    }
    if (grepl("Checksum", conditionMessage(out))) .stop(conditionMessage(out))
    .warn("Download failed ({conditionMessage(out)}), regenerating the cohort locally.")
  }
  sim <- wgh_simulate(n_children, preset = preset, seed = seed, style = "book2")
  out <- sim$visits
  attr(out, "sim") <- sim
  attr(out, "provenance") <- c(list(source = "regenerated", n_children = n_children, seed = seed,
                                    preset = if (is.character(preset)) preset else "custom", style = "book2"), prov)
  out
}

## ---- download helpers (thin wrappers so tests can simulate failures) ------
.norm_md5 <- function(x) if (is.null(x)) NULL else tolower(trimws(unname(as.character(x))[1]))
.file_rename <- function(from, to) isTRUE(suppressWarnings(file.rename(from, to)))
.file_copy <- function(from, to) isTRUE(suppressWarnings(file.copy(from, to, overwrite = TRUE)))

## Moves the verified file `src` to `dest`. Returns TRUE on success. On
## failure `dest` is unchanged (or restored from a backup) and no temporary
## file is left behind.
.replace_file <- function(src, dest) {
  if (.file_rename(src, dest)) return(TRUE)
  part <- paste0(dest, ".part"); bak <- paste0(dest, ".bak")
  on.exit(unlink(c(part, src)), add = TRUE)
  ok_part <- .file_copy(src, part) && identical(.norm_md5(tools::md5sum(part)), .norm_md5(tools::md5sum(src)))
  if (!ok_part) return(FALSE)
  if (!file.exists(dest)) return(.file_rename(part, dest))
  if (!.file_rename(dest, bak)) return(FALSE)
  if (.file_rename(part, dest)) { unlink(bak); return(TRUE) }
  .file_rename(bak, dest)
  FALSE
}
