#' WeGrowHealthR: child growth data analysis and reproducible workflows
#'
#' WeGrowHealthR accompanies the books *Child Growth Data Analysis and
#' Modeling with R* (Book 1) and its advanced companion (Book 2). It is
#' organised in layers.
#'
#' * **Foundation**: [wgh_data()] (the data contract), [wgh_config()] (run
#'   modes), [wgh_sample_flow()] (attrition tracking), formatting, the house
#'   theme [theme_wgh()] and export helpers.
#' * **Method modules**: data preparation, WHO z-scores and classification,
#'   descriptive epidemiology and trends, trajectories, SITAR growth curves,
#'   distributional models, phenotypes, states and transitions, prediction
#'   and explanation, causal helpers, and simulation.
#' * **Flows**: one function per paper (`wgh_flow_*()`) returning a
#'   [wgh_report] with every table, figure and model.
#' * **Pipeline**: [wgh_use_pipeline()] writes a `targets` template that
#'   chains the flows.
#'
#' Every example uses simulated data from [wgh_simulate()]. The simulated
#' cohorts resemble a large school health cohort, so analyses give tables
#' and figures similar to the published ones, but they are not real data
#' and their numbers are not findings.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data .env :=
#' @importFrom stats median quantile sd var qnorm pnorm setNames na.omit
#'   coef predict fitted residuals model.frame model.matrix terms
#'   delete.response as.formula plogis qlogis rnorm runif rbinom
#' @importFrom utils head tail
## usethis namespace: end
NULL

utils::globalVariables(c(".", "n", "pid", "age", "sex", "site", "year", ".grp", "height", "id"))
