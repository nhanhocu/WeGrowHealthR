#' Track attrition and site representativeness through restriction steps
#'
#' Analyses in the research program repeatedly lost a disproportionate share
#' of one site during feature engineering, for example in the height
#' prediction cohort, the first design of the conditional reference panel and
#' the canalization sample (see [wgh_references()]). `wgh_sample_flow()` applies a sequence of named
#' restriction steps and records, after each one, the number of children and
#' visits, the share retained by site and the balance between included and
#' excluded children. It warns when a site's retention falls far below the
#' others. It generalises `sample_check()` from Book 2 Chapter 2.
#'
#' Each step is either a one-sided formula evaluated on visit rows (rows
#' where it is `FALSE` are dropped) or a function that takes the current data
#' and returns the restricted data, such as [wgh_min_visits()].
#'
#' @param x A [wgh_data] object or a data frame with `id` (or `pid`) and
#'   optionally `site` columns.
#' @param ... Named restriction steps.
#' @param site_ratio Warn when a site's cumulative retention divided by the
#'   best site's retention is below this value. Default 0.7.
#' @param balance_vars Optional variables summarised for included versus
#'   excluded children at the final step (first visit of each child).
#' @return An object of class `wgh_sample_flow` with `$data` (restricted data
#'   in the same container type as `x`), `$steps` (attrition table),
#'   `$by_site` (retention by site and step) and `$balance`.
#' @examples
#' fl <- wgh_sample_flow(growdat,
#'   "Ages 5 to 18" = ~ age >= 5 & age <= 18,
#'   "At least 3 visits" = wgh_min_visits(3))
#' fl
#' @export
wgh_sample_flow <- function(x, ..., site_ratio = 0.7, balance_vars = NULL) {
  steps <- list(...)
  if (length(steps) && (is.null(names(steps)) || any(names(steps) == "")))
    .stop("Every restriction step must be named.")
  d0 <- .gd(x, "id")
  has_site <- "site" %in% names(d0)
  cur <- d0
  rows <- list(); site_rows <- list()
  record <- function(label, d) {
    rows[[length(rows) + 1]] <<- tibble::tibble(step = label, children = length(unique(d$id)), visits = nrow(d))
    if (has_site) {
      tab <- tapply(d$id, d$site, function(z) length(unique(z)))
      tab[is.na(tab)] <- 0L
      site_rows[[length(site_rows) + 1]] <<- tibble::tibble(step = label, site = names(tab), children = as.integer(tab))
    }
  }
  record("Start", cur)
  for (nm in names(steps)) {
    s <- steps[[nm]]
    if (inherits(s, "formula")) {
      keep <- eval(rlang::f_rhs(s), cur, environment(s))
      keep[is.na(keep)] <- FALSE
      cur <- cur[keep, , drop = FALSE]
    } else if (is.function(s)) {
      cur <- s(cur)
    } else .stop("Step {.val {nm}} must be a formula or a function.")
    record(nm, cur)
  }
  st <- dplyr::bind_rows(rows)
  st$children_lost <- c(NA, -diff(st$children))
  st$pct_children_retained <- round(100 * st$children / st$children[1], 1)
  by_site <- NULL
  if (has_site) {
    by_site <- dplyr::bind_rows(site_rows)
    start <- by_site[by_site$step == "Start", c("site", "children")]
    names(start)[2] <- "start"
    by_site <- dplyr::left_join(by_site, start, by = "site")
    by_site$pct_retained <- round(100 * by_site$children / by_site$start, 1)
    last <- by_site[by_site$step == st$step[nrow(st)], ]
    ratio <- last$pct_retained / max(last$pct_retained)
    if (any(ratio < site_ratio, na.rm = TRUE)) {
      bad <- last$site[ratio < site_ratio]
      .warn(c("Disproportionate site loss after restriction.",
              i = paste0("Site(s) ", paste(bad, collapse = ", "), " retain ",
                         paste(last$pct_retained[ratio < site_ratio], collapse = ", "),
                         "% of children versus ", max(last$pct_retained), "% for the best site.")))
    }
  }
  bal <- NULL
  if (!is.null(balance_vars)) {
    first <- d0[!duplicated(d0$id), , drop = FALSE]
    first$included <- first$id %in% cur$id
    bal <- .bind(lapply(balance_vars, function(v) {
      if (!v %in% names(first)) return(NULL)
      z <- first[[v]]
      if (is.numeric(z)) {
        m1 <- mean(z[first$included], na.rm = TRUE); m0 <- mean(z[!first$included], na.rm = TRUE)
        sp <- sqrt((stats::var(z[first$included], na.rm = TRUE) + stats::var(z[!first$included], na.rm = TRUE)) / 2)
        tibble::tibble(variable = v, level = "mean", included = m1, excluded = m0, smd = (m1 - m0) / sp)
      } else {
        lv <- unique(stats::na.omit(as.character(z)))
        .bind(lapply(lv, function(l) {
          p1 <- mean(z[first$included] == l, na.rm = TRUE); p0 <- mean(z[!first$included] == l, na.rm = TRUE)
          tibble::tibble(variable = v, level = l, included = p1, excluded = p0,
                         smd = (p1 - p0) / sqrt((p1 * (1 - p1) + p0 * (1 - p0)) / 2))
        }))
      }
    }))
  }
  structure(list(data = .regd(x, cur), steps = st, by_site = by_site, balance = bal),
            class = "wgh_sample_flow")
}

