# consumer-level checks of #274 plot ids and #302 harvest curation at Russell Ranch
suppressMessages(library(readr))
rd <- function(p) read_csv(p, col_types = cols(.default = col_character()), na = character(), progress = FALSE)
tmp <- commandArgs(TRUE)[1]
bo <- rd(file.path(tmp, "base_obs.csv")); o <- rd("data/observations.csv")
say <- function(...) cat(..., "\n", sep = "")
ok <- function(label, cond) { say(if (isTRUE(cond)) "PASS  " else "FAIL  ", label); invisible(cond) }
empty <- function(x) x %in% c("", "NA")

say("== totals ==")
say("observations: base ", nrow(bo), ", target ", nrow(o), ", removed ", nrow(bo) - nrow(o))
ok("observations 37,313 -> 36,641", nrow(bo) == 37313 && nrow(o) == 36641)
rb <- bo[bo$dataset_id == "russell_ranch_tautges_2019", ]; r <- o[o$dataset_id == "russell_ranch_tautges_2019", ]
say("Russell rows: base ", nrow(rb), ", target ", nrow(r))
hw <- sum(rb$variable == "wheat_hh_dry_grain_yield_kg_ha")
say("base hand-harvested wheat rows: ", hw)

say("\n== #274 plot labels ==")
lab <- !empty(r$replicate_id)
plots <- unique(sub("[EW]$", "", r$replicate_id[lab]))
say("rows with a plot: ", sum(lab), "; empty: ", sum(!lab), "; distinct labels: ", length(unique(r$replicate_id[lab])), "; distinct plots: ", length(plots))
ok("12,823 rows carry a plot, 6,967 empty, 195 labels, 66 plots",
   sum(lab) == 12823 && sum(!lab) == 6967 && length(unique(r$replicate_id[lab])) == 195 && length(plots) == 66)
ok("every label is plot-like (1-1 .. 8-9, optional E/W)", all(grepl("^[1-8]-[1-9][EW]?$", r$replicate_id[lab])))
say("base Russell rows with a replicate_id: ", sum(!empty(rb$replicate_id)))
sn <- r$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration")
say("NH4-N/NO3-N rows: ", sum(sn), "; of them labelled: ", sum(lab & sn))
ok("ADVERSARIAL: no NH4-N or NO3-N row carries a plot", sum(sn) > 0 && !any(lab & sn))
other <- r[!lab & !sn, c("min_date", "crop", "variable", "method", "treatment_id", "value")]
say("non-NH4/NO3 rows without a plot:"); print(as.data.frame(other), row.names = FALSE)
ok("exactly 3 withheld: 1 bulk density 2007-12-03, wheat 1995 and 2006",
   nrow(other) == 3 &&
   sum(other$variable == "soil_bulk_density" & other$min_date == "2007-12-03") == 1 &&
   setequal(substr(other$min_date[other$crop == "wheat"], 1, 4), c("1995", "2006")))
ng <- r[grepl("native|grass", r$treatment_id, ignore.case = TRUE) & r$variable == "soil_bulk_density", ]
say("native grass treatments: ", paste(unique(ng$treatment_id), collapse = ","), "; bulk density rows ", nrow(ng), ", labelled ", sum(!empty(ng$replicate_id)))
ok("native grass bulk density labels restored (none withheld)", nrow(ng) > 0 && all(!empty(ng$replicate_id)))
six <- c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6")
iw <- r[lab & sub("[EW]$", "", r$replicate_id) %in% six & r$treatment_id == "irr_wheat_legume" & r$min_date > "2011-12-31", ]
say("rows on the six converted plots still irr_wheat_legume after 2011-12-31: ", nrow(iw)); print(table(paste(iw$variable, iw$min_date)))
ok("documented caveat: 306 rows (288 bulk density 2012-10-08, 18 tomato 2013-08-20) left as irr_wheat_legume",
   nrow(iw) == 306 && sum(iw$variable == "soil_bulk_density" & iw$min_date == "2012-10-08") == 288 &&
   sum(iw$crop == "tomato" & iw$min_date == "2013-08-20") == 18)

say("\n== #302 harvest methods ==")
y <- r[!grepl("^soil_", r$variable), ]
print(table(paste(y$variable, y$crop), y$method))
ok("Russell yields use only hand_harvest or machine_harvest", all(y$method %in% c("hand_harvest", "machine_harvest")))
fh <- o[o$method == "field_harvest", ]
say("field_harvest rows: ", nrow(fh), " (", paste(unique(paste(fh$dataset_id, fh$crop, fh$variable)), collapse = "; "), ")")
ok("field_harvest stays only on 7 US-Twt rice rows", nrow(fh) == 7 && all(fh$dataset_id == "ameriflux_us_twt_mvp") && all(fh$crop == "rice"))
ok("ADVERSARIAL: no hand-harvested wheat in observations", !any(y$crop == "wheat" & y$method == "hand_harvest"))
ok("309 base hand-harvested wheat rows", hw == 309)
mh <- y[y$method == "machine_harvest" & y$crop %in% c("corn", "wheat") & y$variable == "grain_dry_yield", ]
bm <- sum(rb$variable %in% c("corn_grain_mh_dry_yield_kg_ha", "wheat_mh_dry_grain_yield_kg_ha"))
half <- grepl("[EW]$", mh$replicate_id)
say("corn+wheat machine grain rows: base ", bm, ", target ", nrow(mh), " (removed ", bm - nrow(mh), "); half-labelled ", sum(half), " (corn ", sum(half & mh$crop == "corn"), ", wheat ", sum(half & mh$crop == "wheat"), ")")
ok("245 machine copies removed; 570 rows remain, 103 half rows", bm - nrow(mh) == 245 && nrow(mh) == 570 && sum(half) == 103)
key <- paste(mh$crop, mh$treatment_id, mh$min_date, sub("[EW]$", "", mh$replicate_id))
cp <- tapply(mh$value, key, function(v) length(v) > 1 && length(unique(v)) == 1)
ok("ADVERSARIAL: no plot-date keeps two identical machine values (copy on both halves)", !any(cp))
tb <- sum(rb$crop == "tomato"); tt <- sum(r$crop == "tomato")
say("tomato rows: base ", tb, ", target ", tt, " (removed ", tb - tt, ")")
ok("118 repeated tomato rows removed", tb - tt == 118)
ok("removals add up: 309 + 245 + 118 = 672 = Russell rows dropped", nrow(rb) - nrow(r) == 672 && 309 + 245 + 118 == 672)

say("\n== sudangrass and harvested_dry_biomass ==")
hv <- r[r$variable == "harvested_dry_biomass", ]
print(table(hv$crop, substr(hv$min_date, 1, 4)))
sg <- r[r$crop == "sudangrass", ]; print(table(sg$variable, substr(sg$min_date, 1, 4)))
ok("2008 and 2009 sudangrass (24 rows) are aboveground_dry_biomass", sum(sg$variable == "aboveground_dry_biomass" & substr(sg$min_date, 1, 4) %in% c("2008", "2009")) == 24 &&
   !any(sg$variable == "harvested_dry_biomass" & substr(sg$min_date, 1, 4) %in% c("2008", "2009")))
ok("harvested_dry_biomass holds only alfalfa cuttings and 1993 sudangrass hay",
   setequal(unique(hv$crop), c("alfalfa", "sudangrass")) && all(substr(hv$min_date[hv$crop == "sudangrass"], 1, 4) == "1993"))
