test_that("descriptive flows return complete reports", {
  skip_on_cran()
  r <- wgh_flow_malnutrition_trends(growdat, mode = "dev")
  expect_s3_class(r, "wgh_report")
  expect_true(all(c("prevalence_by_year", "trend_tests", "double_burden") %in% names(r$tables)))
  expect_s3_class(r$figures$fig_trends, "ggplot")
})

test_that("pipeline template is written", {
  f <- wgh_use_pipeline(tempdir(), overwrite = TRUE)
  expect_true(file.exists(f))
  expect_true(any(grepl("paper04a", readLines(f))))
})
