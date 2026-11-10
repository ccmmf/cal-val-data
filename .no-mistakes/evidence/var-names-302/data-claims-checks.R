# consumer-side checks of the #302 / #274 claims against the committed CSVs
# usage: Rscript checks.R <repo root> <base dir with pre-change CSVs>
args <- commandArgs(TRUE)
root <- args[1]; base <- args[2]
rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"), na = character(),
                                  show_col_types = FALSE, progress = FALSE)
emp <- function(x) x %in% c("", "NA")
obs <- rd(file.path(root, "data/observations.csv"))
var <- rd(file.path(root, "data/variables.csv"))
met <- rd(file.path(root, "data/methods.csv"))
b_obs <- rd(file.path(base, "observations_pre302.csv"))
b_var <- rd(file.path(base, "variables_pre302.csv"))

res <- list()
chk <- function(name, got, want) {
  ok <- identical(as.character(got), as.character(want))
  res[[length(res) + 1]] <<- data.frame(check = name, got = paste(got, collapse = ", "),
                                        want = paste(want, collapse = ", "), ok = ok)
  cat(sprintf("[%s] %s\n      got:  %s\n      want: %s\n", if (ok) "PASS" else "FAIL", name,
              paste(got, collapse = ", "), paste(want, collapse = ", ")))
}

cat("== Rename map (#302)\n")
chk("observations rows before -> after", c(nrow(b_obs), nrow(obs)), c(37313, 36641))
chk("variables rows before -> after", c(nrow(b_var), nrow(var)), c(106, 88))
chk("CO2_flux dropped, soil_CO2_flux present",
    c("CO2_flux" %in% var$name, "soil_CO2_flux" %in% var$name), c(FALSE, TRUE))
chk("CO2_flux was unused before removal", sum(b_obs$variable == "CO2_flux"), 0)
gone <- setdiff(unique(b_obs$variable), unique(obs$variable))
new <- setdiff(unique(obs$variable), unique(b_obs$variable))
# names that existed before but now receive merged rows also count as targets
merged_into <- c("soil_organic_carbon_content", "soil_bulk_density", "CH4_flux", "N2O_flux")
cat("retired observation names (", length(gone), "):", paste(sort(gone), collapse = " "), "\n")
cat("new observation names (", length(new), "):", paste(sort(new), collapse = " "), "\n")
retired_vars <- setdiff(b_var$name, var$name)
cat("retired variables.csv names (", length(retired_vars), "):", paste(sort(retired_vars), collapse = " "), "\n")
chk("every observation variable is declared in variables.csv",
    length(setdiff(unique(obs$variable), var$name)), 0)
chk("no retired name left in observations or variables",
    length(intersect(c(gone, setdiff(retired_vars, "CO2_flux")), c(obs$variable, var$name))), 0)
chk("no variable name embeds a unit or crop token",
    length(grep("(_kg_ha|_Mg_ha|_pct|_mg_kg|_g_cm3|_t_ha|_mg_m2_d|_g_m2_d|_g_N_ha_d|^corn_|^tomato_|^wheat_|^alfalfa_|^sudangrass_|^rice_|^cover_crop_)",
                var$name)), 0)
chk("tomato red and green fruit kept apart",
    c(sum(obs$variable == "red_fruit_fresh_yield" & obs$crop == "tomato"),
      sum(obs$variable == "green_fruit_fresh_yield" & obs$crop == "tomato")), c(505, 505))
chk("before: red/green tomato rows (each incl. 30 source repeats)",
    c(sum(b_obs$variable == "tomato_red_fresh_yield_Mg_ha"), sum(b_obs$variable == "tomato_green_fresh_yield_Mg_ha")),
    c(535, 535))

cat("\n== Harvest methods\n")
rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
b_rr <- b_obs[b_obs$dataset_id == "russell_ranch_tautges_2019", ]
chk("hand_harvest and machine_harvest declared in methods.csv; field_harvest kept",
    c("hand_harvest", "machine_harvest", "field_harvest") %in% met$`method name`, c(TRUE, TRUE, TRUE))
chk("field_harvest rows after: count and datasets",
    c(sum(obs$method == "field_harvest"), paste(unique(obs$dataset_id[obs$method == "field_harvest"]), collapse = "|"),
      paste(unique(obs$variable[obs$method == "field_harvest"]), collapse = "|"),
      paste(unique(obs$crop[obs$method == "field_harvest"]), collapse = "|")),
    c(7, "ameriflux_us_twt_mvp", "grain_yield", "rice"))
