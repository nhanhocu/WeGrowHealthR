# Transition matrices and canalization summaries

Transition matrices and canalization summaries

## Usage

``` r
wgh_transition_matrix(transitions, by = NULL)

wgh_canalization_summary(
  transitions,
  by = "sex",
  age_blocks = c(0, 5, 9, 13, 19)
)
```

## Arguments

- transitions:

  Output of
  [`wgh_transitions()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_transitions.md).

- by:

  Grouping columns (for example `c("sex")`).

- age_blocks:

  Breaks of age blocks for the summary.

## Value

`wgh_transition_matrix()`: row-percent matrices in long form.
`wgh_canalization_summary()`: persistence, catch-up and catch-down by
group and age block.

## Examples

``` r
tr <- wgh_transitions(wgh_states(growdat))
wgh_canalization_summary(tr, by = "sex")
#> # A tibble: 8 × 7
#>   sex    age_block transitions persistence catch_up catch_down toward_median
#>   <chr>  <chr>           <int>       <dbl>    <dbl>      <dbl>         <dbl>
#> 1 Male   [0,5)             707        82.5    28.3       22.5          25.1 
#> 2 Female [0,5)             598        77.6    54.1       18            36.6 
#> 3 Male   [5,9)             985        86.7    19.0       22.9          21.3 
#> 4 Female [5,9)             830        71.4    78.7        5.36         15.9 
#> 5 Male   [9,13)            667        70.8    46.0       10.3          21.4 
#> 6 Female [9,13)            559        76.7     0         30.2          30   
#> 7 Male   [13,19)           397        72.0     6.25      63.6          50.4 
#> 8 Female [13,19)           384        88.0     4.35      16.2           7.75
```
