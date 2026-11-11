# Consumer-side checks of the committed cal-val-data CSVs on branch var-names-302.
# Reads data/*.csv at the target commit (working tree) and, for comparison, the base
# commit 5575ed2 and the parent of the target (e8837f7) straight from git (no files written).
# Run from the worktree root:  Rscript <this file>
suppressMessages(library(readr))
rd <- function(src) read_csv(src, col_types = cols(.default = col_character()),
                             na = character(), show_col_types = FALSE)
at <- function(rev, path) rd(pipe(sprintf("git show %s:%s", rev, path)))
BASE <- "5575ed2"; PARENT <- "e8837f7"
PRE <- "2da13da"  # last commit before the #302/#274 rename (a882d5f); 5575ed2..2da13da is the stacked PR #25 work
obs <- rd("data/observations.csv"); vars <- rd("data/variables.csv"); meth <- rd("data/methods.csv")
b_obs <- at(BASE, "data/observations.csv"); b_vars <- at(BASE, "data/variables.csv")
b_meth <- at(BASE, "data/methods.csv"); p_obs <- at(PARENT, "data/observations.csv")
pre_obs <- at(PRE, "data/observations.csv")
empty <- function(x) x %in% c("", "NA")
ok <- 0L; bad <- 0L
chk <- function(label, cond, detail = "") {
  if (isTRUE(cond)) { ok <<- ok + 1L; cat("PASS ", label, if (nzchar(detail)) paste0("  [", detail, "]"), "\n") }
  else { bad <<- bad + 1L; cat("FAIL ", label, if (nzchar(detail)) paste0("  [", detail, "]"), "\n") }
}
rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
b_rr <- b_obs[b_obs$dataset_id == "russell_ranch_tautges_2019", ]

cat("== 1. Table sizes ==\n")
chk("observations 37,313 -> 36,641", nrow(b_obs) == 37313 && nrow(obs) == 36641, paste(nrow(b_obs), "->", nrow(obs)))
chk("russell_ranch_tautges_2019 20,462 -> 19,790", nrow(b_rr) == 20462 && nrow(rr) == 19790, paste(nrow(b_rr), "->", nrow(rr)))
chk("variables 106 -> 88", nrow(b_vars) == 106 && nrow(vars) == 88, paste(nrow(b_vars), "->", nrow(vars)))
chk("methods 49 -> 51", nrow(b_meth) == 49 && nrow(meth) == 51, paste(nrow(b_meth), "->", nrow(meth)))
chk("every observation variable is in variables.csv", all(obs$variable %in% vars$name))
chk("CO2_flux row removed, soil_CO2_flux present", !("CO2_flux" %in% vars$name) && "soil_CO2_flux" %in% vars$name)
chk("old CO2_flux was unused by observations at base", !("CO2_flux" %in% b_obs$variable))

cat("\n== 2. Rename map (CHANGELOG) applied with values and units unchanged ==\n")
map <- c(SOC_stock_Mg_ha = "soil_organic_carbon_content", SOC_conc_mg_kg = "soil_organic_carbon_concentration",
  total_carbon_pct = "soil_total_carbon_concentration", total_C_pct = "soil_total_carbon_concentration",
  soil_carbon_content = "soil_total_carbon_concentration", total_nitrogen_pct = "soil_total_nitrogen_concentration",
  total_N_pct = "soil_total_nitrogen_concentration", total_N_conc_mg_kg = "soil_total_nitrogen_concentration",
  soil_nitrogen_content = "soil_total_nitrogen_concentration", soil_no3_n_mg_kg = "soil_nitrate_nitrogen_concentration",
  nitrate_N_mg_kg = "soil_nitrate_nitrogen_concentration", soil_nh4_n_mg_kg = "soil_ammonium_nitrogen_concentration",
  soil_organic_matter_pct = "soil_organic_matter_concentration", bulk_density_g_cm3 = "soil_bulk_density",
  corn_grain_dry_yield_kg_ha = "grain_dry_yield", corn_grain_mh_dry_yield_kg_ha = "grain_dry_yield",
  wheat_mh_dry_grain_yield_kg_ha = "grain_dry_yield", wheat_hh_dry_grain_yield_kg_ha = "(excluded)",
  rice_grain_yield_t_ha = "grain_yield", corn_total_biomass_kg_ha = "aboveground_dry_biomass",
  cover_crop_dry_biomass_kg_ha = "aboveground_dry_biomass", cover_crop_shoot_dry_matter_Mg_ha = "aboveground_dry_biomass",
  alfalfa_dry_yield_kg_ha = "harvested_dry_biomass", sudangrass_dry_yield_kg_ha = "(by year)",
  tomato_red_fresh_yield_Mg_ha = "red_fruit_fresh_yield", tomato_green_fresh_yield_Mg_ha = "green_fruit_fresh_yield",
  tomato_mh_dry_yield_Mg_ha = "fruit_dry_yield", tomato_vine_dry_yield_Mg_ha = "vine_dry_biomass",
  CO2_flux_g_m2_d = "soil_CO2_flux", CH4_flux_mg_m2_d = "CH4_flux", N2O_flux_g_N_ha_d = "N2O_flux",
  N2O_flux_mg_m2_d = "N2O_flux")
