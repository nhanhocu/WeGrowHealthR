## Simulation engine ---------------------------------------------------------
##
## One generator for every teaching dataset in the package and both books.
## It extends the Book 2 Chapter 3 generator (simulate_growdat2): SITAR-type
## individual curves around a Preece-Baines mean curve, a latent adiposity
## score that shifts size, timing and intensity, planted phenotypes, an
## informative school visit process, and a truth file.

.pb1 <- function(t, p) {
  p[["h1"]] - 2 * (p[["h1"]] - p[["h_theta"]]) /
    (exp(p[["s0"]] * (t - p[["theta"]])) + exp(p[["s1"]] * (t - p[["theta"]])))
}
.pb1_vel <- function(t, p) {
  e0 <- exp(p[["s0"]] * (t - p[["theta"]])); e1 <- exp(p[["s1"]] * (t - p[["theta"]]))
  2 * (p[["h1"]] - p[["h_theta"]]) * (p[["s0"]] * e0 + p[["s1"]] * e1) / (e0 + e1)^2
}

## Early-childhood shape: WHO 2006 median height (length converted to
## standing height below 2 years) joined smoothly to the Preece-Baines curve
## with a monotone spline through anchor points.
.early_spline <- function(sex, s) {
  p <- s$mean_curve[[sex]]
  wa <- c(0.75, 1, 1.5, 2.25, 3, 3.5, 4, 4.5)
  wm <- wgh_reference("hfa", wa, sex)$M - 0.7 * (wa < 2)
  off <- .pb1(5, p) - wgh_reference("hfa", 4.99, sex)$M
  pa <- c(5, 5.25, 5.5, 5.75, 6, 6.5, 7)
  stats::splinefun(c(wa, pa), c(wm + off * wa / 5, .pb1(pa, p)), method = "monoH.FC")
}

## Mean height curve for one sex: Preece-Baines from age 6, WHO-shaped below.
.mean_height <- function(t, sex, s) {
  p <- s$mean_curve[[sex]]
  out <- .pb1(t, p)
  young <- !is.na(t) & t < 6 & isTRUE(s$early_childhood)
  if (any(young)) out[young] <- .early_spline(sex, s)(pmax(t[young], 0.75))
  out
}

.mean_velocity <- function(t, sex, s, h = 0.005) {
  (.mean_height(t + h, sex, s) - .mean_height(t - h, sex, s)) / (2 * h)
}

#' Population peak of the mean height curve in a preset
#' @param preset A preset name or settings list from [wgh_preset()].
#' @return A tibble with `sex`, `aphv` and `phv`.
#' @examples
#' wgh_preset_peaks("wgh_like")
#' wgh_preset_peaks("reference")
#' @export
wgh_preset_peaks <- function(preset = "wgh_like") {
  s <- if (is.list(preset)) preset else wgh_preset(preset)
  .bind(lapply(.sexes, function(sx) {
    o <- stats::optimize(function(t) .pb1_vel(t, s$mean_curve[[sx]]), c(7, 17), maximum = TRUE)
    tibble::tibble(sex = sx, aphv = o$maximum, phv = o$objective)
  }))
}

## Inverse LMS with the WHO restricted tails, so simulated BMI maps back to
## the intended BAZ when scored with method = "who".
.lms_value_who <- function(z, L, M, S) {
  v <- wgh_lms_value(z, L, M, S)
  hi <- !is.na(z) & z > 3; lo <- !is.na(z) & z < -3
  if (any(hi)) {
    s3 <- wgh_lms_value(3, L[hi], M[hi], S[hi]); s2 <- wgh_lms_value(2, L[hi], M[hi], S[hi])
    v[hi] <- s3 + (z[hi] - 3) * (s3 - s2)
  }
  if (any(lo)) {
    s3 <- wgh_lms_value(-3, L[lo], M[lo], S[lo]); s2 <- wgh_lms_value(-2, L[lo], M[lo], S[lo])
    v[lo] <- s3 + (z[lo] + 3) * (s2 - s3)
  }
  v
}

