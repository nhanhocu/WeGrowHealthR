# Save a figure as TIFF (600 dpi, LZW) and PDF

Save a figure as TIFF (600 dpi, LZW) and PDF

## Usage

``` r
wgh_save_figure(
  plot,
  file,
  width = 8,
  height = 5,
  dpi = 600,
  formats = c("tiff", "pdf")
)
```

## Arguments

- plot:

  A ggplot object.

- file:

  File name without extension.

- width, height:

  Size in inches.

- dpi:

  Resolution of the TIFF.

- formats:

  Formats to write.

## Value

The written paths, invisibly.

## Examples

``` r
p <- wgh_plot_spaghetti(growdat, "haz", n = 50)
wgh_save_figure(p, file.path(tempdir(), "spaghetti"), formats = "pdf", dpi = 300)
```
