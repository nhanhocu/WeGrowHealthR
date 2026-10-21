# Flow: secular trends, prevalence and regional differences (Ho et al. 2026, Sci Rep 16:7515)

Reproduces the structure of the secular trends study (Ho et al. 2026,
Sci Rep 16:7515) on overweight, obesity and growth trends: cohort
description, median height, weight and BMI by age, sex and year with
trend tests, first-to-last year and site differences, GEE calendar
trends by age group, WHO nutritional status prevalence with simultaneous
intervals and trend tests, and (when `gamlss` is installed) LMS centile
curves for the cohort.

## Usage

``` r
wgh_flow_secular_trends(x = NULL, mode = NULL, fit_lms = TRUE)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- fit_lms:

  Fit cohort LMS curves with gamlss.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_secular_trends(mode = "dev", fit_lms = FALSE)
rep
#> 
#> ── Secular trends, prevalence and regional differences (Ho et al. 2026, Sci Rep 16:7515) ──
#> 
#> Simulated data (wgh_like preset). Tables and figures resemble the published
#> ones but are not findings.
#> Tables (12): table1_visits, median_height_by_age_year, median_trend_tests,
#> height_first_vs_last_year, height_site_differences, gee_height_slopes,
#> prevalence_5_18, prevalence_under5, overweight_obesity_by_year,
#> overweight_obesity_by_site, stunting_by_age_group, trend_tests
#> Figures (3): fig_median_height, fig_prevalence_trend, fig_status_bars
#> Models: gee_height
#> Model status: 1 ok, 0 failed, 1 skipped
#> skipped: Cohort LMS height centiles (fit_lms = FALSE)
#> Settings: mode = dev; n_children = 6443; n_visits = 16873
rep$tables$prevalence_5_18
#> # A tibble: 10 × 7
#>    sex    category            n cases prevalence  lower upper
#>    <chr>  <chr>           <int> <int>      <dbl>  <dbl> <dbl>
#>  1 Male   Severe thinness  6754    17      0.252  0      1.54
#>  2 Male   Thinness         6754   158      2.34   1.07   3.62
#>  3 Male   Normal           6754  3397     50.3   49.0   51.6 
#>  4 Male   Overweight       6754  1581     23.4   22.1   24.7 
#>  5 Male   Obesity          6754  1601     23.7   22.4   25.0 
#>  6 Female Severe thinness  6117    15      0.245  0      1.37
#>  7 Female Thinness         6117   128      2.09   0.981  3.21
#>  8 Female Normal           6117  4451     72.8   71.7   73.9 
#>  9 Female Overweight       6117  1173     19.2   18.1   20.3 
#> 10 Female Obesity          6117   350      5.72   4.61   6.84
# }
```
