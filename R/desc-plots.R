#' Growth chart with reference curves and a child's measurements
#'
#' Draws reference curves for one sex and indicator, either as percentile
#' curves (3rd, 15th, 50th, 85th and 97th by default) or as standard
#' deviation (z-score) curves (-3 to +3 SD by default), and overlays the
#' measurements of one or more children. The reference can be the WHO
#' standards and reference (default), the CDC 2000 growth charts, or your
#' own LMS table. Generalises `plot_growth_chart()` from Book 1 Chapter 5.
#'
#' @param x Data with `id` (or `pid`), `age`, `sex` and the measurement.
#' @param ids Children to plot. When `NULL`, only the reference is drawn.
#' @param indicator `"hfa"` (height), `"wfa"` (weight) or `"bfa"` (BMI).
#' @param sex Sex of the chart (taken from the first child when `NULL`).
#' @param lines `"percentile"` or `"sd"`.
#' @param centiles Percentiles to draw when `lines = "percentile"`.
#' @param sd_lines Z-scores to draw when `lines = "sd"`.
#' @param reference `"who"`, `"cdc"` or a custom LMS table (see
#'   [wgh_reference()]).
#' @param age_range Age range in years (default 2 to 18).
#' @param band Shade the area between the outermost curves.
#' @param label_lines Label each curve at its right end.
#' @param line_colour Colour of the reference curves (default by sex).
#' @param child_colour Colour of the child's measurements. With several
#'   children, use `NULL` to colour each child differently.
#' @param ... Display options (see [wgh_plot_options()]), for example
#'   `title`, `base_size` or `y_limits`.
#' @return A ggplot object.
#' @section Next steps:
#' Read a child's z-scores with [wgh_add_zscores()], compare references with
#' [wgh_compare_references()], or build a personalised expected range with
#' [wgh_condref()] and [wgh_plot_fan()].
#' @examples
#' girl <- growdat$pid[growdat$sex == "Female"][1]
#' # WHO percentiles (default)
#' wgh_plot_growth_chart(growdat, ids = girl)
#' # WHO standard deviation curves
#' wgh_plot_growth_chart(growdat, ids = girl, lines = "sd")
#' # CDC 2000 percentiles for BMI, with a shaded band and a custom title
#' wgh_plot_growth_chart(growdat, ids = girl, indicator = "bfa", reference = "cdc",
#'                       centiles = c(5, 50, 85, 95), band = TRUE, title = "BMI-for-age, CDC 2000")
#' # Reference curves only, for boys
#' wgh_plot_growth_chart(sex = "Male", lines = "sd", sd_lines = c(-2, 0, 2))
#' @export
wgh_plot_growth_chart <- function(x = NULL, ids = NULL, indicator = c("hfa", "wfa", "bfa"), sex = NULL,
                                  lines = c("percentile", "sd"), centiles = c(3, 15, 50, 85, 97),
                                  sd_lines = -3:3, reference = "who", age_range = c(2, 18), band = FALSE,
                                  label_lines = TRUE, line_colour = NULL, child_colour = "grey15", ...) {
  o <- .popts(...)
  indicator <- match.arg(indicator); lines <- match.arg(lines)
  var <- c(hfa = "height", wfa = "weight", bfa = "bmi")[[indicator]]
  d <- NULL
  if (!is.null(x) && !is.null(ids)) {
    d <- .gd(x, c("id", "age"))
    if (indicator == "bfa" && !"bmi" %in% names(d)) d$bmi <- d$weight / (d$height / 100)^2
    d <- d[d$id %in% ids & d$age >= age_range[1] & d$age <= age_range[2], , drop = FALSE]
    if (!nrow(d)) .warn("No measurements of the selected children within the age range.")
    sex <- sex %||% as.character(d$sex[1])
  }
  sex <- .norm_sex(sex %||% "Male")
  ref_name <- if (is.data.frame(reference)) "custom reference" else c(who = "WHO", cdc = "CDC 2000")[[tolower(reference)]]
  ages <- seq(age_range[1], age_range[2], by = 1 / 24)
  ref <- wgh_reference(indicator, ages, sex, reference)
  zs <- if (lines == "percentile") stats::qnorm(centiles / 100) else sd_lines
  labs_l <- if (lines == "percentile") paste0("P", centiles) else
    ifelse(sd_lines == 0, "Median", paste0(ifelse(sd_lines > 0, "+", ""), sd_lines, " SD"))
  cur <- .bind(lapply(seq_along(zs), function(k) tibble::tibble(age = ages, line = labs_l[k], z = zs[k],
                                                                value = wgh_lms_value(zs[k], ref$L, ref$M, ref$S))))
  cur <- cur[!is.na(cur$value), ]
  if (!nrow(cur)) .stop("The {ref_name} reference does not cover ages {age_range[1]} to {age_range[2]} for this indicator.")
  cur$line <- factor(cur$line, levels = labs_l)
  lc <- line_colour %||% (if (sex == "Male") "#0072B2" else "#D55E00")
  p <- ggplot2::ggplot(cur, ggplot2::aes(.data$age, .data$value))
  if (band) {
    lo <- cur[cur$z == min(cur$z), ]; hi <- cur[cur$z == max(cur$z), ]
    bd <- data.frame(age = lo$age, lo = lo$value, hi = hi$value[match(lo$age, hi$age)])
    p <- p + ggplot2::geom_ribbon(data = bd, ggplot2::aes(x = .data$age, ymin = .data$lo, ymax = .data$hi),
                                  inherit.aes = FALSE, fill = lc, alpha = 0.08)
  }
  p <- p + ggplot2::geom_line(ggplot2::aes(group = .data$line, linetype = .data$z == 0 | abs(.data$z) < 1e-8),
                              colour = lc, linewidth = o$line_width %||% 0.5, show.legend = FALSE) +
    ggplot2::scale_linetype_manual(values = c(`TRUE` = 1, `FALSE` = 2)) +
    ggplot2::scale_x_continuous(breaks = seq(0, 20, 2), expand = ggplot2::expansion(mult = c(0.01, 0.08)))
  if (label_lines) {
    lab <- cur[cur$age == max(cur$age), ]
    p <- p + ggplot2::geom_text(data = lab, ggplot2::aes(label = .data$line), hjust = -0.1, size = 3, colour = lc)
  }
  p <- p + ggplot2::labs(x = "Age (years)", y = .axis_label(var),
                         title = paste0(c(hfa = "Height-for-age", wfa = "Weight-for-age", bfa = "BMI-for-age")[[indicator]],
                                        ", ", tolower(sex), " (", ref_name, ", ", if (lines == "sd") "SD curves" else "percentiles", ")"))
  if (!is.null(d) && nrow(d)) {
    if (is.null(child_colour) && length(unique(d$id)) > 1) {
      p <- p + ggplot2::geom_line(data = d, ggplot2::aes(.data$age, .data[[var]], group = .data$id, colour = factor(.data$id))) +
        ggplot2::geom_point(data = d, ggplot2::aes(.data$age, .data[[var]], colour = factor(.data$id)), size = o$point_size %||% 1.8) +
        scale_colour_wgh() + ggplot2::labs(colour = "Child")
    } else {
      cc <- child_colour %||% "grey15"
      p <- p + ggplot2::geom_line(data = d, ggplot2::aes(.data$age, .data[[var]], group = .data$id), colour = cc) +
        ggplot2::geom_point(data = d, ggplot2::aes(.data$age, .data[[var]]), colour = cc, size = o$point_size %||% 1.8)
    }
  }
  .finish(p, o)
}

