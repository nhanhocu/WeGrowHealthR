#' Write a targets pipeline that chains the study flows
#'
#' Writes a `_targets.R` file in which the flows run in the program's real
#' order: data preparation, then the SITAR models of the pubertal spurt study
#' ([wgh_flow_pubertal_spurt()]), then the analyses that reuse them (height
#' prediction, velocity distribution, spurt duration and growth phenotypes),
#' then the analysis that reuses the phenotypes, alongside the independent
#' descriptive and distributional studies. See [wgh_references()] for the
#' studies behind each flow. `targets` caches every step, so changing one
#' analysis reruns only what depends on it. This replaces the hand-off of
#' saved `.RData` workspaces between scripts (Book 2 Chapter 18).
#'
#' @param dir Directory in which `_targets.R` is written (required, for example
#'   `"."` for the current project). It is created if it does not exist.
#' @param data_file Path of an `.rds` file with the visit data. When `NULL`,
#'   the pipeline simulates the `wgh_like` cohort.
#' @param mode Run mode used by every flow.
#' @param overwrite Overwrite an existing file.
#' @return The path of the written file, invisibly.
#' @examples
#' f <- wgh_use_pipeline(tempdir(), overwrite = TRUE)
#' cat(readLines(f)[1:10], sep = "\n")
#' @export
wgh_use_pipeline <- function(dir, data_file = NULL, mode = "analysis", overwrite = FALSE) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, "_targets.R")
  if (!requireNamespace("targets", quietly = TRUE))
    .inform(c("!" = "Package {.pkg targets} is not installed.", i = "Install it to run the pipeline with {.code targets::tar_make()}."))
  if (file.exists(path) && !overwrite) .stop("{.path {path}} exists. Use {.code overwrite = TRUE}.")
  data_line <- if (is.null(data_file)) "wgh_simulate(30000, preset = \"wgh_like\", seed = 2026)$visits" else sprintf("readRDS(\"%s\")", data_file)
  txt <- c(
    "## Pipeline written by WeGrowHealthR::wgh_use_pipeline()",
    "library(targets)",
    "tar_option_set(packages = c(\"WeGrowHealthR\"))",
    sprintf("WeGrowHealthR::wgh_config(\"%s\")", mode),
    "",
    "list(",
    sprintf("  tar_target(visits, %s),", data_line),
    "  tar_target(secular_trends, wgh_flow_secular_trends(visits)),",
    "  tar_target(malnutrition, wgh_flow_malnutrition_trends(visits)),",
    "  tar_target(trajectory, wgh_flow_index_trajectory(visits)),",
    "  tar_target(spurt, wgh_flow_pubertal_spurt(visits)),",
    "  tar_target(height_prediction, wgh_flow_height_prediction(visits, spurt = spurt)),",
    "  tar_target(distribution, wgh_flow_distributional_height(visits)),",
    "  tar_target(velocity, wgh_flow_velocity_distribution(visits, spurt = spurt)),",
    "  tar_target(duration, wgh_flow_spurt_duration(visits, spurt = spurt)),",
    "  tar_target(phenotypes, wgh_flow_growth_phenotypes(visits, spurt = spurt)),",
    "  tar_target(condref, wgh_flow_conditional_references(visits)),",
    "  tar_target(canalization, wgh_flow_canalization(visits)),",
    "  tar_target(inequality, wgh_flow_growth_inequality(visits)),",
    "  tar_target(phenotype_outcomes, wgh_flow_phenotype_outcomes(visits, phenotypes = phenotypes)),",
    "  tar_target(explanation, wgh_flow_explain_prediction(visits)),",
    "  tar_target(exports, {",
    "    reps <- list(secular_trends = secular_trends, malnutrition = malnutrition, trajectory = trajectory,",
    "                 spurt = spurt, height_prediction = height_prediction, distribution = distribution,",
    "                 velocity = velocity, duration = duration, phenotypes = phenotypes, condref = condref,",
    "                 canalization = canalization, inequality = inequality,",
    "                 phenotype_outcomes = phenotype_outcomes, explanation = explanation)",
    "    for (nm in names(reps)) wgh_export(reps[[nm]], file.path(\"results\", nm))",
    "    \"results\"",
    "  }, format = \"file\")",
    ")")
  writeLines(txt, path)
  .inform("Wrote {.path {path}}. Run it with {.code targets::tar_make()}.")
  invisible(path)
}
