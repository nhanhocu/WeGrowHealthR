## Prediction: cohort, features, benchmark (Book 1 Ch 10 and 11, the late-adolescent height prediction study (Ho 2026, manuscript under review)) --

#' Build a prediction cohort: prepubertal features and a late outcome
#'
#' Reproduces the cohort construction of the late-adolescent height prediction study (Ho 2026, manuscript under review). For each child it takes
#' the earliest visit at or before a sex-specific prepubertal cutoff as the
#' baseline, derives growth features from all prepubertal visits, and links
#' the median height in a sex-specific late-adolescent outcome window. A
#' temporal check confirms that every baseline precedes the outcome window.
#' Generalises `build_growth_features()` from Book 1 Chapter 10.
#'
#' Features: baseline height, HAZ, BAZ, height-for-age and BMI categories;
#' short-term velocity (first two prepubertal visits 0.4 to 3 years apart),
#' long-term velocity (first to last prepubertal visit); BAZ and HAZ slopes
#' per year; a three-level BMI trajectory; birth year. Optional SITAR
#' timing and intensity (`b`, `c`) are joined when `sitar_effects` is
#' supplied. SITAR size (`a`) is never joined, because it is estimated from
#' the outcome-window visits.
#'
#' @param x Growth data with `haz` and `baz`.
#' @param cutoff Named vector of the latest baseline age by sex (whole years,
#'   as in the late-adolescent height prediction study (Ho 2026, manuscript under review), so 11 means up to 11.999 years).
#' @param outcome_window Named list of outcome age windows by sex.
#' @param sitar_effects Optional output of [wgh_sitar_effects()].
#' @return A tibble with one row per child, the outcome `height_late`, and
#'   an attribute `"attrition"`.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(growdat)
#' table(pc$sex)
#' attr(pc, "attrition")
#' }
#' @export
wgh_prediction_cohort <- function(x, cutoff = c(Male = 11, Female = 9),
                                 outcome_window = list(Male = c(16, 18), Female = c(14, 16)),
                                 sitar_effects = NULL) {
  d <- .gd(x, c("id", "age", "sex", "height"))
  d <- d[order(d$id, d$age), ]
  d$.cut <- unname(cutoff[as.character(d$sex)])
  pre <- d[floor(d$age) <= d$.cut & !is.na(d$height), ]
  att <- list(tibble::tibble(step = "All children", children = length(unique(d$id))))
  att[[2]] <- tibble::tibble(step = "With a prepubertal visit", children = length(unique(pre$id)))
  base <- pre[!duplicated(pre$id), ]
  feat <- tibble::tibble(id = base$id, sex = base$sex, site = if ("site" %in% names(base)) base$site else NA,
                         age_base = base$age, height_base = base$height, haz_base = base$haz,
                         baz_base = if ("baz" %in% names(base)) base$baz else NA_real_,
                         birth_year = if ("year" %in% names(base)) base$year - round(base$age) else NA_real_)
  feat$hfa_base <- factor(ifelse(feat$haz_base < -2, "Stunting", ifelse(feat$haz_base > 2, "Tall", "Normal")),
                          levels = c("Normal", "Stunting", "Tall"))
  feat$bmi_cat_base <- wgh_bmi_category(feat$baz_base, feat$age_base)
  feat$bmi_cat_base <- factor(feat$bmi_cat_base, levels = c("Normal", "Thinness", "Overweight", "Obesity"))
  per <- .child_features(pre)
  feat <- dplyr::left_join(feat, per, by = "id")
  feat$bmi_traj3 <- factor(feat$bmi_traj3, levels = c("Normal", "OW/OB-related", "Thin-related"))
  ow <- do.call(rbind, outcome_window[as.character(d$sex)])
  late <- d[d$age >= ow[, 1] & d$age <= ow[, 2], ]
  lo <- stats::aggregate(cbind(height = late$height, haz = late$haz) ~ id, data = late, FUN = stats::median)
  names(lo) <- c("id", "height_late", "haz_late")
  out <- dplyr::inner_join(feat, lo, by = "id")
  att[[3]] <- tibble::tibble(step = "With an outcome-window visit", children = nrow(out))
  out$height_gain <- out$height_late - out$height_base
  win_lo <- vapply(outcome_window[as.character(out$sex)], `[`, 1, 1)
  if (any(out$age_base >= win_lo)) .stop("Leakage: a baseline visit falls inside the outcome window.")
  if (!is.null(sitar_effects)) {
    se <- sitar_effects[, intersect(c("id", "b", "c", "aphv"), names(sitar_effects))]
    names(se) <- c("id", "sitar_b", "sitar_c", "aphv")[seq_along(se)]
    out <- dplyr::left_join(out, se, by = "id")
  }
  out$birth_year[is.na(out$birth_year)] <- stats::median(out$birth_year, na.rm = TRUE)
  att <- .bind(att)
  if ("site" %in% names(d)) {
    by_site <- tapply(out$id, out$site, length) / tapply(d$id[!duplicated(d$id)], d$site[!duplicated(d$id)], length)
    att <- dplyr::bind_rows(att, tibble::tibble(step = paste("Retained,", names(by_site)), children = NA_integer_,
                                                pct = round(100 * as.numeric(by_site), 1)))
  }
  attr(out, "attrition") <- att
  out
}

