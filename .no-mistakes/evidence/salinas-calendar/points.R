m <- readr::read_csv("data/managements.csv", col_types = readr::cols(.default = "c"), show_col_types = FALSE)
s <- m[m$sites.name == "salinas_socs", ]
s$d0 <- substr(s$min_date, 1, 10); s$d1 <- substr(s$max_date, 1, 10)
pt <- s[s$d0 == s$d1, ]
cat("Salinas rows:", nrow(s), " point-date rows:", nrow(pt), " window rows:", nrow(s) - nrow(pt), "\n\n")
# a point date is backed when its own notes print that exact day (e.g. 'Table 2: planted 2007-10-15') or name the paper date it takes
pt$backed <- mapply(function(d, n) grepl(d, n, fixed = TRUE), pt$d0, pt$notes)
agg <- aggregate(event_id ~ mgmttype + backed, pt, length); names(agg)[3] <- "rows"; print(agg)
cat("\npoint-date rows whose notes do not print the day:\n")
u <- pt[!pt$backed, ]
if (nrow(u)) print(unique(data.frame(date = u$d0, mgmttype = u$mgmttype, notes = substr(u$notes, 1, 230))), right = FALSE) else cat("none\n")
cat("\ndistinct point dates by mgmttype:\n")
for (t in unique(pt$mgmttype)) cat(sprintf("%-20s %s\n", t, paste(sort(unique(pt$d0[pt$mgmttype == t])), collapse = " ")))
