#' Create a validated growth data object
#'
#' `wgh_data()` is the entry point of the package's data contract. It maps
#' the columns of a user's data frame to standard roles (`id`, `age`, `sex`,
#' `height`, `weight`, `site`, `year`), checks types and units, orders the
#' visits within each child and records the mapping so outputs can be
#' relabelled in the user's own terms. Columns not named in the mapping are
#' kept unchanged.
#'
#' Age can be given directly (`age`) or computed from the date of birth
#' (`dob`) and the date of measurement (`date`). With `age_from = "auto"`
#' (default) a supplied age column is used and missing ages are filled in
#' from the dates. With `age_from = "dates"` age is always computed from the
#' dates, which is the most accurate choice when both dates are recorded.
#' Exact age in years is `(date - dob) / 365.25`.
#'
#' Arguments are given as bare column names (tidy evaluation). `id`, `sex`
#' and either `age` or both `dob` and `date` are required.
#'
#' @param data A data frame with one row per child visit.
#' @param id,sex Child identifier and sex (any common coding such as
#'   `"Male"`/`"Female"`, `"M"`/`"F"` or `1`/`2`).
#' @param age Age at measurement (optional when `dob` and `date` are given).
#' @param dob,date Date of birth and date of measurement. Dates, or character
#'   strings in a format readable by [as.Date()] (see `date_format`).
#' @param height,weight Height in cm and weight in kg (optional).
#' @param site,year Recruitment site and calendar (or school) year (optional).
#'   When `year` is not given but `date` is, the calendar year of the
#'   measurement is used.
#' @param bmi Optional existing BMI column. When absent and both height and
#'   weight are present, BMI is computed.
#' @param age_unit Unit of `age`: `"years"` (default), `"months"` or `"days"`.
#' @param age_from `"auto"`, `"age"` (use the age column only) or
#'   `"dates"` (always compute age from `dob` and `date`).
#' @param date_format Format passed to [as.Date()] when dates are stored as
#'   text, for example `"%d/%m/%Y"`. The default reads ISO dates
#'   (`"2024-09-15"`).
#' @param check If `TRUE` (default), run plausibility checks and report them.
#' @return An object of class `wgh_data`: a list with the standardised data
#'   (`$data`), the column mapping (`$map`) and a log of checks (`$log`).
#'   The data always contain `id`, `age` (years) and `sex`, plus any mapped
#'   roles, `bmi` when height and weight are present, and the original
#'   columns that were not mapped.
#' @section Next steps:
#' Pass the object to [wgh_clean()] for cleaning, [wgh_add_zscores()] for
#' WHO or CDC z-scores, [wgh_classify()] for nutritional status and
#' [wgh_sample_flow()] to record the analytic sample. Every function in the
#' package accepts a `wgh_data` object or a plain data frame.
#' @seealso [wgh_clean()], [wgh_add_zscores()], [wgh_sample_flow()]
#' @examples
#' # Age already recorded
#' gd <- wgh_data(growdat, id = pid, age = age, sex = sex, height = height,
#'                weight = weight, site = site, year = yearvisit)
#' gd
#' summary(gd)
#'
#' # Age computed from date of birth and date of measurement
#' gd2 <- wgh_data(growdat, id = pid, sex = sex, dob = dob, date = examdate,
#'                 height = height, weight = weight, site = site)
#' head(gd2$data[, c("id", "dob", "date", "age", "year")])
#'
#' # Dates stored as day/month/year text
#' df <- data.frame(child = c("a", "a"), gender = c("F", "F"),
#'                  birth = c("01/03/2015", "01/03/2015"),
#'                  visit = c("15/09/2022", "20/09/2023"), ht = c(124.0, 130.2))
#' wgh_data(df, id = child, sex = gender, dob = birth, date = visit, height = ht,
#'          date_format = "%d/%m/%Y")$data
#' @export
wgh_data <- function(data, id, sex, age = NULL, dob = NULL, date = NULL, height = NULL, weight = NULL,
                     site = NULL, year = NULL, bmi = NULL, age_unit = c("years", "months", "days"),
                     age_from = c("auto", "age", "dates"), date_format = NULL, check = TRUE) {
  age_unit <- match.arg(age_unit); age_from <- match.arg(age_from)
  if (inherits(data, "wgh_data")) return(data)
  if (!is.data.frame(data)) .stop("{.arg data} must be a data frame.")
  q <- list(id = rlang::enquo(id), age = rlang::enquo(age), sex = rlang::enquo(sex),
            dob = rlang::enquo(dob), date = rlang::enquo(date),
            height = rlang::enquo(height), weight = rlang::enquo(weight),
            site = rlang::enquo(site), year = rlang::enquo(year), bmi = rlang::enquo(bmi))
  map <- vapply(q, function(x) if (rlang::quo_is_null(x)) NA_character_ else rlang::as_name(x), character(1))
  if (anyNA(map[c("id", "sex")])) .stop("{.arg id} and {.arg sex} are required.")
  has_dates <- !anyNA(map[c("dob", "date")])
  if (is.na(map["age"]) && !has_dates) .stop("Give {.arg age}, or both {.arg dob} and {.arg date} to compute age.")
  if (age_from == "dates" && !has_dates) .stop("{.code age_from = \"dates\"} needs both {.arg dob} and {.arg date}.")
  if (age_from == "age" && is.na(map["age"])) .stop("{.code age_from = \"age\"} needs an {.arg age} column.")
  used <- map[!is.na(map)]
  miss <- setdiff(used, names(data))
  if (length(miss)) .stop(paste0("Column(s) not found in data: {.val ", paste(miss, collapse = ", "), "}."))

  d <- as.data.frame(data, stringsAsFactors = FALSE)
  out <- d
  ## copy mapped columns to their standard names, drop the originals
  for (role in names(used)) out[[role]] <- d[[used[[role]]]]
  drop <- setdiff(unname(used), names(used))
  out <- out[, setdiff(names(out), drop), drop = FALSE]

  out$id <- as.character(out$id)
  if (has_dates) {
    out$dob <- .as_date(out$dob, date_format, "dob")
    out$date <- .as_date(out$date, date_format, "date")
  }
  age_given <- if (!is.na(map["age"])) as.numeric(out$age) / switch(age_unit, years = 1, months = 12, days = 365.25) else NULL
  age_dates <- if (has_dates) as.numeric(out$date - out$dob) / 365.25 else NULL
  out$age <- switch(age_from,
    age = age_given,
    dates = age_dates,
    auto = if (is.null(age_given)) age_dates else if (is.null(age_dates)) age_given else
      ifelse(is.na(age_given), age_dates, age_given))
  if (!is.null(age_given) && !is.null(age_dates)) {
    disagree <- sum(abs(age_given - age_dates) > 0.1, na.rm = TRUE)
    if (disagree) .warn("{disagree} row{?s} where the recorded age and the age from the dates differ by more than 0.1 years.")
  }
  if (has_dates && is.na(map["year"])) out$year <- as.integer(format(out$date, "%Y"))
  sx <- .norm_sex(out$sex)
  if (anyNA(sx[!is.na(out$sex)])) .stop("Some {.field sex} values could not be read as Male or Female.")
  out$sex <- factor(sx, levels = .sexes)
  if (!is.na(map["site"])) out$site <- factor(out$site)
  if (!is.na(map["year"])) out$year <- as.integer(as.character(out$year))
  if (!is.na(map["height"])) out$height <- as.numeric(out$height)
  if (!is.na(map["weight"])) out$weight <- as.numeric(out$weight)
  if (is.na(map["bmi"]) && all(c("height", "weight") %in% names(out))) {
    out$bmi <- out$weight / (out$height / 100)^2
  }
  first <- intersect(c("id", "sex", "age", "dob", "date", "year", "site", "height", "weight", "bmi"), names(out))
  out <- out[order(out$id, out$age), c(first, setdiff(names(out), first)), drop = FALSE]
  rownames(out) <- NULL
  log <- if (check) .wgh_checks(out) else tibble::tibble()
  structure(list(data = tibble::as_tibble(out), map = used, log = log),
            class = "wgh_data")
}

