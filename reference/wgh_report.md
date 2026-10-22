# Report objects returned by the paper flows

Every `wgh_flow_*()` function returns a `wgh_report`: a list with
`tables` (named tibbles), `figures` (named ggplots), `models`,
`sample_flow`, `diagnostics`, `settings` and a `note`. Methods print a
summary, plot a figure by name and export everything at once.

## Usage

``` r
wgh_report(
  title,
  tables = list(),
  figures = list(),
  models = list(),
  diagnostics = list(),
  sample_flow = NULL,
  settings = list(),
  note = NULL,
  model_status = .status_table()
)
```

## Arguments

- title:

  Report title.

- tables, figures, models, diagnostics:

  Named lists.

- sample_flow:

  A
  [`wgh_sample_flow()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sample_flow.md)
  object or `NULL`.

- settings:

  List of settings used.

- note:

  Free text shown when printing (for example the simulated data label).

- model_status:

  A tibble with `step`, `status` (`"ok"`, `"failed"` or `"skipped"`) and
  `message`. Inside a flow it is filled automatically, so a failed or
  skipped optional analysis is visible rather than silently missing from
  the tables.

## Value

An object of class `wgh_report`.

## Next steps

Print the report to see what it holds, take tables with `x$tables$name`,
show figures with
[`plot.wgh_report()`](https://nhanhocu.github.io/WeGrowHealthR/reference/plot.wgh_report.md),
check `x$model_status`, and write everything to disk with
[`wgh_export()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_export.md).

## Examples

``` r
tab <- data.frame(sex = c("Male", "Female"), n = c(10, 12))
r <- wgh_report("A small report", tables = list(n = tab))
r
#> 
#> ── A small report ──
#> 
#> Tables (1): n
#> Figures (0):
#> Settings:
r$tables$n
#>      sex  n
#> 1   Male 10
#> 2 Female 12
```