.band_value <- function(x, breaks, values) {
  values[findInterval(x, breaks, rightmost.closed = TRUE, all.inside = TRUE)]
}

#' Simulate a longitudinal school health cohort
#'
#' `wgh_simulate()` generates a cohort of children followed through annual
#' school health examinations. Each child's height curve is a SITAR-type
#' transformation (size, timing and intensity) of a Preece-Baines mean curve,
#' so every child's velocity is positive at every age. A latent adiposity
#' score shifts timing, size and intensity, drives BMI through the WHO
#' BMI-for-age reference and makes attendance informative. Children belong to
#' latent phenotypes. The output separates what a real study would see
#' (`visits`) from what only the simulation knows (`truth_child`,
#' `truth_visit`).
#'
#' Two presets are provided (see [wgh_preset()]):
#'
#' * `"wgh_like"` (default) resembles the published school health cohort: ages
#'   18 months to 18 years, three sites of unequal size, early puberty
#'   (APHV near 12.2 years in boys and 9.2 years in girls) with a timing
#'   spread in girls about twice that in boys, high overweight and obesity in
#'   boys, falling obesity over calendar years and no examinations in 2021.
#'   Analyses run on it give tables and figures that resemble the papers.
#'   They do not reproduce published numbers, and they are not findings.
#' * `"reference"` keeps the WHO-like settings of Book 2 Chapter 3, useful
#'   for teaching simulation and for known-truth exercises.
#'
#' @param n_children Number of simulated children before enrolment rules
#'   are applied. About 60% of them appear in the visit data.
#' @param preset A preset name or a settings list from [wgh_preset()].
#' @param seed Random seed. The same seed always gives the same cohort.
#' @param informative_visits If `FALSE`, attendance does not depend on
#'   adiposity.
#' @param style Column names of the visit data: `"book1"` (`pid`,
#'   `site`, `yearvisit`, `baz`) or `"book2"` (`schoolyear` and
#'   `bmiz` as in Book 2).
#' @param monotone Keep every child's measured heights non-decreasing with
#'   age, so the observed height velocity is never negative. Measurement
#'   error is added first, then each child's measured values are replaced by
#'   their isotonic regression (the closest non-decreasing sequence in the
#'   least-squares sense). Values change only where error created a
#'   decrease, where neighbouring visits are pooled to their mean, so
#'   observed increments of exactly zero occur. This slightly reduces the
#'   measurement error at those visits (see the validation tests). Use
#'   `monotone = TRUE` for teaching and for methods that assume
#'   non-negative observed velocity. Use `FALSE` to keep raw measurement
#'   error, as in real records, for example when studying methods that must
#'   cope with negative observed increments or when simulating false band
#'   moves. The true growth curves (`height_true`) are non-decreasing in
#'   both modes. If overrides in `...` would make a true curve decrease, it
#'   is replaced by its running maximum, `velocity_true` is set to 0 where
#'   it is flat, and a warning says how many children were affected.
#' @param ... Settings that override single elements of the preset, for
#'   example `beta_tempo_adiposity = c(Male = 0, Female = 0)` for a world
#'   where adiposity does not affect timing.
#' @return An object of class `wgh_sim`: a list with `visits`, `roster`,
#'   `truth_child`, `truth_visit`, `pop_peaks`, `settings` and `call`.
#' @seealso [wgh_preset()], [wgh_add_messiness()], [wgh_truth_check()],
#'   [wgh_resemblance_report()]
#' @examples
#' sim <- wgh_simulate(2000, seed = 1)
#' sim
#' head(sim$visits)
#' @export
wgh_simulate <- function(n_children = 30000, preset = "wgh_like", seed = 2026,
                        informative_visits = TRUE, style = c("book1", "book2"), monotone = TRUE, ...) {
  style <- match.arg(style)
  s <- if (is.list(preset)) preset else wgh_preset(preset)
  ov <- list(...)
  for (nm in names(ov)) s[[nm]] <- ov[[nm]]
  .local_seed(seed)
  n <- as.integer(n_children)
  peaks <- wgh_preset_peaks(s)
  mu <- stats::setNames(peaks$aphv, peaks$sex)
  phv <- stats::setNames(peaks$phv, peaks$sex)

  ## ---- children -----------------------------------------------------------
  yr <- s$years
  first_day <- as.Date(paste0(min(yr), "-09-15")) - round(s$age_range[2] * 365.25)
  last_day <- as.Date(paste0(max(yr), "-09-15")) + 120 - round(s$age_range[1] * 365.25)
  sexv <- sample(.sexes, n, replace = TRUE, prob = c(s$p_male, 1 - s$p_male))
  site <- sample(names(s$site_probs), n, replace = TRUE, prob = s$site_probs)
  dob <- first_day + sample.int(as.integer(last_day - first_day), n, replace = TRUE)
  birth_year <- as.integer(format(dob, "%Y"))
  phen_names <- names(s$phenotype_probs)
  phen <- sample(phen_names, n, replace = TRUE, prob = s$phenotype_probs)
  sh <- s$phenotype_shift
  u_adip <- stats::rnorm(n) + unname(sh$adiposity[phen])
  d_adip <- stats::rnorm(n, 0, s$adiposity_drift_sd)
  z_size <- stats::rnorm(n)
  a_size <- unname(s$site_size[site]) + unname(sh$a[phen]) +
    s$beta_size_adiposity * u_adip +
    s$size_sd * exp(s$size_sd_adiposity * u_adip) * z_size
  tsc <- unname(s$phenotype_tempo_scale[sexv])
  b_sys <- unname(sh$b[phen]) * tsc +
    unname(s$beta_tempo_adiposity[sexv]) * u_adip +
    unname(s$beta_tempo_size[sexv]) * z_size +
    unname(s$tempo_cohort_trend[sexv]) * (birth_year - 2010)
  b_tempo <- numeric(n)
  for (sx in .sexes) {
    i <- sexv == sx
    bs <- b_sys[i] - mean(b_sys[i])
    resid_sd <- sqrt(max(s$tempo_sd_total[[sx]]^2 - stats::var(bs), 0.05^2))
    b_tempo[i] <- b_sys[i] + stats::rnorm(sum(i), 0, resid_sd)
  }
  c_int <- unname(sh$c[phen]) + s$beta_intensity_adiposity * u_adip +
    stats::rnorm(n, 0, s$intensity_sd)
  kids <- data.frame(pid = sprintf("C%06d", seq_len(n)), sex = sexv, site = site,
                     dob = dob, birth_year = birth_year, phenotype = phen,
                     u_adip = u_adip, d_adip = d_adip, z_size = z_size,
                     a_size = a_size, b_tempo = b_tempo, c_intensity = c_int,
                     entry_draw = stats::runif(n), entry_u = stats::runif(n),
                     stringsAsFactors = FALSE)

  ## ---- roster -------------------------------------------------------------
  yrs <- setdiff(yr, s$missing_years)
  r <- kids[rep(seq_len(n), each = length(yrs)), c("pid", "sex", "site", "dob")]
  r$yearvisit <- rep(yrs, times = n)
  r$examdate <- as.Date(paste0(r$yearvisit, "-09-15")) + sample(0:120, nrow(r), replace = TRUE)
  r$age <- as.numeric(r$examdate - r$dob) / 365.25
  open <- unname(s$site_open[r$site])
  r <- r[r$age >= s$age_range[1] & r$age < s$age_range[2] & r$yearvisit >= open, ]
  r <- r[order(r$pid, r$yearvisit), ]
  ki <- match(r$pid, kids$pid)
  rank <- stats::ave(seq_along(r$pid), r$pid, FUN = seq_along)
  n_el <- stats::ave(seq_along(r$pid), r$pid, FUN = length)
  entry_rank <- ifelse(kids$entry_draw[ki] < s$entry_first_prob, 1L,
                       pmax(1L, as.integer(ceiling(kids$entry_u[ki] * n_el))))
  enrolled_from <- rank >= entry_rank
  p_drop <- stats::plogis(s$dropout[["intercept"]] + s$dropout[["age"]] * (r$age - 10))
  drop_now <- enrolled_from & stats::runif(nrow(r)) < p_drop
  cum_drop <- stats::ave(as.integer(drop_now), r$pid, FUN = cumsum)
  dropped_before <- (cum_drop - drop_now) > 0
  entry_age <- stats::ave(ifelse(rank == entry_rank, r$age, NA_real_), r$pid,
                          FUN = function(z) z[!is.na(z)][1])
  keep <- enrolled_from & !dropped_before
  if (!is.null(s$site_max_entry_age)) {
    mx <- unname(s$site_max_entry_age[r$site])
    keep <- keep & (is.na(mx) | entry_age <= mx)
  }
  r <- r[keep, ]
  ki <- match(r$pid, kids$pid)

  ## ---- measurements -------------------------------------------------------
  sx <- r$sex
  muv <- unname(mu[sx])
  onset <- if (is.null(s$tempo_onset)) NULL else unname(s$tempo_onset[sx])
  bcl <- pmax(pmin(kids$b_tempo[ki], 4), -4)
  ## remaining-growth scaling for adult size effects keeps velocity positive
  h_adult <- vapply(.sexes, function(g2) .mean_height(30, g2, s), 1)
  h_t0 <- vapply(.sexes, function(g2) .mean_height(mu[[g2]] - 1, g2, s), 1)
  rem <- unname(h_adult[sx] - h_t0[sx])
  delta <- s$adult_size_tempo * kids$b_tempo[ki] + (s$adult_size_adiposity %||% 0) * kids$u_adip[ki] +
    s$size_cohort_trend * (kids$birth_year[ki] - 2004)
  delta <- pmax(delta, -0.8 * rem)
  hfun <- function(age) {
    tstar <- muv + (age - muv - bcl) * exp(kids$c_intensity[ki])
    if (!is.null(onset)) {
      g <- stats::plogis((age - (muv - onset)) / 1.5)
      tstar <- age + (tstar - age) * g
    }
    hc <- numeric(length(age))
    for (g2 in .sexes) {
      i <- sx == g2
      hc[i] <- .mean_height(tstar[i], g2, s)
    }
    frac <- pmax(hc - unname(h_t0[sx]), 0) / rem
    kids$a_size[ki] + hc + delta * frac
  }
  r$height_true <- hfun(r$age)
  r$velocity_true <- (hfun(r$age + 0.01) - hfun(r$age - 0.01)) / 0.02
  ## the latent curve must be non-decreasing, and the stored velocity must agree with it
  ## (rows are in age order within child)
  fixed <- .monotone_truth(r$height_true, r$velocity_true, r$pid)
  r$height_true <- fixed$height; r$velocity_true <- fixed$velocity
  r$height <- r$height_true + stats::rnorm(nrow(r), 0, s$measurement_sd_height)
  ## monotone measured heights: least-squares projection of each child's measured
  ## values onto non-decreasing sequences (isotonic regression). Values change
  ## only where measurement error created a decrease, and nothing is moved to
  ## another visit.
  if (monotone) r$height <- stats::ave(r$height, r$pid, FUN = .isotonic)
  r$height <- round(r$height, 1)

  young_shift <- unname(s$baz_under5_shift[sx]) * (1 - stats::plogis((r$age - 4.5) / 0.6))
  r$baz_true <- unname(s$baz_mean[sx]) + young_shift +
    unname(s$site_adiposity[r$site]) +
    s$adiposity_period_trend * (r$yearvisit - 2021.5) +
    unname(s$baz_sd[sx]) * (kids$u_adip[ki] + kids$d_adip[ki] * (r$age - 10) / 5) +
    stats::rnorm(nrow(r), 0, s$baz_noise_sd)
  lms <- wgh_reference("bfa", r$age, sx)
  r$bmi_true <- .lms_value_who(r$baz_true, lms$L, lms$M, lms$S)
  r$weight <- round(r$bmi_true * (r$height_true / 100)^2 +
                      stats::rnorm(nrow(r), 0, s$measurement_sd_weight), 1)
  r$bmi <- r$weight / (r$height / 100)^2

  ## ---- attendance ---------------------------------------------------------
  yeff <- unname(s$attend_year[as.character(r$yearvisit)]); yeff[is.na(yeff)] <- 0
  r$p_attend <- stats::plogis(
    s$attend_intercept +
      (if (informative_visits) s$attend_adiposity else 0) * (kids$u_adip[ki] + kids$d_adip[ki] * (r$age - 10) / 5) +
      .band_value(r$age, s$attend_age$breaks, s$attend_age$values) + yeff +
      unname(s$site_attend[r$site]))
  r$attended <- stats::runif(nrow(r)) < r$p_attend

  ## ---- z-scores and outputs ----------------------------------------------
  r$haz <- wgh_zscore(r$height, r$age, sx, "hfa")
  r$haz_true <- wgh_zscore(r$height_true, r$age, sx, "hfa")
  r$waz <- wgh_zscore(r$weight, r$age, sx, "wfa")
  r$baz <- wgh_zscore(r$bmi, r$age, sx, "bfa")
  r$site <- factor(r$site, levels = names(s$site_probs))
  r$sex <- factor(r$sex, levels = .sexes)
  rownames(r) <- NULL

  vis <- r[r$attended, c("pid", "sex", "site", "dob", "yearvisit", "examdate",
                         "age", "height", "weight", "bmi", "haz", "waz", "baz")]
  vis$age <- round(vis$age, 3); vis$bmi <- round(vis$bmi, 2)
  for (z in c("haz", "waz", "baz")) vis[[z]] <- round(vis[[z]], 3)
  if (style == "book2") {
    names(vis)[names(vis) == "yearvisit"] <- "schoolyear"
    names(vis)[names(vis) == "baz"] <- "bmiz"
  }
  enrolled <- unique(r$pid)
  tc <- kids[kids$pid %in% enrolled, ]
  tc$aphv_true <- unname(mu[tc$sex]) + tc$b_tempo
  tc$phv_true <- unname(phv[tc$sex]) * exp(tc$c_intensity)
  tc$sex <- factor(tc$sex, levels = .sexes)
  tc$site <- factor(tc$site, levels = names(s$site_probs))
  tc <- tc[, c("pid", "sex", "site", "dob", "birth_year", "phenotype", "u_adip",
               "d_adip", "z_size", "a_size", "b_tempo", "c_intensity", "aphv_true", "phv_true")]
  tv <- r[, c("pid", "sex", "site", "yearvisit", "age", "attended", "p_attend",
              "baz_true", "height_true", "velocity_true", "haz_true", "height", "weight",
              "bmi", "haz", "waz", "baz")]
  structure(list(
    visits = tibble::as_tibble(vis),
    roster = tibble::as_tibble(r[, c("pid", "sex", "site", "yearvisit", "examdate", "age", "attended")]),
    truth_child = tibble::as_tibble(tc), truth_visit = tibble::as_tibble(tv),
    pop_peaks = peaks, settings = s,
    call = list(n_children = n, preset = s$name, seed = seed,
                informative_visits = informative_visits, style = style)),
    class = "wgh_sim")
}

