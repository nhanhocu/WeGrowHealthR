# Conditional centile of an observed later measurement

Locates each observed target value within its predicted conditional
distribution. A conditional centile near 50 means the child grew as
expected given the baseline. Values below the 3rd or above the 97th
centile flag growth that departs from the child's own expected course,
even when the child is still inside the WHO -2 to +2 SD band.

## Usage

``` r
wgh_condref_centile(object, newdata, type = "conditional", flag = 3)
```

## Arguments

- object:

  A `wgh_condref` object.

- newdata:

  Rows with `sex`, `target_nominal`, the baseline features and the
  observed `target`.

- type:

  Reference used (see
  [`predict.wgh_condref()`](https://nhanhocu.github.io/WeGrowHealthR/reference/predict.wgh_condref.md)).

- flag:

  Lower centile for flagging (the upper is `100 - flag`).

## Value

`newdata` with `cond_centile` (0 to 100), `cond_z` (the normal score of
the centile) and `cond_flag` (`"below"`, `"within"`, `"above"`).

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(10, 12, 14))
cr <- wgh_condref(cp)
sc <- wgh_condref_centile(cr, cp)
table(sc$cond_flag)
#> 
#>  above  below within 
#>     13     18    565 
# Children within the WHO band but outside their own expected range
flagged <- abs(sc$target) < 2 & sc$cond_flag != "within"
sc[flagged, c("id", "target_nominal", "target", "cond_centile")]
#> # A tibble: 78 × 4
#>    id      target_nominal target cond_centile
#>    <chr>            <dbl>  <dbl>        <dbl>
#>  1 C000408             10  1.67     99.4     
#>  2 C000462             10  0.902   100.0     
#>  3 C000742             10  0.979    97.7     
#>  4 C001297             10  1.04     97.6     
#>  5 C001339             10 -1.00      2.81    
#>  6 C001412             10  0.239     2.43    
#>  7 C001421             10  0.71      2.98    
#>  8 C001760             10 -0.201     0.000108
#>  9 C002357             10 -0.301     3.00    
#> 10 C002410             10 -0.524     3.00    
#> # ℹ 68 more rows
# }
```