.as_date <- function(x, fmt, what) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  y <- if (is.null(fmt)) suppressWarnings(as.Date(as.character(x), optional = TRUE)) else as.Date(as.character(x), format = fmt)
  bad <- sum(is.na(y) & !is.na(x))
  if (bad) .warn("{bad} value{?s} of {.field {what}} could not be read as a date. Use {.arg date_format}.")
  y
}

.wgh_checks <- function(d) {
  chk <- list(
    c("Missing age", sum(is.na(d$age))),
    c("Negative or zero age", sum(d$age <= 0, na.rm = TRUE)),
    c("Age above 20 years", sum(d$age > 20, na.rm = TRUE)),
    c("Missing sex", sum(is.na(d$sex)))
  )
  if ("height" %in% names(d)) {
    chk <- c(chk, list(c("Height outside 40 to 210 cm", sum(d$height < 40 | d$height > 210, na.rm = TRUE)),
                       c("Height looks like metres (< 3)", sum(d$height < 3, na.rm = TRUE))))
  }
  if ("weight" %in% names(d)) {
    chk <- c(chk, list(c("Weight outside 2 to 200 kg", sum(d$weight < 2 | d$weight > 200, na.rm = TRUE))))
  }
  dup <- sum(duplicated(d[, c("id", "age")]))
  chk <- c(chk, list(c("Duplicate child-age rows", dup)))
  sx_conf <- tapply(as.character(d$sex), d$id, function(s) length(unique(stats::na.omit(s))) > 1)
  chk <- c(chk, list(c("Children with conflicting sex", sum(sx_conf, na.rm = TRUE))))
  tibble::tibble(check = vapply(chk, `[`, "", 1), n = as.integer(vapply(chk, `[`, "", 2)))
}

