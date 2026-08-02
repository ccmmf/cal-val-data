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

# coverage carries a two row title block above its header row
skip_rows <- c(coverage = 2)

workbooks <- unlist(cfg$workbook, use.names = FALSE)

# tab names differ in case between workbooks, so match on the lowercased name
tab_names <- lapply(workbooks, function(wb) gs4_get(wb)$sheets$name)

# a column guessed as numeric in one workbook and text in another, or read as a
# list because its cells are mixed, has to fall back to text before it stacks
as_text <- function(x) {
  vapply(x, function(v) if (length(v) && !is.na(v[1])) as.character(v[1]) else NA_character_, character(1))
}
harmonise <- function(parts) {
  for (col in unique(unlist(lapply(parts, names)))) {
    types <- unique(unlist(lapply(parts, function(p) class(p[[col]])[1])))
    if (length(types) > 1 || "list" %in% types) {
      parts <- lapply(parts, function(p) {
        if (col %in% names(p)) p[[col]] <- as_text(p[[col]])
        p
      })
    }
  }
  parts
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
      skip = if (tab %in% names(skip_rows)) skip_rows[[tab]] else 0
    )
  }
  if (!length(parts)) next
  readr::write_csv(
    dplyr::bind_rows(harmonise(parts)),
    file.path(cfg$data_dir, paste0(tab, ".csv"))
  )
}
