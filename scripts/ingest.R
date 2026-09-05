#!/usr/bin/env Rscript

# read the cal/val workbooks and write one csv per tab to data/.
# the workbooks are the source of truth; the csvs are generated, not edited.
# each dataset group is curated in its own workbook, so a tab in data/ is the
# rows of that tab from every workbook that has one.

library(googlesheets4)

cfg <- config::get(file = "000-config.yml")

tabs <- c(
  "citations", "sites", "treatments", "treatment_pairs", "managements",
  "observations", "methods", "variables", "crops", "coverage"
)

workbooks <- unlist(cfg$workbook, use.names = FALSE)

# some tabs open with a title block above the header, and it is not the same
# height in every workbook, so find the first row that holds more than one cell.
# guessing wrong would silently shift a whole tab, so stop rather than assume row 1
header_offset <- function(wb, tab) {
  top <- read_sheet(wb, sheet = tab, range = "1:5", col_names = FALSE, col_types = "c")
  filled <- vapply(seq_len(nrow(top)), function(i) sum(!is.na(unlist(top[i, ]))), integer(1))
  first <- which(filled > 1)[1]
  if (is.na(first)) {
    stop("no header row found in the first 5 rows of tab '", tab, "'", call. = FALSE)
  }
  first - 1L
}

# tab names differ in case between workbooks, so match on the lowercased name
tab_names <- lapply(workbooks, function(wb) gs4_get(wb)$sheets$name)

# a column guessed as numeric in one workbook and text in another, or read as a
# list because its cells are mixed, has to fall back to text before it stacks.
# only the workbooks that actually have the column count: `p[[col]]` is NULL when
# a part lacks it, and "NULL" would otherwise read as a second type and cast a
# perfectly consistent numeric column to text.
as_text <- function(x) {
  vapply(x, function(v) {
    # no cell in the current workbooks holds more than one value, and silently
    # keeping the first would drop data if that ever changed
    if (length(v) > 1) {
      stop("a single cell holds ", length(v), " values; cannot flatten to text", call. = FALSE)
    }
    if (length(v) && !is.na(v[1])) as.character(v[1]) else NA_character_
  }, character(1))
}
harmonise <- function(parts) {
  for (col in unique(unlist(lapply(parts, names)))) {
    types <- unique(unlist(lapply(
      parts, function(p) if (col %in% names(p)) class(p[[col]])[1]
    )))
    if (length(types) > 1 || "list" %in% types) {
      parts <- lapply(parts, function(p) {
        if (col %in% names(p)) p[[col]] <- as_text(p[[col]])
        p
      })
    }
  }
  parts
}

# the workbooks pad with blank rows, and a blank header cell arrives auto-named
# (`...4`) carrying nothing. neither belongs in the exported csv: validate.R drops
# empty rows before checking, so leaving them in means the committed artifact is
# not the table that was validated.
is_blank <- function(x) is.na(x) | trimws(as.character(x)) == ""
drop_empty <- function(dat) {
  keep_col <- vapply(dat, function(col) !all(is_blank(col)), logical(1))
  keep_col <- keep_col | !grepl("^\\.\\.\\.[0-9]+$", names(dat))  # keep named-but-empty columns
  dat <- dat[, keep_col, drop = FALSE]
  keep_row <- !apply(dat, 1, function(r) all(is_blank(r)))
  dat[keep_row, , drop = FALSE]
}

# one workbook labels some columns its own way alongside the canonical name, and
# the two agree on every row they fill. the duplicate carries nothing, so it is
# dropped rather than exported and declared. named per table because the same
# column name means different things in different tables: `treatment_id` in
# observations is the foreign key, in treatments it merely repeats `name`.
redundant <- list(
  observations = c("site_id", "method_id"),
  sites        = "site_id",
  treatments   = c("treatment_id", "treatment_definition"),
  managements  = c("site_id", "treatment_id", "event_type"),
  variables    = "variable"
)
drop_redundant <- function(dat, tab) {
  dat[, !names(dat) %in% redundant[[tab]], drop = FALSE]
}

dir.create(cfg$data_dir, showWarnings = FALSE)

for (tab in tabs) {
  parts <- list()
  for (i in seq_along(workbooks)) {
    hit <- tab_names[[i]][tolower(tab_names[[i]]) == tab]
    if (!length(hit)) next
    parts[[length(parts) + 1]] <- read_sheet(
      workbooks[i],
      sheet = hit[1],
      skip = header_offset(workbooks[i], hit[1]),
      # Later datasets can populate columns left empty in the first 1000 rows.
      guess_max = Inf
    )
  }
  if (!length(parts)) next
  readr::write_csv(
    drop_redundant(drop_empty(dplyr::bind_rows(harmonise(parts))), tab),
    file.path(cfg$data_dir, paste0(tab, ".csv"))
  )
}
