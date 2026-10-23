# cell-level diff of data/observations.csv between the parent commit and HEAD,
# reading both git blobs as text (no type guessing) exactly as validate.R does
args <- commandArgs(trailingOnly = TRUE)
old_rev <- args[1]; new_rev <- args[2]
rd <- function(rev) {
  txt <- system2("git", c("show", paste0(rev, ":data/observations.csv")), stdout = TRUE)
  readr::read_csv(I(paste(txt, collapse = "\n")),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(), name_repair = "minimal", progress = FALSE)
}
a <- rd(old_rev); b <- rd(new_rev)
cat("rows:", old_rev, nrow(a), "|", new_rev, nrow(b), "\n")
cat("columns identical:", identical(names(a), names(b)), "\n")
stopifnot(nrow(a) == nrow(b), identical(names(a), names(b)))
ch <- which(as.matrix(a) != as.matrix(b), arr.ind = TRUE)
out <- data.frame(
  line = ch[, "row"] + 1L,
  sitename = b$sitename[ch[, "row"]],
  variable = b$variable[ch[, "row"]],
  study_year = b$study_year[ch[, "row"]],
  column = names(a)[ch[, "col"]],
  before = as.matrix(a)[ch],
  after = as.matrix(b)[ch]
)
out <- out[order(out$line, out$column), ]
print(out, row.names = FALSE)
cat("\nchanged cells:", nrow(out), "\n")
cat("changed rows:", length(unique(out$line)), "\n")
cat("columns touched:", paste(unique(out$column), collapse = ", "), "\n")
cat("all changed rows are US-Twt rice_grain_yield_t_ha:",
    all(out$sitename == "US-Twt" & out$variable == "rice_grain_yield_t_ha"), "\n")
cat("rice_grain_yield_t_ha rows at HEAD:", sum(b$variable == "rice_grain_yield_t_ha"), "\n")