newvar <- function(d) {
  v <- ifelse(d$variable %in% names(map), map[d$variable], d$variable)
  sg <- d$variable == "sudangrass_dry_yield_kg_ha"
  v[sg] <- ifelse(substr(d$min_date[sg], 1, 4) == "1993", "harvested_dry_biomass", "aboveground_dry_biomass")
  unname(v)
}
retired <- setdiff(b_vars$name, vars$name)
chk("no observation uses a retired name", !any(obs$variable %in% retired), paste(length(retired), "retired names"))
chk("every base observation variable is mapped or kept", all(newvar(b_obs) %in% c(vars$name, "(excluded)")))
nb <- pre_obs[pre_obs$dataset_id != "russell_ranch_tautges_2019", ]; nb$variable <- newvar(nb)
nn <- obs[obs$dataset_id != "russell_ranch_tautges_2019", ]
key_all <- function(d) sort(do.call(paste, c(d[, names(d)], sep = "\x1f")))
nb <- nb[, names(nn)]
chk("non-Russell datasets: every row identical to pre-rename 2da13da apart from the renamed variable",
    identical(key_all(nb), key_all(nn)), paste(nrow(nn), "rows compared on all", ncol(nn), "columns"))
kc <- c("min_date", "max_date", "crop", "sitename", "variable", "value", "n", "treatment_id",
        "study_year", "min_depth", "max_depth", "reported_units", "observation_level", "citation")
b_rr2 <- b_rr; b_rr2$variable <- newvar(b_rr2)
kb <- do.call(paste, c(b_rr2[, kc], sep = "|")); kn <- do.call(paste, c(rr[, kc], sep = "|"))
tb <- table(kb); tn <- table(kn)
extra <- tn[!(names(tn) %in% names(tb)) | tn > tb[names(tn)]]
chk("Russell: no row invented (every new row's value/date/plot-free key exists in base)", length(extra) == 0,
    paste(length(extra), "new keys absent from base"))
gone <- tb - ifelse(names(tb) %in% names(tn), tn[names(tb)], 0)
gone <- gone[gone > 0]
chk("Russell: 672 rows removed (309 hand wheat + 245 machine copies + 118 tomato)", sum(gone) == 672, paste(sum(gone), "removed"))
gv <- sub("^([^|]*\\|){4}([^|]*)\\|.*$", "\\2", names(gone)); gc <- sub("^([^|]*\\|){2}([^|]*)\\|.*$", "\\2", names(gone))
rm_tab <- tapply(as.integer(gone), paste(gc, gv), sum); print(rm_tab)
chk("removed rows: 309 hand wheat", sum(gone[gv == "(excluded)"]) == 309)
chk("removed rows: 245 corn/wheat machine copies", sum(gone[gv == "grain_dry_yield" & gc %in% c("corn", "wheat")]) == 245)
chk("removed rows: 118 tomato", sum(gone[gc == "tomato"]) == 118)

