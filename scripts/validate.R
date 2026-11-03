#!/usr/bin/env Rscript

# validate the generated data/*.csv against datapackage.json.
#
# warn mode: nothing here is fatal. missing columns, empty or duplicate keys,
# broken foreign keys, odd dates, rows that repeat apart from their key, a DOI
# on more than one citation, empty observation_level, reported_units or
# mgmttype, and units variables.csv does not declare all warn, so a workbook in
# progress still passes. this is what surfaces new gaps. the known ones are
# listed under Known warnings in the README, and tests/testthat/test-integrity.R
# caps them so that a new one fails the tests.
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

# where a warning's rows are, without printing them all: counts by dataset_id
# (or sites.name), split by variable (or mgmttype), largest first. a table with
# neither, like citations or coverage, is counted by its first column.
row_tally <- function(dat, max_show = 8) {
  by <- intersect(c("dataset_id", "sites.name"), names(dat))[1]
  if (is.na(by)) {
    key <- dat[[1]]
  } else {
    key <- dat[[by]]
    sub_by <- intersect(c("variable", "mgmttype"), names(dat))[1]
    if (!is.na(sub_by)) key <- paste(key, dat[[sub_by]], sep = " / ")
  }
  n <- sort(table(key, useNA = "ifany"), decreasing = TRUE)
  shown <- paste(names(n), n)[seq_len(min(length(n), max_show))]
  more <- if (length(n) > max_show) paste0("; and ", length(n) - max_show, " more") else ""
  paste0("[", paste(shown, collapse = "; "), more, "]")
}

# rows that repeat an earlier row in every column but the declared primary key;
# TRUE marks each copy after the first. a key does not show a record entered
# twice: event_id numbers the rows, and citation_id is a curated key per entry
# (knox2016bco beside ref_10_1002_2015jg003247), so two copies of one record
# carry two keys. comparing every other column is what finds them.
repeated_rows <- function(dat, resource) {
  pk <- unlist(resource$schema$primaryKey)
  rest <- dat[, setdiff(names(dat), pk), drop = FALSE]
  if (nrow(rest) < 2 || ncol(rest) == 0) {
    return(rep(FALSE, nrow(dat)))
  }
  duplicated(rest)
}

# one warning per table, counting the copies after the first. nothing is
# dropped: a repeat can be two real records the curation could not tell apart,
# e.g. plots whose ids were not carried over.
check_duplicate_rows <- function(dat, resource) {
  dup <- repeated_rows(dat, resource)
  if (!any(dup)) {
    return(0L)
  }
  pk <- unlist(resource$schema$primaryKey)
  but <- if (length(pk) > 0) paste(" but", paste(pk, collapse = ", ")) else ""
  log_warn(
    resource$name, "has", sum(dup),
    paste0("row(s) repeating an earlier row in every column", but),
    row_tally(dat[dup, , drop = FALSE])
  )
  1L
}

# columns whose values must not repeat although they are not the primary key.
# observations.citation, managements.citation and methods.citation_id all
# reference citations.doi, so a DOI on two citation rows doubles every row
# joined to it.
unique_values <- list(citations = "doi")

# DOIs are case-insensitive, so values are compared trimmed and lower-cased
fold_value <- function(x) tolower(trimws(as.character(x)))

# values, in folded form, that occur on more than one row; empty cells are ignored
duplicated_values <- function(x) {
  v <- fold_value(x)
  v <- v[is_present(v)]
  unique(v[duplicated(v)])
}

check_unique_values <- function(dat, resource) {
  pk <- unlist(resource$schema$primaryKey)
  id <- if (length(pk) == 1 && pk %in% names(dat)) dat[[pk]] else seq_len(nrow(dat))
  warns <- 0L
  for (col in intersect(unique_values[[resource$name]], names(dat))) {
    dups <- duplicated_values(dat[[col]])
    if (length(dups) == 0) next
    v <- fold_value(dat[[col]])
    each <- vapply(dups, function(d) {
      at <- which(v == d)
      paste0(trimws(dat[[col]][at[1]]), " (", paste(id[at], collapse = " = "), ")")
    }, character(1), USE.NAMES = FALSE)
    log_warn(
      resource$name, col, "has", length(dups), "value(s) on more than one row:",
      paste(each, collapse = "; ")
    )
    warns <- warns + 1L
  }
  warns
}

# columns the schema leaves optional but every row should fill: which
# experimental unit an observation is, what units it is in, and what kind of
# management event a row is
expected_present <- list(
  observations = c("observation_level", "reported_units"),
  managements = "mgmttype"
)

check_expected_present <- function(dat, resource) {
  warns <- 0L
  for (col in intersect(expected_present[[resource$name]], names(dat))) {
    empty <- !is_present(dat[[col]])
    if (!any(empty)) next
    log_warn(
      resource$name, col, "is empty on", sum(empty), "row(s)",
      row_tally(dat[empty, setdiff(names(dat), col), drop = FALSE])
    )
    warns <- warns + 1L
  }
  warns
}

