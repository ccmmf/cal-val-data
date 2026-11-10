# Consumer-side checks of the committed cal-val-data snapshot against the
# #302 / #274 intent. Run from the repo root: Rscript /tmp/.../check.R <olddir>
args <- commandArgs(trailingOnly = TRUE)
old_dir <- args[1]
rd <- function(p) read.csv(p, colClasses = "character", na.strings = character(),
                          check.names = FALSE)
obs <- rd("data/observations.csv")
vars <- rd("data/variables.csv")
meth <- rd("data/methods.csv")
old <- rd(file.path(old_dir, "old_obs.csv"))
old_vars <- rd(file.path(old_dir, "old_vars.csv"))
old_meth <- rd(file.path(old_dir, "old_methods.csv"))

results <- list()
check <- function(name, ok, detail = "") {
  results[[length(results) + 1]] <<- data.frame(check = name, ok = isTRUE(ok), detail = detail)
  cat(sprintf("[%s] %s %s\n", if (isTRUE(ok)) "PASS" else "FAIL", name, detail))
}
empty <- function(x) x %in% c("", "NA")

cat("== S1 table sizes\n")
check("observations 37,313 -> 36,641", nrow(old) == 37313 && nrow(obs) == 36641,
      paste(nrow(old), "->", nrow(obs)))
rr_old <- old[old$dataset_id == "russell_ranch_tautges_2019", ]
rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
check("russell_ranch_tautges_2019 20,462 -> 19,790", nrow(rr_old) == 20462 && nrow(rr) == 19790,
      paste(nrow(rr_old), "->", nrow(rr)))
check("variables 106 -> 88", nrow(old_vars) == 106 && nrow(vars) == 88,
      paste(nrow(old_vars), "->", nrow(vars)))
check("methods 49 -> 51 (hand_harvest, machine_harvest added)",
      nrow(old_meth) == 49 && nrow(meth) == 51 &&
        setequal(setdiff(meth$`method name`, old_meth$`method name`), c("hand_harvest", "machine_harvest")),
      paste(nrow(old_meth), "->", nrow(meth)))

cat("== S2 one name per quantity\n")
gone <- setdiff(old_vars$name, vars$name)
added <- setdiff(vars$name, old_vars$name)
cat("retired names:", length(gone), "\n"); print(sort(gone))
cat("new names:", length(added), "\n"); print(sort(added))
check("CO2_flux removed, soil_CO2_flux present",
      !"CO2_flux" %in% vars$name && "soil_CO2_flux" %in% vars$name &&
        any(obs$variable == "soil_CO2_flux"))
check("old CO2_flux had no observation rows (unused duplicate)", !any(old$variable == "CO2_flux"))
check("no retired name left in observations", length(intersect(gone, unique(obs$variable))) == 0)
check("every observation variable is declared in variables.csv", all(obs$variable %in% vars$name),
      paste(setdiff(unique(obs$variable), vars$name), collapse = ","))
check("no variable name embeds a unit or crop token",
      !any(grepl("_(kg|Mg|g|mg|t)_(ha|m2|kg)|_pct$|_g_cm3$|^(corn|wheat|tomato|rice|alfalfa|sudangrass|cover_crop)_", vars$name)),
      paste(grep("_(kg|Mg|g|mg|t)_(ha|m2|kg)|_pct$|_g_cm3$|^(corn|wheat|tomato|rice|alfalfa|sudangrass|cover_crop)_", vars$name, value = TRUE), collapse = ","))
tom <- obs[obs$crop == "tomato", ]
check("tomato red and green fresh fruit kept apart",
      all(c("red_fruit_fresh_yield", "green_fruit_fresh_yield") %in% tom$variable) &&
        sum(tom$variable == "red_fruit_fresh_yield") == 505 && sum(tom$variable == "green_fruit_fresh_yield") == 505,
      paste(sum(tom$variable == "red_fruit_fresh_yield"), sum(tom$variable == "green_fruit_fresh_yield")))

cat("== S3 harvest methods\n")
yld <- rr[!grepl("^soil_", rr$variable), ]
check("Russell yields use only hand_harvest / machine_harvest",
      all(yld$method %in% c("hand_harvest", "machine_harvest")), paste(unique(yld$method), collapse = ","))
