#!/usr/bin/env Rscript

# validate the generated data/*.csv against datapackage.json.
#
# warn mode: nothing here is fatal. missing columns, empty keys, broken foreign
# keys, and odd dates all warn so a workbook in progress still passes. this is
# what surfaces new gaps; known ones live in the repo docs.
#
# depends only on base R, jsonlite, and readr; logging is plain base R messages.

log_info <- function(...) message(paste(...))
log_warn <- function(...) message(paste("WARNING:", ...))

read_datapackage <- function(path) {
  jsonlite::read_json(path, simplifyVector = FALSE)
}

# drop rows that are entirely empty; the workbook export pads with blank rows
drop_empty_rows <- function(dat) {
  if (nrow(dat) == 0) {
    return(dat)
  }
  blank <- apply(dat, 1, function(r) all(is.na(r) | trimws(as.character(r)) == ""))
  dat[!blank, , drop = FALSE]
}

# a value counts as present if it is not NA and not blank
is_present <- function(x) !is.na(x) & trimws(as.character(x)) != ""

# every check here treats values as text, and guessing types from the leading
# rows silently drops data: a column left empty for the first several thousand
# rows is guessed logical, so the JSON or flag string that finally appears fails
# to parse and becomes NA without failing the run. read as text and compare text.
read_table <- function(path) {
  dat <- readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    name_repair = "minimal", progress = FALSE
  )
  drop_empty_rows(dat)
}

field_names <- function(resource) {
  vapply(resource$schema$fields, function(f) f$name, character(1))
}

# missing columns warn rather than fail; ingest may still be catching up (e.g.
# the coverage tab preamble must be stripped). tests/ assert the column contract.
check_columns <- function(dat, resource) {
  missing <- setdiff(field_names(resource), names(dat))
  if (length(missing) > 0) {
    log_warn(
      resource$name, "is missing expected columns:",
      paste(missing, collapse = ", ")
    )
    return(1L)
  }
  0L
}

check_primary_key <- function(dat, resource) {
  pk <- unlist(resource$schema$primaryKey)
  if (is.null(pk)) {
    return(0L)
  }
  warns <- 0L
  for (k in pk) {
    if (!k %in% names(dat)) next
    n_empty <- sum(!is_present(dat[[k]]))
    if (n_empty > 0) {
      log_warn(resource$name, "primary key", k, "has", n_empty, "empty value(s)")
      warns <- warns + 1L
    }
  }
  if (length(pk) == 1 && pk %in% names(dat)) {
    vals <- dat[[pk]][is_present(dat[[pk]])]
    dups <- unique(vals[duplicated(vals)])
    if (length(dups) > 0) {
      log_warn(
        resource$name, "primary key", pk, "has duplicate value(s):",
        paste(utils::head(dups, 5), collapse = ", ")
      )
      warns <- warns + 1L
    }
  }
  warns
}

check_foreign_keys <- function(dat, resource, dp, root) {
  fks <- resource$schema$foreignKeys
  if (is.null(fks)) {
    return(0L)
  }
  warns <- 0L
  for (fk in fks) {
    local_col <- unlist(fk$fields)
    ref_name <- fk$reference$resource
    ref_col <- unlist(fk$reference$fields)
    if (!local_col %in% names(dat)) next
    ref_res <- Find(function(r) r$name == ref_name, dp$resources)
    if (is.null(ref_res)) next
    ref_path <- file.path(root, ref_res$path)
    if (!file.exists(ref_path)) next
    ref <- read_table(ref_path)
    if (!ref_col %in% names(ref)) next
    ref_vals <- unique(as.character(ref[[ref_col]][is_present(ref[[ref_col]])]))
    local_vals <- as.character(dat[[local_col]])
    bad <- unique(local_vals[is_present(local_vals) & !local_vals %in% ref_vals])
    if (length(bad) > 0) {
      log_warn(
        resource$name, local_col, "->", paste0(ref_name, ".", ref_col),
        "has", length(bad), "unmatched value(s):",
        paste(utils::head(bad, 5), collapse = ", ")
      )
      warns <- warns + 1L
    }
  }
  warns
}

# light plausibility check. an unanchored excel-serial branch used to sit here and
# accepted any bare number, so 0 or 42 passed as a date; every exported date is
# ISO or YYYYMMDD, so matching those two is both stricter and sufficient.
date_like <- function(x) {
  x <- trimws(as.character(x))
  grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", x) | # YYYY-MM-DD[ ...]
    grepl("^[0-9]{8}$", x) # YYYYMMDD
}

check_dates <- function(dat, resource) {
  date_cols <- intersect(
    c("min_date", "max_date", "start_date", "end_date"), names(dat)
  )
  warns <- 0L
  for (col in date_cols) {
    vals <- dat[[col]]
    bad <- unique(vals[is_present(vals) & !date_like(vals)])
    if (length(bad) > 0) {
      log_warn(
        resource$name, col, "has", length(bad),
        "value(s) that do not look like a date:",
        paste(utils::head(bad, 5), collapse = ", ")
      )
      warns <- warns + 1L
    }
  }
  warns
}

#' validate every data/*.csv that exists against datapackage.json
#'
#' @param root repo root; resource paths in datapackage.json are relative to it
#' @param datapackage path to the frictionless schema
#' @return number of warnings, invisibly
validate_data <- function(root = ".",
                          datapackage = file.path(root, "datapackage.json")) {
  dp <- read_datapackage(datapackage)
  total_warns <- 0L
  checked <- 0L
  for (res in dp$resources) {
    path <- file.path(root, res$path)
    if (!file.exists(path)) {
      log_info("skip", res$name, "not generated yet")
      next
    }
    dat <- read_table(path)
    total_warns <- total_warns + check_columns(dat, res)
    total_warns <- total_warns + check_primary_key(dat, res)
    total_warns <- total_warns + check_foreign_keys(dat, res, dp, root)
    total_warns <- total_warns + check_dates(dat, res)
    checked <- checked + 1L
    log_info("checked", res$name, nrow(dat), "rows")
  }
  if (checked == 0) {
    log_info("no data/*.csv generated yet; run scripts/ingest.R first")
  } else {
    log_info("validated", checked, "table(s) with", total_warns, "warning(s)")
  }
  invisible(total_warns)
}

# run when called as a script, not when sourced (tests source this file)
if (sys.nframe() == 0L) {
  validate_data(root = ".")
}
