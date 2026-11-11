root <- here::here()
read_chr <- function(path) {
  readr::read_csv(path,
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), show_col_types = FALSE)
}
# value of one key in an attributes_keyvalue string ("k=v; k=v"), NA if absent
kv <- function(x, key) {
  hit <- regmatches(x, regexpr(paste0("(^|;)\\s*", key, "=[^;]*"), x))
  out <- rep(NA_character_, length(x))
  out[grepl(paste0("(^|;)\\s*", key, "="), x)] <- sub(".*=", "", hit)
  out
}
blank <- function(x) is.na(x) | x %in% c("", "NA")

test_that("white_salinas_2020 total N and nitrate-N rows carry units and level", {
  obs_path <- file.path(root, "data", "observations.csv")
  skip_if_not(file.exists(obs_path), "observations not generated yet")
  obs <- read_chr(obs_path)
  n_rows <- obs[obs$dataset_id == "white_salinas_2020" &
                  obs$variable %in% c("soil_total_nitrogen_concentration", "soil_nitrate_nitrogen_concentration"), ]
  units <- c(soil_total_nitrogen_concentration = "mg N kg-1 soil",
             soil_nitrate_nitrogen_concentration = "mg NO3-N kg-1 soil")

  expect_equal(nrow(n_rows), 216L)
  expect_equal(as.vector(table(n_rows$variable)[names(units)]), c(108L, 108L))
  # Supplementary Table 1 prints mg kg-1 soil over both columns; the rows name
  # the element, so a blank cell or a swapped unit re-entered in the workbook fails
  expect_false(any(blank(n_rows$reported_units)))
  expect_identical(n_rows$reported_units, unname(units[n_rows$variable]))
  # block level is replicate level at this site
  expect_false(any(blank(n_rows$observation_level)))
  expect_true(all(n_rows$observation_level == "replicate"))
})

test_that("white_salinas_2020 marketed harvests carry the published harvest index", {
  mgmt_path <- file.path(root, "data", "managements.csv")
  skip_if_not(file.exists(mgmt_path), "managements not generated yet")
  mgmt <- read_chr(mgmt_path)
  sal <- mgmt[mgmt$sites.name == "salinas_socs", ]
  harv <- sal[sal$mgmttype == "harvest", ]
  attr <- harv$attributes_keyvalue
  component <- kv(attr, "harvested_component")
  hi <- kv(attr, "harvest_index")

  # White et al. (2020b) define 0.26 for romaine hearts and 0.24 for broccoli
  heart <- component %in% "heart"
  expect_equal(sum(heart), 64L)
  expect_true(all(kv(attr[heart], "crop") == "romaine_lettuce"))
  expect_true(all(hi[heart] == "0.26"))
  floret <- component %in% "floret"
  expect_equal(sum(floret), 40L)
  expect_true(all(kv(attr[floret], "crop") == "broccoli"))
  expect_true(all(hi[floret] == "0.24"))
  # the 2004 spinach and 2005 broccoli were incorporated, not harvested
  unmarketed <- kv(attr, "marketed") %in% "no"
  expect_equal(sum(unmarketed), 16L)
  expect_true(all(is.na(hi[unmarketed])))
  expect_equal(sum(!is.na(hi)), 104L)
  # a hearts harvest index on a row that says head would contradict itself
  expect_false(any(kv(sal$attributes_keyvalue, "harvested_component") %in% "head"))

  crops_path <- file.path(root, "data", "crops.csv")
  skip_if_not(file.exists(crops_path), "crops not generated yet")
  crops <- read_chr(crops_path)
  romaine <- crops$notes[crops$`common name` == "romaine lettuce"]
  expect_length(romaine, 1L)
  expect_true(startsWith(romaine, "Hearts harvested"))
})

test_that("CH4_flux and NEE declare source-reported units", {
  var_path <- file.path(root, "data", "variables.csv")
  skip_if_not(file.exists(var_path), "variables not generated yet")
  vars <- read_chr(var_path)
  # their rows mix CH4-C tower totals, CH4 mass chamber means and gC NEE, so a
  # single PEcAn unit restored in the dictionary would misdescribe them
  units <- vars$units[match(c("CH4_flux", "NEE"), vars$name)]
  expect_identical(units, c("source-reported units", "source-reported units"))
})

test_that("Russell wheat definitions match the systems and their N records", {
  trt_path <- file.path(root, "data", "treatments.csv")
  pairs_path <- file.path(root, "data", "treatment_pairs.csv")
  mgmt_path <- file.path(root, "data", "managements.csv")
  skip_if_not(all(file.exists(c(trt_path, pairs_path, mgmt_path))),
              "treatments, treatment_pairs or managements not generated yet")
  trt <- read_chr(trt_path)
  wheat <- trt[grepl("wheat", trt$name) & blank(trt$site_id), ]
  def <- setNames(wheat$definition, wheat$name)

  # every Century wheat system alternates wheat with fallow or a cover crop
  expect_true(length(def) >= 6L)
  expect_false(any(grepl("continuous", def, ignore.case = TRUE)))
  controls <- c("irr_wheat_control", "rf_wheat_control")
  expect_true(all(grepl("no N fertilizer", def[controls], fixed = TRUE)))
  expect_false(any(grepl("synthetic N", def[controls], fixed = TRUE)))
  legumes <- c("irr_wheat_legume", "rf_wheat_legume")
  expect_true(all(grepl("winter legume cover crop", def[legumes], fixed = TRUE)))

  # a definition that says no N must have no N in managements, and one that
  # says synthetic N must have some
  mgmt <- read_chr(mgmt_path)
  fert <- mgmt[mgmt$sites.name == "russell_ranch_davis" &
                 mgmt$mgmttype == "fertilization" & mgmt$units == "kg N ha-1", ]
  n_total <- function(t) sum(as.numeric(fert$level[fert$treatments.name == t]))
  no_n <- names(def)[grepl("no N fertilizer", def, fixed = TRUE)]
  with_n <- names(def)[grepl("synthetic N", def, fixed = TRUE)]
  expect_true(all(controls %in% no_n))
  expect_true(all(c("irr_wheat_fallow", "rf_wheat_fallow") %in% with_n))
  expect_true(all(vapply(no_n, n_total, numeric(1)) == 0))
  expect_true(all(vapply(with_n, n_total, numeric(1)) > 0))

  # control vs fertilized wheat-fallow is an N contrast, not a fallow one
  pairs <- read_chr(pairs_path)
  n_pairs <- pairs[pairs$pair_id %in% c("russell-6", "russell-9"), ]
  expect_equal(nrow(n_pairs), 2L)
  expect_true(all(n_pairs$comparison_factor == "synthetic_N"))
  expect_true(all(blank(n_pairs$healthy_soils_practice)))
  expect_false(any(grepl("continuous", pairs$comparison_label, ignore.case = TRUE)))
})
