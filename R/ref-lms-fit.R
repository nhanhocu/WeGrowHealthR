#' Fit LMS-type growth reference curves with GAMLSS
#'
#' Fits a Box-Cox Cole and Green (BCCG, the LMS method), Box-Cox power
#' exponential (BCPE) or Box-Cox t (BCT) distribution with penalised
#' B-splines of age for every parameter, separately by sex, as in the cohort
#' centile curves of the secular trends study (Ho et al. 2026, Sci Rep 16:7515) and Book 1 Chapter 9.
#'
#' @param x Growth data.
#' @param var Measurement (`"height"`, `"weight"` or `"bmi"`).
#' @param by Grouping column (default `"sex"`).
#' @param family `"BCCG"`, `"BCPE"` or `"BCT"`.
#' @param max_n Largest number of rows used per group (a random subsample
#'   keeps fitting fast).
#' @param seed Random seed for the subsample.
#' @return An object of class `wgh_lms` with one gamlss fit per group.
#' @examples
#' \donttest{
#' lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
#' wgh_centiles(lms, ages = c(5, 10, 15))
#' }
#' @export
wgh_fit_lms <- function(x, var = "height", by = "sex", family = c("BCCG", "BCPE", "BCT"), max_n = 20000, seed = 1) {
  .need("gamlss"); .need("gamlss.dist")
  family <- match.arg(family)
  d <- as.data.frame(.gd(x, "age"))
  d <- d[!is.na(d[[var]]) & d[[var]] > 0, ]
  .local_seed(seed)
  fits <- lapply(split(d, d[[by]], drop = TRUE), function(z) {
    if (nrow(z) > max_n) z <- z[sample.int(nrow(z), max_n), ]
    dd <- data.frame(y = z[[var]], age = z$age)
    env <- new.env(parent = asNamespace("gamlss")); env$dd <- dd
    fam_call <- as.call(list(call("::", as.name("gamlss.dist"), as.name(family))))
    f <- eval(bquote(gamlss(y ~ pb(age), sigma.formula = ~ pb(age), nu.formula = ~ pb(age),
                            family = .(fam_call), data = dd, control = gamlss.control(n.cyc = 60, trace = FALSE))), env)
    f$wgh_data <- dd
    f
  })
  structure(list(fits = fits, var = var, by = by, family = family, age_range = range(d$age)), class = "wgh_lms")
}

#' Centiles from a fitted LMS reference
#' @param object A `wgh_lms` object.
#' @param ages Ages at which centiles are computed.
#' @param centiles Centiles in percent.
#' @return A tibble with one row per group and age.
#' @examples
#' \donttest{
#' if (requireNamespace("gamlss", quietly = TRUE)) {
#'   lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
#'   wgh_centiles(lms, ages = c(5, 10, 15), centiles = c(3, 50, 97))
#' }
#' }
#' @export
wgh_centiles <- function(object, ages = seq(2, 18, by = 0.5), centiles = c(3, 10, 25, 50, 75, 90, 97)) {
  .need("gamlss")
  qf <- get(paste0("q", object$family), asNamespace("gamlss.dist"))
  .bind(lapply(names(object$fits), function(g) {
    f <- object$fits[[g]]
    nd <- data.frame(age = ages)
    pa <- suppressWarnings(gamlss::predictAll(f, newdata = nd, data = f$wgh_data, output = "matrix"))
    out <- tibble::tibble(!!object$by := g, age = ages, mu = pa[, "mu"], sigma = pa[, "sigma"], nu = pa[, "nu"])
    for (cc in centiles) {
      args <- list(p = cc / 100, mu = pa[, "mu"], sigma = pa[, "sigma"], nu = pa[, "nu"])
      if ("tau" %in% colnames(pa)) args$tau <- pa[, "tau"]
      out[[paste0("P", cc)]] <- do.call(qf, args)
    }
    out
  }))
}

#' Plot cohort centile curves
#'
#' Draws the centile curves of a fitted cohort LMS-type reference, by group,
#' optionally against the WHO curves for the same centiles.
#' @param x A `wgh_lms` object from [wgh_fit_lms()].
#' @param ages Ages at which the curves are evaluated.
#' @param compare_who Add the WHO curves (grey) for comparison.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' \donttest{
#' lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
#' plot(lms)
#' plot(lms, compare_who = TRUE, title = "Cohort against WHO height centiles")
#' }
#' @export
plot.wgh_lms <- function(x, ages = NULL, compare_who = FALSE, ...) {
  o <- .popts(...)
  ages <- ages %||% seq(ceiling(x$age_range[1]), floor(x$age_range[2]), by = 0.25)
  ce <- wgh_centiles(x, ages)
  pc <- grep("^P", names(ce), value = TRUE)
  long <- .bind(lapply(pc, function(p) tibble::tibble(group = ce[[x$by]], age = ce$age, centile = p, value = ce[[p]])))
  long$centile <- factor(long$centile, levels = pc)
  p <- ggplot2::ggplot(long, ggplot2::aes(.data$age, .data$value, group = .data$centile, linetype = .data$centile == "P50"))
  ind <- c(height = "hfa", weight = "wfa", bmi = "bfa")[x$var]
  if (compare_who && !is.na(ind) && x$by == "sex") {
    cen <- as.numeric(sub("^P", "", pc))
    who <- .bind(lapply(unique(long$group), function(g) .bind(lapply(cen, function(k) {
      r <- wgh_reference(ind, ages, g)
      tibble::tibble(group = g, age = ages, centile = paste0("P", k), value = wgh_lms_value(stats::qnorm(k / 100), r$L, r$M, r$S))
    }))))
    who$centile <- factor(who$centile, levels = pc)
    p <- p + ggplot2::geom_line(data = who, colour = "grey60", linewidth = 0.4)
  }
  p <- p + ggplot2::geom_line(colour = "#0072B2", linewidth = o$line_width %||% 0.5) + ggplot2::facet_wrap(~group) +
    ggplot2::scale_linetype_manual(values = c(`TRUE` = 1, `FALSE` = 2), guide = "none") +
    ggplot2::labs(x = "Age (years)", y = .axis_label(x$var), title = paste("Cohort", x$family, "centiles"),
                  caption = if (compare_who) "Grey: WHO centiles." else NULL)
  .finish(p, o)
}
