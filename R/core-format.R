#' Consistent number formatting for tables
#'
#' The program's scripts defined these helpers again and again with small
#' differences, so tables from different papers were not formatted the same
#' way. These versions are used by every table in the package.
#'
#' @param p P-values.
#' @param digits Number of decimals.
#' @param est,lo,hi Estimate and interval limits.
#' @param sep Separator between interval limits.
#' @return Character vectors.
#' @examples
#' wgh_fmt_p(c(0.2, 0.0004, 1e-8))
#' wgh_fmt_est(1.234, 0.5, 2)
#' wgh_fmt_ci(0.5, 2)
#' @export
wgh_fmt_p <- function(p, digits = 3) {
  thr <- 10^-digits
  out <- ifelse(is.na(p), "NA",
         ifelse(p < thr, paste0("<", format(thr, scientific = FALSE)),
                formatC(p, digits = digits, format = "f")))
  out
}

#' @rdname wgh_fmt_p
#' @export
wgh_fmt_est <- function(est, lo, hi, digits = 2, sep = " to ") {
  f <- function(x) formatC(x, digits = digits, format = "f")
  ifelse(is.na(est), "NA", paste0(f(est), " (", f(lo), sep, f(hi), ")"))
}

#' @rdname wgh_fmt_p
#' @export
wgh_fmt_ci <- function(lo, hi, digits = 2, sep = " to ") {
  f <- function(x) formatC(x, digits = digits, format = "f")
  paste0(f(lo), sep, f(hi))
}

#' Midline decimal point for journals that require it
#'
#' Some journals (for example The Lancet) print decimals with a middle dot.
#' Generalises `to_midline_decimal()` from Book 1 Chapter 13.
#' @param x Character or numeric vector.
#' @return Character vector with "." between digits replaced by a middle dot.
#' @examples
#' wgh_midline_decimal("Mean 12.5 (95% CI 11.2 to 13.8)")
#' @export
wgh_midline_decimal <- function(x) enc2utf8(gsub("(?<=[0-9])\\.(?=[0-9])", "\u00b7", enc2utf8(as.character(x)), perl = TRUE))
