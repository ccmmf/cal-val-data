rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"), na = character(), show_col_types = FALSE)
par <- ".nm_scratch/fabf5f5/data/"
for (t in c("managements", "treatments", "crops", "citations", "sites", "treatment_pairs", "observations", "methods", "variables", "coverage")) {
  o <- rd(paste0(par, t, ".csv")); n <- rd(paste0("data/", t, ".csv"))
  key <- names(n)[1]
  ok <- o[[key]] %in% n[[key]]; added <- sum(!(n[[key]] %in% o[[key]]))
  common <- intersect(o[[key]], n[[key]])
  oc <- o[match(common, o[[key]]), names(n)[names(n) %in% names(o)]]; nc <- n[match(common, n[[key]]), names(n)[names(n) %in% names(o)]]
  changed <- sum(apply(as.matrix(oc) != as.matrix(nc), 1, any))
  cat(sprintf("%-16s parent %6d rows, HEAD %6d rows: %4d changed, %4d added, %d removed (key %s)\n", t, nrow(o), nrow(n), changed, added, sum(!ok), key))
}
o <- rd(paste0(par, "managements.csv")); n <- rd("data/managements.csv")
cat("\nmanagements by site, parent vs HEAD:\n")
print(merge(as.data.frame(table(parent = o$sites.name)), as.data.frame(table(head = n$sites.name)), by = 1, all = TRUE))
non_o <- o[o$sites.name != "salinas_socs", ]; non_n <- n[n$sites.name != "salinas_socs", ]
cat("non-Salinas managements rows identical (all columns, same order):", identical(non_o, non_n), "\n")
s_new <- n[n$sites.name == "salinas_socs" & !(n$event_id %in% o$event_id), ]
cat("added Salinas rows by mgmttype:\n"); print(table(s_new$mgmttype))
