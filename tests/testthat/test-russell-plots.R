# Russell Ranch observations after organization#274 and #302: rows name their Century
# Experiment plot where the source is consistent about it, hand and machine harvest are methods of one quantity, the hand harvested
# wheat is left out, and a machine yield the source gives once per plot is kept once.
root <- here::here()
read_chr <- function(path) {
  readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                  na = character(), show_col_types = FALSE)
}
obs_path <- file.path(root, "data", "observations.csv")

test_that("Russell Ranch rows carry the source plot label where the source is consistent", {
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
  lab <- !(rr$replicate_id %in% c("", "NA"))   # write_csv writes an empty cell as NA
  # 1-1 to 8-9, then E or W for a half; no suffix for the whole plot
  expect_true(all(grepl("^[1-8]-[1-9][EW]?$", rr$replicate_id[lab])))
  # the source's N file gives a plot and a system that disagree on 2,727 of 3,484 lines,
  # so no NH4-N or NO3-N row takes a plot
  soil_n <- rr$variable %in% c("soil_ammonium_nitrogen_concentration", "soil_nitrate_nitrogen_concentration")
  expect_false(any(lab[soil_n]))
  # every other row has its plot, except 1 bulk density and 2 wheat lines whose plot and system disagree
  expect_equal(sum(!lab[!soil_n]), 3L)
  # one treatment per plot, apart from the six Irrigated Wheat/Legume plots that became
  # Alfalfa/Corn/Tomato in 2012
  plot <- sub("[EW]$", "", rr$replicate_id[lab])
  n_trt <- tapply(rr$treatment_id[lab], plot, function(v) length(unique(v)))
  expect_setequal(names(n_trt)[n_trt > 1], c("4-7", "4-8", "5-1", "5-2", "7-5", "7-6"))
})

test_that("old variable names are gone", {
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  retired <- c(
    "corn_grain_dry_yield_kg_ha", "corn_grain_mh_dry_yield_kg_ha", "wheat_hh_dry_grain_yield_kg_ha",
    "wheat_mh_dry_grain_yield_kg_ha", "rice_grain_yield_t_ha", "corn_total_biomass_kg_ha",
    "cover_crop_dry_biomass_kg_ha", "cover_crop_shoot_dry_matter_Mg_ha", "alfalfa_dry_yield_kg_ha",
    "sudangrass_dry_yield_kg_ha", "tomato_red_fresh_yield_Mg_ha", "tomato_green_fresh_yield_Mg_ha",
    "tomato_mh_dry_yield_Mg_ha", "tomato_vine_dry_yield_Mg_ha", "SOC_stock_Mg_ha", "SOC_conc_mg_kg",
    "total_carbon_pct", "total_C_pct", "soil_carbon_content", "total_nitrogen_pct", "total_N_pct",
    "total_N_conc_mg_kg", "soil_nitrogen_content", "soil_no3_n_mg_kg", "nitrate_N_mg_kg",
    "soil_nh4_n_mg_kg", "soil_organic_matter_pct", "bulk_density_g_cm3", "CH4_flux_mg_m2_d",
    "N2O_flux_g_N_ha_d", "N2O_flux_mg_m2_d", "CO2_flux_g_m2_d"
  )
  expect_identical(intersect(unique(obs$variable), retired), character(0))
})

test_that("Russell Ranch yields name their harvest method and leave hand wheat out", {
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
  yields <- rr[!grepl("^soil_", rr$variable), ]
  expect_true(all(yields$method %in% c("hand_harvest", "machine_harvest")))
  # hand harvested wheat "grain" looks like whole plant biomass (organization#302)
  wheat <- yields[yields$crop == "wheat", ]
  expect_true(all(wheat$method == "machine_harvest"))
  methods <- read_chr(file.path(root, "data", "methods.csv"))
  expect_true(all(c("hand_harvest", "machine_harvest") %in% methods$`method name`))
})

test_that("harvested_dry_biomass holds only biomass taken off the field", {
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  rr <- obs[obs$dataset_id == "russell_ranch_tautges_2019", ]
  hv <- rr[rr$variable == "harvested_dry_biomass", ]
  # alfalfa cuttings and the 1993 sudangrass hay; the 2008 and 2009 sudangrass was plowed under
  expect_setequal(unique(hv$crop), c("alfalfa", "sudangrass"))
  expect_true(all(substr(hv$min_date[hv$crop == "sudangrass"], 1, 4) == "1993"))
  sg <- rr[rr$crop == "sudangrass" & substr(rr$min_date, 1, 4) %in% c("2008", "2009"), ]
  expect_equal(nrow(sg), 24L)
  expect_true(all(sg$variable == "aboveground_dry_biomass"))
})

test_that("a machine yield copied onto both halves of a plot is kept once", {
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  mh <- obs[obs$dataset_id == "russell_ranch_tautges_2019" & obs$method == "machine_harvest" &
              obs$crop %in% c("corn", "wheat"), ]
  base <- sub("[EW]$", "", mh$replicate_id)
  key <- paste(mh$variable, mh$crop, mh$treatment_id, mh$min_date, base)
  # a plot and date with more than one row must carry different values (true per half yields)
  copies <- tapply(mh$value, key, function(v) length(v) > 1 && length(unique(v)) == 1)
  expect_false(any(copies))
})