fh <- obs[obs$method == "field_harvest", ]
check("field_harvest stays only on 7 US-Twt rice rows",
      nrow(fh) == 7 && all(fh$crop == "rice") && all(fh$dataset_id == "ameriflux_us_twt_mvp"),
      paste(nrow(fh), paste(unique(fh$crop), collapse = ","), paste(unique(fh$dataset_id), collapse = ",")))
check("no hand harvested wheat left in observations",
      !any(obs$crop == "wheat" & obs$method == "hand_harvest"))
check("309 hand wheat rows existed before",
      sum(old$variable == "wheat_hh_dry_grain_yield_kg_ha") == 309)

cat("== S4 plot labels (#274)\n")
lab <- !empty(rr$replicate_id)
plots <- unique(sub("[EW]$", "", rr$replicate_id[lab]))
check("12,823 labelled, 6,967 empty", sum(lab) == 12823 && sum(!lab) == 6967, paste(sum(lab), sum(!lab)))
check("195 labels on 66 plots", length(unique(rr$replicate_id[lab])) == 195 && length(plots) == 66,
      paste(length(unique(rr$replicate_id[lab])), length(plots)))
check("labels are trimmed and well formed", all(grepl("^[1-8]-[1-9][EW]?$", rr$replicate_id[lab])))
soil_n <- rr$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration")
check("no NH4-N or NO3-N row carries a plot (6,964 rows)", sum(soil_n) == 6964 && !any(lab[soil_n]),
      paste(sum(soil_n), sum(lab[soil_n])))
other <- rr[!lab & !soil_n, c("variable", "crop", "min_date", "treatment_id", "method", "value", "min_depth", "max_depth")]
print(other)
check("the 3 other unlabelled rows: 1 BD 2007-12-03, wheat 2006 and wheat 1995",
      nrow(other) == 3 &&
        sum(other$variable == "soil_bulk_density" & other$min_date == "2007-12-03") == 1 &&
        sum(other$crop == "wheat" & substr(other$min_date, 1, 4) == "2006") == 1 &&
        sum(other$crop == "wheat" & substr(other$min_date, 1, 4) == "1995") == 1)
# old replicate half preserved: rows labelled before only as E / W / NA
check("old replicate_id held only the half (E, W, NA)",
      all(rr_old$replicate_id %in% c("E", "W", "", "NA")), paste(unique(rr_old$replicate_id), collapse = ","))

