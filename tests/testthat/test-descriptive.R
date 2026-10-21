test_that("WHO classification uses the age-5 cut-offs", {
  d <- data.frame(id = 1:2, age = c(4, 6), sex = "Male", haz = 0, baz = c(1.5, 1.5))
  cl <- wgh_classify(d)
  expect_equal(as.character(cl$bmi_status), c("Normal", "Overweight"))
})

test_that("Sison-Glaz intervals contain the estimates and narrow with n", {
  a <- wgh_multinom_ci(c(a = 31, b = 26, c = 22, d = 18, e = 3))
  b <- wgh_multinom_ci(c(a = 310, b = 260, c = 220, d = 180, e = 30))
  expect_true(all(a$lower <= a$estimate & a$upper >= a$estimate))
  expect_true(mean(b$upper - b$lower) < mean(a$upper - a$lower))
})

test_that("prevalence agrees with a direct calculation", {
  cl <- wgh_classify(growdat)
  p <- wgh_prevalence(cl, "obesity", by = "sex")
  direct <- 100 * tapply(cl$obesity, cl$sex, mean, na.rm = TRUE)
  expect_equal(p$prevalence, as.numeric(direct[p$sex]))
})

test_that("Cochran-Armitage test equals prop.trend.test", {
  cl <- wgh_classify(growdat)
  r <- wgh_trend_test(cl, "obesity", "yearvisit")
  k <- tapply(cl$obesity, cl$yearvisit, sum, na.rm = TRUE); n <- tapply(!is.na(cl$obesity), cl$yearvisit, sum)
  expect_equal(r$p_value, suppressWarnings(prop.trend.test(k, n, score = as.numeric(names(k)))$p.value), tolerance = 1e-6)
})
