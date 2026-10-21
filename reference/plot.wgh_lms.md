# Plot cohort centile curves

Draws the centile curves of a fitted cohort LMS-type reference, by
group, optionally against the WHO curves for the same centiles.

## Usage

``` r
# S3 method for class 'wgh_lms'
plot(x, ages = NULL, compare_who = FALSE, ...)
```

## Arguments

- x:

  A `wgh_lms` object from [`wgh_fit_lms()`](wgh_fit_lms.md).

- ages:

  Ages at which the curves are evaluated.

- compare_who:

  Add the WHO curves (grey) for comparison.

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
# \donttest{
lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
plot(lms)

plot(lms, compare_who = TRUE, title = "Cohort against WHO height centiles")

# }
```