#' @export
print.wgh_data <- function(x, ...) {
  d <- x$data
  cli::cli_text("{.cls wgh_data}: {nrow(d)} visits from {length(unique(d$id))} children")
  rng <- range(d$age, na.rm = TRUE)
  cli::cli_text("Ages {round(rng[1], 2)} to {round(rng[2], 2)} years. Sex: {paste(names(table(d$sex)), table(d$sex), sep = ' ', collapse = ', ')}")
  if ("site" %in% names(d)) cli::cli_text("Sites: {paste(levels(d$site), collapse = ', ')}")
  if ("year" %in% names(d)) cli::cli_text("Years: {paste(range(d$year, na.rm = TRUE), collapse = ' to ')}")
  cli::cli_text("Mapping: {paste(names(x$map), x$map, sep = ' = ', collapse = ', ')}")
  bad <- x$log[x$log$n > 0, ]
  if (nrow(bad)) {
    cli::cli_alert_warning("Checks needing attention:")
    for (i in seq_len(nrow(bad))) cli::cli_li("{bad$check[i]}: {bad$n[i]}")
  }
  invisible(x)
}

#' @export
as.data.frame.wgh_data <- function(x, ...) as.data.frame(x$data, ...)

#' Work with the columns of a wgh_data object
#'
#' A `wgh_data` object holds the standardised data (`$data`), the column
#' mapping (`$map`) and the data checks (`$log`). For convenience it also
#' behaves like its data: `x$age` returns a column, `x$bmi <- ...` adds or
#' replaces one, `x[rows, ]` keeps the selected rows and returns a
#' `wgh_data` (mapping and checks kept, rows where a logical condition is
#' `NA` dropped), `x[rows, cols]` returns a tibble,
#' and `nrow(x)`, `ncol(x)` and `dim(x)` refer to the data. The names
#' `data`, `map` and `log` always refer to the parts of the object, so a
#' data column with one of these names must be reached through `x$data`.
#'
#' @param x A `wgh_data` object.
#' @param name A column name, or `data`, `map` or `log`.
#' @param value New values.
#' @param i,j Row and column indices, as for a data frame.
#' @param ... Not used.
#' @param drop Passed to the tibble when columns are selected.
#' @return See Description.
#' @examples
#' gd <- wgh_data(growdat, id = "pid", sex = "sex", age = "age", height = "height", weight = "weight")
#' summary(gd$age)
#' older <- gd[gd$age >= 10, ]
#' older
#' nrow(older)
#' head(gd[, c("id", "age", "height")])
#' @name wgh_data_access
NULL

