# Exposure defined in a window that precedes the outcome

Summarises an exposure over a window of ages that ends before the
outcome period, so that the exposure respects temporal order. Returns
one row per child.

## Usage

``` r
wgh_exposure_window(
  x,
  var = "baz",
  window = c(5, 9),
  outcome_start = NULL,
  summary = c("mean", "first", "last", "max")
)
```

## Arguments

- x:

  Growth data.

- var:

  Exposure variable.

- window:

  Age window of the exposure.

- outcome_start:

  Age at which the outcome period starts; the function stops if the
  window reaches it.

- summary:

  `"mean"`, `"first"`, `"last"` or `"max"`.

## Value

A tibble with `id`, `sex`, the exposure summary and the number of visits
used.

## Examples

``` r
ex <- wgh_exposure_window(growdat, "baz", window = c(6, 9), outcome_start = 12)
head(ex)
#> # A tibble: 6 × 4
#>   id      sex    baz_mean n_visits
#>   <chr>   <fct>     <dbl>    <int>
#> 1 C000001 Female    0.908        4
#> 2 C000004 Female   -1.33         1
#> 3 C000010 Male     -1.13         1
#> 4 C000020 Male      0.726        3
#> 5 C000021 Male      1.19         2
#> 6 C000022 Male      1.68         1
```
