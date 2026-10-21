# Stacked bars of nutritional status by group

Stacked bars of nutritional status by group

## Usage

``` r
wgh_plot_status_bars(
  x,
  status = "bmi_status",
  group = "yearvisit",
  facet = "sex",
  position = c("stack", "dodge"),
  ...
)
```

## Arguments

- x:

  Classified data (see [`wgh_classify()`](wgh_classify.md)).

- status:

  `"bmi_status"` or `"height_status"`.

- group:

  Column on the x axis (for example an age band or year).

- facet:

  Facet column (default `"sex"`).

- position:

  `"stack"` (shares add to 100%) or `"dodge"` (bars side by side).

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
cl <- wgh_classify(growdat)
cl$age_group <- wgh_age_bands(cl$age)
wgh_plot_status_bars(cl, group = "age_group")

wgh_plot_status_bars(cl, status = "height_status", group = "age_group", legend = "right")
```
