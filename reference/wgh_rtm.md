# Conditional change scores

Separates true catch-up from regression to the mean: the conditional
z-score is \\(z_2 - r z_1) / \sqrt{1 - r^2}\\, where `r` is the
correlation between the two measurements in the group.

## Usage

``` r
wgh_rtm(transitions, x = NULL, var = "haz", by = "sex")
```

## Arguments

- transitions:

  Output of
  [`wgh_transitions()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_transitions.md)
  (needs `haz` at both visits) or a data frame with `z1` and `z2`.

- x:

  Growth data used to look up the second z-score.

- var:

  Z-score variable.

- by:

  Groups within which `r` is estimated.

## Value

The input with columns `z1`, `z2`, `r` and `conditional_z`.

## Examples

``` r
st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
tr <- wgh_transitions(st)
rt <- wgh_rtm(tr, growdat2_mini)
# Raw change against change conditional on the starting z-score
summary(rt$z2 - rt$z1)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.48500 -0.14500  0.01300  0.01639  0.18200  1.67900 
summary(rt$conditional_z)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -3.85695 -0.37984  0.05910  0.08726  0.54734  4.16376 
```
