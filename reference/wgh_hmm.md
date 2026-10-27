# Hidden Markov model for misclassified growth bands

Height bands observed at a single visit can be wrong because of
measurement error near a cut-off. This multistate model treats the true
band as hidden and allows each observation to be misclassified into an
adjacent band, which separates real movement between bands from
measurement noise (Book 2 Chapter 13).

## Usage

``` r
wgh_hmm(data, covariates = NULL, misclass = 0.05, age_origin = NULL)
```

## Arguments

- data:

  Output of
  [`wgh_msm_data()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_msm_data.md).

- covariates:

  Covariate names.

- misclass:

  Starting probability of misclassification into each adjacent band.

- age_origin:

  Age subtracted from age to form the time scale (default: the youngest
  age, so expected prevalences start at the observed starting
  distribution).

## Value

An object of class `wgh_hmm` (also `wgh_msm`) whose `misclassification`
element holds the estimated misclassification matrix.

## Examples

``` r
# \donttest{
if (requireNamespace("msm", quietly = TRUE)) {
  # 1,000 children keep the example to well under a minute
  kids <- unique(growdat2_mini$pid)[1:1000]
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5 & growdat2_mini$pid %in% kids, ])
  hm <- wgh_hmm(wgh_msm_data(st))
  hm$misclassification
}
#>              State 1      State 2      State 3      State 4     State 5
#> State 1 0.8117527316 1.882473e-01 0.0000000000 0.000000e+00 0.000000000
#> State 2 0.0002952567 9.292736e-01 0.0704310969 0.000000e+00 0.000000000
#> State 3 0.0000000000 1.966271e-07 0.9999979570 1.846327e-06 0.000000000
#> State 4 0.0000000000 0.000000e+00 0.0004105133 9.964469e-01 0.003142537
#> State 5 0.0000000000 0.000000e+00 0.0000000000 1.855318e-03 0.998144682
# }
```
