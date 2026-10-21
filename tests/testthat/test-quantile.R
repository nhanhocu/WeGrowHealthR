test_that("wgh_rq point estimates equal direct quantreg fits", {
  skip_if_not_installed("quantreg")
  d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
  d <- d[complete.cases(d[, c("haz", "baz", "age")]), ]
  f <- haz ~ age + baz
  fit <- wgh_rq(d, f, taus = c(0.25, 0.75), exposure = "baz", anchor_ages = 10, B = 0)
  direct <- coef(quantreg::rq(f, tau = c(0.25, 0.75), data = d, method = "fn"))
  expect_equal(unname(fit$coefs), unname(direct), tolerance = 1e-6)
  expect_equal(fit$slopes$estimate, unname(direct["baz", ]), tolerance = 1e-6)
})

test_that("slopes are read by contrast, not from the main effect", {
  skip_if_not_installed("quantreg")
  d <- growdat[growdat$age >= 5, ]
  d <- d[complete.cases(d[, c("haz", "baz", "age")]), ]
  fit <- wgh_rq(d, haz ~ splines::ns(age, df = 3) * baz, taus = 0.5, anchor_ages = c(6, 15), B = 0)
  expect_false(isTRUE(all.equal(fit$slopes$estimate[1], fit$slopes$estimate[2])))
})

test_that("rearrangement removes crossing", {
  P <- rbind(c(1, 3, 2), c(0, 1, 2))
  expect_equal(wgh_crossing(P), 0.5)
  expect_equal(wgh_crossing(wgh_rearrange(P)), 0)
})

test_that("scores behave as proper scores", {
  set.seed(1); y <- rnorm(2000)
  taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
  good <- wgh_score(y, matrix(qnorm(taus), 2000, 7, byrow = TRUE), taus)
  bad <- wgh_score(y, matrix(qnorm(taus, 1), 2000, 7, byrow = TRUE), taus)
  expect_lt(good$crps, bad$crps); expect_lt(good$wis, bad$wis)
  expect_equal(good$coverage_90, 0.9, tolerance = 0.03)
})

test_that("leakage check flags overlapping windows", {
  expect_false(wgh_leakage_check(c(5, 18), c(12, 15))$ok)
  expect_true(wgh_leakage_check(c(5, 9), c(12, 15))$ok)
})

test_that("conformal intervals reach nominal coverage", {
  set.seed(3); y <- rnorm(4000)
  ci <- wgh_conformal(y[1:2000], rep(-0.5, 2000), rep(0.5, 2000), rep(-0.5, 2000), rep(0.5, 2000), level = 0.9)
  expect_equal(mean(y[2001:4000] >= ci$lower & y[2001:4000] <= ci$upper), 0.9, tolerance = 0.03)
})
