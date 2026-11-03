#!/usr/bin/env Rscript
# Push each committed data/*.csv back through scripts/ingest.R's own export
# helpers (drop_empty, harmonise, drop_redundant, order_columns, readr::write_csv)
# and compare the bytes with the committed file. The Google Sheet read is
# replaced by readr::read_csv on the committed CSV; everything after the read is
# ingest.R's code, evaluated from the file itself (no sheet access).
# usage: Rscript export_roundtrip.R <repo_root> <out_dir>
args <- commandArgs(TRUE)
root <- normalizePath(args[1])
out <- args[2]
dir.create(out, showWarnings = FALSE, recursive = TRUE)
owd <- setwd(root)
exprs <- parse(file.path(root, "scripts", "ingest.R"))
keep <- c("as_text", "harmonise", "is_blank", "drop_empty", "redundant",
          "drop_redundant", "declared_fields", "order_columns", "tabs")
for (e in exprs) {
  if (is.call(e) && identical(e[[1]], as.name("<-")) && as.character(e[[2]]) %in% keep) eval(e)
}
setwd(owd)
bad <- 0L
for (tab in tabs) {
  src <- file.path(root, "data", paste0(tab, ".csv"))
  # all-text read: ingest stacks three workbooks and harmonise() turns mixed-type
  # columns (e.g. Date in one workbook, datetime in another) into text
  part <- readr::read_csv(src, col_types = readr::cols(.default = "c"), progress = FALSE)
  dst <- file.path(out, paste0(tab, ".csv"))
  readr::write_csv(order_columns(drop_redundant(drop_empty(dplyr::bind_rows(harmonise(list(part)))), tab), tab), dst)
  same <- identical(unname(tools::md5sum(src)), unname(tools::md5sum(dst)))
  if (!same) bad <- bad + 1L
  cat(sprintf("%-16s %s  %s\n", tab, if (same) "byte-identical" else "DIFFERS", unname(tools::md5sum(src))))
}
cat(sprintf("%d table(s) differ\n", bad))
quit(status = if (bad) 1 else 0)