#' Prevalence over time
#'
#' Plots prevalence with confidence bands over calendar time (or any
#' ordered variable) from the output of [wgh_prevalence()].
#'
#' @param prev Output of [wgh_prevalence()] with a time column.
#' @param time Time column (default `"yearvisit"`).
#' @param colour Column mapped to colour (default `"sex"`).
#' @param facet Optional column to facet by.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' cl <- wgh_classify(growdat)
#' pv <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "yearvisit"))
#' wgh_plot_prevalence(pv)
#' wgh_plot_prevalence(pv, show_ci = FALSE, title = "Obesity by year", y_limits = c(0, 35))
#' @export
wgh_plot_prevalence <- function(prev, time = "yearvisit", colour = "sex", facet = NULL, ...) {
  o <- .popts(...)
  if (!time %in% names(prev) && "year" %in% names(prev)) time <- "year"
  p <- ggplot2::ggplot(prev, ggplot2::aes(.data[[time]], .data$prevalence, colour = .data[[colour]],
                                          group = .data[[colour]]))
  if (isTRUE(o$show_ci %||% TRUE)) p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lower, ymax = .data$upper, fill = .data[[colour]]),
                                                                 alpha = o$alpha %||% 0.15, colour = NA)
  p <- p + ggplot2::geom_line(linewidth = o$line_width %||% 0.9) + ggplot2::geom_point(size = o$point_size %||% 1.8) +
    ggplot2::labs(x = NULL, y = "Prevalence (%)", colour = NULL, fill = NULL)
  if (colour == "sex") p <- p + scale_colour_wgh_sex() + scale_fill_wgh_sex() else p <- p + scale_colour_wgh() + scale_fill_wgh()
  if (!is.null(facet)) p <- p + ggplot2::facet_wrap(facet)
  .finish(p, o)
}