yl <- rr[!grepl("^soil_", rr$variable), ]
chk("Russell yields use hand_harvest or machine_harvest only",
    paste(sort(unique(yl$method)), collapse = "|"), "hand_harvest|machine_harvest")
chk("no hand harvested wheat in observations",
    sum(rr$crop == "wheat" & rr$method == "hand_harvest"), 0)
chk("hand wheat rows before (removed to excluded_obs)",
    sum(b_obs$variable == "wheat_hh_dry_grain_yield_kg_ha"), 309)
# machine copies: before corn+wheat machine rows minus after
b_mh <- sum(b_obs$variable %in% c("corn_grain_mh_dry_yield_kg_ha", "wheat_mh_dry_grain_yield_kg_ha"))
a_mh <- sum(rr$variable == "grain_dry_yield" & rr$method == "machine_harvest")
chk("corn+wheat machine copies removed", b_mh - a_mh, 245)
chk("corn / wheat machine copies removed",
    c(sum(b_obs$variable == "corn_grain_mh_dry_yield_kg_ha") - sum(rr$variable == "grain_dry_yield" & rr$method == "machine_harvest" & rr$crop == "corn"),
      sum(b_obs$variable == "wheat_mh_dry_grain_yield_kg_ha") - sum(rr$variable == "grain_dry_yield" & rr$method == "machine_harvest" & rr$crop == "wheat")),
    c(101, 144))
tom_old <- c("tomato_red_fresh_yield_Mg_ha", "tomato_green_fresh_yield_Mg_ha", "tomato_vine_dry_yield_Mg_ha", "tomato_mh_dry_yield_Mg_ha")
tom_new <- c("red_fruit_fresh_yield", "green_fruit_fresh_yield", "vine_dry_biomass", "fruit_dry_yield")
chk("tomato rows removed (red, green, vine, machine)",
    vapply(seq_along(tom_old), function(i) sum(b_obs$variable == tom_old[i]) - sum(rr$variable == tom_new[i]), numeric(1)),
    c(30, 30, 30, 28))
chk("removed tomato rows were all on 2012-09-04",
    vapply(seq_along(tom_old), function(i) {
      a <- table(b_obs$min_date[b_obs$variable == tom_old[i]]); b <- table(rr$min_date[rr$variable == tom_new[i]])
      d <- a[names(a)] - c(b[names(a)])[seq_along(a)]; d[is.na(d)] <- a[is.na(d)]
      paste(names(d)[d != 0], collapse = "|")
    }, character(1)), rep("2012-09-04", 4))
chk("total rows removed = 309 + 245 + 118", nrow(b_obs) - nrow(obs), 309 + 245 + 118)
chk("Russell rows 20,462 -> 19,790", c(nrow(b_rr), nrow(rr)), c(20462, 19790))
other <- function(d) d[d$dataset_id != "russell_ranch_tautges_2019", ]
chk("non-Russell row count unchanged", nrow(other(obs)), nrow(other(b_obs)))
# same values per (dataset, value, unit) outside Russell: only names changed
key <- function(d) sort(paste(d$dataset_id, d$sitename, d$value, d$reported_units, d$min_date, d$treatment_id, d$replicate_id))
chk("non-Russell values, units, dates unchanged (only names moved)", identical(key(other(obs)), key(other(b_obs))), TRUE)
# values per Russell variable: multiset of values after is a subset of before
map <- c(bulk_density_g_cm3 = "soil_bulk_density", soil_nh4_n_mg_kg = "soil_ammonium_nitrogen_concentration",
         soil_no3_n_mg_kg = "soil_nitrate_nitrogen_concentration", total_carbon_pct = "soil_total_carbon_concentration",
         total_nitrogen_pct = "soil_total_nitrogen_concentration", soil_organic_matter_pct = "soil_organic_matter_concentration")
chk("Russell soil rows: identical value multiset before/after rename",
    vapply(names(map), function(o) identical(sort(b_rr$value[b_rr$variable == o]), sort(rr$value[rr$variable == map[[o]]])), logical(1)),
    rep(TRUE, length(map)))
chk("Russell units unchanged per renamed variable",
    vapply(names(map), function(o) identical(sort(unique(b_rr$reported_units[b_rr$variable == o])),
                                              sort(unique(rr$reported_units[rr$variable == map[[o]]]))), logical(1)),
    rep(TRUE, length(map)))