bs <- b_obs[b_obs$dataset_id == "white_salinas_2020", ]; ps <- pre_obs[pre_obs$dataset_id == "white_salinas_2020", ]
fill <- bs$reported_units != ps$reported_units | bs$observation_level != ps$observation_level
chk("base 5575ed2 -> 2da13da (PR #25 'Fill calval metadata'): only 216 Salinas N rows gain units/level, values untouched",
    sum(fill) == 216 && all(bs$reported_units[fill] == "NA") && identical(bs$value, ps$value), paste(sum(fill), "rows"))
cat("\n== 3. Tomato red and green fresh fruit kept apart ==\n")
red <- rr[rr$variable == "red_fruit_fresh_yield", ]; grn <- rr[rr$variable == "green_fruit_fresh_yield", ]
k3 <- function(d) paste(d$crop, d$method, d$reported_units, d$replicate_id, d$min_date, d$treatment_id)
chk("both variables present, crop tomato", nrow(red) > 0 && nrow(grn) > 0 && all(c(red$crop, grn$crop) == "tomato"),
    paste(nrow(red), "red,", nrow(grn), "green"))
chk("red and green share crop, method, units, plot and date (merging would lose which is which)",
    mean(k3(red) %in% k3(grn)) > 0.9, sprintf("%.1f%% of red rows have a green twin", 100 * mean(k3(red) %in% k3(grn))))

cat("\n== 4. Sudangrass: plowed-under 2008/2009 vs 1993 hay (target commit) ==\n")
sgy <- function(d) substr(d$min_date, 1, 4)
hv <- rr[rr$variable == "harvested_dry_biomass", ]
chk("harvested_dry_biomass crops are alfalfa and sudangrass only", setequal(unique(hv$crop), c("alfalfa", "sudangrass")))
chk("harvested sudangrass is all 1993 hay (63 rows)", all(sgy(hv[hv$crop == "sudangrass", ]) == "1993") &&
      sum(hv$crop == "sudangrass") == 63, paste(sum(hv$crop == "sudangrass"), "rows"))
sg89 <- rr[rr$crop == "sudangrass" & sgy(rr) %in% c("2008", "2009"), ]
chk("24 sudangrass rows of 2008/2009, all aboveground_dry_biomass", nrow(sg89) == 24 && all(sg89$variable == "aboveground_dry_biomass"),
    paste(table(sg89$variable), collapse = ","))
chk("2008/2009 sudangrass is hand_harvest, 1993 hay is machine_harvest",
    all(sg89$method == "hand_harvest") && all(hv$method[hv$crop == "sudangrass"] == "machine_harvest"))
b_sg <- b_rr[b_rr$variable == "sudangrass_dry_yield_kg_ha", ]
n_sg <- rr[rr$crop == "sudangrass", ]
chk("sudangrass values, dates, units and treatments identical to base (87 rows, only the name moved)",
    identical(sort(paste(b_sg$value, b_sg$min_date, b_sg$reported_units, b_sg$treatment_id)),
              sort(paste(n_sg$value, n_sg$min_date, n_sg$reported_units, n_sg$treatment_id))), paste(nrow(b_sg), "vs", nrow(n_sg)))
p_sg <- p_obs[p_obs$dataset_id == "russell_ranch_tautges_2019" & p_obs$crop == "sudangrass" & sgy(p_obs) %in% c("2008", "2009"), ]
chk("adversarial: at parent e8837f7 those 24 rows were harvested_dry_biomass (the new test would have failed)",
    nrow(p_sg) == 24 && all(p_sg$variable == "harvested_dry_biomass"), paste(table(p_sg$variable), collapse = ","))
chk("Russell aboveground_dry_biomass crops", TRUE,
    paste(names(table(rr$crop[rr$variable == "aboveground_dry_biomass"])), table(rr$crop[rr$variable == "aboveground_dry_biomass"]), collapse = "; "))