#' Keep children with at least a given number of visits
#' @param k Minimum number of visits.
#' @param span Optional minimum follow-up span in years.
#' @return A function usable as a step in [wgh_sample_flow()].
#' @examples
#' f <- wgh_min_visits(3)
#' kept <- f(transform(growdat, id = pid))
#' length(unique(kept$id))
#' @export
wgh_min_visits <- function(k = 3, span = 0) {
  force(k); force(span)
  function(d) {
    nv <- table(d$id)
    sp <- tapply(d$age, d$id, function(a) diff(range(a)))
    ok <- names(nv)[nv >= k & sp[names(nv)] >= span]
    d[d$id %in% ok, , drop = FALSE]
  }
}


#' @export
print.wgh_sample_flow <- function(x, ...) {
  cli::cli_text("{.cls wgh_sample_flow}: {nrow(x$steps) - 1} restriction step{?s}")
  print(x$steps, n = Inf)
  if (!is.null(x$by_site)) {
    w <- stats::reshape(as.data.frame(x$by_site[, c("step", "site", "pct_retained")]),
                        idvar = "step", timevar = "site", direction = "wide")
    names(w) <- sub("pct_retained.", "% ", names(w), fixed = TRUE)
    cli::cli_text("Children retained by site (%):")
    print(tibble::as_tibble(w), n = Inf)
  }
  invisible(x)
}

#' Plot a sample flow
#'
#' Shows how many children remain after each restriction step, or, when the
#' flow was built with a `site` column, the share retained at each site.
#' Unequal retention across sites is a warning sign of selection bias.
#' @param x A `wgh_sample_flow` object from [wgh_sample_flow()].
#' @param type `"auto"` (by site when available), `"total"` or `"site"`.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' sf <- wgh_sample_flow(growdat, "At least 3 visits" = wgh_min_visits(3))
#' plot(sf)
#' plot(sf, type = "total", title = "Children after each step")
#' @export
plot.wgh_sample_flow <- function(x, type = c("auto", "total", "site"), ...) {
  o <- .popts(...); type <- match.arg(type)
  if (type == "total" || (type == "auto" && is.null(x$by_site))) {
    d <- x$steps; d$step <- factor(d$step, levels = d$step)
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$step, .data$children)) +
      ggplot2::geom_col(fill = "#56B4E9", alpha = o$alpha %||% 1) +
      ggplot2::geom_text(ggplot2::aes(label = format(.data$children, big.mark = ",")), vjust = -0.3, size = 3.2) +
      ggplot2::labs(x = NULL, y = "Children")
  } else {
    if (is.null(x$by_site)) .stop("This sample flow has no site breakdown.")
    d <- x$by_site; d$step <- factor(d$step, levels = unique(d$step))
    p <- ggplot2::ggplot(d, ggplot2::aes(.data$step, .data$pct_retained, colour = .data$site, group = .data$site)) +
      ggplot2::geom_line(linewidth = o$line_width %||% 0.9) + ggplot2::geom_point(size = o$point_size %||% 2) +
      scale_colour_wgh() +
      ggplot2::labs(x = NULL, y = "Children retained (%)", colour = "Site",
                    title = "Retention by site through the restriction steps")
  }
  .finish(p, o) + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
}
