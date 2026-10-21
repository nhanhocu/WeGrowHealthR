#' WHO growth reference LMS parameters
#'
#' LMS parameters of the WHO 2006 Child Growth Standards (birth to 60 months)
#' and the WHO 2007 Growth Reference for school-aged children and
#' adolescents (60 to 228 months) for height-for-age (`hfa`),
#' weight-for-age (`wfa`, to 120 months in the 2007 reference) and
#' BMI-for-age (`bfa`). Below 24 months the height-for-age rows refer to
#' recumbent length. Ages are in months.
#'
#' @format A data frame with columns `indicator`, `sex`, `age_mo`, `L`, `M`,
#'   `S` and `source` (`"WHO2006"` or `"WHO2007"`).
#' @source World Health Organization. WHO Child Growth Standards:
#'   length/height-for-age, weight-for-age, weight-for-length,
#'   weight-for-height and body mass index-for-age. Geneva: WHO, 2006.
#'   de Onis M, Onyango AW, Borghi E, Siyam A, Nishida C, Siekmann J.
#'   Development of a WHO growth reference for school-aged children and
#'   adolescents. Bull World Health Organ. 2007;85:660-667. The values were
#'   taken from the tables distributed with the R packages `anthro` and
#'   `anthroplus` (GPL-3), thinned to weekly steps after the first two months
#'   for the 2006 standards. See `data-raw/who_lms.R` in the package sources.
#' @examples
#' head(who_lms)
#' table(who_lms$indicator, who_lms$sex)
#' # The same values through the lookup function
#' wgh_reference("hfa", age = c(5, 10), sex = "Female")
"who_lms"

#' CDC 2000 growth chart LMS parameters
#'
#' LMS parameters of the 2000 CDC growth charts for the United States for
#' height-for-age (`hfa`), weight-for-age (`wfa`) and BMI-for-age (`bfa`)
#' from 24 to 240 months, by sex. Ages are in months.
#'
#' @format A data frame with columns `indicator`, `sex`, `age_mo`, `L`, `M`,
#'   `S` and `source` (`"CDC2000"`).
#' @source Kuczmarski RJ, Ogden CL, Guo SS, et al. 2000 CDC growth charts for
#'   the United States: methods and development. Vital Health Stat 11.
#'   2002;(246):1-190. The values were taken from the tables distributed with
#'   the R package `cdcanthro` (GPL-3). See `data-raw/cdc_lms.R`.
#' @examples
#' head(cdc_lms)
#' range(cdc_lms$age_mo)
#' wgh_reference("bfa", age = c(5, 10), sex = "Male", reference = "cdc")
"cdc_lms"

.lms_cache <- new.env(parent = emptyenv())

.lms_table <- function(indicator, sex, reference = "who") {
  key <- paste(reference, indicator, sex)
  if (!is.null(.lms_cache[[key]])) return(.lms_cache[[key]])
  w <- if (reference == "cdc") WeGrowHealthR::cdc_lms else WeGrowHealthR::who_lms
  tab <- w[w$indicator == indicator & w$sex == sex, ]
  tab <- tab[order(tab$age_mo), ]
  .lms_cache[[key]] <- tab
  tab
}

## Validate a user-supplied LMS table: columns sex, age (years), L, M, S and
## optionally indicator.
.custom_lms <- function(tab, indicator) {
  tab <- as.data.frame(tab)
  need <- c("sex", "age", "L", "M", "S")
  miss <- setdiff(need, names(tab))
  if (length(miss)) .stop("A custom reference needs columns {.val {need}}; missing {.val {miss}}.")
  if ("indicator" %in% names(tab)) tab <- tab[tab$indicator == indicator, ]
  if (!nrow(tab)) .stop("The custom reference has no rows for indicator {.val {indicator}}.")
  tab$sex <- .norm_sex(tab$sex)
  tab
}