.wgh_parts <- c("data", "map", "log")

#' @rdname wgh_data_access
#' @export
`$.wgh_data` <- function(x, name) {
  if (name %in% .wgh_parts) return(unclass(x)[[name]])
  unclass(x)[["data"]][[name]]
}

#' @rdname wgh_data_access
#' @export
`$<-.wgh_data` <- function(x, name, value) {
  cls <- class(x); y <- unclass(x)
  if (name %in% .wgh_parts) y[[name]] <- value else y[["data"]][[name]] <- value
  structure(y, class = cls)
}

#' @rdname wgh_data_access
#' @export
`[.wgh_data` <- function(x, i, j, ..., drop = FALSE) {
  d <- unclass(x)[["data"]]
  if (missing(j)) {
    if (nargs() == 2) .stop("Use {.code x[rows, ]} to select rows or {.code x$data} for the data.")
    y <- unclass(x)
    if (!missing(i)) {
      if (is.logical(i)) i <- i & !is.na(i)
      y[["data"]] <- d[i, , drop = FALSE]
    }
    return(structure(y, class = class(x)))
  }
  if (missing(i)) d[, j, drop = drop] else d[i, j, drop = drop]
}

#' @rdname wgh_data_access
#' @export
dim.wgh_data <- function(x) dim(unclass(x)[["data"]])

#' @export
summary.wgh_data <- function(object, ...) {
  d <- object$data
  per <- table(d$id)
  tibble::tibble(
    children = length(per), visits = nrow(d),
    visits_per_child_median = stats::median(as.numeric(per)),
    age_min = min(d$age, na.rm = TRUE), age_max = max(d$age, na.rm = TRUE),
    male = sum(tapply(d$sex == "Male", d$id, any), na.rm = TRUE),
    female = sum(tapply(d$sex == "Female", d$id, any), na.rm = TRUE)
  )
}

#' Show or extract the column mapping of a wgh_data object
#' @param x A `wgh_data` object.
#' @return A tibble with the standard role and the original column name.
#' @examples
#' gd <- wgh_data(growdat, id = "pid", sex = "sex", age = "age", height = "height", weight = "weight")
#' wgh_map(gd)
#' @export
wgh_map <- function(x) {
  if (!inherits(x, "wgh_data")) .stop("{.arg x} must be a {.cls wgh_data} object.")
  tibble::tibble(role = names(x$map), column = unname(x$map))
}

## internal: accept a wgh_data or a data frame that already uses standard names
.gd <- function(x, need = c("id", "age", "sex")) {
  d <- if (inherits(x, "wgh_data")) x$data else tibble::as_tibble(x)
  if (!inherits(x, "wgh_data")) {
    ## allow common book names
    ren <- c(pid = "id", hospitalcode = "site", yearvisit = "year", schoolyear = "year", bmiz = "baz")
    for (nm in names(ren)) if (nm %in% names(d) && !(ren[[nm]] %in% names(d))) d[[ren[[nm]]]] <- d[[nm]]
    if ("sex" %in% names(d) && !is.factor(d$sex)) d$sex <- factor(.norm_sex(d$sex), levels = .sexes)
    if ("id" %in% names(d)) d$id <- as.character(d$id)
    if (!"age" %in% names(d) && "dob" %in% names(d)) {
      dt <- intersect(c("date", "examdate", "visitdate"), names(d))[1]
      if (!is.na(dt)) d$age <- as.numeric(as.Date(d[[dt]]) - as.Date(d$dob)) / 365.25
    }
  }
  .check_cols(d, need, "WeGrowHealthR")
  d
}

## internal: rewrap modified data into the same container type
.regd <- function(x, d) {
  if (inherits(x, "wgh_data")) { x$data <- tibble::as_tibble(d); x } else tibble::as_tibble(d)
}
