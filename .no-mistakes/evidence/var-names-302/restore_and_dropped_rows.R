args <- commandArgs(trailingOnly = TRUE); d <- args[1]
rd <- function(p) read.csv(p, colClasses = "character", na.strings = character(), check.names = FALSE)
empty <- function(x) x %in% c("", "NA")
a <- rd(file.path(d, "pre_restore_obs.csv")); b <- rd(file.path(d, "restore_obs.csv")); cur <- rd("data/observations.csv")
cat("== S6 restore commit ca63889: rows going from empty replicate_id to a label\n")
stopifnot(nrow(a) == nrow(b))
cols <- setdiff(names(a), "replicate_id")
same_other <- all(do.call(paste, a[cols]) == do.call(paste, b[cols]))
cat("row order and all other columns identical across the restore:", same_other, "\n")
ch <- which(a$replicate_id != b$replicate_id)
cat("rows whose replicate_id changed:", length(ch), "\n")
print(table(from_empty = empty(a$replicate_id[ch]), b$treatment_id[ch], b$variable[ch], b$min_date[ch]))
cat("restored labels:", paste(sort(unique(b$replicate_id[ch])), collapse = " "), "\n")
cat("any space in a label now:", any(grepl(" ", cur$replicate_id)), "\n")
ng <- cur[cur$dataset_id == "russell_ranch_tautges_2019" & cur$treatment_id == "native_grass" & cur$variable == "soil_bulk_density", ]
cat("native grass BD rows now:", nrow(ng), "labelled:", sum(!empty(ng$replicate_id)), "\n")
cat("restore commit observations identical to HEAD:", identical(b, cur), "\n")

cat("== S8b dropped rows by category (method included in the match)\n")
old <- rd(file.path(d, "old_obs.csv"))
src <- old$variable
map <- c(corn_grain_dry_yield_kg_ha="grain_dry_yield", corn_grain_mh_dry_yield_kg_ha="grain_dry_yield",
 wheat_mh_dry_grain_yield_kg_ha="grain_dry_yield", wheat_hh_dry_grain_yield_kg_ha="grain_dry_yield",
 corn_total_biomass_kg_ha="aboveground_dry_biomass", cover_crop_dry_biomass_kg_ha="aboveground_dry_biomass",
 alfalfa_dry_yield_kg_ha="harvested_dry_biomass", sudangrass_dry_yield_kg_ha="harvested_dry_biomass",
 tomato_red_fresh_yield_Mg_ha="red_fruit_fresh_yield", tomato_green_fresh_yield_Mg_ha="green_fruit_fresh_yield",
 tomato_mh_dry_yield_Mg_ha="fruit_dry_yield", tomato_vine_dry_yield_Mg_ha="vine_dry_biomass")
rr <- old$dataset_id == "russell_ranch_tautges_2019" & src %in% names(map)
cat("old Russell yield methods:", paste(unique(old$method[rr]), collapse=","), "\n")
old$method[rr] <- ifelse(grepl("_mh_", src[rr]) | (src[rr] == "sudangrass_dry_yield_kg_ha" & substr(old$min_date[rr],1,4) == "1993"),
                         "machine_harvest", "hand_harvest")
cols <- c("min_date","max_date","crop","sitename","method","value","n","treatment_id","study_year","min_depth","max_depth","citation","dataset_id","reported_units","observation_level")
ko <- paste(src, do.call(paste, c(old[cols], sep="\r")))
newname <- ifelse(src %in% names(map), map[src], src)
ko2 <- do.call(paste, c(list(newname), old[cols], sep="\r"))
kn <- do.call(paste, c(list(cur$variable), cur[cols], sep="\r"))
# drop count per key, attributed to the old variable name
to <- table(ko2); tn <- table(kn)
k <- names(to); dropn <- as.integer(to) - ifelse(is.na(tn[k]), 0L, as.integer(tn[k]))
cat("new rows with no old counterpart (method included):", sum(!(names(tn) %in% names(to))), "\n")
cat("keys where new has more copies than old:", sum(dropn < 0), "\n")
first_src <- src[match(k, ko2)]
dd <- tapply(pmax(dropn, 0), first_src, sum); dd <- dd[dd > 0]
print(dd); cat("total dropped:", sum(dd), "\n")
cat("== S8c yields only (method derived from old name included in match)\n")
yv <- c("grain_dry_yield","aboveground_dry_biomass","harvested_dry_biomass","red_fruit_fresh_yield","green_fruit_fresh_yield","fruit_dry_yield","vine_dry_biomass")
oy <- rr; ny <- cur$dataset_id == "russell_ranch_tautges_2019" & cur$variable %in% yv
to <- table(ko2[oy]); tn <- table(kn[ny])
cat("old Russell yield rows:", sum(oy), " new:", sum(ny), "\n")
cat("new yield rows with no old counterpart (variable, method, value, date, treatment...):", sum(pmax(as.integer(tn) - ifelse(is.na(to[names(tn)]), 0L, as.integer(to[names(tn)])), 0)), "\n")
k <- names(to); dropn <- as.integer(to) - ifelse(is.na(tn[k]), 0L, as.integer(tn[k]))
dd <- tapply(pmax(dropn, 0), src[oy][match(k, ko2[oy])], sum); print(dd[dd > 0]); cat("total yield rows dropped:", sum(dd), "\n")
