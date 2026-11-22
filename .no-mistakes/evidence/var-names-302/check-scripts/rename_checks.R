# consumer-level checks of the #302 variable rename against the committed snapshot
suppressMessages(library(readr))
rd <- function(p) read_csv(p, col_types = cols(.default = col_character()), na = character(), progress = FALSE)
args <- commandArgs(TRUE); tmp <- args[1]
bo <- rd(file.path(tmp, "base_obs.csv")); bv <- rd(file.path(tmp, "base_vars.csv"))
o <- rd("data/observations.csv"); v <- rd("data/variables.csv")
say <- function(...) cat(..., "\n", sep = "")
ok <- function(label, cond) { say(if (isTRUE(cond)) "PASS  " else "FAIL  ", label); invisible(cond) }

say("== variables.csv ==")
say("base rows: ", nrow(bv), "  target rows: ", nrow(v))
ok("variables 106 -> 85", nrow(bv) == 106 && nrow(v) == 85)
gone <- c("CO2_flux", "SoilTemp", "SoilMoistFrac", "soil_oxygen_concentration")
keep <- c("soil_CO2_flux", "soil_temperature", "soil_water_content", "soil_oxygen_content")
ok("unused duplicates CO2_flux, SoilTemp, SoilMoistFrac, soil_oxygen_concentration removed", !any(gone %in% v$name))
ok("their counterparts soil_CO2_flux, soil_temperature, soil_water_content, soil_oxygen_content kept", all(keep %in% v$name))
ok("removed duplicates had no observations in the base snapshot", !any(gone %in% bo$variable))
ok("every observation variable resolves to variables.name", all(unique(o$variable) %in% v$name))
ok("variables.name unique", !anyDuplicated(v$name))

say("\n== observations: old names -> new names ==")
old_used <- setdiff(unique(bo$variable), unique(o$variable))
new_used <- setdiff(unique(o$variable), unique(bo$variable))
say("old names used in base obs, absent now (", length(old_used), "): ", paste(sort(old_used), collapse = ", "))
say("new names used now, absent in base obs (", length(new_used), "): ", paste(sort(new_used), collapse = ", "))
# derive the map row by row for datasets whose rows were not curated beyond the rename
rr <- c("russell_ranch_tautges_2019")
nb <- bo[!bo$dataset_id %in% rr, ]; nt <- o[!o$dataset_id %in% rr, ]
say("non-Russell rows: base ", nrow(nb), ", target ", nrow(nt))
ok("non-Russell row count unchanged", nrow(nb) == nrow(nt))
cols <- setdiff(names(o), "variable")
kb <- do.call(paste, c(nb[cols], sep = "\x1f")); kt <- do.call(paste, c(nt[cols], sep = "\x1f"))
ok("non-Russell rows identical in every column but variable (same order)", identical(kb, kt))
m <- unique(data.frame(old = nb$variable, new = nt$variable))
m <- m[m$old != m$new, ]
print(m[order(m$new, m$old), ], row.names = FALSE)
ok("each old name maps to exactly one new name", !anyDuplicated(m$old))

say("\n== names carry no crop or unit ==")
crop_unit <- "corn|wheat|tomato|rice|alfalfa|sudangrass|cover_crop|_kg_ha|_Mg_ha|_t_ha|_pct|_g_cm3|_mg_kg|_m2_d|_g_N_ha|_mh_|_hh_"
bad <- grep(crop_unit, unique(o$variable), value = TRUE)
ok(paste0("no observation variable names a crop or unit (found: ", paste(bad, collapse = ","), ")"), length(bad) == 0)

say("\n== tomato red and green fruit kept apart ==")
tom <- o[o$dataset_id == "russell_ranch_tautges_2019" & o$crop == "tomato", ]
print(table(tom$variable, tom$method))
red <- tom[tom$variable == "red_fruit_fresh_yield", ]; grn <- tom[tom$variable == "green_fruit_fresh_yield", ]
ok("red_fruit_fresh_yield and green_fruit_fresh_yield both present", nrow(red) > 0 && nrow(grn) > 0)
k <- function(d) paste(d$treatment_id, d$replicate_id, d$min_date)
j <- merge(data.frame(k = k(red), r = red$value), data.frame(k = k(grn), g = grn$value), by = "k")
say("plot-dates with both red and green: ", nrow(j), "; of those, red value == green value: ", sum(j$r == j$g))
ok("red and green are separate values, not one merged quantity", nrow(j) > 0 && mean(j$r == j$g) < 0.05)
ok("tomato fruit rows have crop=tomato and Mg ha-1", all(c(red$reported_units, grn$reported_units) == "Mg ha-1"))
