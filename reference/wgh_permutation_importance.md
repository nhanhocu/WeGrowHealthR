# Permutation importance

Increase in a loss when one feature is randomly permuted, averaged over
repeats. A model-agnostic check on SHAP rankings (Ho 2026, manuscript
under review).

## Usage

``` r
wgh_permutation_importance(
  object,
  X,
  y,
  pred_fun = NULL,
  loss = NULL,
  repeats = 5,
  seed = 2030
)
```

## Arguments

- object:

  A fitted model.

- X:

  Data frame of features.

- y:

  Observed outcomes.

- pred_fun:

  Prediction function `function(object, newdata)`.

- loss:

  Loss function `function(y, pred)`; default squared error.

- repeats:

  Number of permutations per feature.

- seed:

  Random seed.

## Value

A tibble with the loss increase per feature.

## Examples

``` r
fit <- lm(height ~ age + baz + sex, data = growdat)
X <- growdat[, c("age", "baz", "sex")]
wgh_permutation_importance(fit, X, growdat$height, repeats = 3)
#> # A tibble: 3 × 3
#>   feature loss_increase  rank
#>   <chr>           <dbl> <dbl>
#> 1 age          1249.        1
#> 2 baz             2.53      2
#> 3 sex             0.871     3
```
