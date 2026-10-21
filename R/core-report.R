#' Report objects returned by the paper flows
#'
#' Every `wgh_flow_*()` function returns a `wgh_report`: a list with
#' `tables` (named tibbles), `figures` (named ggplots), `models`,
#' `sample_flow`, `diagnostics`, `settings` and a `note`. Methods print a
#' summary, plot a figure by name and export everything at once.
#'
#' @param tables,figures,models,diagnostics Named lists.
#' @param sample_flow A [wgh_sample_flow()] object or `NULL`.
#' @param title Report title.
#' @param settings List of settings used.
#' @param note Free text shown when printing (for example the simulated
#'   data label).
#' @param model_status A tibble with `step`, `status` (`"ok"`, `"failed"`
#'   or `"skipped"`) and `message`. Inside a flow it is filled
#'   automatically, so a failed or skipped optional analysis is visible
#'   rather than silently missing from the tables.
#' @return An object of class `wgh_report`.
#' @section Next steps:
#' Print the report to see what it holds, take tables with
#' `x$tables$name`, show figures with [plot.wgh_report()], check
#' `x$model_status`, and write everything to disk with [wgh_export()].
#' @examples
#' tab <- data.frame(sex = c("Male", "Female"), n = c(10, 12))
#' r <- wgh_report("A small report", tables = list(n = tab))
#' r
#' r$tables$n
#' @export
wgh_report <- function(title, tables = list(), figures = list(), models = list(), diagnostics = list(),
                      sample_flow = NULL, settings = list(), note = NULL, model_status = .status_table()) {
  structure(list(title = title, tables = tables, figures = figures, models = models, diagnostics = diagnostics,
                 sample_flow = sample_flow, settings = settings, note = note, model_status = model_status,
                 created = Sys.time()),
            class = "wgh_report")
}

#' @export
print.wgh_report <- function(x, ...) {
  cli::cli_h2(x$title)
  if (!is.null(x$note)) cli::cli_text(cli::col_grey(x$note))
  cli::cli_text("Tables ({length(x$tables)}): {paste(names(x$tables), collapse = ', ')}")
  cli::cli_text("Figures ({length(x$figures)}): {paste(names(x$figures), collapse = ', ')}")
  if (length(x$models)) cli::cli_text("Models: {paste(names(x$models), collapse = ', ')}")
  if (length(x$diagnostics)) cli::cli_text("Diagnostics: {paste(names(x$diagnostics), collapse = ', ')}")
  ms <- x$model_status
  if (!is.null(ms) && nrow(ms)) {
    n <- table(factor(ms$status, levels = c("ok", "failed", "skipped")))
    cli::cli_text("Model status: {n[['ok']]} ok, {n[['failed']]} failed, {n[['skipped']]} skipped")
    bad <- ms[ms$status != "ok" | nzchar(ms$message), ]
    for (i in seq_len(nrow(bad))) cli::cli_text(cli::col_grey("  {bad$status[i]}: {bad$step[i]} ({bad$message[i]})"))
  }
  cli::cli_text("Settings: {paste(names(x$settings), vapply(x$settings, function(s) paste(format(s), collapse = '/'), ''), sep = ' = ', collapse = '; ')}")
  invisible(x)
}

#' Show a figure of a report
#'
#' Every flow returns a `wgh_report` holding its figures. `plot()` returns
#' one of them, optionally restyled with the shared display options.
#' @param x A `wgh_report`.
#' @param which Figure number or name (see `names(x$figures)`).
#' @param ... Display options (see [wgh_plot_options()]). When none are
#'   given, the figure is returned exactly as the flow made it.
#' @return A ggplot object.
#' @examples
#' rep <- wgh_flow_secular_trends(growdat, mode = "dev", fit_lms = FALSE)
#' names(rep$figures)
#' plot(rep, "fig_prevalence_trend")
#' plot(rep, 1, title = "Overweight and obesity by year", base_size = 13)
#' @export
plot.wgh_report <- function(x, which = 1, ...) {
  if (!length(x$figures)) .stop("This report has no figures.")
  if (is.character(which) && !which %in% names(x$figures))
    .stop(c("No figure called {.val {which}}.", i = "Available: {.val {names(x$figures)}}."))
  p <- x$figures[[which]]
  if (!...length() || !inherits(p, "ggplot")) return(p)
  .finish(p, .popts(...))
}

#' Export a report: workbook of tables, figures and a bundle
#' @param x A `wgh_report`.
#' @param dir Output directory (created if needed).
#' @param figures Also save the figures.
#' @param formats Figure formats.
#' @return The output directory, invisibly.
#' @examples
#' \donttest{
#' rep <- wgh_flow_malnutrition_trends(growdat, mode = "dev")
#' out <- wgh_export(rep, file.path(tempdir(), "malnutrition"), formats = "pdf")
#' list.files(out)
#' }
#' @export
wgh_export <- function(x, dir, figures = TRUE, formats = c("tiff", "pdf")) {
  if (!inherits(x, "wgh_report")) .stop("{.arg x} must be a {.cls wgh_report}.")
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  tabs <- c(x$tables, x$diagnostics[vapply(x$diagnostics, is.data.frame, logical(1))])
  if (!is.null(x$sample_flow)) tabs$sample_flow <- x$sample_flow$steps
  if (!is.null(x$model_status) && nrow(x$model_status)) tabs$model_status <- x$model_status
  if (length(tabs) && requireNamespace("openxlsx", quietly = TRUE)) wgh_export_xlsx(tabs, file.path(dir, "tables.xlsx"))
  else for (nm in names(tabs)) utils::write.csv(tabs[[nm]], file.path(dir, paste0(nm, ".csv")), row.names = FALSE)
  if (figures) for (nm in names(x$figures)) wgh_save_figure(x$figures[[nm]], file.path(dir, nm), formats = formats)
  wgh_bundle_save(x[c("title", "tables", "settings", "note")], file.path(dir, "report_bundle.rds"))
  .inform("Report written to {.path {dir}}")
  invisible(dir)
}

#' Compare a report's tables with frozen golden outputs
#'
#' Matches tables by name and reports, for each numeric column, the largest
#' absolute difference. Used to show that a flow reproduces the outputs of
#' the original paper script (private equivalence track).
#' @param report A `wgh_report` or a named list of tables.
#' @param golden A named list of reference tables (for example read from the
#'   frozen workbook of the original script).
#' @param tolerance Differences above this value are flagged.
#' @return A tibble with one row per table and column.
#' @examples
#' rep <- list(prev = data.frame(group = c("a", "b"), value = c(10.2, 11.5)))
#' golden <- list(prev = data.frame(group = c("a", "b"), value = c(10.2, 11.6)))
#' wgh_compare_outputs(rep, golden, tolerance = 0.05)
#' @export
wgh_compare_outputs <- function(report, golden, tolerance = 1e-6) {
  tabs <- if (inherits(report, "wgh_report")) report$tables else report
  .bind(lapply(intersect(names(tabs), names(golden)), function(nm) {
    a <- as.data.frame(tabs[[nm]]); b <- as.data.frame(golden[[nm]])
    cols <- intersect(names(a)[vapply(a, is.numeric, logical(1))], names(b))
    if (nrow(a) != nrow(b)) return(tibble::tibble(table = nm, column = NA, max_abs_diff = NA, match = FALSE, note = "different number of rows"))
    .bind(lapply(cols, function(cc) {
      dmax <- max(abs(a[[cc]] - b[[cc]]), na.rm = TRUE)
      tibble::tibble(table = nm, column = cc, max_abs_diff = dmax, match = dmax <= tolerance, note = "")
    }))
  }))
}
