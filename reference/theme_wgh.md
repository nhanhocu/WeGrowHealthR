# House ggplot2 theme and palettes

`theme_wgh()` is the publication theme used across the program (it
replaces `theme_paper()` in the paper scripts and `theme_growth()` in
Book 1 Chapter 5). The scales apply colour-blind safe palettes: sex, BMI
category, nutritional status and the Okabe-Ito set.

## Usage

``` r
theme_wgh(base_size = 11, legend = "bottom")

scale_colour_wgh_sex(...)

scale_fill_wgh_sex(...)

scale_colour_wgh_bmi(...)

scale_fill_wgh_bmi(...)

scale_colour_wgh(...)

scale_fill_wgh(...)
```

## Arguments

- base_size:

  Base font size.

- legend:

  Legend position.

- ...:

  Passed to the underlying ggplot2 scale.

## Value

A ggplot2 theme or scale.

## Examples

``` r
library(ggplot2)
ggplot(growdat, aes(age, height, colour = sex)) +
  geom_point(size = 0.3, alpha = 0.3) + scale_colour_wgh_sex() + theme_wgh()
```