#' Look up LMS parameters of a growth reference
#'
#' Linear interpolation of LMS tables at exact ages.
#'
#' * `"who"` (default): WHO 2006 standards below 60 months and the WHO 2007
#'   reference from 60 months, the WHO recommendation. Switching at exactly
#'   60 months avoids the gap around age 5 that appears when packages switch
#'   references at different ages.
#' * `"cdc"`: CDC 2000 growth charts, 2 to 20 years.
#' * A data frame: your own LMS reference (for example a national
#'   reference), with columns `sex`, `age` (years), `L`, `M`, `S` and
#'   optionally `indicator`.
#'
#' @param indicator `"hfa"`, `"wfa"` or `"bfa"`.
#' @param age Age in years.
#' @param sex `"Male"` or `"Female"` (other spellings are recognised).
#' @param reference `"who"`, `"cdc"` or a data frame (see Details).
#' @return A data frame with columns `L`, `M`, `S` (`NA` outside the
#'   reference's age range).
#' @section Next steps:
#' Use [wgh_lms_value()] to turn the parameters into centile curves, or
#' [wgh_zscore()] to score measurements.
#' @examples
#' wgh_reference("hfa", c(2, 5, 10, 18), "Female")
#' wgh_reference("hfa", c(2, 5, 10, 18), "Female", reference = "cdc")
#'
#' # A custom reference (here a made-up two-row table for illustration)
#' my_ref <- data.frame(sex = "Female", age = c(10, 11), L = 1, M = c(138, 144), S = 0.045)
#' wgh_reference("hfa", 10.5, "Female", reference = my_ref)
#' @export
wgh_reference <- function(indicator = c("hfa", "wfa", "bfa"), age, sex, reference = "who") {
  indicator <- match.arg(indicator)
  sex <- .norm_sex(sex)
  n <- max(length(age), length(sex))
  age <- rep_len(age, n); sex <- rep_len(sex, n)
  am <- age * 12
  out <- matrix(NA_real_, n, 3, dimnames = list(NULL, c("L", "M", "S")))
  custom <- is.data.frame(reference)
  if (!custom) reference <- match.arg(tolower(reference), c("who", "cdc"))
  ctab <- if (custom) .custom_lms(reference, indicator) else NULL
  for (s in .sexes) {
    idx <- which(sex == s & !is.na(am))
    if (!length(idx)) next
    if (custom) {
      tt <- ctab[ctab$sex == s, ]
      tt <- tt[order(tt$age), ]
      if (!nrow(tt)) next
      for (p in c("L", "M", "S")) out[idx, p] <- stats::approx(tt$age, tt[[p]], xout = age[idx], rule = 1)$y
      next
    }
    tab <- .lms_table(indicator, s, reference)
    if (reference == "cdc") {
      for (p in c("L", "M", "S")) out[idx, p] <- stats::approx(tab$age_mo, tab[[p]], xout = am[idx], rule = 1)$y
      next
    }
    for (src in c("WHO2006", "WHO2007")) {
      tt <- tab[tab$source == src, ]
      sel <- if (src == "WHO2006") idx[am[idx] < 60] else idx[am[idx] >= 60]
      if (!length(sel)) next
      for (p in c("L", "M", "S"))
        out[sel, p] <- stats::approx(tt$age_mo, tt[[p]], xout = am[sel], rule = if (src == "WHO2006") 2 else 1)$y
    }
  }
  as.data.frame(out)
}

#' LMS z-scores and their inverse
#'
#' `wgh_lms_z()` converts a measurement to a z-score with Cole's LMS formula
#' \eqn{z = ((y/M)^L - 1)/(L S)} (or \eqn{\log(y/M)/S} when \eqn{L = 0}).
#' With `restricted = TRUE` it applies the WHO adjustment beyond plus or
#' minus 3 SD, which the WHO uses for weight-based indicators so that the
#' distance between successive SDs stays constant in the tails.
#' `wgh_lms_value()` returns the measurement at a given z-score, which is
#' how centile curves are drawn.
#'
#' @param y Measurements.
#' @param L,M,S LMS parameters (vectors recycled to the common length).
#' @param restricted Apply the WHO restricted tail adjustment.
#' @param z Z-scores.
#' @return A numeric vector.
#' @examples
#' wgh_lms_z(30, L = -1.5, M = 18, S = 0.12)
#' wgh_lms_z(30, L = -1.5, M = 18, S = 0.12, restricted = TRUE)
#' wgh_lms_value(2, L = -1.5, M = 18, S = 0.12)
#'
#' # The 3rd, 50th and 97th centiles of height for 10-year-old girls (WHO)
#' p <- wgh_reference("hfa", 10, "Female")
#' wgh_lms_value(qnorm(c(0.03, 0.5, 0.97)), p$L, p$M, p$S)
#' @export
wgh_lms_z <- function(y, L, M, S, restricted = FALSE) {
  n <- max(length(y), length(L), length(M), length(S))
  y <- rep_len(y, n); L <- rep_len(L, n); M <- rep_len(M, n); S <- rep_len(S, n)
  z <- ifelse(abs(L) < 1e-8, log(y / M) / S, ((y / M)^L - 1) / (L * S))
  if (restricted) {
    sd_at <- function(k) wgh_lms_value(k, L, M, S)
    hi <- !is.na(z) & z > 3
    lo <- !is.na(z) & z < -3
    if (any(hi)) {
      sd3 <- sd_at(3)[hi]; sd2 <- sd_at(2)[hi]
      z[hi] <- 3 + (y[hi] - sd3) / (sd3 - sd2)
    }
    if (any(lo)) {
      sd3 <- sd_at(-3)[lo]; sd2 <- sd_at(-2)[lo]
      z[lo] <- -3 + (y[lo] - sd3) / (sd2 - sd3)
    }
  }
  z
}