#' Growth features from serial visits
#'
#' Velocity, slope and change features for each child from visits within an
#' age window (a lower-level helper used by [wgh_prediction_cohort()]).
#' @param x Growth data.
#' @param max_age Latest age used.
#' @param min_age Earliest age used.
#' @return One row per child with the number of visits, short- and long-term
#'   height velocity and HAZ and BAZ slopes.
#' @examples
#' head(wgh_features(growdat, max_age = 10))
#' @export
wgh_features <- function(x, max_age = 10, min_age = 5) {
  d <- .gd(x, c("id", "age", "height"))
  d <- d[d$age >= min_age & d$age <= max_age & !is.na(d$height), ]
  .child_features(d[order(d$id, d$age), ])
}

.child_features <- function(pre) {
  sp <- split(pre, pre$id)
  .bind(lapply(sp, function(z) {
    z <- z[order(z$age), ]
    n <- nrow(z)
    vs <- if (n >= 2) { da <- z$age[2] - z$age[1]; if (da >= 0.4 && da <= 3) (z$height[2] - z$height[1]) / da else NA_real_ } else NA_real_
    vl <- if (n >= 2 && (z$age[n] - z$age[1]) >= 0.5) (z$height[n] - z$height[1]) / (z$age[n] - z$age[1]) else NA_real_
    bs <- if (n >= 2 && "baz" %in% names(z) && sum(!is.na(z$baz)) >= 2) unname(stats::coef(stats::lm(baz ~ age, z))[2]) else NA_real_
    hs <- if (n >= 2 && "haz" %in% names(z) && sum(!is.na(z$haz)) >= 2) unname(stats::coef(stats::lm(haz ~ age, z))[2]) else NA_real_
    tr <- NA_character_
    if (n >= 2 && "baz" %in% names(z) && !anyNA(z$baz[c(1, n)])) {
      c1 <- wgh_bmi_category(z$baz[1], z$age[1]); c2 <- wgh_bmi_category(z$baz[n], z$age[n])
      ## as in the height prediction study: the collapsed trajectory is defined by the earliest category
      tr <- if (c1 %in% c("Overweight", "Obesity")) "OW/OB-related" else if (c1 == "Thinness") "Thin-related" else "Normal"
    }
    tibble::tibble(id = z$id[1], n_prepub_visits = n, vel_short = vs, vel_long = vl, baz_slope = bs,
                   haz_slope = hs, bmi_traj3 = tr)
  }))
}

.prep_bench <- function(d, train) {
  ## medians for imputation come from the training data only
  num <- c("height_base", "haz_base", "baz_base", "vel_short", "vel_long", "baz_slope", "haz_slope",
           "age_base", "birth_year", "sitar_b", "sitar_c")
  for (v in intersect(num, names(d))) d[[v]][is.na(d[[v]])] <- stats::median(train[[v]], na.rm = TRUE)
  for (v in intersect(c("bmi_traj3", "bmi_cat_base", "hfa_base", "site"), names(d))) {
    tv <- droplevels(factor(train[[v]]))
    mode <- names(sort(table(tv), decreasing = TRUE))[1]
    z <- as.character(d[[v]]); z[is.na(z) | !z %in% levels(tv)] <- mode
    d[[v]] <- factor(z, levels = levels(tv))
  }
  d
}

## Remove terms whose factor has a single level in the training data
.drop_single <- function(f, data) {
  f <- stats::as.formula(f)
  for (v in all.vars(f)[-1]) {
    z <- data[[v]]
    if ((is.factor(z) || is.character(z)) && length(unique(stats::na.omit(z))) < 2)
      f <- stats::update(f, stats::as.formula(paste(". ~ . -", v)))
  }
  f
}

.xgb_X <- function(d) {
  ## SITAR b and c are left out: they are estimated with outcome-window visits (see M6)
  cols <- intersect(c("height_base", "haz_base", "baz_base", "vel_short", "vel_long", "baz_slope", "haz_slope",
                      "age_base", "birth_year"), names(d))
  X <- as.matrix(d[, cols])
  add <- function(nm, v) X <<- cbind(X, stats::setNames(data.frame(as.integer(v)), nm)[[1]])
  for (l in c("Thinness", "Overweight", "Obesity")) { X <- cbind(X, as.integer(d$bmi_cat_base == l)); colnames(X)[ncol(X)] <- paste0("bmi_", l) }
  for (l in c("Stunting", "Tall")) { X <- cbind(X, as.integer(d$hfa_base == l)); colnames(X)[ncol(X)] <- paste0("hfa_", l) }
  if ("site" %in% names(d)) for (l in levels(factor(d$site))[-1]) { X <- cbind(X, as.integer(d$site == l)); colnames(X)[ncol(X)] <- paste0("site_", l) }
  if ("bmi_traj3" %in% names(d)) for (l in c("OW/OB-related", "Thin-related")) { X <- cbind(X, as.integer(d$bmi_traj3 == l)); colnames(X)[ncol(X)] <- paste0("traj_", l) }
  X
}

