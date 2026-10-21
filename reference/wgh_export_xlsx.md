# Write several tables to one workbook, one sheet per table

Write several tables to one workbook, one sheet per table

## Usage

``` r
wgh_export_xlsx(tables, file)
```

## Arguments

- tables:

  A named list of data frames.

- file:

  Output `.xlsx` path.

## Value

The file path, invisibly.

## Examples

``` r
if (requireNamespace("openxlsx", quietly = TRUE)) {
  cl <- wgh_classify(growdat)
  tabs <- list(obesity = wgh_prevalence(cl, "obesity", by = "sex"),
               stunting = wgh_prevalence(cl, "stunting", by = "sex"))
  wgh_export_xlsx(tabs, file.path(tempdir(), "tables.xlsx"))
}
```
