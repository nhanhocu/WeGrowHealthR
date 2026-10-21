# Show one child's height prediction on a growth chart

Draws the child's measured heights before the prepubertal cutoff, the
predicted late-adolescent height with its 95% prediction interval at the
middle of the outcome window, and WHO height centiles for context. When
later measurements of the child are supplied, they are shown so the
prediction can be checked against what happened. This is how a
prediction would be shown to a clinician or a family: the interval says
how sure the model is, and the centiles show what the predicted height
means relative to other children.

## Usage

``` r
wgh_plot_child_prediction(
  benchmark,
  child,
  visits = NULL,
  model = "M5",
  outcome_window = list(Male = c(16, 18), Female = c(14, 16)),
  cutoff = c(Male = 11, Female = 9),
  centiles = c(3, 50, 97),
  ...
)
```

## Arguments

- benchmark:

  A `wgh_benchmark` object from [`wgh_benchmark()`](wgh_benchmark.md).

- child:

  A one-row data frame with the child's features (one row of
  [`wgh_prediction_cohort()`](wgh_prediction_cohort.md)).

- visits:

  Optional growth data of the child (`id`, `age`, `height`). Visits
  after the prepubertal cutoff are drawn as the observed outcome.

- model:

  Model code (a linear model gives the interval).

- outcome_window:

  Named list of outcome windows by sex, as used for the cohort.

- cutoff:

  Named vector of prepubertal cutoffs by sex.

- centiles:

  WHO centiles shown in the background (`NULL` for none).

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object, with the prediction table as attribute `"prediction"`.

## Examples

``` r
# \donttest{
sim <- wgh_simulate(8000, seed = 4)$visits
pc <- wgh_prediction_cohort(sim)
bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
girl <- pc[pc$sex == "Female", ][1, ]
wgh_plot_child_prediction(bm, girl, visits = sim[sim$pid == girl$id, ])

# }
```