## Model ladder M0 to M8 (Ho 2026, manuscript under review). Each entry: fit(train) and predict(fit, test).
.bench_models <- function(site_effect = c("fixed", "random")) {
  site_effect <- match.arg(site_effect)
  st <- if (site_effect == "fixed") " + site" else " + (1 | site)"
  lmer_or_lm <- function(f) {
    if (site_effect == "fixed") {
      list(fit = function(tr) stats::lm(.drop_single(paste(f, st), tr), data = tr),
           predict = function(m, te) stats::predict(m, te))
    } else {
      list(fit = function(tr) lme4::lmer(.drop_single(paste(f, st), tr), data = tr, REML = FALSE),
           predict = function(m, te) stats::predict(m, te, re.form = NA, allow.new.levels = TRUE))
    }
  }
  step_lm <- function(f) list(
    fit = function(tr) { ff <- .drop_single(f, tr); full <- do.call(stats::lm, list(formula = ff, data = tr))
      MASS::stepAIC(full, direction = "both", trace = FALSE) },
    predict = function(m, te) stats::predict(m, te))
  list(
    M0 = list(label = "OLS baseline height", fit = function(tr) stats::lm(height_late ~ height_base, data = tr),
              predict = function(m, te) stats::predict(m, te)),
    M1 = c(list(label = "OLS categorical, stepwise"),
           step_lm("height_late ~ height_base + hfa_base + bmi_cat_base + age_base + site + birth_year")),
    M2 = c(list(label = "OLS z-scores and velocity, stepwise"),
           step_lm("height_late ~ height_base + haz_base + baz_base + vel_short + vel_long + baz_slope + haz_slope + age_base + birth_year + site")),
    M3 = c(list(label = "LMEM with splines"),
           lmer_or_lm("height_late ~ splines::ns(age_base, df = 2) + height_base + hfa_base + bmi_cat_base + baz_base + birth_year")),
    M4 = list(label = "GAM", fit = function(tr) mgcv::gam(.drop_single("height_late ~ s(age_base, k = 5) + s(height_base, k = 5) +
                                                            s(haz_base, k = 5) + bmi_cat_base + birth_year + site", tr), data = tr),
              predict = function(m, te) as.numeric(stats::predict(m, te))),
    M5 = c(list(label = "LMEM velocity and BAZ slope (primary)"),
           lmer_or_lm("height_late ~ splines::ns(age_base, df = 2) + height_base + haz_base + vel_short + baz_slope + hfa_base + bmi_cat_base + bmi_traj3 + birth_year")),
    M6 = c(list(label = "LMEM with SITAR b and c", needs = c("sitar_b", "sitar_c")),
           lmer_or_lm("height_late ~ splines::ns(age_base, df = 2) + height_base + haz_base + vel_short + baz_slope + sitar_b + sitar_c + hfa_base + bmi_cat_base + birth_year")),
    M7 = list(label = "XGBoost", fit = function(tr) {
      X <- .xgb_X(tr)
      prm <- list(objective = "reg:squarederror", max_depth = 3, eta = 0.05, subsample = 0.8,
                  colsample_bytree = 0.8, min_child_weight = 5, nthread = 1)
      dm <- xgboost::xgb.DMatrix(X, label = tr$height_late)
      cv <- xgboost::xgb.cv(params = prm, data = dm, nrounds = 400, nfold = 5, early_stopping_rounds = 25, verbose = 0)
      best <- cv$early_stop$best_iteration %||% cv$best_iteration %||% 200
      list(model = xgboost::xgb.train(params = prm, data = dm, nrounds = best, verbose = 0), cols = colnames(X))
    }, predict = function(m, te) {
      X <- .xgb_X(te)
      miss <- setdiff(m$cols, colnames(X)); for (cc in miss) { X <- cbind(X, 0); colnames(X)[ncol(X)] <- cc }
      stats::predict(m$model, xgboost::xgb.DMatrix(X[, m$cols, drop = FALSE]))
    }),
    M8 = list(label = "Random forest", fit = function(tr) {
      cols <- intersect(c("height_late", "height_base", "haz_base", "baz_base", "vel_short", "vel_long", "baz_slope",
                          "haz_slope", "age_base", "birth_year", "bmi_cat_base", "hfa_base", "bmi_traj3", "site"), names(tr))
      ranger::ranger(height_late ~ ., data = as.data.frame(tr[, cols]), num.trees = 500, min.node.size = 5,
                     seed = 2025, num.threads = 1)
    }, predict = function(m, te) stats::predict(m, as.data.frame(te))$predictions)
  )
}

.perf <- function(obs, pred) {
  ok <- !is.na(obs) & !is.na(pred)
  o <- obs[ok]; p <- pred[ok]
  if (length(o) < 3) return(tibble::tibble(n = length(o), RMSE = NA_real_, MAE = NA_real_, R2 = NA_real_, calibration_slope = NA_real_))
  tibble::tibble(n = sum(ok), RMSE = sqrt(mean((o - p)^2)), MAE = mean(abs(o - p)),
                 R2 = 1 - sum((o - p)^2) / sum((o - mean(o))^2),
                 calibration_slope = unname(stats::coef(stats::lm(o ~ p))[2]))
}

#' Benchmark prediction models on identical folds
#'
#' Fits the late-adolescent height prediction study (Ho 2026, manuscript under review) model ladder (M0 baseline OLS through M8 random forest)
#' separately by sex and evaluates every model on the same child-level
#' cross-validation folds, so the comparison is fair. Missing feature values
#' are imputed with training-fold medians. Book 1 Chapter 11's `run_cv()`
#' is the teaching version of this function.
#'
#' By default site enters as a fixed effect, because a random intercept with
#' only three sites is poorly estimated. `site_effect = "random"` gives the
#' the late-adolescent height prediction study (Ho 2026, manuscript under review) specification.
#'
#' @param cohort Output of [wgh_prediction_cohort()].
#' @param models Models to run, from `"M0"` to `"M8"`.
#' @param folds Number of folds (default from the run mode), or `"site"`
#'   for leave-one-site-out geographic validation.
#' @param site_effect `"fixed"` or `"random"`.
#' @param seed Random seed.
#' @return An object of class `wgh_benchmark` with `performance` (cross-
#'   validated metrics by sex and model), `apparent` (in-sample metrics),
#'   `predictions` (out-of-fold predictions) and `fits` (full-data fits).
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M0", "M1", "M5", "M8"), folds = 3)
#' bm
#' }
#' @export
wgh_benchmark <- function(cohort, models = paste0("M", 0:8), folds = wgh_opt("folds"),
                         site_effect = c("fixed", "random"), seed = 2026) {
  site_effect <- match.arg(site_effect)
  if (any(models %in% c("M3", "M5", "M6")) && site_effect == "random") .need("lme4")
  if ("M4" %in% models) .need("mgcv")
  if ("M7" %in% models) .need("xgboost")
  if ("M8" %in% models) .need("ranger")
  if (any(models %in% c("M1", "M2"))) .need("MASS")
  spec <- .bench_models(site_effect)[models]
  k_model <- function(nm) match(nm, paste0("M", 0:8)) * 1000L
  if (!all(c("sitar_b", "sitar_c") %in% names(cohort))) spec$M6 <- NULL
  cohort$site <- factor(cohort$site)
  preds <- list(); perf <- list(); app <- list(); fits <- list(); errs <- list()
  .local_seed(seed)
  for (sx in .sexes) {
    d <- cohort[cohort$sex == sx & !is.na(cohort$height_late), ]
    if (nrow(d) < 30) next
    d <- droplevels(d)
    fid <- if (identical(folds, "site")) as.integer(factor(d$site)) else sample(rep(seq_len(folds), length.out = nrow(d)))
    nf <- max(fid)
    for (nm in names(spec)) {
      s <- spec[[nm]]
      dd <- if (!is.null(s$needs)) d[stats::complete.cases(d[, s$needs]), ] else d
      fidd <- fid[match(dd$id, d$id)]
      oof <- rep(NA_real_, nrow(dd))
      ## folds run in parallel when a parallel plan is active
      fold_res <- .wgh_map(seq_len(nf), function(k, dd, fidd, s) {
        tr <- dd[fidd != k, ]; te <- dd[fidd == k, ]
        trp <- .prep_bench(tr, tr); tep <- .prep_bench(te, tr)
        err <- NULL
        m <- tryCatch(suppressWarnings(s$fit(trp)), error = function(e) { err <<- conditionMessage(e); NULL })
        p <- if (is.null(m)) rep(NA_real_, nrow(te)) else
          tryCatch(as.numeric(s$predict(m, tep)), error = function(e) { err <<- conditionMessage(e); rep(NA_real_, nrow(te)) })
        list(p = p, err = err)
      }, dd = dd, fidd = fidd, s = s, seed = seed + k_model(nm),
      packages = .installed(c("MASS", "mgcv", "lme4", "xgboost", "ranger")))
      for (k in seq_len(nf)) {
        oof[fidd == k] <- fold_res[[k]]$p
        if (!is.null(fold_res[[k]]$err)) errs[[paste(sx, nm)]] <- fold_res[[k]]$err
      }
      full <- tryCatch(suppressWarnings(s$fit(.prep_bench(dd, dd))), error = function(e) NULL)
      fits[[paste(sx, nm)]] <- full
      inpred <- if (is.null(full)) rep(NA_real_, nrow(dd)) else tryCatch(as.numeric(s$predict(full, .prep_bench(dd, dd))), error = function(e) rep(NA_real_, nrow(dd)))
      preds[[paste(sx, nm)]] <- tibble::tibble(id = dd$id, sex = sx, model = nm, label = s$label,
                                               observed = dd$height_late, predicted = oof, fold = fidd)
      perf[[paste(sx, nm)]] <- dplyr::bind_cols(tibble::tibble(sex = sx, model = nm, label = s$label), .perf(dd$height_late, oof))
      app[[paste(sx, nm)]] <- dplyr::bind_cols(tibble::tibble(sex = sx, model = nm, label = s$label), .perf(dd$height_late, inpred))
    }
  }
  structure(list(performance = .bind(perf), apparent = .bind(app), predictions = .bind(preds), fits = fits,
                 folds = folds, site_effect = site_effect, cohort = cohort, errors = errs), class = "wgh_benchmark")
}

#' @export
print.wgh_benchmark <- function(x, ...) {
  cli::cli_text("{.cls wgh_benchmark}: {x$folds}-fold cross-validated performance (cm)")
  p <- x$performance; for (v in c("RMSE", "MAE", "R2", "calibration_slope")) p[[v]] <- round(p[[v]], 3)
  print(p, n = Inf)
  invisible(x)
}

#' Plot a prediction benchmark
#'
#' Compares the cross-validated accuracy of the candidate models, by sex.
#' @param x A `wgh_benchmark` object from [wgh_benchmark()].
#' @param metric Performance column to show: `"RMSE"` (default), `"MAE"`,
#'   `"R2"` or any other column of `x$performance`.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object. The best model per sex is highlighted.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M0", "M1", "M5"), folds = 3)
#' plot(bm)
#' plot(bm, metric = "MAE", base_size = 13)
#' }
#' @export
plot.wgh_benchmark <- function(x, metric = "RMSE", ...) {
  o <- .popts(...)
  p <- x$performance
  if (!metric %in% names(p)) .stop("Unknown metric {.val {metric}}. Available: {.val {setdiff(names(p), c('model', 'sex'))}}.")
  p$model <- factor(p$model, levels = rev(unique(p$model)))
  higher_better <- toupper(metric) %in% c("R2", "COVERAGE", "COVERAGE_90", "COR")
  best <- stats::ave(p[[metric]], p$sex, FUN = if (higher_better) max else min) == p[[metric]]
  g <- ggplot2::ggplot(p, ggplot2::aes(.data[[metric]], .data$model, fill = best)) +
    ggplot2::geom_col(width = 0.7) + ggplot2::facet_wrap(~sex) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#009E73", `FALSE` = "grey65"), guide = "none") +
    ggplot2::labs(x = paste("Cross-validated", metric, if (metric %in% c("RMSE", "MAE")) "(cm)" else ""), y = NULL,
                  title = "Prediction of late-adolescent height",
                  caption = paste0("Green: ", if (higher_better) "highest" else "lowest", " ", metric, " per sex."))
  .finish(g, o)
}

#' Individual prediction intervals for linear and mixed models
#'
#' A 95% prediction interval combines the uncertainty of the fitted mean
#' with the residual variance: \eqn{\hat y \pm t \sqrt{se(\hat y)^2 + \sigma^2}}.
#' For `lmerMod` fits the fixed-effect standard error is computed from the
#' fixed-effect covariance matrix (as `manual_pi()` in the late-adolescent height prediction study (Ho 2026, manuscript under review)).
#' @param model An `lm` or `lmerMod` fit.
#' @param newdata Data to predict.
#' @param level Interval level.
#' @return A tibble with `fit`, `lower`, `upper` and `width`.
#' @examples
#' fit <- lm(height ~ age + I(age^2) + sex, data = growdat[growdat$age >= 5, ])
#' new <- data.frame(age = c(8, 12), sex = c("Female", "Male"))
#' wgh_prediction_interval(fit, new)
#' @export
wgh_prediction_interval <- function(model, newdata, level = 0.95) {
  if (inherits(model, "lm")) {
    p <- stats::predict(model, newdata, interval = "prediction", level = level)
    return(tibble::tibble(fit = p[, 1], lower = p[, 2], upper = p[, 3], width = p[, 3] - p[, 2]))
  }
  .need("lme4")
  tt <- stats::delete.response(stats::terms(model))
  fr <- model@frame
  xlev <- Filter(Negate(is.null), lapply(fr, function(z) if (is.factor(z)) levels(z)))
  X <- stats::model.matrix(tt, stats::model.frame(tt, as.data.frame(newdata), xlev = xlev))
  fe <- lme4::fixef(model)
  X <- X[, names(fe), drop = FALSE]
  fit <- as.vector(X %*% fe)
  se <- sqrt(rowSums((X %*% as.matrix(stats::vcov(model))) * X))
  vc <- as.data.frame(lme4::VarCorr(model))
  s2 <- sum(vc$vcov)
  z <- stats::qnorm(1 - (1 - level) / 2)
  half <- z * sqrt(se^2 + s2)
  tibble::tibble(fit = fit, lower = fit - half, upper = fit + half, width = 2 * half)
}

#' Bootstrap comparison of two models' cross-validated error
#'
#' Resamples children and recomputes the difference in RMSE (and MAE)
#' between two models from their out-of-fold predictions, as in the late-adolescent height prediction study (Ho 2026, manuscript under review)
#' comparison of the primary mixed model (M5) with XGBoost (M7).
#' @param benchmark A `wgh_benchmark` object.
#' @param model_a,model_b Model codes.
#' @param B Bootstrap replicates.
#' @param seed Random seed.
#' @return A tibble by sex with the RMSE and MAE differences (a minus b) and
#'   percentile intervals.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
#' # Paired bootstrap of the RMSE difference between two models
#' wgh_compare_models(bm, "M1", "M5", B = 200)
#' }
#' @export
wgh_compare_models <- function(benchmark, model_a = "M5", model_b = "M7", B = 1000, seed = 2026) {
  pr <- benchmark$predictions
  .local_seed(seed)
  .bind(lapply(.sexes, function(sx) {
    a <- pr[pr$sex == sx & pr$model == model_a, ]; b <- pr[pr$sex == sx & pr$model == model_b, ]
    m <- merge(a[, c("id", "observed", "predicted")], b[, c("id", "predicted")], by = "id", suffixes = c("_a", "_b"))
    m <- m[stats::complete.cases(m), ]
    if (!nrow(m)) return(NULL)
    f <- function(i) c(sqrt(mean((m$observed[i] - m$predicted_a[i])^2)) - sqrt(mean((m$observed[i] - m$predicted_b[i])^2)),
                       mean(abs(m$observed[i] - m$predicted_a[i])) - mean(abs(m$observed[i] - m$predicted_b[i])))
    est <- f(seq_len(nrow(m)))
    dr <- replicate(B, f(sample.int(nrow(m), replace = TRUE)))
    tibble::tibble(sex = sx, comparison = paste(model_a, "minus", model_b), n = nrow(m),
                   rmse_diff = est[1], rmse_lower = stats::quantile(dr[1, ], 0.025), rmse_upper = stats::quantile(dr[1, ], 0.975),
                   mae_diff = est[2], mae_lower = stats::quantile(dr[2, ], 0.025), mae_upper = stats::quantile(dr[2, ], 0.975))
  }))
}

#' Calibration and Bland-Altman plots for a prediction model
#' @param benchmark A `wgh_benchmark` object.
#' @param model Model code.
#' @param groups Number of groups for the calibration plot.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object. In the calibration plot, points on the diagonal
#'   mean predictions are right on average across the range. In the
#'   Bland-Altman plot, the solid line is the mean error (bias) and the
#'   dashed lines are the 95% limits of agreement.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
#' wgh_plot_calibration(bm, "M5")
#' wgh_plot_bland_altman(bm, "M5", alpha = 0.5)
#' }
#' @export
wgh_plot_calibration <- function(benchmark, model = "M5", groups = 10, ...) {
  o <- .popts(...)
  p <- benchmark$predictions[benchmark$predictions$model == model & !is.na(benchmark$predictions$predicted), ]
  p$bin <- stats::ave(p$predicted, p$sex, FUN = function(z) as.integer(cut(rank(z), groups)))
  ag <- stats::aggregate(cbind(observed, predicted) ~ sex + bin, data = p, FUN = mean)
  g <- ggplot2::ggplot(ag, ggplot2::aes(.data$predicted, .data$observed, colour = .data$sex)) +
    ggplot2::geom_abline(linetype = 2, colour = "grey50") + ggplot2::geom_point(size = o$point_size %||% 2.5) +
    ggplot2::geom_line(linewidth = o$line_width %||% 0.5) + scale_colour_wgh_sex() +
    ggplot2::labs(x = "Mean predicted height (cm)", y = "Mean observed height (cm)", colour = NULL,
                  title = paste("Calibration,", model), caption = paste("Out-of-fold predictions in", groups, "groups."))
  .finish(g, o)
}

#' @rdname wgh_plot_calibration
#' @export
wgh_plot_bland_altman <- function(benchmark, model = "M5", ...) {
  o <- .popts(...)
  p <- benchmark$predictions[benchmark$predictions$model == model & !is.na(benchmark$predictions$predicted), ]
  p$mean <- (p$observed + p$predicted) / 2; p$diff <- p$observed - p$predicted
  lim <- .bind(lapply(split(p, p$sex), function(z) tibble::tibble(sex = z$sex[1], bias = mean(z$diff),
                                                                  lo = mean(z$diff) - 1.96 * stats::sd(z$diff), hi = mean(z$diff) + 1.96 * stats::sd(z$diff))))
  g <- ggplot2::ggplot(p, ggplot2::aes(.data$mean, .data$diff)) +
    ggplot2::geom_point(alpha = o$alpha %||% 0.3, size = o$point_size %||% 1) + ggplot2::facet_wrap(~sex) +
    ggplot2::geom_hline(data = lim, ggplot2::aes(yintercept = .data$bias), colour = "#0072B2") +
    ggplot2::geom_hline(data = lim, ggplot2::aes(yintercept = .data$lo), linetype = 2, colour = "#D55E00") +
    ggplot2::geom_hline(data = lim, ggplot2::aes(yintercept = .data$hi), linetype = 2, colour = "#D55E00") +
    ggplot2::labs(x = "Mean of observed and predicted (cm)", y = "Observed minus predicted (cm)",
                  title = paste("Bland-Altman,", model))
  .finish(g, o)
}

#' Predict late-adolescent height for one new child
#'
#' Uses the full-data fit of a benchmark model to predict height with a 95%
#' prediction interval for a child described by baseline features, the
#' basis of the late-adolescent height prediction study (Ho 2026, manuscript under review) clinical tool. Only linear models have intervals.
#' @param benchmark A `wgh_benchmark` object.
#' @param child A one-row data frame with the features of
#'   [wgh_prediction_cohort()] (missing ones are imputed with cohort medians).
#' @param model Model code.
#' @return A tibble with the prediction and interval.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
#' # A girl measured at 9 years
#' child <- pc[pc$sex == "Female", ][1, ]
#' wgh_predict_child(bm, child, "M5")
#' }
#' @export
wgh_predict_child <- function(benchmark, child, model = "M5") {
  sx <- as.character(.norm_sex(child$sex))
  fit <- benchmark$fits[[paste(sx, model)]]
  if (is.null(fit)) .stop("No fitted {model} model for {sx}.")
  co <- benchmark$cohort[benchmark$cohort$sex == sx, ]
  ch <- as.data.frame(child); ch$sex <- sx
  for (v in setdiff(names(co), names(ch))) ch[[v]] <- if (is.numeric(co[[v]])) stats::median(co[[v]], na.rm = TRUE) else co[[v]][1]
  ch <- .prep_bench(ch, co)
  for (v in c("site", "hfa_base", "bmi_cat_base", "bmi_traj3")) if (v %in% names(co)) ch[[v]] <- factor(ch[[v]], levels = levels(factor(co[[v]])))
  if (inherits(fit, c("lm", "lmerMod"))) return(dplyr::bind_cols(tibble::tibble(sex = sx, model = model), wgh_prediction_interval(fit, ch)))
  spec <- .bench_models(benchmark$site_effect)[[model]]
  tibble::tibble(sex = sx, model = model, fit = as.numeric(spec$predict(fit, ch)), lower = NA_real_, upper = NA_real_, width = NA_real_)
}

#' Show one child's height prediction on a growth chart
#'
#' Draws the child's measured heights before the prepubertal cutoff, the
#' predicted late-adolescent height with its 95% prediction interval at the
#' middle of the outcome window, and WHO height centiles for context. When
#' later measurements of the child are supplied, they are shown so the
#' prediction can be checked against what happened. This is how a
#' prediction would be shown to a clinician or a family: the interval says
#' how sure the model is, and the centiles show what the predicted height
#' means relative to other children.
#'
#' @param benchmark A `wgh_benchmark` object from [wgh_benchmark()].
#' @param child A one-row data frame with the child's features (one row of
#'   [wgh_prediction_cohort()]).
#' @param visits Optional growth data of the child (`id`, `age`, `height`).
#'   Visits after the prepubertal cutoff are drawn as the observed outcome.
#' @param model Model code (a linear model gives the interval).
#' @param outcome_window Named list of outcome windows by sex, as used for
#'   the cohort.
#' @param cutoff Named vector of prepubertal cutoffs by sex.
#' @param centiles WHO centiles shown in the background (`NULL` for none).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object, with the prediction table as attribute
#'   `"prediction"`.
#' @examples
#' \donttest{
#' sim <- wgh_simulate(8000, seed = 4)$visits
#' pc <- wgh_prediction_cohort(sim)
#' bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
#' girl <- pc[pc$sex == "Female", ][1, ]
#' wgh_plot_child_prediction(bm, girl, visits = sim[sim$pid == girl$id, ])
#' }
#' @export
wgh_plot_child_prediction <- function(benchmark, child, visits = NULL, model = "M5",
                                      outcome_window = list(Male = c(16, 18), Female = c(14, 16)),
                                      cutoff = c(Male = 11, Female = 9), centiles = c(3, 50, 97), ...) {
  o <- .popts(...)
  child <- as.data.frame(child)[1, , drop = FALSE]
  sx <- as.character(.norm_sex(child$sex))
  pr <- wgh_predict_child(benchmark, child, model)
  win <- outcome_window[[sx]]
  at <- mean(win)
  p <- ggplot2::ggplot()
  if (!is.null(centiles)) {
    ages <- seq(max(2, floor(child$age_base) - 1), win[2] + 0.5, by = 0.1)
    r <- wgh_reference("hfa", ages, sx)
    cc <- .bind(lapply(centiles, function(k) tibble::tibble(age = ages, centile = paste0("P", k),
                                                            value = wgh_lms_value(stats::qnorm(k / 100), r$L, r$M, r$S))))
    p <- p + ggplot2::geom_line(data = cc, ggplot2::aes(.data$age, .data$value, group = .data$centile),
                                colour = "grey70", linetype = 2) +
      ggplot2::geom_text(data = cc[cc$age == max(cc$age), ], ggplot2::aes(.data$age, .data$value, label = .data$centile),
                         hjust = -0.15, size = 3, colour = "grey50")
  }
  p <- p + ggplot2::annotate("rect", xmin = win[1], xmax = win[2], ymin = -Inf, ymax = Inf, fill = "#009E73", alpha = 0.06)
  if (!is.null(visits)) {
    v <- .gd(visits, c("id", "age"))
    v <- v[v$id %in% child$id & !is.na(v$height), ]
    pre <- v[floor(v$age) <= cutoff[[sx]], ]; post <- v[floor(v$age) > cutoff[[sx]], ]
    if (nrow(pre) > 1) p <- p + ggplot2::geom_line(data = pre, ggplot2::aes(.data$age, .data$height), colour = "grey20")
    if (nrow(pre)) p <- p + ggplot2::geom_point(data = pre, ggplot2::aes(.data$age, .data$height), size = o$point_size %||% 2)
    if (nrow(post)) p <- p + ggplot2::geom_point(data = post, ggplot2::aes(.data$age, .data$height), shape = 1,
                                                 colour = "#D55E00", size = o$point_size %||% 2)
  } else {
    p <- p + ggplot2::geom_point(data = child, ggplot2::aes(.data$age_base, .data$height_base), size = o$point_size %||% 2)
  }
  pd <- data.frame(age = at, fit = pr$fit, lower = pr$lower, upper = pr$upper)
  if (!is.na(pr$lower)) p <- p + ggplot2::geom_errorbar(data = pd, ggplot2::aes(x = .data$age, ymin = .data$lower, ymax = .data$upper),
                                                        width = 0.3, colour = "#0072B2", linewidth = o$line_width %||% 0.8)
  lab <- if (is.na(pr$lower)) sprintf("Predicted %.1f cm", pr$fit) else sprintf("Predicted %.1f cm\n(95%% PI %.1f to %.1f)", pr$fit, pr$lower, pr$upper)
  p <- p + ggplot2::geom_point(data = pd, ggplot2::aes(.data$age, .data$fit), colour = "#0072B2", size = 3.5, shape = 18) +
    ggplot2::annotate("text", x = at, y = if (is.na(pr$upper)) pr$fit else pr$upper, label = lab, vjust = -0.4,
                      size = 3.2, colour = "#0072B2", lineheight = 0.9) +
    ggplot2::scale_x_continuous(breaks = seq(0, 20, 2), expand = ggplot2::expansion(mult = c(0.02, 0.08))) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.05, 0.12))) +
    ggplot2::labs(x = "Age (years)", y = "Height (cm)",
                  title = paste0("Predicted late-adolescent height, ", tolower(sx), " (", model, ")"),
                  caption = paste0("Black: measured heights up to the cutoff. Blue: prediction with 95% interval.\n",
                                   if (!is.null(visits)) "Orange: later measurements. " else "",
                                   "Green band: outcome window. Dashed: WHO centiles."))
  p <- .finish(p, o)
  attr(p, "prediction") <- pr
  p
}

