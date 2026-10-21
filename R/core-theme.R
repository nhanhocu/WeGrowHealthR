.pal <- list(
  sex = c(Male = "#0072B2", Female = "#D55E00"),
  okabe = c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"),
  bmi = c(Thinness = "#56B4E9", Normal = "#009E73", Overweight = "#E69F00", Obesity = "#D55E00",
          `Severe thinness` = "#0072B2"),
  status = c(Normal = "#009E73", Stunting = "#56B4E9", Thinness = "#0072B2", Wasting = "#0072B2",
             Underweight = "#CC79A7", Overweight = "#E69F00", Obesity = "#D55E00")
)

#' House ggplot2 theme and palettes
#'
#' `theme_wgh()` is the publication theme used across the program (it
#' replaces `theme_paper()` in the paper scripts and `theme_growth()` in
#' Book 1 Chapter 5). The scales apply colour-blind safe palettes: sex,
#' BMI category, nutritional status and the Okabe-Ito set.
#'
#' @param base_size Base font size.
#' @param legend Legend position.
#' @param ... Passed to the underlying ggplot2 scale.
#' @return A ggplot2 theme or scale.
#' @examples
#' library(ggplot2)
#' ggplot(growdat, aes(age, height, colour = sex)) +
#'   geom_point(size = 0.3, alpha = 0.3) + scale_colour_wgh_sex() + theme_wgh()
#' @export
theme_wgh <- function(base_size = 11, legend = "bottom") {
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey92", linewidth = 0.3),
      strip.background = ggplot2::element_rect(fill = "grey95", colour = "grey70"),
      strip.text = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.caption = ggplot2::element_text(size = base_size - 2, colour = "grey40", hjust = 0),
      legend.position = legend,
      legend.title = ggplot2::element_text(size = base_size - 1)
    )
}

#' @rdname theme_wgh
#' @export
scale_colour_wgh_sex <- function(...) ggplot2::scale_colour_manual(values = .pal$sex, ...)
#' @rdname theme_wgh
#' @export
scale_fill_wgh_sex <- function(...) ggplot2::scale_fill_manual(values = .pal$sex, ...)
#' @rdname theme_wgh
#' @export
scale_colour_wgh_bmi <- function(...) ggplot2::scale_colour_manual(values = .pal$bmi, ...)
#' @rdname theme_wgh
#' @export
scale_fill_wgh_bmi <- function(...) ggplot2::scale_fill_manual(values = .pal$bmi, ...)
#' @rdname theme_wgh
#' @export
scale_colour_wgh <- function(...) ggplot2::discrete_scale("colour", "wgh", palette = .wgh_pal_n, ...)
#' @rdname theme_wgh
#' @export
scale_fill_wgh <- function(...) ggplot2::discrete_scale("fill", "wgh", palette = .wgh_pal_n, ...)

.wgh_pal_n <- function(n) {
  ok <- c("#0072B2", "#D55E00", "#009E73", "#E69F00", "#56B4E9", "#CC79A7", "#F0E442", "#000000")
  if (n <= length(ok)) ok[seq_len(n)] else grDevices::hcl.colors(n, "Dark 3")
}

#' Colour palettes used by the package
#' @param name `"sex"`, `"okabe"`, `"bmi"` or `"status"`.
#' @return A named character vector of colours.
#' @examples wgh_palette("sex")
#' @export
wgh_palette <- function(name = c("okabe", "sex", "bmi", "status")) .pal[[match.arg(name)]]