cat("\n== 5. Harvest methods (David on #302) ==\n")
fh <- obs[obs$method == "field_harvest", ]
chk("field_harvest only on 7 US-Twt rice rows", nrow(fh) == 7 && all(fh$crop == "rice") && all(grepl("Twt", fh$sitename)),
    paste(nrow(fh), "rows;", paste(unique(fh$sitename), collapse = ",")))
yl <- rr[!grepl("^soil_", rr$variable), ]
chk("Russell yields use only hand_harvest/machine_harvest", all(yl$method %in% c("hand_harvest", "machine_harvest")),
    paste(names(table(yl$method)), table(yl$method), collapse = "; "))
chk("no hand harvested wheat in observations", !any(yl$crop == "wheat" & yl$method == "hand_harvest"))
chk("base had 309 hand wheat rows", sum(b_rr$variable == "wheat_hh_dry_grain_yield_kg_ha") == 309)
mhcw <- rr[rr$method == "machine_harvest" & rr$crop %in% c("corn", "wheat") & rr$variable == "grain_dry_yield", ]
half <- grepl("[EW]$", mhcw$replicate_id)
chk("machine corn+wheat grain rows: 103 of 570 are half rows (machine_harvest description: 'usually' once per plot)",
    nrow(mhcw) == 570 && sum(half) == 103, paste(sum(half), "of", nrow(mhcw)))
md <- meth$description[meth$`method name` == "machine_harvest"]
chk("machine_harvest description says 'usually' and keeps half rows where halves differ or one is given",
    grepl("usually", md) && grepl("only one half is given", md))

cat("\n== 6. replicate_id holds the plot label (#274) ==\n")
lab <- !empty(rr$replicate_id)
chk("12,823 Russell rows carry a plot, 6,967 empty", sum(lab) == 12823 && sum(!lab) == 6967, paste(sum(lab), "/", sum(!lab)))
chk("195 labels on 66 plots", length(unique(rr$replicate_id[lab])) == 195 &&
      length(unique(sub("[EW]$", "", rr$replicate_id[lab]))) == 66,
    paste(length(unique(rr$replicate_id[lab])), "labels,", length(unique(sub("[EW]$", "", rr$replicate_id[lab]))), "plots"))
chk("6,967 empty-replicate rows were empty at base too", sum(empty(b_rr$replicate_id)) >= 6967,
    paste("base empty:", sum(empty(b_rr$replicate_id)), "of", nrow(b_rr)))
sn <- rr$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration")
chk("no NH4-N or NO3-N row carries a plot", !any(lab[sn]), paste(sum(sn), "soil N rows"))
oth <- rr[!lab & !sn, ]
print(oth[, c("min_date", "crop", "variable", "treatment_id", "min_depth", "max_depth", "value")])
chk("other unlabelled rows: 1 bulk density 2007-12-03 + 2 wheat (2006, 1995)",
    nrow(oth) == 3 && sum(oth$variable == "soil_bulk_density" & oth$min_date == "2007-12-03") == 1 &&
      setequal(substr(oth$min_date[oth$crop == "wheat"], 1, 4), c("2006", "1995")))
gbd <- rr[rr$variable == "soil_bulk_density" & rr$treatment_id == "native_grass", ]
chk("native grass bulk density labels restored (all labelled)", nrow(gbd) > 0 && all(!empty(gbd$replicate_id)),
    paste(nrow(gbd), "rows"))
iwl <- rr[rr$treatment_id == "irr_wheat_legume" & rr$min_date > "2011-12-31", ]
chk("306 IWL rows after 2011-12-31 kept as documented caveat (288 BD 2012-10-08 + 18 tomato 2013-08-20)",
    nrow(iwl) == 306 && sum(iwl$variable == "soil_bulk_density" & iwl$min_date == "2012-10-08") == 288 &&
      sum(iwl$crop == "tomato" & iwl$min_date == "2013-08-20") == 18, paste(nrow(iwl), "rows"))
