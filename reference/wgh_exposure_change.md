# Change in exposure category between two index ages

Change in exposure category between two index ages

## Usage

``` r
wgh_exposure_change(
  x,
  var = "baz",
  ages = c(7, 10),
  tol = 1,
  categories = wgh_bmi_category
)
```

## Arguments

- x:

  Growth data.

- var:

  Exposure (default `"baz"`).

- ages:

  Two ages; the visit nearest each (within `tol`) is used.

- tol:

  Tolerance in years.

- categories:

  Categorisation function.

## Value

One row per child with the two categories and a change group such as
`"Normal to Overweight"` or `"Stable Obesity"`.

## Examples

``` r
ch <- wgh_exposure_change(growdat, ages = c(7, 10))
table(ch$change)
#> 
#>  Normal to Overweight    Normal to Thinness Obesity to Overweight 
#>                    16                     5                    23 
#>  Overweight to Normal Overweight to Obesity         Stable Normal 
#>                    30                     4                   220 
#>        Stable Obesity     Stable Overweight       Stable Thinness 
#>                    47                    58                     7 
#>    Thinness to Normal 
#>                     2 
```