# units. variables.csv gives the units each variable is expected in: one unit,
# or alternatives separated by ';', each with an optional trailing qualifier in
# parentheses ('kg C m-2 s-1 (daily mean)'), or the phrase below when units are
# kept as each source publishes them. reported_units must match one alternative
# as text, after squashing whitespace. the match is case sensitive, because mg
# and Mg are different units, and nothing is converted: 'g C m-2 yr-1' is not
# 'kg C m-2 year-1' here even though one converts to the other. rows stay in
# published units, so a mismatch is fixed in variables.csv unless the row
# mis-transcribes its source.
source_reported_units <- "source-reported units"

clean_unit <- function(x) gsub("\\s+", " ", trimws(as.character(x)))

# one status per row: unknown (variable not in variables.csv; check_foreign_keys
# reports it), missing (no reported_units; check_expected_present reports it),
# undeclared (variables.csv gives no units), deferred (source-reported units),
# ok, or conflict
unit_status <- function(variable, unit, vars) {
  unit <- clean_unit(unit)
  row <- match(variable, vars$name)
  declared <- clean_unit(vars$units[row])
  key <- paste(variable, unit, sep = "\r")
  first <- which(!duplicated(key))
  one <- function(known, d, u) {
    if (!known) return("unknown")
    if (!is_present(u)) return("missing")
    if (!is_present(d)) return("undeclared")
    if (tolower(d) == source_reported_units) return("deferred")
    parts <- trimws(strsplit(d, ";", fixed = TRUE)[[1]])
    accepted <- c(parts, trimws(sub("\\s*\\([^()]*\\)$", "", parts)))
    if (u %in% accepted) "ok" else "conflict"
  }
  status <- vapply(first, function(i) one(!is.na(row[i]), declared[i], unit[i]),
                   character(1))
  status[match(key, key[first])]
}

# each distinct unit with its row count and, per method, the datasets that
# carry it, so tower and chamber support show up side by side
unit_tally <- function(dat) {
  u <- clean_unit(dat$reported_units)
  ds <- if ("dataset_id" %in% names(dat)) dat$dataset_id else rep(NA_character_, nrow(dat))
  me <- if ("method" %in% names(dat)) dat$method else rep(NA_character_, nrow(dat))
  parts <- vapply(unique(u), function(x) {
    at <- u %in% x
    from <- vapply(unique(me[at]), function(m) {
      d <- paste(unique(ds[at & me %in% m]), collapse = ", ")
      if (is.na(m)) d else paste0(m, ": ", d)
    }, character(1))
    paste0("'", x, "' ", sum(at), " (", paste(from, collapse = "; "), ")")
  }, character(1), USE.NAMES = FALSE)
  paste(parts, collapse = "; ")
}

check_units <- function(dat, resource, vars) {
  if (is.null(vars) || nrow(dat) == 0 ||
      !all(c("variable", "reported_units") %in% names(dat)) ||
      !all(c("name", "units") %in% names(vars))) {
    return(0L)
  }
  status <- unit_status(dat$variable, dat$reported_units, vars)
  warns <- 0L
  undeclared <- unique(dat$variable[status == "undeclared"])
  if (length(undeclared) > 0) {
    log_warn(
      "variables.csv gives no units for", length(undeclared),
      "variable(s) used in", paste0(resource$name, ":"),
      paste(utils::head(undeclared, 5), collapse = ", ")
    )
    warns <- warns + 1L
  }
  for (v in unique(dat$variable[status == "conflict"])) {
    rows <- status == "conflict" & dat$variable == v
    log_warn(
      resource$name, v, "has", sum(rows),
      "row(s) in units variables.csv does not declare",
      paste0("('", clean_unit(vars$units[match(v, vars$name)]), "'):"),
      unit_tally(dat[rows, , drop = FALSE])
    )
    warns <- warns + 1L
  }
  # a variable kept in source-reported units may mix units across sources; that
  # is by design, so it is shown for information and does not warn
  for (v in unique(dat$variable[status == "deferred"])) {
    rows <- status == "deferred" & dat$variable == v
    if (length(unique(clean_unit(dat$reported_units[rows]))) > 1) {
      log_info(
        resource$name, v, "carries more than one unit as published",
        "(variables.csv: source-reported units):",
        unit_tally(dat[rows, , drop = FALSE])
      )
    }
  }
  warns
}

# read one table by its datapackage name, or NULL if it is not generated yet
read_resource <- function(dp, root, name) {
  res <- Find(function(r) r$name == name, dp$resources)
  if (is.null(res) || !file.exists(file.path(root, res$path))) {
    return(NULL)
  }
  read_table(file.path(root, res$path))
}

#' validate every data/*.csv that exists against datapackage.json
#'
#' @param root repo root; resource paths in datapackage.json are relative to it
#' @param datapackage path to the frictionless schema
#' @return number of warnings, invisibly
validate_data <- function(root = ".",
                          datapackage = file.path(root, "datapackage.json")) {
  dp <- read_datapackage(datapackage)
  vars <- read_resource(dp, root, "variables")
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
    total_warns <- total_warns + check_duplicate_rows(dat, res)
    total_warns <- total_warns + check_unique_values(dat, res)
    total_warns <- total_warns + check_expected_present(dat, res)
    total_warns <- total_warns + check_units(dat, res, vars)
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
