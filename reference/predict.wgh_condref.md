# Predict conditional quantiles for new children

Predict conditional quantiles for new children

## Usage

``` r
# S3 method for class 'wgh_condref'
predict(
  object,
  newdata,
  type = c("conditional", "unconditional", "persistence", "who", "forest"),
  ...
)
```

## Arguments

- object:

  A `wgh_condref` object.

- newdata:

  Rows with `sex`, `target_nominal` and the baseline features.

- type:

  `"conditional"` (default), `"unconditional"`, `"persistence"`, `"who"`
  or `"forest"` (when the references were fitted with `forest = TRUE`).

- ...:

  Unused.

## Value

A matrix with one row per case and one column per quantile (rearranged
to be monotone).

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
cr <- wgh_condref(cp)
# Predicted centiles at age 10 for the first three children
round(predict(cr, cp[cp$target_nominal == 10, ][1:3, ]), 2)
#>      q0.030 q0.050 q0.100 q0.250 q0.500 q0.750 q0.900 q0.950 q0.970
#> [1,]   1.67   1.70   1.73   1.98   2.07   2.19   2.51   2.55   2.57
#> [2,]   0.07   0.07   0.34   0.71   1.11   1.38   1.60   1.65   1.81
#> [3,]   0.58   0.62   0.67   0.86   0.98   1.12   1.36   1.47   1.52
# The same children under the WHO and unconditional references
round(predict(cr, cp[cp$target_nominal == 10, ][1:3, ], type = "who"), 2)
#>      q0.030 q0.050 q0.100 q0.250 q0.500 q0.750 q0.900 q0.950 q0.970
#> [1,]  -1.88  -1.64  -1.28  -0.67      0   0.67   1.28   1.64   1.88
#> [2,]  -1.88  -1.64  -1.28  -0.67      0   0.67   1.28   1.64   1.88
#> [3,]  -1.88  -1.64  -1.28  -0.67      0   0.67   1.28   1.64   1.88
# }
```