cat("\n== Plot labels (#274)\n")
lab <- !emp(rr$replicate_id)
chk("Russell rows with plot / without", c(sum(lab), sum(!lab)), c(12823, 6967))
chk("distinct labels / plots", c(length(unique(rr$replicate_id[lab])), length(unique(sub("[EW]$", "", rr$replicate_id[lab])))), c(195, 66))
chk("before #274 these rows had no plot (only E/W/NA)",
    paste(sort(unique(b_rr$replicate_id)), collapse = "|"), "E|NA|W")
soil_n <- rr$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration")
chk("NH4-N + NO3-N rows: none carry a plot", c(sum(soil_n), sum(lab & soil_n)), c(6964, 0))
w <- rr[!lab & !soil_n, ]
chk("the 3 other unlabelled rows",
    sort(paste(w$variable, w$crop, w$min_date, w$treatment_id)),
    sort(c(paste("soil_bulk_density", "NA", "2007-12-03", w$treatment_id[w$variable == "soil_bulk_density"]),
           paste("grain_dry_yield", "wheat", w$min_date[w$crop == "wheat"], w$treatment_id[w$crop == "wheat"]))))
print(as.data.frame(w[, c("variable", "crop", "min_date", "treatment_id", "replicate_id", "min_depth", "max_depth", "value", "notes")]))
cat("wheat years:", sort(substr(w$min_date[w$crop == "wheat"], 1, 4)), "\n")
ng <- rr$treatment_id == "native_grass" & rr$variable == "soil_bulk_density" & rr$min_date == "2012-10-08"; ngl <- rr$replicate_id[ng]
chk("native grass 2012-10-08 bulk density rows all labelled (96 of them restored from spaced source labels; see restore check), no label has spaces",
    c(sum(ng), sum(lab[ng]), sum(grepl("^\\s|\\s$", rr$replicate_id))), c(144, 144, 0))