#' Display options shared by all plot functions
#'
#' Every plot function and `plot()` method in the package accepts these
#' options through `...`, so any figure can be tuned without rewriting it.
#' `wgh_plot_options()` documents them and can also be called to build an
#' options list, for example to reuse the same settings for several plots
#' with `do.call()`.
#'
#' @param title,subtitle,caption Plot title, subtitle and caption.
#' @param x_label,y_label,colour_label Axis and legend titles.
#' @param base_size Base font size of the theme.
#' @param legend Legend position: `"bottom"`, `"right"`, `"top"`, `"left"`
#'   or `"none"`.
#' @param palette Colours for the colour and fill scales: an unnamed vector
#'   (used in order) or a vector named by group (for example
#'   `c(Male = "black", Female = "grey50")`).
#' @param point_size,line_width,alpha Size of points, width of lines and
#'   transparency, where the plot uses them.
#' @param show_ci Show confidence or prediction bands, where available.
#' @param facet A column to facet by, overriding the plot's default, or
#'   `FALSE` for no facets where the plot facets by default.
#' @param facet_scales `"fixed"`, `"free"`, `"free_x"` or `"free_y"`.
#' @param ncol Number of facet columns.
#' @param x_limits,y_limits Axis limits (zoom without dropping data).
#' @param theme A complete ggplot2 theme replacing [theme_wgh()].
#' @return A list of class `wgh_plot_options`.
#' @examples
#' cl <- wgh_classify(growdat)
#' pv <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "yearvisit"))
#' # The same plot with different display options
#' wgh_plot_prevalence(pv)
#' wgh_plot_prevalence(pv, title = "Obesity, 5 to 18 years", base_size = 14,
#'                     palette = c(Male = "black", Female = "grey60"), show_ci = FALSE,
#'                     y_limits = c(0, 40), legend = "right")
#' # Reuse a set of options
#' opts <- wgh_plot_options(base_size = 9, legend = "none")
#' do.call(wgh_plot_prevalence, c(list(pv), opts))
#' @export
wgh_plot_options <- function(title = NULL, subtitle = NULL, caption = NULL, x_label = NULL, y_label = NULL,
                             colour_label = NULL, base_size = 11, legend = "bottom", palette = NULL,
                             point_size = NULL, line_width = NULL, alpha = NULL, show_ci = TRUE,
                             facet = NULL, facet_scales = "fixed", ncol = NULL, x_limits = NULL,
                             y_limits = NULL, theme = NULL) {
  o <- list(title = title, subtitle = subtitle, caption = caption, x_label = x_label, y_label = y_label,
            colour_label = colour_label, base_size = base_size, legend = legend, palette = palette,
            point_size = point_size, line_width = line_width, alpha = alpha, show_ci = show_ci,
            facet = facet, facet_scales = facet_scales, ncol = ncol, x_limits = x_limits,
            y_limits = y_limits, theme = theme)
  structure(Filter(Negate(is.null), o), class = "wgh_plot_options")
}

## Collect display options from ... with a clear error for unknown names
.popts <- function(...) {
  dots <- list(...)
  if (length(dots) == 1 && inherits(dots[[1]], "wgh_plot_options")) dots <- unclass(dots[[1]])
  ok <- names(formals(wgh_plot_options))
  bad <- setdiff(names(dots), ok)
  if (length(bad)) .stop(c("Unknown display option{?s}: {.arg {bad}}.", i = "See {.fn wgh_plot_options} for the options."))
  res <- unclass(do.call(wgh_plot_options, dots))
  full <- stats::setNames(vector("list", length(ok)), ok)  # keep every name so `$` never partially matches
  full[names(res)] <- res
  full
}

## Apply common display options to a finished ggplot
.finish <- function(p, o) {
  suppressMessages({
    p <- p + (o$theme %||% theme_wgh(o$base_size %||% 11, o$legend %||% "bottom"))
    lb <- list(title = o$title, subtitle = o$subtitle, caption = o$caption, x = o$x_label, y = o$y_label,
               colour = o$colour_label, fill = o$colour_label)
    lb <- Filter(Negate(is.null), lb)
    if (length(lb)) p <- p + do.call(ggplot2::labs, lb)
    if (!is.null(o$palette)) p <- p + ggplot2::scale_colour_manual(values = o$palette) +
      ggplot2::scale_fill_manual(values = o$palette)
    if (!is.null(o$facet) && !isFALSE(o$facet))
      p <- p + ggplot2::facet_wrap(o$facet, scales = o$facet_scales %||% "fixed", ncol = o$ncol)
    if (isFALSE(o$facet)) p <- p + ggplot2::facet_null()
    if (!is.null(o$x_limits) || !is.null(o$y_limits))
      p <- p + ggplot2::coord_cartesian(xlim = o$x_limits, ylim = o$y_limits)
  })
  p
}
