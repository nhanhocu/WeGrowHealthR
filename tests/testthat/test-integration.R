## Integration tier: end-to-end runs of the flows on simulated data.
## These take several minutes and run only when WGH_INTEGRATION=true.

skip_integration <- function() {
  skip_on_cran()
  if (!identical(Sys.getenv("WGH_INTEGRATION"), "true")) skip("Set WGH_INTEGRATION=true to run integration tests")
}

test_that("the SITAR-based flows chain from one spurt report", {
  skip_integration()
  skip_if_not_installed("sitar")
  spurt <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
  expect_s3_class(spurt, "wgh_report")
  expect_true(all(spurt$model_status$status != "failed"))
  vel <- wgh_flow_velocity_distribution(growdat2_mini, mode = "dev", spurt = spurt)
  dur <- wgh_flow_spurt_duration(growdat2_mini, mode = "dev", spurt = spurt)
  expect_s3_class(vel, "wgh_report"); expect_s3_class(dur, "wgh_report")
  boys <- spurt$models$sitar_male
  eff <- wgh_sitar_effects(boys)
  leg <- wgh_sitar_effects(boys, legacy_c_labels = TRUE)
  expect_true(all(eff$faster_tempo != leg$faster_tempo | eff$c == 0))
})

test_that("the distribution flows run end to end and export", {
  skip_integration()
  skip_if_not_installed("quantreg")
  rep <- wgh_flow_distributional_height(growdat, mode = "dev", engine = "rq")
  expect_true(nrow(rep$tables$quantile_slopes) > 0)
  cr <- wgh_flow_conditional_references(growdat, mode = "dev", window = c(5, 9), targets = c(10, 12))
  expect_s3_class(cr, "wgh_report")
  out <- wgh_export(rep, file.path(tempdir(), "dist_flow"), formats = "pdf")
  expect_true(length(list.files(out)) > 0)
})

test_that("the simulated cohort meets every published pattern", {
  skip_integration()
  rr <- wgh_resemblance_report(wgh_simulate(30000, seed = 2026))
  expect_true(all(rr$pass[!is.na(rr$pass)]))
})

test_that("SITAR recovers known timing and the selection rule behaves as stated", {
  skip_integration()
  skip_if_not_installed("sitar")
  sim <- wgh_simulate(6000, preset = "reference", seed = 21, years = 2012:2025, missing_years = integer(),
                      dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9)
  boys <- sim$visits[sim$visits$sex == "Male", ]
  fit <- suppressMessages(wgh_fit_sitar(boys, df = 5, age_range = c(6, 18), max_children = 800))
  pk <- sim$pop_peaks[sim$pop_peaks$sex == "Male", ]
  expect_lt(abs(wgh_aphv(fit)$population$aphv - pk$aphv), 0.4)
  eff <- wgh_sitar_effects(fit)
  truth <- sim$truth_child$aphv_true[match(eff$id, sim$truth_child$pid)]
  expect_gt(cor(eff$aphv, truth, use = "complete.obs"), 0.7)
  cands <- list(F1 = list(df = 5, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18), max_children = 400),
                F2 = list(df = 4, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18), max_children = 400))
  ## a simple model that is acceptable is kept
  sel <- suppressMessages(wgh_sitar_select(boys, candidates = cands, velocity_tol = -Inf))
  expect_equal(sel$selected, "F1")
  ## when every candidate fails a criterion the first is kept and the reasons are given
  none <- suppressMessages(wgh_sitar_select(boys, candidates = cands, velocity_tol = 100))
  expect_equal(none$selected, "F1")
  expect_match(none$reason, "No candidate met all criteria")
  expect_true(all(nzchar(none$table$why_not)))
  ## a time limit gives an explicit failed fit
  slow <- wgh_fit_sitar(boys, df = 5, max_time = 0.5, max_children = 400)
  expect_null(slow$model)
  expect_true(any(grepl("max_time", slow$warnings)))
})

test_that("all flows run on simulated data and record their model status", {
  skip_integration()
  v <- wgh_simulate(8000, seed = 7, years = 2012:2025, missing_years = integer(),
                    dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9)$visits
  old <- wgh_config("dev"); on.exit(wgh_config(old))
  reps <- list(
    wgh_flow_secular_trends(v, fit_lms = FALSE), wgh_flow_malnutrition_trends(v), wgh_flow_index_trajectory(v),
    wgh_flow_distributional_height(v, engine = "rq"), wgh_flow_growth_inequality(v),
    wgh_flow_conditional_references(v, window = c(5, 9), targets = c(10, 12)), wgh_flow_canalization(v),
    wgh_flow_explain_prediction(v, window = c(5, 9), targets = c(10, 12)))
  spurt <- wgh_flow_pubertal_spurt(v)
  pheno <- wgh_flow_growth_phenotypes(v, spurt = spurt)
  reps <- c(reps, list(spurt, wgh_flow_height_prediction(v, spurt = spurt), wgh_flow_velocity_distribution(v, spurt = spurt),
                       wgh_flow_spurt_duration(v, spurt = spurt), pheno, wgh_flow_phenotype_outcomes(v, phenotypes = pheno)))
  expect_length(reps, 14)
  for (r in reps) {
    expect_s3_class(r, "wgh_report")
    expect_true(length(r$tables) > 0 && length(r$figures) > 0)
    expect_false(any(r$model_status$status == "failed"), info = r$title)
  }
})