plot <- sub("[EW]$", "", rr$replicate_id[lab]); ntr <- tapply(rr$treatment_id[lab], plot, function(v) length(unique(v)))
chk("one treatment per plot except the 6 IWL->ACT plots", setequal(names(ntr)[ntr > 1], c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6")))

cat("\n== 7. Merged definitions match their rows ==\n")
dfn <- setNames(vars$description, vars$name)
for (v in c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration"))
  chk(paste(v, "no longer claims dry combustion"), !grepl("dry combustion", dfn[[v]]))
dl <- obs[grepl("^ameriflux_us_(bi1|bi2|twt)_mvp$", obs$dataset_id) &
            obs$variable %in% c("soil_total_carbon_concentration", "soil_total_nitrogen_concentration"), ]
chk("12 AmeriFlux Delta total C/N rows: empty depth, layer in attributes_json",
    nrow(dl) == 12 && all(empty(dl$min_depth) & empty(dl$max_depth)) &&
      all(grepl("reported_layer_top_cm", dl$attributes_json) & grepl("reported_layer_bottom_cm", dl$attributes_json)),
    paste(nrow(dl), "rows;", paste(names(table(dl$dataset_id)), table(dl$dataset_id), collapse = " ")))
mbd <- obs[obs$dataset_id == "nichols_modesto_2024" & obs$variable == "soil_bulk_density", ]
chk("6 Modesto bulk density rows have empty depth, definition allows it",
    nrow(mbd) == 6 && all(empty(mbd$min_depth)) && grepl("empty where the source does not report", dfn[["soil_bulk_density"]]))
soc <- obs[obs$variable == "soil_organic_carbon_content", ]
has_ed <- grepl("equivalent_depth_cm", soc$attributes_json)
chk("equivalent_depth_cm: raffeld_2024 yes (96), white_salinas_2020 no; definition says 'where the source reports it'",
    all(has_ed[soc$dataset_id == "raffeld_2024"]) && sum(soc$dataset_id == "raffeld_2024") == 96 &&
      !any(has_ed[soc$dataset_id == "white_salinas_2020"]) && grepl("where the source reports it", dfn[["soil_organic_carbon_content"]]))
remaining <- setdiff(unique(c(obs$variable)), "")
undocumented <- remaining[!(remaining %in% vars$name)]
chk("README Measured Variables names all exist in variables.csv", all(c("soil_organic_carbon_content",
  "soil_organic_carbon_concentration", "soil_bulk_density", "soil_total_carbon_concentration",
  "soil_total_nitrogen_concentration", "soil_nitrate_nitrogen_concentration", "N2O_flux", "CH4_flux",
  "grain_dry_yield", "aboveground_dry_biomass", "harvested_dry_biomass") %in% vars$name))

cat("\n== 8. Carbon to bulk density pairing figures in the Russell report ==\n")
cc <- rr[rr$variable == "soil_total_carbon_concentration", ]; bd <- rr[rr$variable == "soil_bulk_density" & !empty(rr$replicate_id), ]
cc$yr <- substr(cc$min_date, 1, 4); bd$yr <- substr(bd$min_date, 1, 4)
d <- function(x) paste(x$min_depth, x$max_depth)
anyyr <- paste(cc$replicate_id, d(cc)) %in% paste(bd$replicate_id, d(bd))
sameyr <- paste(cc$replicate_id, cc$yr, d(cc)) %in% paste(bd$replicate_id, bd$yr, d(bd))
pool <- function(x) sub("[EW]$", "", x)
pooled <- paste(pool(cc$replicate_id), cc$yr, d(cc)) %in% paste(pool(bd$replicate_id), bd$yr, d(bd))
cat(sprintf("carbon rows %d; any year %d (%.1f%%); same year %d (%.1f%%); pooled halves %d (%.1f%%)\n",
            nrow(cc), sum(anyyr), 100 * mean(anyyr), sum(sameyr), 100 * mean(sameyr), sum(pooled), 100 * mean(pooled)))
chk("report figures 2,180 / 1,664 (76.3%) / 24 (1.1%) / 279 (12.8%) reproduce",
    nrow(cc) == 2180 && sum(anyyr) == 1664 && sum(sameyr) == 24 && sum(pooled) == 279)

cat(sprintf("\n%d checks passed, %d failed\n", ok, bad))
