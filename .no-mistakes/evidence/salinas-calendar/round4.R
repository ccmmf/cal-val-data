rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"), na = character(), show_col_types = FALSE)
old <- rd(".nm_scratch/236a7cd/data/managements.csv")
new <- rd("data/managements.csv")
cat("rows before:", nrow(old), " rows after:", nrow(new), " same event_id order:", identical(old$event_id, new$event_id), "\n")
diffcells <- which(as.matrix(old) != as.matrix(new), arr.ind = TRUE)
cat("cells changed:", nrow(diffcells), "\n")
print(data.frame(event_id = new$event_id[diffcells[, 1]], column = names(new)[diffcells[, 2]], csv_line = diffcells[, 1] + 1))
ids <- c("tillage-0049", "tillage-0050", "tillage-0113", "tillage-0114")
x <- new[new$event_id %in% ids, c("event_id", "treatments.name", "min_date", "max_date", "level", "units", "notes")]
for (i in seq_len(nrow(x))) { cat("\n", x$event_id[i], x$treatments.name[i], x$min_date[i], "->", x$max_date[i], x$level[i], x$units[i], "\n  notes:", x$notes[i], "\n") }
sal <- new[new$sites.name == "salinas_socs", ]
cat("\nSalinas rows still containing 'end of March':", sum(grepl("end of March", sal$notes, fixed = TRUE)), "\n")
cat("Salinas rows citing '30 days before the bed formation':", sum(grepl("30 days before the bed formation", sal$notes, fixed = TRUE)), "\n")
# window end vs bed formation: next fertilization/compost window start for the same system
for (id in ids) {
  r <- new[new$event_id == id, ]
  nxt <- sal[sal$treatments.name == r$treatments.name & substr(sal$min_date, 1, 4) == substr(r$min_date, 1, 4) & sal$min_date > r$max_date & sal$mgmttype %in% c("fertilization", "tillage", "planting"), ]
  nxt <- nxt[order(nxt$min_date), ][1, ]
  gap <- as.integer(as.Date(substr(nxt$min_date, 1, 10)) - as.Date(substr(r$max_date, 1, 10)))
  cat(id, "window ends", substr(r$max_date, 1, 10), "; next event", nxt$event_id, nxt$mgmttype, "starts", substr(nxt$min_date, 1, 10), "; gap", gap, "days\n")
}
