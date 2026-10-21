# Show or extract the column mapping of a wgh_data object

Show or extract the column mapping of a wgh_data object

## Usage

``` r
wgh_map(x)
```

## Arguments

- x:

  A `wgh_data` object.

## Value

A tibble with the standard role and the original column name.

## Examples

``` r
gd <- wgh_data(growdat, id = "pid", sex = "sex", age = "age", height = "height", weight = "weight")
wgh_map(gd)
#> # A tibble: 5 × 2
#>   role   column
#>   <chr>  <chr> 
#> 1 id     pid   
#> 2 age    age   
#> 3 sex    sex   
#> 4 height height
#> 5 weight weight
```