#' @rdname wgh_lms_z
#' @export
wgh_lms_value <- function(z, L, M, S) {
  n <- max(length(z), length(L), length(M), length(S))
  z <- rep_len(z, n); L <- rep_len(L, n); M <- rep_len(M, n); S <- rep_len(S, n)
  ifelse(abs(L) < 1e-8, M * exp(S * z), M * (1 + L * S * z)^(1 / L))
}

#' Z-scores against a growth reference for any indicator
#'
#' @param value Measurements (cm for height, kg for weight, kg/m2 for BMI).
#' @param age Age in years.
#' @param sex Sex.
#' @param indicator `"hfa"`, `"wfa"` or `"bfa"`.
#' @param reference `"who"` (default), `"cdc"` or a custom LMS table (see
#'   [wgh_reference()]).
#' @param method For the WHO reference: `"who"` (default, LMS with the WHO
#'   restricted tails for weight and BMI), `"lms"` (plain LMS without the
#'   tail adjustment) or `"symmetric"` (distance from the median divided by
#'   the distance to the 1 SD curve on the same side, an approximation used
#'   in older code and kept only to reproduce earlier results). For other
#'   references plain LMS is always used.
#' @return Numeric vector of z-scores. Convert to percentiles with
#'   `100 * pnorm(z)`.
#' @examples
#' wgh_zscore(c(120, 150), age = c(7, 12), sex = "Male", indicator = "hfa")
#' wgh_zscore(c(120, 150), age = c(7, 12), sex = "Male", indicator = "hfa", reference = "cdc")
#' # As percentiles
#' round(100 * pnorm(wgh_zscore(150, 12, "Male", "hfa")), 1)
#' @export
wgh_zscore <- function(value, age, sex, indicator = c("hfa", "wfa", "bfa"), reference = "who",
                       method = c("who", "lms", "symmetric")) {
  indicator <- match.arg(indicator); method <- match.arg(method)
  ref <- wgh_reference(indicator, age, sex, reference)
  is_who <- !is.data.frame(reference) && tolower(reference) == "who"
  value <- rep_len(value, nrow(ref))
  if (method == "symmetric" && is_who) {
    up <- wgh_lms_value(1, ref$L, ref$M, ref$S) - ref$M
    dn <- ref$M - wgh_lms_value(-1, ref$L, ref$M, ref$S)
    return(ifelse(value >= ref$M, (value - ref$M) / up, (value - ref$M) / dn))
  }
  wgh_lms_z(value, ref$L, ref$M, ref$S,
            restricted = is_who && method == "who" && indicator %in% c("wfa", "bfa"))
}