plot <- sub("[EW]$", "", rr$replicate_id)
trt <- tapply(rr$treatment_id[lab], plot[lab], function(v) paste(sort(unique(v)), collapse = "+"))
chk("plots with >1 treatment", sort(names(trt)[grepl("\\+", trt)]), c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6"))
cat("their treatments:", unique(trt[grepl("\\+", trt)]), "\n")
iwl <- rr$treatment_id == "irr_wheat_legume" & lab & rr$min_date > "2011-12-31"
chk("rows keeping irr_wheat_legume after 2011-12-31 (total, BD 2012-10-08, tomato 2013-08-20)",
    c(sum(iwl), sum(iwl & rr$variable == "soil_bulk_density" & rr$min_date == "2012-10-08"),
      sum(iwl & rr$crop == "tomato" & rr$min_date == "2013-08-20")), c(306, 288, 18))
chk("those rows are only on the six switching plots",
    sort(unique(plot[iwl])), c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6"))
rf <- obs[obs$dataset_id == "raffeld_2024", ]
chk("raffeld_2024 labels use an underscore", all(grepl("^[1-8]_[1-9][EW]?$", rf$replicate_id)), TRUE)
chk("raffeld plots are a subset of Russell plots after normalising separator",
    length(setdiff(unique(sub("[EW]$", "", chartr("_", "-", rf$replicate_id))), unique(plot[lab]))), 0)

cat("\n== Machine yields once per plot\n")
mh <- rr[rr$method == "machine_harvest" & rr$crop %in% c("corn", "wheat") & rr$variable == "grain_dry_yield", ]
k <- paste(mh$crop, mh$treatment_id, mh$min_date, sub("[EW]$", "", mh$replicate_id))
dupl <- tapply(mh$value, k, function(v) length(v) > 1 && length(unique(v)) == 1)
chk("no plot/date with copies of one machine value", sum(dupl), 0)
chk("rows with the kept-once note", sum(grepl("once per plot|kept once|both hal", mh$notes, ignore.case = TRUE)), 244)

cat("\n== Repeats (validate)\n")
cols <- setdiff(names(obs), character(0))
d <- duplicated(obs)
chk("observation rows repeating an earlier row", sum(d), 347)
chk("all repeats in Russell", unique(obs$dataset_id[d]), "russell_ranch_tautges_2019")
tb <- table(obs$variable[d])
chk("repeat split BD/TN/NO3/TC/NH4",
    as.integer(tb[c("soil_bulk_density", "soil_total_nitrogen_concentration", "soil_nitrate_nitrogen_concentration",
                    "soil_total_carbon_concentration", "soil_ammonium_nitrogen_concentration")]), c(131, 124, 52, 27, 13))
chk("non-N repeats are on a labelled plot (303 = 347 - 65 + 21)",
    c(sum(d & !emp(obs$replicate_id)), sum(d & obs$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration"))),
    c(282, 65))

cat("\n== Depth claims in merged definitions\n")
dl <- obs[obs$variable %in% c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration") & grepl("^ameriflux_", obs$dataset_id), ]
chk("Delta total C/N rows: count, depth empty, layer in attributes_json",
    c(nrow(dl), sum(emp(dl$min_depth) & emp(dl$max_depth)),
      sum(grepl("reported_layer_top_cm", dl$attributes_json) & grepl("reported_layer_bottom_cm", dl$attributes_json))),
    c(12, 12, 12))
chk("Delta total C/N per dataset (bi1, bi2, twt)",
    as.integer(table(dl$dataset_id)[c("ameriflux_us_bi1_mvp", "ameriflux_us_bi2_mvp", "ameriflux_us_twt_mvp")]), c(6, 2, 4))
o <- obs[obs$variable %in% c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration") & !grepl("^ameriflux_", obs$dataset_id), ]
chk("other total C/N rows all have depth", sum(emp(o$min_depth) | emp(o$max_depth)), 0)
soc <- obs[obs$variable == "soil_organic_carbon_content", ]
chk("SOC stock rows with equivalent_depth_cm: raffeld / white_salinas",
    c(sum(grepl("equivalent_depth_cm", soc$attributes_json[soc$dataset_id == "raffeld_2024"])), sum(soc$dataset_id == "raffeld_2024"),
      sum(grepl("equivalent_depth_cm", soc$attributes_json[soc$dataset_id == "white_salinas_2020"]))),
    c(96, 96, 0))
chk("SOC stock rows all have min/max depth", sum(emp(soc$min_depth) | emp(soc$max_depth)), 0)
bd <- obs[obs$variable == "soil_bulk_density", ]
nod <- bd[emp(bd$min_depth) | emp(bd$max_depth), ]
chk("bulk density rows without depth", c(nrow(nod), paste(unique(nod$dataset_id), collapse = "|")), c(6, "nichols_modesto_2024"))
for (v in c("soil_organic_carbon_concentration")) {
  x <- obs[obs$variable == v, ]
  chk(paste(v, "rows all have depth (definition says so)"), sum(emp(x$min_depth) | emp(x$max_depth)), 0)
}
dd <- var$description[var$name %in% c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration")]
chk("merged total C/N definitions do not say 'dry combustion'", any(grepl("dry combustion", dd)), FALSE)

cat("\n== Carbon to bulk density pairing (docs: 76.3%, 1.1%, 12.8%)\n")
tc <- rr[rr$variable == "soil_total_carbon_concentration", ]
bdr <- rr[rr$variable == "soil_bulk_density" & !emp(rr$replicate_id), ]
yr <- function(x) substr(x, 1, 4)
k_any <- unique(paste(bdr$replicate_id, bdr$min_depth, bdr$max_depth))
k_yr <- unique(paste(bdr$replicate_id, yr(bdr$min_date), bdr$min_depth, bdr$max_depth))
k_pool <- unique(paste(sub("[EW]$", "", bdr$replicate_id), yr(bdr$min_date), bdr$min_depth, bdr$max_depth))
a_any <- sum(paste(tc$replicate_id, tc$min_depth, tc$max_depth) %in% k_any)
a_yr <- sum(paste(tc$replicate_id, yr(tc$min_date), tc$min_depth, tc$max_depth) %in% k_yr)
a_pool <- sum(paste(sub("[EW]$", "", tc$replicate_id), yr(tc$min_date), tc$min_depth, tc$max_depth) %in% k_pool)
chk("carbon rows", nrow(tc), 2180)
chk("pairs any year / same year / pooled halves",
    c(a_any, a_yr, a_pool), c(1664, 24, 279))
chk("as percentages", sprintf("%.1f%%", 100 * c(a_any, a_yr, a_pool) / nrow(tc)), c("76.3%", "1.1%", "12.8%"))

r <- do.call(rbind, res)
cat(sprintf("\n%d checks, %d pass, %d fail\n", nrow(r), sum(r$ok), sum(!r$ok)))
