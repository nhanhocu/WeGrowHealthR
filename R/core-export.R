## Publication output: tables, figures, workbooks, bundles ----------------

#' Publication-style flextable
#' @param df A data frame.
#' @param caption Table caption.
#' @param digits Decimals for numeric columns.
#' @param merge_col Optional column whose repeated values are merged.
#' @return A `flextable` object.
#' @examples
#' \donttest{
#' # Loading flextable and its dependencies takes a few seconds the first time
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   cl <- wgh_classify(growdat)
#'   wgh_flextable(wgh_prevalence(cl, "obesity", by = "sex"), caption = "Obesity by sex", digits = 1)
#' }
#' }
#' @export
wgh_flextable <- function(df, caption = NULL, digits = 2, merge_col = NULL) {
  .need("flextable")
  df <- as.data.frame(df)
  for (v in names(df)) if (is.numeric(df[[v]]) && !is.integer(df[[v]])) df[[v]] <- round(df[[v]], digits)
  ft <- flextable::flextable(df)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::fontsize(ft, size = 9, part = "all")
  ft <- flextable::font(ft, fontname = "Arial", part = "all")
  ft <- flextable::bold(ft, part = "header")
  if (!is.null(merge_col)) ft <- flextable::merge_v(ft, j = merge_col)
  if (!is.null(caption)) ft <- flextable::set_caption(ft, caption)
  flextable::autofit(ft)
}

#' Write several tables to one workbook, one sheet per table
#' @param tables A named list of data frames.
#' @param file Output `.xlsx` path.
#' @return The file path, invisibly.
#' @examples
#' if (requireNamespace("openxlsx", quietly = TRUE)) {
#'   cl <- wgh_classify(growdat)
#'   tabs <- list(obesity = wgh_prevalence(cl, "obesity", by = "sex"),
#'                stunting = wgh_prevalence(cl, "stunting", by = "sex"))
#'   wgh_export_xlsx(tabs, file.path(tempdir(), "tables.xlsx"))
#' }
#' @export
wgh_export_xlsx <- function(tables, file) {
  .need("openxlsx")
  wb <- openxlsx::createWorkbook()
  for (nm in names(tables)) {
    sh <- substr(gsub("[\\[\\]\\*\\?/\\\\:]", "_", nm), 1, 31)
    openxlsx::addWorksheet(wb, sh)
    openxlsx::writeData(wb, sh, as.data.frame(tables[[nm]]), headerStyle = openxlsx::createStyle(textDecoration = "bold"))
    openxlsx::setColWidths(wb, sh, cols = seq_len(ncol(tables[[nm]])), widths = "auto")
    openxlsx::freezePane(wb, sh, firstRow = TRUE)
  }
  openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  invisible(file)
}

#' Save a figure as TIFF (600 dpi, LZW) and PDF
#' @param plot A ggplot object.
#' @param file File name without extension.
#' @param width,height Size in inches.
#' @param dpi Resolution of the TIFF.
#' @param formats Formats to write.
#' @return The written paths, invisibly.
#' @examples
#' p <- wgh_plot_spaghetti(growdat, "haz", n = 50)
#' wgh_save_figure(p, file.path(tempdir(), "spaghetti"), formats = "pdf", dpi = 300)
#' @export
wgh_save_figure <- function(plot, file, width = 8, height = 5, dpi = 600, formats = c("tiff", "pdf")) {
  out <- character()
  if ("tiff" %in% formats) { f <- paste0(file, ".tiff"); ggplot2::ggsave(f, plot, width = width, height = height, dpi = dpi, compression = "lzw"); out <- c(out, f) }
  if ("pdf" %in% formats) { f <- paste0(file, ".pdf"); ggplot2::ggsave(f, plot, width = width, height = height); out <- c(out, f) }
  if ("png" %in% formats) { f <- paste0(file, ".png"); ggplot2::ggsave(f, plot, width = width, height = height, dpi = 300); out <- c(out, f) }
  invisible(out)
}

#' Versioned reproducibility bundles
#'
#' Saves an object together with the run mode, package versions, session
#' information and a hash of the input data, so a result can be traced to
#' the exact code and data that produced it.
#' @param object Object to save.
#' @param file `.rds` path.
#' @param data Optional input data whose checksum is recorded.
#' @return `wgh_bundle_save()`: the path, invisibly. `wgh_bundle_load()`: the
#'   bundle (a list with `object` and `meta`).
#' @examples
#' f <- tempfile(fileext = ".rds")
#' wgh_bundle_save(summary(growdat$height), f, data = growdat)
#' b <- wgh_bundle_load(f)
#' b$object
#' b$meta$data_md5
#' @export
wgh_bundle_save <- function(object, file, data = NULL) {
  hash <- if (!is.null(data)) {
    tf <- tempfile(); saveRDS(data, tf); h <- unname(tools::md5sum(tf)); unlink(tf); h } else NA_character_
  meta <- list(created = Sys.time(), mode = wgh_mode(), package_version = as.character(utils::packageVersion("WeGrowHealthR")),
               r_version = R.version.string, data_md5 = hash, session = utils::sessionInfo())
  saveRDS(list(object = object, meta = meta), file)
  invisible(file)
}

#' @rdname wgh_bundle_save
#' @export
wgh_bundle_load <- function(file) readRDS(file)

#' Convergence and diagnostics log for many fits
#' @param ... Named fits or tables of diagnostics (for example the
#'   `convergence` element of [wgh_lqmm()]).
#' @return A named list of tibbles ready for [wgh_export_xlsx()].
#' @examples
#' fit <- lm(height ~ age, data = growdat)
#' log <- wgh_log_fit(height_model = fit, check = data.frame(converged = TRUE, iterations = 12))
#' names(log)
#' log$check
#' @export
wgh_log_fit <- function(...) {
  x <- list(...)
  lapply(x, function(z) if (is.data.frame(z)) tibble::as_tibble(z) else tibble::tibble(value = utils::capture.output(print(z))))
}