#' Prediction intervals for every child of a benchmark cohort
#'
#' Applies [wgh_prediction_interval()] to the full-data fit of a linear or
#' mixed model of a benchmark, for every child of the cohort, and reports
#' whether each observed height falls inside its interval. The coverage is
#' in sample, so it is slightly optimistic. Cross-validated accuracy is in
#' the benchmark's `performance` table.
#'
#' @param benchmark A `wgh_benchmark` object.
#' @param model Model code (a linear or mixed model, for example `"M5"`).
#' @param level Interval level.
#' @return A tibble with one row per child: `id`, `sex`, `observed`, `fit`,
#'   `lower`, `upper`, `width` and `covered`, with a summary by sex as
#'   attribute `"summary"`.
#' @examples
#' \donttest{
#' pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#' bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
#' iv <- wgh_benchmark_intervals(bm, "M5")
#' attr(iv, "summary")
#' }
#' @export
wgh_benchmark_intervals <- function(benchmark, model = "M5", level = 0.95) {
  out <- .bind(lapply(.sexes, function(sx) {
    f <- benchmark$fits[[paste(sx, model)]]
    if (is.null(f)) return(NULL)
    if (!inherits(f, c("lm", "lmerMod"))) .stop("Model {model} is not a linear or mixed model, so it has no prediction interval.")
    z <- benchmark$cohort[benchmark$cohort$sex == sx, ]
    pi <- wgh_prediction_interval(f, .prep_bench(z, z), level = level)
    tibble::tibble(id = z$id, sex = sx, observed = z$height_late, fit = pi$fit, lower = pi$lower, upper = pi$upper,
                   width = pi$width, covered = z$height_late >= pi$lower & z$height_late <= pi$upper)
  }))
  if (!nrow(out)) .stop("No fitted {model} model in this benchmark.")
  attr(out, "summary") <- .bind(lapply(split(out, out$sex), function(z) tibble::tibble(
    sex = z$sex[1], n = nrow(z), mean_width = mean(z$width), coverage = mean(z$covered, na.rm = TRUE))))
  out
}

