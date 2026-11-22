# check the reworded variable and method definitions against the rows they describe
suppressMessages(library(readr))
rd <- function(p) read_csv(p, col_types = cols(.default = col_character()), na = character(), progress = FALSE)
tmp <- commandArgs(TRUE)[1]
bo <- rd(file.path(tmp, "base_obs.csv")); o <- rd("data/observations.csv"); v <- rd("data/variables.csv"); m <- rd("data/methods.csv")
say <- function(...) cat(..., "\n", sep = "")
ok <- function(label, cond) { say(if (isTRUE(cond)) "PASS  " else "FAIL  ", label); invisible(cond) }
empty <- function(x) x %in% c("", "NA")
def <- function(n) v$description[v$name == n]
rb <- bo[bo$dataset_id == "russell_ranch_tautges_2019", ]
say("base Russell NH4/NO3 rows labelled: ", sum(!empty(rb$replicate_id) & rb$variable %in% c("soil_nh4_n_mg_kg", "soil_no3_n_mg_kg")), " of ", sum(rb$variable %in% c("soil_nh4_n_mg_kg", "soil_no3_n_mg_kg")))

for (n in c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration", "soil_organic_carbon_content", "soil_bulk_density")) say("\n", n, ": ", def(n))
tcn <- o[o$variable %in% c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration"), ]
ok("total C/N definitions no longer claim 'dry combustion'", !any(grepl("dry combustion", c(def("soil_total_carbon_concentration"), def("soil_total_nitrogen_concentration")), ignore.case = TRUE)))
nd <- tcn[empty(tcn$min_depth) | empty(tcn$max_depth), ]
say("total C/N rows with empty depth: ", nrow(nd), " -> ", paste(names(table(nd$dataset_id)), table(nd$dataset_id), collapse = "; "))
ok("those 12 rows are AmeriFlux Delta and carry reported_layer_top_cm/bottom_cm in attributes_json, as the definition says",
   nrow(nd) == 12 && all(grepl("^ameriflux_", nd$dataset_id)) && all(grepl("reported_layer_top_cm", nd$attributes_json) & grepl("reported_layer_bottom_cm", nd$attributes_json)))
soc <- o[o$variable == "soil_organic_carbon_content", ]
esm <- tapply(grepl("equivalent_depth_cm", soc$attributes_json), soc$dataset_id, sum)
say("soil_organic_carbon_content rows by dataset: ", paste(names(table(soc$dataset_id)), table(soc$dataset_id), collapse = "; "), "; with equivalent_depth_cm: ", paste(names(esm), esm, collapse = "; "))
ok("definition says equivalent_depth_cm only where reported; raffeld_2024 has it on all 96, white_salinas_2020 on none of 288",
   grepl("where the source reports it", def("soil_organic_carbon_content")) && esm[["raffeld_2024"]] == 96 && esm[["white_salinas_2020"]] == 0 &&
   sum(soc$dataset_id == "white_salinas_2020") == 288)
bd <- o[o$variable == "soil_bulk_density", ]; bdn <- bd[empty(bd$min_depth) | empty(bd$max_depth), ]
say("bulk density rows with empty depth: ", nrow(bdn), " (", paste(unique(bdn$dataset_id), collapse = ","), ")")
ok("bulk density definition allows empty depth; exactly the 6 nichols_modesto_2024 rows are empty",
   grepl("empty where the source does not report", def("soil_bulk_density")) && nrow(bdn) == 6 && all(bdn$dataset_id == "nichols_modesto_2024"))
mhd <- m$description[m$`method name` == "machine_harvest"]
say("\nmachine_harvest: ", mhd)
ok("machine_harvest says corn and wheat usually come once per plot and keeps half rows where halves differ or only one half is given",
   grepl("usually gives one value per plot", mhd) && grepl("only one half is given", mhd))
ok("field_harvest method row still exists for the US-Twt rice rows", "field_harvest" %in% m$`method name`)
