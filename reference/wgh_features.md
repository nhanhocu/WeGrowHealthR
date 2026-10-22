# Growth features from serial visits

Velocity, slope and change features for each child from visits within an
age window (a lower-level helper used by
[`wgh_prediction_cohort()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_prediction_cohort.md)).

## Usage

``` r
wgh_features(x, max_age = 10, min_age = 5)
```

## Arguments

- x:

  Growth data.

- max_age:

  Latest age used.

- min_age:

  Earliest age used.

## Value

One row per child with the number of visits, short- and long-term height
velocity and HAZ and BAZ slopes.

## Examples

``` r
head(wgh_features(growdat, max_age = 10))
#> # A tibble: 6 × 7
#>   id      n_prepub_visits vel_short vel_long baz_slope haz_slope bmi_traj3    
#>   <chr>             <int>     <dbl>    <dbl>     <dbl>     <dbl> <chr>        
#> 1 C000001               4      6.08     6.06   -0.0964    0.0291 OW/OB-related
#> 2 C000004               3      4.33     5.94   -0.0472   -0.0164 Normal       
#> 3 C000007               1     NA       NA      NA        NA      NA           
#> 4 C000010               2      3.85     3.85    0.155    -0.191  Normal       
#> 5 C000014               1     NA       NA      NA        NA      NA           
#> 6 C000019               1     NA       NA      NA        NA      NA           
```