#' @export
print.wgh_sim <- function(x, ...) {
  v <- x$visits
  cli::cli_text("{.cls wgh_sim} preset {.val {x$settings$name}}, seed {x$call$seed}")
  cli::cli_text("{nrow(v)} visits from {length(unique(v$pid))} children ({length(unique(x$roster$pid))} enrolled)")
  pk <- x$pop_peaks
  cli::cli_text("Mean-curve APHV: boys {round(pk$aphv[1], 1)} y, girls {round(pk$aphv[2], 1)} y. PHV: {round(pk$phv[1], 1)} and {round(pk$phv[2], 1)} cm/y")
  cli::cli_text(cli::col_grey("Simulated data. Results resemble but do not reproduce published findings."))
  invisible(x)
}

#' Settings of a simulation preset
#'
#' Returns the full list of settings used by [wgh_simulate()]. Change single
#' elements to build alternative worlds, for example a cohort in which
#' adiposity has no effect on timing, and pass the list back as `preset`.
#'
#' @param name `"wgh_like"` or `"reference"`.
#' @return A named list of settings, with units documented in comments in
#'   the package source.
#' @examples
#' s <- wgh_preset("wgh_like")
#' names(s)
#' s$tempo_sd_total
#' @export
wgh_preset <- function(name = c("wgh_like", "reference")) {
  name <- match.arg(name)
  base <- list(
    name = name, p_male = 0.52,
    years = 2018:2025, missing_years = integer(),
    age_range = c(5, 18.5), early_childhood = FALSE,
    site_probs = c(Site1 = 0.55, Site2 = 0.30, Site3 = 0.15),
    site_open = c(Site1 = 2018, Site2 = 2018, Site3 = 2020),
    site_max_entry_age = c(Site1 = NA, Site2 = NA, Site3 = 10.5),
    ## Preece-Baines model 1 mean curves (cm, years)
    mean_curve = list(
      Male = c(h1 = 176.77, h_theta = 162.81, theta = 14.04, s0 = 0.097, s1 = 0.959),
      Female = c(h1 = 163.08, h_theta = 150.50, theta = 11.94, s0 = 0.111, s1 = 0.922)),
    phenotype_probs = c(`Early-intense` = 0.25, Average = 0.50, `Late-gentle` = 0.25),
    phenotype_shift = list(
      a = c(`Early-intense` = 0.5, Average = 0, `Late-gentle` = -0.5),
      b = c(`Early-intense` = -0.9, Average = 0, `Late-gentle` = 0.9),
      c = c(`Early-intense` = 0.08, Average = 0, `Late-gentle` = -0.08),
      adiposity = c(`Early-intense` = 0, Average = 0, `Late-gentle` = 0)),
    phenotype_tempo_scale = c(Male = 1, Female = 1),
    tempo_onset = NULL,                                       # NULL = pure SITAR timing at all ages
    site_size = c(Site1 = 1, Site2 = 1, Site3 = 1),          # cm
    size_sd = 4.0, size_sd_adiposity = 0.12,                  # cm, log-SD per SD adiposity
    beta_size_adiposity = 0.8,                                # cm per SD adiposity
    tempo_sd_total = c(Male = 0.91, Female = 0.91),           # years, total SD of b
    beta_tempo_adiposity = c(Male = -0.25, Female = -0.25),   # years per SD adiposity
    beta_tempo_size = c(Male = 0, Female = 0),                # years per SD of size
    tempo_cohort_trend = c(Male = 0, Female = 0),             # years per birth year
    intensity_sd = 0.07, beta_intensity_adiposity = 0.02,
    adult_size_tempo = 0, size_cohort_trend = 0,              # cm per year of b, per birth year
    adult_size_adiposity = 0,                                 # cm of adult size per SD adiposity
    baz_mean = c(Male = 0.35, Female = 0.35), baz_sd = c(Male = 1, Female = 1),
    baz_under5_shift = c(Male = 0, Female = 0),
    site_adiposity = c(Site1 = 0.15, Site2 = 0.05, Site3 = -0.20),
    adiposity_period_trend = 0, adiposity_drift_sd = 0.30, baz_noise_sd = 0.25,
    entry_first_prob = 0.6, dropout = c(intercept = -3.0, age = 0.2),
    attend_intercept = 2.0, attend_adiposity = -0.5,
    attend_age = list(breaks = c(0, 15, Inf), values = c(0, -0.6)),
    attend_year = c(`2020` = -0.5, `2021` = -1.5),
    site_attend = c(Site1 = 0, Site2 = -0.2, Site3 = 0.3),
    measurement_sd_height = 0.5, measurement_sd_weight = 0.2
  )
  if (name == "reference") return(base)
  ## wgh_like: resembles the published school health cohort (see wgh_targets)
  v <- base
  v$years <- 2018:2025; v$missing_years <- 2021L
  v$age_range <- c(1.5, 18.5); v$early_childhood <- TRUE
  v$site_probs <- c(Site1 = 0.62, Site2 = 0.27, Site3 = 0.11)
  v$site_open <- c(Site1 = 2018, Site2 = 2018, Site3 = 2018)
  v$site_max_entry_age <- NULL
  v$mean_curve <- list(
    Male = c(h1 = 172.046, h_theta = 158.214, theta = 12.616, s0 = 0.106, s1 = 1.186),
    Female = c(h1 = 160.100, h_theta = 145.882, theta = 10.610, s0 = 0.109, s1 = 0.763))
  v$phenotype_probs <- c(Average = 0.55, `Early-intense` = 0.19, `Late-gentle` = 0.21,
                         `Tall-accelerated` = 0.05)
  v$phenotype_shift <- list(
    a = c(Average = 0, `Early-intense` = 0.4, `Late-gentle` = -0.4, `Tall-accelerated` = 4.5),
    b = c(Average = 0, `Early-intense` = -0.9, `Late-gentle` = 0.9, `Tall-accelerated` = -0.8),
    c = c(Average = 0, `Early-intense` = 0.06, `Late-gentle` = -0.06, `Tall-accelerated` = 0.10),
    adiposity = c(Average = 0, `Early-intense` = 0.15, `Late-gentle` = -0.15, `Tall-accelerated` = 0.9))
  v$phenotype_tempo_scale <- c(Male = 0.5, Female = 1.0)
  v$tempo_onset <- c(Male = 3.0, Female = 2.0)   # timing acts from 2 to 3 years before APHV
  v$site_size <- c(Site1 = 0, Site2 = 0.6, Site3 = -1.2)
  v$size_sd <- 4.2; v$size_sd_adiposity <- 0.08; v$beta_size_adiposity <- 0.3
  v$tempo_sd_total <- c(Male = 0.52, Female = 1.02)
  v$beta_tempo_adiposity <- c(Male = -0.15, Female = -0.12)
  v$beta_tempo_size <- c(Male = -0.05, Female = 0.60)
  v$tempo_cohort_trend <- c(Male = 0, Female = -0.08)
  v$adult_size_tempo <- 1.5; v$size_cohort_trend <- 0.30; v$adult_size_adiposity <- -0.6
  v$baz_mean <- c(Male = 0.90, Female = 0.22); v$baz_sd <- c(Male = 1.34, Female = 1.05)
  v$baz_under5_shift <- c(Male = -1.15, Female = -0.30)
  v$site_adiposity <- c(Site1 = 0, Site2 = 0.12, Site3 = 0.30)
  v$adiposity_period_trend <- -0.05
  v$entry_first_prob <- 0.5; v$dropout <- c(intercept = -1.9, age = 0.05)
  v$attend_intercept <- 1.4; v$attend_adiposity <- -0.2
  v$attend_age <- list(breaks = c(0, 5, 11, 15, Inf), values = c(0, 1.3, -0.6, -1.2))
  v$attend_year <- c(`2018` = -3.0, `2019` = -0.6, `2020` = -0.45, `2022` = 0.45,
                     `2023` = 0.3, `2024` = 0.35, `2025` = 0.35)
  v$site_attend <- c(Site1 = 0, Site2 = 0, Site3 = 0)
  v
}

## isotonic (non-decreasing) least-squares fit of a sequence in its given order
.isotonic <- function(h) if (length(h) < 2) h else stats::isoreg(h)$yf

## Makes true heights non-decreasing within child (rows in age order) and the
## stored velocity consistent with them: a decreasing stretch is replaced by
## the running maximum and its velocity set to 0, with a warning.
.monotone_truth <- function(height, velocity, pid) {
  h_env <- stats::ave(height, pid, FUN = cummax)
  flat <- h_env > height + 1e-9 | velocity < 0
  if (any(flat)) {
    n_bad <- sum(tapply(flat, pid, any))
    .warn(c("The settings give a decreasing true height curve for {n_bad} child{?ren}.",
            "i" = "Their true heights were replaced by the running maximum and the true velocity set to 0 where the curve is flat.",
            "i" = "Check the overrides passed to {.fn wgh_simulate} if this is not intended."))
    velocity[flat] <- 0
  }
  list(height = h_env, velocity = velocity)
}
