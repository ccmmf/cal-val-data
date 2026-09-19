root <- here::here()
benchmark_dir <- file.path(root, "data_raw", "statewide_benchmarking")
read_benchmark <- function(name) {
  readr::read_csv(file.path(benchmark_dir, paste0(name, ".csv")),
                 col_types = readr::cols(.default = readr::col_character()),
                 na = character(), show_col_types = FALSE)
}
selected <- read_benchmark("summarized_targets")
model <- read_benchmark("model_vs_evidence")
normalized <- read_benchmark("normalised_targets")
evidence <- read_benchmark("extracted_evidence")
assessment <- read_benchmark("evidence_assessment")
coverage <- read_benchmark("coverage")

split_ids <- function(x) unique(unlist(strsplit(x[nzchar(x)], ";", fixed = TRUE)))

test_that("target keys and evidence references are unambiguous", {
  expect_false(anyDuplicated(normalized$row_id) > 0)
  expect_false(anyDuplicated(evidence$evidence_id) > 0)
  expect_false(anyDuplicated(selected[c("practice", "outcome", "subclass")]) > 0)
  expect_false(anyDuplicated(assessment$assessment_id) > 0)
  expect_true(all(normalized$parent_evidence_id %in% evidence$evidence_id))
  expect_true(all(selected$source_id[nzchar(selected$source_id)] %in% normalized$row_id))
  expect_true(all(split_ids(assessment$evidence_ids) %in% evidence$evidence_id))
  expect_true(all(split_ids(assessment$target_row_ids) %in% normalized$row_id))
  expect_true(all(split_ids(model$assessment_ids) %in% assessment$assessment_id))
})

test_that("comparison scaffold preserves target quantity, uncertainty and use", {
  expect_identical(model[c("practice", "outcome", "subclass")],
                   selected[c("practice", "outcome", "subclass")])
  expect_identical(model$selected_row_id, selected$source_id)
  expect_identical(model$selected_value, selected$center)
  expect_identical(model$selected_spread, selected$spread)
  expect_identical(model$selected_units, selected[["scale/units"]])
  expect_identical(model$use, selected$use)
  expect_true(all(nzchar(selected$observation_operator[selected$use == "likelihood"])))
  aggregate <- selected$source_id == "Shcherbak_2014_dEFdN"
  expect_equal(as.numeric(selected$spread[aggregate]), 0.00085)
  expect_true(all(model$model_effect == "" & model$model_direction == "" & model$agreement == ""))
})

test_that("rice CH4 uncertainty is transformed on the log scale", {
  rice <- normalized[startsWith(normalized$row_id, "Jiang_2019_CH4_dry"), ]
  expected <- (log1p(as.numeric(rice$reported_upper) / 100) -
                 log1p(as.numeric(rice$reported_lower) / 100)) / 3.92
  expect_equal(as.numeric(rice$lrr_se), round(expected, 5), tolerance = 1e-8)
  expect_equal(nrow(rice), 5)
  expect_true(all(grepl("overlap", selected$note[startsWith(selected$source_id, "Jiang_2019_CH4_dry")])))
})

test_that("conditional assessments do not infer contrasts from absolute fluxes", {
  expect_true(all(assessment$direction %in%
                    c("increase", "decrease", "variable", "unresolved", "not_applicable")))
  expect_true(all(nzchar(assessment$conditions) & nzchar(assessment$comparator)))
  expect_equal(assessment$direction[assessment$assessment_id == "ap_n2o"], "unresolved")
  expect_equal(assessment$direction[assessment$assessment_id == "rt_n2o_short"], "increase")
  expect_equal(assessment$direction[assessment$assessment_id == "rt_n2o_long"], "decrease")
  expect_equal(assessment$direction[assessment$assessment_id == "rt_n2o_overall"], "unresolved")
  expect_equal(assessment$direction[assessment$assessment_id == "ap_soc_short"], "decrease")
  expect_equal(assessment$direction[assessment$assessment_id == "ap_soc_long"], "increase")
  rice <- assessment[assessment$assessment_id == "rice_n2o", ]
  expect_equal(rice$evidence_ids, "Jiang_2019_N2O_tradeoff")
  deficit <- normalized[normalized$row_id == "Li_2024_deficit_irrigation", ]
  expect_equal(deficit$practice, "Deficit irrigation")
  expect_true(all(unique(paste(selected$practice, selected$outcome)) %in%
                    paste(assessment$practice, assessment$outcome)))
})

test_that("assumed spreads and reference-only observations remain distinct", {
  assumed <- selected$source_id %in% c("Jiang_2019_N2O_tradeoff", "Siddique_2023_vs_monoculture")
  expect_true(all(selected$use[assumed] == "sign_check"))
  expect_true(all(selected$spread_type[assumed] == "assumed log-scale sensitivity spread"))
  expect_false(any(grepl("calibrated rather than arbitrary|within 5 percent|only cell with a real SE",
                         selected$note, ignore.case = TRUE)))
  expect_false(any(grepl("^(CARB|IPCC)_", selected$source_id[selected$use == "likelihood"])))
  expect_false(any(selected$source_id == "Anthony_2023_alfalfa_N2O"))
})


test_that("coverage counts and availability describe curated findings", {
  expect_equal(nrow(coverage), 18)
  expect_false(anyDuplicated(coverage[c("practice", "outcome")]) > 0)
  counts <- vapply(seq_len(nrow(coverage)), function(i) {
    sum(evidence$practice == coverage$practice[i] &
          evidence$outcome == coverage$outcome[i])
  }, integer(1))
  expect_equal(as.integer(coverage$evidence_rows), counts)
  expect_identical(coverage$evidence_availability,
                   ifelse(counts > 0, "present", "none_curated"))
  for (records in list(coverage, selected)) {
    expect_false("status" %in% names(records))
    expect_identical(records$evidence_availability,
                     ifelse(as.integer(records$evidence_rows) > 0,
                            "present", "none_curated"))
  }
  coverage_key <- paste(coverage$practice, coverage$outcome, sep = "|")
  selected_key <- paste(selected$practice, selected$outcome, sep = "|")
  expect_true(all(selected_key %in% coverage_key))
  expect_identical(selected$evidence_availability,
                   coverage$evidence_availability[match(selected_key, coverage_key)])
})
