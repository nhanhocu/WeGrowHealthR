.wgh_papers <- data.frame(
  key = c("trends", "malnutrition", "trajectory", "spurt", "prediction", "distribution", "velocity",
          "duration", "phenotypes", "condref", "canalization", "inequality", "phenotype_outcomes", "explanation"),
  flow = c("wgh_flow_secular_trends", "wgh_flow_malnutrition_trends", "wgh_flow_index_trajectory",
           "wgh_flow_pubertal_spurt", "wgh_flow_height_prediction", "wgh_flow_distributional_height",
           "wgh_flow_velocity_distribution", "wgh_flow_spurt_duration", "wgh_flow_growth_phenotypes",
           "wgh_flow_conditional_references", "wgh_flow_canalization", "wgh_flow_growth_inequality",
           "wgh_flow_phenotype_outcomes", "wgh_flow_explain_prediction"),
  short = c("Ho et al. 2026, Sci Rep 16:7515",
            "Ho et al. 2026, medRxiv 2026.07.26.26358982",
            "Ho et al. 2026, medRxiv 2026.07.26.26358003",
            "Ho et al. 2026, medRxiv 2026.07.26.26358986",
            "Ho 2026, manuscript under review, late-adolescent height prediction",
            "Ho 2026, medRxiv 2026.09.08.26362487",
            "Ho 2026, medRxiv 2026.09.04.26362313",
            "Ho 2026, medRxiv 2026.09.09.26362696",
            "Ho 2026, medRxiv 2026.09.05.26362315",
            "Ho 2026, medRxiv 2026.09.23.26363771",
            "Ho 2026, manuscript under review, canalization",
            "Ho 2026, manuscript under review, growth inequality",
            "Ho 2026, manuscript in preparation, growth phenotypes and later health",
            "Ho 2026, manuscript under review, explainable growth prediction"),
  citation = c(
    "Ho NT, Bangsberg D, Hermiston ML, et al. Overweight and obesity epidemic, temporal trends and regional disparities in physical growth of Vietnamese children. Scientific Reports. 2026;16:7515.",
    "Ho NT, Hermiston M, Nguyen MA, Nguyen QV, Dao AQ, Tran CTL, Le HTM, Pham TV, Phung LT, Nguyen HT, Nguyen QN, Phung LN, Do CT, Pham AN. Stunting, thinness, obesity, and double burden of malnutrition in Vietnamese urban children. medRxiv. 2026. 2026.07.26.26358982.",
    "Ho NT, Hermiston M, Nguyen QT, Nguyen MA, Nguyen QV, Dao AQ, Tran CTL, Nguyen QN, Phung LN, Do CT, Pham AN. Effect of pre-pubertal body mass index status on longitudinal height trajectory in Vietnamese children: 2018-2025 school health analysis. medRxiv. 2026. 2026.07.26.26358003.",
    "Ho NT, Nguyen QV, Dao AQ, Tran CTL, Pham AN. Pubertal growth spurt characteristics of Vietnamese urban schoolchildren: population and individual level analysis using SITAR. medRxiv. 2026. 2026.07.26.26358986.",
    "Ho NT. Predicting late-adolescent height from prepubertal growth trajectories in Vietnamese schoolchildren. Manuscript under review. 2026.",
    "Ho NT. The age-varying association between BMI and height-for-age in Vietnamese schoolchildren: a sex-stratified quantile regression study. medRxiv. 2026. 2026.09.08.26362487.",
    "Ho NT. Prepubertal body mass index reshapes the distribution of pubertal growth velocity in Vietnamese children: a SITAR-based quantile analysis. medRxiv. 2026. 2026.09.04.26362313.",
    "Ho NT. Body mass index and the duration of the pubertal growth spurt in Vietnamese urban children. medRxiv. 2026. 2026.09.09.26362696.",
    "Ho NT. Distinct peri-pubertal growth phenotypes among Vietnamese urban children: a functional clustering analysis of 2018-2025 school health data. medRxiv. 2026. 2026.09.05.26362315.",
    "Ho NT. Conditional growth references for Vietnamese children: quantile regression of growth distributions and phenotypes. medRxiv. 2026. 2026.09.23.26363771.",
    "Ho NT. Height trajectory canalization, catch-up, and catch-down growth in urban Vietnamese children. Manuscript under review. 2026.",
    "Ho NT. Growth inequality over age and BMI in Vietnamese children: age-varying dispersion of the conditional height-for-age distribution from quantile regression. Manuscript under review. 2026.",
    "Ho NT. Peri-pubertal growth phenotypes and later health in Vietnamese schoolchildren. Manuscript in preparation. 2026.",
    "Ho NT. Explainable individualized growth prediction: interpreting conditional height-for-age predictions across the growth distribution. Manuscript under review. 2026."),
  doi = c("10.1038/s41598-026-37210-w", "10.64898/2026.07.26.26358982", "10.64898/2026.07.26.26358003",
          "10.64898/2026.07.26.26358986", NA, "10.64898/2026.09.08.26362487", "10.64898/2026.09.04.26362313",
          "10.64898/2026.09.09.26362696", "10.64898/2026.09.05.26362315", "10.64898/2026.09.23.26363771",
          NA, NA, NA, NA),
  stringsAsFactors = FALSE)

#' Studies of the research program reproduced by the flows
#'
#' Returns the full citation of each published paper, preprint or
#' manuscript whose analyses a `wgh_flow_*()` function reproduces, with the
#' DOI where one exists. Use it to cite the original analyses alongside the
#' package.
#'
#' @param key Optional keys (see the `key` column) or flow names to select.
#'   The result follows the order of `key`, so a reference list can be
#'   numbered by order of first citation.
#' @param format `"table"` (a tibble) or `"text"` (numbered citations, one
#'   per line, ready to paste into a reference list).
#' @return A tibble with `key`, `flow`, `short`, `citation` and `doi`, or a
#'   character vector when `format = "text"`.
#' @examples
#' wgh_references()
#' wgh_references("spurt", format = "text")
#' wgh_references("wgh_flow_conditional_references")$citation
#' @export
wgh_references <- function(key = NULL, format = c("table", "text")) {
  format <- match.arg(format)
  p <- .wgh_papers
  if (!is.null(key)) {
    pos <- ifelse(is.na(match(p$key, key)), match(p$flow, key), match(p$key, key))
    p <- p[!is.na(pos), , drop = FALSE]
    p <- p[order(pos[!is.na(pos)]), , drop = FALSE]
  }
  if (format == "text") {
    txt <- ifelse(is.na(p$doi), p$citation, paste0(p$citation, " https://doi.org/", p$doi))
    return(paste0(seq_along(txt), ". ", txt))
  }
  tibble::as_tibble(p)
}

## Short citation used in report titles and messages
.cite <- function(key) .wgh_papers$short[match(key, .wgh_papers$key)]