cat("== S5 one treatment per plot except the six IWL plots\n")
pl <- sub("[EW]$", "", rr$replicate_id[lab])
n_trt <- tapply(rr$treatment_id[lab], pl, function(v) length(unique(v)))
multi <- names(n_trt)[n_trt > 1]
check("only 4-7, 4-8, 5-1, 5-2, 7-5, 7-6 change treatment",
      setequal(multi, c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6")), paste(multi, collapse = ","))
iwl6 <- rr[lab & sub("[EW]$", "", rr$replicate_id) %in% c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6"), ]
print(table(iwl6$treatment_id, substr(iwl6$min_date, 1, 4) > "2011"))
late <- iwl6[iwl6$treatment_id == "irr_wheat_legume" & iwl6$min_date > "2011-12-31", ]
check("306 rows keep irr_wheat_legume after 2011-12-31 (288 BD 2012-10-08, 18 tomato 2013-08-20)",
      nrow(late) == 306 &&
        sum(late$variable == "soil_bulk_density" & late$min_date == "2012-10-08") == 288 &&
        sum(late$crop == "tomato" & late$min_date == "2013-08-20") == 18,
      paste(nrow(late), sum(late$variable == "soil_bulk_density" & late$min_date == "2012-10-08"),
            sum(late$crop == "tomato" & late$min_date == "2013-08-20")))
# independent source: raffeld_2024 (Raffeld et al. 2024 Dryad deposit) names plot -> treatment
rf <- obs[obs$dataset_id == "raffeld_2024", ]
rf_map <- unique(data.frame(plot = gsub("_", "-", sub("[EW]$", "", rf$replicate_id)), trt = rf$treatment_id))
rr_map <- unique(data.frame(plot = pl, trt = rr$treatment_id[lab], yr = substr(rr$min_date[lab], 1, 4)))
rr_pre2012 <- unique(rr_map[rr_map$yr < "2012", c("plot", "trt")])
cmp <- merge(rf_map, rr_pre2012, by = "plot", suffixes = c("_raffeld", "_russell"))
mism <- cmp[cmp$trt_raffeld != cmp$trt_russell, ]
cat("plots shared with raffeld_2024:", length(unique(cmp$plot)), "\n")
print(mism)
check("Russell plot -> treatment agrees with raffeld_2024 on every shared plot (pre-2012 rows)",
      nrow(mism) == 0 && length(unique(cmp$plot)) > 0, paste(length(unique(cmp$plot)), "plots compared"))

cat("== S6 native grass bulk density labels restored\n")
ng <- rr[rr$treatment_id == "native_grass" & rr$variable == "soil_bulk_density" & rr$min_date == "2012-10-08", ]
# 96 of these 144 were the space-padded source labels restored in ca63889 (see restore_and_dropped_rows.txt)
check("every native grass BD row of 2012-10-08 (144, incl. the 96 restored) carries a trimmed plot label",
      nrow(ng) == 144 && all(grepl("^[1-8]-[1-9][EW]?$", ng$replicate_id)),
      paste(nrow(ng), sum(grepl("^[1-8]-[1-9][EW]?$", ng$replicate_id))))
bd <- rr[rr$variable == "soil_bulk_density", ]
check("4,451 of 4,452 Russell BD rows labelled",
      nrow(bd) == 4452 && sum(!empty(bd$replicate_id)) == 4451, paste(sum(!empty(bd$replicate_id)), "/", nrow(bd)))

cat("== S7 machine yields once per plot, tomato source repeats removed\n")
mh <- rr[rr$method == "machine_harvest" & rr$crop %in% c("corn", "wheat"), ]
base <- sub("[EW]$", "", mh$replicate_id)
key <- paste(mh$variable, mh$crop, mh$treatment_id, mh$min_date, base)
copies <- tapply(mh$value, key, function(v) length(v) > 1 && length(unique(v)) == 1)
check("no corn/wheat machine yield copied across a plot's halves", !any(copies & !grepl(" $", names(copies))))
t12 <- rr[rr$crop == "tomato" & rr$min_date == "2012-09-04", ]
k12 <- paste(t12$variable, t12$replicate_id, t12$value, t12$treatment_id)
check("2012-09-04 tomato lines no longer listed twice", !any(duplicated(k12)),
      paste(nrow(t12), "rows,", sum(duplicated(k12)), "dups"))

cat("== S8 values and units unchanged (old snapshot vs new)\n")
vmap <- c(
  SOC_stock_Mg_ha = "soil_organic_carbon_content", SOC_conc_mg_kg = "soil_organic_carbon_concentration",
  total_carbon_pct = "soil_total_carbon_concentration", total_C_pct = "soil_total_carbon_concentration",
  soil_carbon_content = "soil_total_carbon_concentration",
  total_nitrogen_pct = "soil_total_nitrogen_concentration", total_N_pct = "soil_total_nitrogen_concentration",
  total_N_conc_mg_kg = "soil_total_nitrogen_concentration", soil_nitrogen_content = "soil_total_nitrogen_concentration",
  soil_no3_n_mg_kg = "soil_nitrate_nitrogen_concentration", nitrate_N_mg_kg = "soil_nitrate_nitrogen_concentration",
  soil_nh4_n_mg_kg = "soil_ammonium_nitrogen_concentration", soil_organic_matter_pct = "soil_organic_matter_concentration",
  bulk_density_g_cm3 = "soil_bulk_density",
  corn_grain_dry_yield_kg_ha = "grain_dry_yield", corn_grain_mh_dry_yield_kg_ha = "grain_dry_yield",
  wheat_mh_dry_grain_yield_kg_ha = "grain_dry_yield", wheat_hh_dry_grain_yield_kg_ha = "grain_dry_yield",
  rice_grain_yield_t_ha = "grain_yield",
  corn_total_biomass_kg_ha = "aboveground_dry_biomass", cover_crop_dry_biomass_kg_ha = "aboveground_dry_biomass",
  cover_crop_shoot_dry_matter_Mg_ha = "aboveground_dry_biomass",
  alfalfa_dry_yield_kg_ha = "harvested_dry_biomass", sudangrass_dry_yield_kg_ha = "harvested_dry_biomass",
  tomato_red_fresh_yield_Mg_ha = "red_fruit_fresh_yield", tomato_green_fresh_yield_Mg_ha = "green_fruit_fresh_yield",
  tomato_mh_dry_yield_Mg_ha = "fruit_dry_yield", tomato_vine_dry_yield_Mg_ha = "vine_dry_biomass",
  CO2_flux_g_m2_d = "soil_CO2_flux", CH4_flux_mg_m2_d = "CH4_flux",
  N2O_flux_g_N_ha_d = "N2O_flux", N2O_flux_mg_m2_d = "N2O_flux"
)
check("map covers every retired name with observation rows",
      all(intersect(gone, unique(old$variable)) %in% names(vmap)),
      paste(setdiff(intersect(gone, unique(old$variable)), names(vmap)), collapse = ","))
old2 <- old
hit <- old2$variable %in% names(vmap)
old2$variable[hit] <- vmap[old2$variable[hit]]
cols <- setdiff(names(obs), c("method", "replicate_id", "notes"))
check("same columns before and after", setequal(names(old), names(obs)),
      paste(setdiff(union(names(old), names(obs)), intersect(names(old), names(obs))), collapse = ","))
ko <- do.call(paste, c(old2[cols], sep = "\r"))
kn <- do.call(paste, c(obs[cols], sep = "\r"))
# multiset difference
tab_o <- table(ko); tab_n <- table(kn)
allk <- union(names(tab_o), names(tab_n))
co <- as.integer(tab_o[allk]); co[is.na(co)] <- 0L
cn <- as.integer(tab_n[allk]); cn[is.na(cn)] <- 0L
only_new <- sum(pmax(cn - co, 0)); only_old <- sum(pmax(co - cn, 0))
check("no observation row is new (every new row matches an old row on all value columns)", only_new == 0,
      paste(only_new, "new-only rows"))
check("exactly 672 old rows dropped (309 hand wheat + 245 machine copies + 118 tomato repeats)",
      only_old == 672, paste(only_old, "old-only rows"))
dk <- allk[co > cn]
dropped <- old2[ko %in% dk, ]
dropped_ct <- table(paste(old$variable[ko %in% dk]))
print(dropped_ct)
check("dropped rows are all Russell Ranch", all(dropped$dataset_id == "russell_ranch_tautges_2019"))
# units unchanged per renamed variable
u_old <- unique(paste(old2$variable, old2$reported_units))
u_new <- unique(paste(obs$variable, obs$reported_units))
check("no new (variable, reported_units) pair introduced", length(setdiff(u_new, u_old)) == 0,
      paste(setdiff(u_new, u_old), collapse = "; "))

cat("== S9 carbon / bulk density pairing figures in the docs\n")
cc <- rr[rr$variable == "soil_total_carbon_concentration", ]
bb <- rr[rr$variable == "soil_bulk_density" & !empty(rr$replicate_id), ]
yr <- function(d) substr(d$min_date, 1, 4)
k_any <- function(d, plot) paste(plot, d$min_depth, d$max_depth)
any_yr <- k_any(cc, cc$replicate_id) %in% k_any(bb, bb$replicate_id) & !empty(cc$replicate_id)
same_yr <- paste(cc$replicate_id, yr(cc), cc$min_depth, cc$max_depth) %in%
  paste(bb$replicate_id, yr(bb), bb$min_depth, bb$max_depth) & !empty(cc$replicate_id)
pooled <- paste(sub("[EW]$", "", cc$replicate_id), yr(cc), cc$min_depth, cc$max_depth) %in%
  paste(sub("[EW]$", "", bb$replicate_id), yr(bb), bb$min_depth, bb$max_depth) & !empty(cc$replicate_id)
f <- function(x) sprintf("%d (%.1f%%)", sum(x), 100 * mean(x))
cat("carbon rows:", nrow(cc), " any year:", f(any_yr), " same year:", f(same_yr), " halves pooled:", f(pooled), "\n")
check("pairing: any year 1,664 (76.3%)", sum(any_yr) == 1664 && nrow(cc) == 2180, f(any_yr))
check("pairing: same year 24 (1.1%)", sum(same_yr) == 24, f(same_yr))
check("pairing: halves pooled 279 (12.8%)", sum(pooled) == 279, f(pooled))
check("pooled pairs only in 2003 and 2012", setequal(unique(yr(cc)[pooled]), c("2003", "2012")),
      paste(unique(yr(cc)[pooled]), collapse = ","))

res <- do.call(rbind, results)
cat("\n", sum(res$ok), "of", nrow(res), "checks pass\n")
write.csv(res, file.path(old_dir, "check_results.csv"), row.names = FALSE)
