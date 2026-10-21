test_that("the simulator is reproducible and resembles published patterns", {
  s1 <- wgh_simulate(3000, seed = 11); s2 <- wgh_simulate(3000, seed = 11)
  expect_identical(s1$visits, s2$visits)
  r <- wgh_resemblance_report(wgh_simulate(15000, seed = 3))
  key <- r[r$target %in% c("Population APHV (y)", "SD of timing (b)", "Overweight or obesity, 5 to 18 y (%)"), ]
  expect_true(all(key$pass))
})

test_that("every simulated child has positive true velocity", {
  s <- wgh_simulate(2000, seed = 5)
  expect_true(all(s$truth_visit$velocity_true > 0))
})

test_that("messiness is logged and largely repaired by wgh_clean", {
  raw <- wgh_add_messiness(growdat[1:2000, ], rate = 0.05, seed = 2)
  lg <- attr(raw, "messiness_log")
  expect_gt(nrow(lg), 50)
  cl <- wgh_clean(raw)
  expect_true(all(cl$height > 40 | cl$implausible, na.rm = TRUE))
  expect_true(all(levels(cl$sex) %in% c("Male", "Female")))
})

test_that("truth check reports bias", {
  tc <- growdat2_mini_truth
  est <- data.frame(pid = tc$pid, est = tc$aphv_true + 0.5)
  r <- wgh_truth_check(est, tc, "est", "aphv_true")
  expect_equal(r$bias, 0.5, tolerance = 1e-8)
})

test_that("simulated growth never has a negative velocity", {
  sim <- wgh_simulate(3000, seed = 5)
  expect_true(all(sim$truth_visit$velocity_true >= 0))
  inc <- function(v) {
    v <- v[order(v$pid, v$age), ]
    dv <- stats::ave(v$height, v$pid, FUN = function(z) c(0, diff(z)))
    all(dv >= 0)
  }
  expect_true(inc(sim$visits))
  expect_true(inc(growdat))
  expect_true(inc(growdat2_mini))
  expect_true(inc(clinical_cases))
  # raw measurement error can be requested
  raw <- wgh_simulate(3000, seed = 5, monotone = FALSE)
  expect_false(inc(raw$visits))
  # the monotone projection does not shift heights on average
  expect_lt(abs(mean(raw$visits$height) - mean(sim$visits$height)), 0.1)
})

test_that("true height curves are non-decreasing for every preset", {
  for (p in c("wgh_like", "reference")) {
    sim <- suppressWarnings(wgh_simulate(1500, preset = p, seed = 3))
    tv <- sim$truth_visit[order(sim$truth_visit$pid, sim$truth_visit$age), ]
    d <- stats::ave(tv$height_true, tv$pid, FUN = function(z) c(0, diff(z)))
    expect_true(all(d >= -1e-9), info = p)
    expect_true(all(tv$velocity_true >= 0), info = p)
  }
})

test_that("a decreasing true curve is repaired consistently", {
  pid <- rep(1:2, each = 5)
  h <- c(100, 105, 104, 103, 110, 120, 125, 130, 135, 140)
  v <- c(5, 2, -1, -1, 6, 5, 5, 5, 5, 5)
  expect_warning(out <- WeGrowHealthR:::.monotone_truth(h, v, pid), "decreasing true height curve for 1 child")
  expect_equal(out$height, c(100, 105, 105, 105, 110, 120, 125, 130, 135, 140))
  expect_equal(out$velocity, c(5, 2, 0, 0, 6, 5, 5, 5, 5, 5))
  expect_silent(WeGrowHealthR:::.monotone_truth(h[6:10], v[6:10], pid[6:10]))
})

test_that("monotone and raw measurement modes keep the error structure and derived measures", {
  mono <- wgh_simulate(6000, seed = 21)
  raw <- wgh_simulate(6000, seed = 21, monotone = FALSE)
  res <- function(sim) {
    v <- as.data.frame(sim$truth_visit)
    v$e <- v$height - v$height_true
    v$band <- cut(v$age, c(0, 9, 12, 15, 30))
    v
  }
  m <- res(mono); r <- res(raw)
  sd_set <- wgh_preset("wgh_like")$measurement_sd_height
  # raw errors have the preset SD (plus rounding) and mean 0
  expect_lt(abs(sd(r$e) - sqrt(sd_set^2 + 1 / 1200)), 0.05)
  expect_lt(abs(mean(r$e)), 0.02)
  # monotone errors stay centred, slightly smaller, in every age band
  expect_lt(abs(mean(m$e)), 0.03)
  for (b in levels(m$band)) {
    sm <- sd(m$e[m$band == b]); sr <- sd(r$e[r$band == b])
    expect_lte(sm, sr + 0.01, label = b); expect_gt(sm, 0.6 * sr, label = b)
  }
  # BMI distribution is practically unchanged
  expect_lt(abs(mean(m$bmi) - mean(r$bmi)), 0.02)
  expect_lt(max(abs(stats::quantile(m$bmi, c(0.05, 0.5, 0.95)) - stats::quantile(r$bmi, c(0.05, 0.5, 0.95)))), 0.15)
  # observed annualised velocity: never negative when monotone, occasionally negative when raw
  vel <- function(v) {
    v <- v[order(v$pid, v$age), ]
    dh <- stats::ave(v$height, v$pid, FUN = function(z) c(NA, diff(z)))
    da <- stats::ave(v$age, v$pid, FUN = function(z) c(NA, diff(z)))
    (dh / da)[!is.na(dh) & da > 0.5]
  }
  vm <- vel(m); vr <- vel(r)
  expect_true(all(vm >= 0))
  expect_gt(mean(vr < 0), 0); expect_lt(mean(vr < 0), 0.10)
  expect_lt(abs(stats::median(vm) - stats::median(vr)), 0.1)
  # height-for-age band transitions between consecutive visits are similar
  moves <- function(sim) {
    v <- sim$visits[order(sim$visits$pid, sim$visits$age), ]
    b <- cut(v$haz, c(-Inf, -2, -1, 1, 2, Inf))
    prev <- stats::ave(as.integer(b), v$pid, FUN = function(z) c(NA, z[-length(z)]))
    mean(prev != as.integer(b), na.rm = TRUE)
  }
  expect_lt(abs(moves(mono) - moves(raw)), 0.02)
})
