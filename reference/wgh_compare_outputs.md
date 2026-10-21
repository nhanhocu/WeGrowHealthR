# Compare a report's tables with frozen golden outputs

Matches tables by name and reports, for each numeric column, the largest
absolute difference. Used to show that a flow reproduces the outputs of
the original paper script (private equivalence track).

## Usage

``` r
wgh_compare_outputs(report, golden, tolerance = 1e-06)
```

## Arguments

- report:

  A `wgh_report` or a named list of tables.

- golden:

  A named list of reference tables (for example read from the frozen
  workbook of the original script).

- tolerance:

  Differences above this value are flagged.

## Value

A tibble with one row per table and column.

## Examples

``` r
rep <- list(prev = data.frame(group = c("a", "b"), value = c(10.2, 11.5)))
golden <- list(prev = data.frame(group = c("a", "b"), value = c(10.2, 11.6)))
wgh_compare_outputs(rep, golden, tolerance = 0.05)
#> # A tibble: 1 × 5
#>   table column max_abs_diff match note 
#>   <chr> <chr>         <dbl> <lgl> <chr>
#> 1 prev  value        0.1000 FALSE ""   
```