#' Add z-scores to growth data
#'
#' Adds height-for-age (`haz`), weight-for-age (`waz`) and BMI-for-age
#' (`baz`) z-scores against the chosen reference. Under the WHO reference
#' weight-for-age is only defined up to 10 years and is `NA` above that age.
#' The CDC 2000 charts cover 2 to 20 years.
#'
#' @param x A [wgh_data] object or data frame with `age`, `sex` and the
#'   needed measurements (`height`, `weight`, `bmi`).
#' @param indicators Which z-scores to add.
#' @param reference `"who"` (default), `"cdc"` or a custom LMS table.
#' @param method See [wgh_zscore()]. Use `"lms"` or `"symmetric"` only to
#'   reproduce earlier results computed that way.
#' @param flag_limit Absolute z-score at or above which a value is flagged
#'   as biologically implausible in a column `<z>_flag`. Use `NULL` for no
#'   flags.
#' @param percentiles Also add percentile columns (`haz_pct`, ...).
#' @return `x` with the z-score columns (and flags) added, in the same
#'   container type as `x`.
#' @section Next steps:
#' Classify nutritional status with [wgh_classify()], summarise with
#' [wgh_prevalence()], or plot individual children with
#' [wgh_plot_growth_chart()].
#' @examples
#' gd <- wgh_add_zscores(growdat)
#' summary(gd$haz)
#' # CDC 2000 references with percentiles
#' cdc <- wgh_add_zscores(growdat[growdat$age >= 2, ], reference = "cdc", percentiles = TRUE)
#' head(cdc[, c("age", "height", "haz", "haz_pct")])
#' @export
wgh_add_zscores <- function(x, indicators = c("haz", "waz", "baz"), reference = "who",
                            method = c("who", "lms", "symmetric"), flag_limit = 6, percentiles = FALSE) {
  method <- match.arg(method)
  d <- .gd(x, c("age", "sex"))
  if ("baz" %in% indicators && !"bmi" %in% names(d) && all(c("height", "weight") %in% names(d)))
    d$bmi <- d$weight / (d$height / 100)^2
  spec <- list(haz = c("height", "hfa"), waz = c("weight", "wfa"), baz = c("bmi", "bfa"))
  for (z in indicators) {
    v <- spec[[z]][1]
    if (!v %in% names(d)) { .warn("Skipping {z}: column {.field {v}} not found."); next }
    d[[z]] <- wgh_zscore(d[[v]], d$age, d$sex, spec[[z]][2], reference = reference, method = method)
    if (percentiles) d[[paste0(z, "_pct")]] <- 100 * stats::pnorm(d[[z]])
    if (!is.null(flag_limit)) d[[paste0(z, "_flag")]] <- !is.na(d[[z]]) & abs(d[[z]]) >= flag_limit
  }
  .regd(x, d)
}

#' Compare z-scores from different references, methods and packages
#'
#' Computes the same z-score with the WHO reference (with and without the
#' restricted tails), the symmetric approximation, the CDC 2000 charts and,
#' when installed, the `anthroplus` package (5 to 19 years), so differences
#' between references and methods are visible for any child.
#'
#' @param value,age,sex,indicator As in [wgh_zscore()].
#' @return A tibble with one column per reference or method.
#' @examples
#' wgh_compare_references(c(25, 60), age = c(6, 9), sex = "Male", indicator = "wfa")
#' wgh_compare_references(c(130, 160), age = c(9, 15), sex = "Female", indicator = "hfa")
#' @export
wgh_compare_references <- function(value, age, sex, indicator = c("hfa", "wfa", "bfa")) {
  indicator <- match.arg(indicator)
  out <- tibble::tibble(age = age, sex = .norm_sex(sex), value = value,
                        who = wgh_zscore(value, age, sex, indicator, method = "who"),
                        who_plain_lms = wgh_zscore(value, age, sex, indicator, method = "lms"),
                        symmetric = wgh_zscore(value, age, sex, indicator, method = "symmetric"),
                        cdc = wgh_zscore(value, age, sex, indicator, reference = "cdc"))
  if (requireNamespace("anthroplus", quietly = TRUE)) {
    a <- rep(NA_real_, length(value))
    ok <- age >= 5 & age <= 19
    if (any(ok)) {
      sx <- ifelse(out$sex[ok] == "Male", 1, 2)
      args <- list(sex = sx, age_in_months = age[ok] * 12, oedema = "n")
      if (indicator == "hfa") { args$height_in_cm <- value[ok]; args$weight_in_kg <- NA_real_ }
      if (indicator == "wfa") { args$weight_in_kg <- value[ok]; args$height_in_cm <- NA_real_ }
      if (indicator == "bfa") { args$weight_in_kg <- value[ok]; args$height_in_cm <- 100 }
      r <- tryCatch(do.call(anthroplus::anthroplus_zscores, args), error = function(e) NULL)
      if (!is.null(r)) a[ok] <- r[[c(hfa = "zhfa", wfa = "zwfa", bfa = "zbfa")[[indicator]]]]
    }
    out$anthroplus <- a
  }
  out
}
