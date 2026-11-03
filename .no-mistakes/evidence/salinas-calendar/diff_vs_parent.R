#!/usr/bin/env Rscript
# Row-level diff of the generated tables between the parent commit's data and
# the change's data: which rows changed, were added or removed, per site.
args <- commandArgs(trailingOnly = TRUE)
old_root <- args[1]; new_root <- args[2]
rd <- function(root, f) as.data.frame(readr::read_csv(file.path(root, "data", f),
  col_types = readr::cols(.default = "c"), progress = FALSE, na = character()))
key_of <- c(managements = "event_id", treatments = "name", crops = "scientific name",
            citations = "doi")
for (tab in names(key_of)) {
  o <- rd(old_root, paste0(tab, ".csv")); n <- rd(new_root, paste0(tab, ".csv"))
  k <- key_of[[tab]]
  common <- intersect(o[[k]], n[[k]])
  ro <- do.call(paste, c(o[match(common, o[[k]]), ], sep = "\x1f"))
  rn <- do.call(paste, c(n[match(common, n[[k]]), names(o)], sep = "\x1f"))
  changed <- common[ro != rn]
  added <- setdiff(n[[k]], o[[k]]); removed <- setdiff(o[[k]], n[[k]])
  cat(sprintf("%-12s rows old=%d new=%d  changed=%d added=%d removed=%d  dup-keys(new)=%d\n",
    tab, nrow(o), nrow(n), length(changed), length(added), length(removed),
    sum(duplicated(n[[k]]))))
  if (tab == "managements") {
    site_old <- setNames(o$sites.name, o$event_id); site_new <- setNames(n$sites.name, n$event_id)
    cat("  changed rows by site:"); print(table(site_new[changed]))
    cat("  added rows by site:  "); print(table(site_new[added]))
    cat("  added Salinas rows by mgmttype:"); print(table(n$mgmttype[n$event_id %in% added]))
    others <- setdiff(unique(c(o$sites.name, n$sites.name)), "salinas_socs")
    oo <- o[o$sites.name %in% others, ]; nn <- n[n$sites.name %in% others, ]
    oo <- oo[order(oo$event_id), ]; nn <- nn[order(nn$event_id), names(oo)]
    rownames(oo) <- rownames(nn) <- NULL
    cat("  non-Salinas rows identical:", identical(oo, nn), "(", nrow(nn), "rows )\n")
    sal_old <- sum(o$sites.name == "salinas_socs")
    est <- "compost_application-0001"
    cat("  Salinas rows old:", sal_old, " unchanged Salinas rows:",
        paste(setdiff(o$event_id[o$sites.name == "salinas_socs"], changed), collapse = ","), "\n")
  }
  if (tab %in% c("treatments", "crops", "citations") && length(c(changed, added)))
    cat("  keys:", paste(c(changed, added), collapse = " | "), "\n")
}