#' SHAP explanation of a benchmark model
#'
#' Explains the full-data fit of one model of a benchmark for the children
#' of one sex, with the same feature preparation as in the benchmark. Tree
#' boosting models (M7) get exact TreeSHAP values. Other models get kernel
#' SHAP values on a random subset of children (`n`) against a background
#' sample (`bg`).
#'
#' @param benchmark A `wgh_benchmark` object.
#' @param model Model code.
#' @param sex `"Male"` or `"Female"`.
#' @param n,bg Numbers of children explained and in the background, for
#'   kernel SHAP (defaults from the run mode).
#' @param seed Random seed for the subsets.
#' @return A `wgh_shap` object (see [wgh_shap()]) whose rows are children of
#'   the cohort, with their ids as attribute `"id"`.
#' @examples
#' \donttest{
#' if (requireNamespace("xgboost", quietly = TRUE)) {
#'   pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
#'   bm <- wgh_benchmark(pc, models = c("M5", "M7"), folds = 3)
#'   sh <- wgh_benchmark_shap(bm, "M7", "Male")
#'   plot(sh)
#' }
#' }
#' @export
wgh_benchmark_shap <- function(benchmark, model = "M7", sex = "Male", n = wgh_opt("shap_n"),
                               bg = wgh_opt("shap_bg"), seed = 2030) {
  sx <- as.character(.norm_sex(sex))
  fit <- benchmark$fits[[paste(sx, model)]]
  if (is.null(fit)) .stop("No fitted {model} model for {sx}.")
  z <- benchmark$cohort[benchmark$cohort$sex == sx, ]
  zp <- .prep_bench(z, z)
  if (model == "M7") {
    X <- .xgb_X(zp)
    for (cc in setdiff(fit$cols, colnames(X))) { X <- cbind(X, 0); colnames(X)[ncol(X)] <- cc }
    sh <- wgh_shap(fit$model, X[, fit$cols, drop = FALSE])
    attr(sh, "id") <- z$id
    return(sh)
  }
  spec <- .bench_models(benchmark$site_effect)[[model]]
  feats <- intersect(c("age_base", "height_base", "haz_base", "baz_base", "vel_short", "vel_long", "baz_slope", "haz_slope",
                       "sitar_b", "sitar_c", "hfa_base", "bmi_cat_base", "bmi_traj3", "birth_year", "site"), names(zp))
  .local_seed(seed)
  rows <- sample.int(nrow(zp), min(n, nrow(zp))); bgr <- sample.int(nrow(zp), min(bg, nrow(zp)))
  pf <- function(m, newdata) {
    nd <- zp[rep(1, nrow(newdata)), , drop = FALSE]
    for (v in names(newdata)) nd[[v]] <- newdata[[v]]
    as.numeric(spec$predict(m, nd))
  }
  sh <- wgh_shap(fit, as.data.frame(zp[rows, feats]), bg_X = as.data.frame(zp[bgr, feats]), pred_fun = pf)
  attr(sh, "id") <- z$id[rows]
  sh
}
