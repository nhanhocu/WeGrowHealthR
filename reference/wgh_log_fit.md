# Convergence and diagnostics log for many fits

Convergence and diagnostics log for many fits

## Usage

``` r
wgh_log_fit(...)
```

## Arguments

- ...:

  Named fits or tables of diagnostics (for example the `convergence`
  element of
  [`wgh_lqmm()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_lqmm.md)).

## Value

A named list of tibbles ready for
[`wgh_export_xlsx()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_export_xlsx.md).

## Examples

``` r
fit <- lm(height ~ age, data = growdat)
log <- wgh_log_fit(height_model = fit, check = data.frame(converged = TRUE, iterations = 12))
names(log)
#> [1] "height_model" "check"       
log$check
#> # A tibble: 1 × 2
#>   converged iterations
#>   <lgl>          <dbl>
#> 1 TRUE              12
```
