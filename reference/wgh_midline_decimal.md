# Midline decimal point for journals that require it

Some journals (for example The Lancet) print decimals with a middle dot.
Generalises `to_midline_decimal()` from Book 1 Chapter 13.

## Usage

``` r
wgh_midline_decimal(x)
```

## Arguments

- x:

  Character or numeric vector.

## Value

Character vector with "." between digits replaced by a middle dot.

## Examples

``` r
wgh_midline_decimal("Mean 12.5 (95% CI 11.2 to 13.8)")
#> [1] "Mean 12·5 (95% CI 11·2 to 13·8)"
```
