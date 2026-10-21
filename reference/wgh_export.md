# Export a report: workbook of tables, figures and a bundle

Export a report: workbook of tables, figures and a bundle

## Usage

``` r
wgh_export(x, dir, figures = TRUE, formats = c("tiff", "pdf"))
```

## Arguments

- x:

  A `wgh_report`.

- dir:

  Output directory (created if needed).

- figures:

  Also save the figures.

- formats:

  Figure formats.

## Value

The output directory, invisibly.

## Examples

``` r
# \donttest{
rep <- wgh_flow_malnutrition_trends(growdat, mode = "dev")
out <- wgh_export(rep, file.path(tempdir(), "malnutrition"), formats = "pdf")
#> Report written to /tmp/RtmpCADCMM/malnutrition
list.files(out)
#> [1] "fig_dbm_heatmap.pdf" "fig_or_forest.pdf"   "fig_status_bars.pdf"
#> [4] "fig_trends.pdf"      "report_bundle.rds"   "tables.xlsx"        
# }
```