#' Stacked bars of nutritional status by group
#' @param x Classified data (see [wgh_classify()]).
#' @param status `"bmi_status"` or `"height_status"`.
#' @param group Column on the x axis (for example an age band or year).
#' @param facet Facet column (default `"sex"`).
#' @param position `"stack"` (shares add to 100%) or `"dodge"` (bars side by
#'   side).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' cl <- wgh_classify(growdat)
#' cl$age_group <- wgh_age_bands(cl$age)
#' wgh_plot_status_bars(cl, group = "age_group")
#' wgh_plot_status_bars(cl, status = "height_status", group = "age_group", legend = "right")
#' @export
wgh_plot_status_bars <- function(x, status = "bmi_status", group = "yearvisit", facet = "sex",
                                 position = c("stack", "dodge"), ...) {
  o <- .popts(...); position <- match.arg(position)
  d <- .gd(x, "age")
  group <- .fix_by(d, group)
  d <- d[!is.na(d[[status]]), ]
  tab <- as.data.frame(prop.table(table(d[[group]], d[[status]], d[[facet]]), margin = c(1, 3)))
  names(tab) <- c("group", "status", "facet", "share")
  pal <- c(.pal$bmi, `Severe stunting` = "#0072B2", Stunting = "#56B4E9", Tall = "#CC79A7",
           Underweight = "#56B4E9", `Healthy weight` = "#009E73", `Short stature` = "#56B4E9")
  p <- ggplot2::ggplot(tab, ggplot2::aes(.data$group, 100 * .data$share, fill = .data$status)) +
    ggplot2::geom_col(width = 0.8, position = position) + ggplot2::facet_wrap(~facet) +
    ggplot2::scale_fill_manual(values = pal) +
    ggplot2::labs(x = NULL, y = "Share (%)", fill = NULL)
  p <- .finish(p, o)
  p + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Heat map of a summary by two variables
#' @param x A data frame (for example a prevalence table).
#' @param xvar,yvar Columns on the two axes.
#' @param fill Column mapped to colour.
#' @param label Show values in the tiles.
#' @param digits Decimals of the labels.
#' @param option Viridis colour map option (`"magma"`, `"viridis"`,
#'   `"mako"`, ...).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' cl <- wgh_classify(growdat); cl$age_group <- wgh_age_bands(cl$age)
#' pv <- wgh_prevalence(cl, "overweight_obesity", by = c("yearvisit", "age_group"))
#' wgh_plot_heatmap(pv, "yearvisit", "age_group", "prevalence")
#' wgh_plot_heatmap(pv, "yearvisit", "age_group", "prevalence", option = "viridis", digits = 0)
#' @export
wgh_plot_heatmap <- function(x, xvar, yvar, fill, label = TRUE, digits = 1, option = "magma", ...) {
  o <- .popts(...)
  if (!"legend" %in% names(list(...))) o$legend <- "right"
  p <- ggplot2::ggplot(x, ggplot2::aes(factor(.data[[xvar]]), factor(.data[[yvar]]), fill = .data[[fill]])) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_viridis_c(option = option, direction = -1) +
    ggplot2::labs(x = NULL, y = NULL, fill = fill)
  if (label) p <- p + ggplot2::geom_text(ggplot2::aes(label = formatC(.data[[fill]], digits = digits, format = "f")),
                                         size = 3, colour = "grey10")
  .finish(p, o)
}

#' Forest plot of estimates with intervals
#' @param x A data frame with an estimate and interval columns.
#' @param label Column with row labels.
#' @param estimate,lower,upper Column names.
#' @param colour Optional column mapped to colour.
#' @param ref Reference line (0 for differences, 1 for ratios).
#' @param log Use a log scale (for ratios).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' d <- data.frame(term = c("A", "B"), estimate = c(1.2, 0.8), lower = c(1, 0.6), upper = c(1.4, 1.1))
#' wgh_plot_forest(d, "term", ref = 1, log = TRUE)
#' wgh_plot_forest(d, "term", ref = 1, log = TRUE, x_label = "Odds ratio", point_size = 1)
#' @export
wgh_plot_forest <- function(x, label, estimate = "estimate", lower = "lower", upper = "upper",
                            colour = NULL, ref = 0, log = FALSE, ...) {
  o <- .popts(...)
  x[[label]] <- factor(x[[label]], levels = rev(unique(x[[label]])))
  aes_col <- if (is.null(colour)) ggplot2::aes() else ggplot2::aes(colour = .data[[colour]])
  p <- ggplot2::ggplot(x, ggplot2::aes(.data[[estimate]], .data[[label]])) + aes_col +
    ggplot2::geom_vline(xintercept = ref, linetype = 2, colour = "grey50") +
    ggplot2::geom_pointrange(ggplot2::aes(xmin = .data[[lower]], xmax = .data[[upper]]),
                             position = ggplot2::position_dodge(width = 0.5), size = (o$point_size %||% 1.5) / 3) +
    ggplot2::labs(x = estimate, y = NULL)
  if (!is.null(colour)) p <- p + (if (colour == "sex") scale_colour_wgh_sex() else scale_colour_wgh())
  if (log) p <- p + ggplot2::scale_x_log10()
  .finish(p, o)
}

#' Spaghetti plot of individual trajectories
#' @param x Growth data.
#' @param y Variable on the y axis.
#' @param n Number of children sampled per facet.
#' @param facet Facet column (default `"sex"`).
#' @param smooth Add a LOESS mean curve.
#' @param seed Random seed for sampling children.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' wgh_plot_spaghetti(growdat, "haz", n = 100)
#' wgh_plot_spaghetti(growdat, "height", n = 50, smooth = FALSE, alpha = 0.6, facet = "site")
#' @export
wgh_plot_spaghetti <- function(x, y = "height", n = 200, facet = "sex", smooth = TRUE, seed = 1, ...) {
  o <- .popts(...)
  d <- .gd(x, c("id", "age"))
  .local_seed(seed)
  keep <- unlist(lapply(split(d$id, d[[facet]]), function(z) { u <- unique(z); sample(u, min(n, length(u))) }))
  dd <- d[d$id %in% keep, ]
  p <- ggplot2::ggplot(dd, ggplot2::aes(.data$age, .data[[y]], group = .data$id)) +
    ggplot2::geom_line(alpha = o$alpha %||% 0.25, colour = "grey30", linewidth = o$line_width %||% 0.4) +
    ggplot2::facet_wrap(facet) + ggplot2::labs(x = "Age (years)", y = .axis_label(y))
  if (smooth) p <- p + ggplot2::geom_smooth(data = d, ggplot2::aes(group = NULL), method = "loess",
                                            formula = y ~ x, se = FALSE, colour = "#D55E00", linewidth = 1)
  .finish(p, o)
}
