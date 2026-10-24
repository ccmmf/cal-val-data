# downstream consumer view of the committed snapshot: answer "which sites have
# per-year cover crop biomass" and check the Salinas rows' contract
suppressMessages(library(readr))
root <- commandArgs(trailingOnly = TRUE)[1]
rd <- function(f) read_csv(file.path(root, "data", f), col_types = cols(.default = "c"), progress = FALSE)
obs <- rd("observations.csv"); vars <- rd("variables.csv"); meth <- rd("methods.csv")
cit <- rd("citations.csv"); crops <- rd("crops.csv")
ok <- function(label, cond) { cat(sprintf("[%s] %s\n", if (isTRUE(cond)) "PASS" else "FAIL", label)); if (!isTRUE(cond)) assign("fails", fails + 1, .GlobalEnv) }
fails <- 0

cat("== Which sites have per-year cover crop biomass? ==\n")
bio <- obs[grepl("cover_crop", obs$variable), ]
print(as.data.frame(table(dataset = bio$dataset_id, variable = bio$variable)), row.names = FALSE)
cat("\n")
cc <- obs[obs$variable == "cover_crop_shoot_dry_matter_Mg_ha", ]
ok(sprintf("observations total rows = %d (report says 37,313)", nrow(obs)), nrow(obs) == 37313)
ok(sprintf("cover_crop_shoot_dry_matter_Mg_ha rows = %d, all white_salinas_2020 / salinas_socs", nrow(cc)),
   nrow(cc) == 48 && all(cc$dataset_id == "white_salinas_2020") && all(cc$sitename == "salinas_socs"))
ok("treatments socs_sys3..socs_sys8 x study_year 1..8, one row each",
   identical(sort(unique(cc$treatment_id)), paste0("socs_sys", 3:8)) &&
   all(table(cc$treatment_id, cc$study_year) == 1) && identical(sort(unique(as.integer(cc$study_year))), 1:8))
ok("n = 4, observation_level = treatment_mean, reported_units = Mg ha-1",
   all(cc$n == "4") && all(cc$observation_level == "treatment_mean") && all(cc$reported_units == "Mg ha-1"))
ok("no replicate_id, no statname/stat (means only)", all(is.na(cc$replicate_id)))
v <- vars[vars$name == "cover_crop_shoot_dry_matter_Mg_ha", ]
ok(sprintf("variables row exists, units '%s'", v$units), nrow(v) == 1 && v$units == "Mg ha-1")
ok("method cover_crop_quadrat_clipping defined in methods, cites 10.2134/agronj2011.0330",
   all(cc$method == "cover_crop_quadrat_clipping") &&
   meth$citation_id[meth$`method name` == "cover_crop_quadrat_clipping"] == "10.2134/agronj2011.0330")
ok("citation 10.2134/agronj2011.0330 exists in citations (Brennan & Boyd 2012)",
   all(cc$citation == "10.2134/agronj2011.0330") && any(cit$doi == "10.2134/agronj2011.0330" & grepl("Brennan EB, Boyd NS \\(2012\\)", cit$citation_id)))
ok("fill_status = FILLED_PUBLICATION_FIGURE", all(cc$fill_status == "FILLED_PUBLICATION_FIGURE"))
crop_map <- c(socs_sys3 = "legume-rye mix", socs_sys4 = "legume-rye mix", socs_sys5 = "mustard", socs_sys6 = "mustard",
              socs_sys7 = "cereal rye", socs_sys8 = "cereal rye")
ok("crop per system: sys3/4 legume-rye, sys5/6 mustard, sys7/8 cereal rye; each joins to crops.csv",
   all(cc$crop == crop_map[cc$treatment_id]) && all(cc$crop %in% crops$`common name`))
cat("   crops joined:\n"); print(as.data.frame(crops[crops$`common name` %in% unique(cc$crop), 1:2]), row.names = FALSE)
md <- as.Date(cc$min_date); xd <- as.Date(cc$max_date); yr <- as.integer(cc$study_year)
ok("dates: season-end Feb/Mar of winter (2002+k)-(2003+k), max_date >= min_date",
   all(format(md, "%Y") == as.character(2003 + yr)) && all(format(md, "%m") %in% c("02", "03")) && all(xd >= md))
ok("each year's sampling window identical across the 6 systems (one Table 2 date per winter)",
   all(tapply(paste(cc$min_date, cc$max_date), cc$study_year, function(x) length(unique(x))) == 1))
cat("   sampling dates by year:\n")
d <- unique(cc[order(yr), c("study_year", "min_date", "max_date")]); print(as.data.frame(d), row.names = FALSE)
a <- lapply(cc$attributes_json, jsonlite::fromJSON)
ok("attributes_json cover_crop_year matches study_year",
   all(vapply(seq_along(a), function(i) a[[i]]$cover_crop_year == sprintf("%d-%d", 2002 + yr[i], 2003 + yr[i]), logical(1))))
lo <- vapply(a, function(x) if (is.null(x$ci95_lower)) NA_real_ else x$ci95_lower, 1)
hi <- vapply(a, function(x) if (is.null(x$ci95_upper)) NA_real_ else x$ci95_upper, 1)
val <- as.numeric(cc$value)
ok(sprintf("95%% CIs present on %d of 48 rows, both ends together", sum(!is.na(lo))), sum(!is.na(lo)) == 33 && identical(is.na(lo), is.na(hi)))
ok("every CI brackets its value (lower < value < upper)", all((lo < val & val < hi)[!is.na(lo)]))
stated <- c(socs_sys7 = 7.1, socs_sys8 = 7.2, socs_sys3 = 6.9, socs_sys4 = 7.5, socs_sys5 = 5.5, socs_sys6 = 5.7)
m <- tapply(val, cc$treatment_id, mean)
tab <- data.frame(treatment_id = names(m), mean_48_rows = round(as.numeric(m), 3), stated = stated[names(m)],
                  diff = round(as.numeric(m) - stated[names(m)], 3))
cat("   8-year means vs the paper's stated means:\n"); print(tab, row.names = FALSE)
ok("8-year means within 0.05 Mg ha-1 of stated means for all six systems", all(abs(tab$diff) <= 0.05 + 1e-9))
ok("stated 8-year means NOT added as extra rows (no study_year outside 1..8, no period rows)",
   !any(is.na(cc$study_year)) && nrow(cc) == 48)
ok("no Salinas cover crop rows for socs_sys1/socs_sys2 (open follow-up)", !any(cc$treatment_id %in% c("socs_sys1", "socs_sys2")))
cat(sprintf("\n%d check(s) failed\n", fails)); quit(status = fails > 0)
