# fixture tests for the warn-only checks in scripts/validate.R: repeated rows,
# duplicated DOIs, empty expected columns, and units against variables.csv.
# small hand-built tables, so each check is pinned independently of data/.

obs_res <- list(name = "observations", schema = list(fields = list()))
mgmt_res <- list(
  name = "managements",
  schema = list(primaryKey = list("event_id"), fields = list())
)
cit_res <- list(
  name = "citations",
  schema = list(primaryKey = list("citation_id"), fields = list())
)
tbl <- function(...) data.frame(..., stringsAsFactors = FALSE, check.names = FALSE)

vars <- tbl(
  name = c("soc", "ch4", "n2o", "bare"),
  units = c(
    "Mg C ha-1",
    "kg C m-2 s-1 (daily mean); kg C m-2 year-1 (annual total)",
    "source-reported units",
    NA
  )
)

test_that("an exact repeat warns once with its count; one differing cell is not a repeat", {
  obs <- tbl(
    dataset_id = c("a", "a", "a", "b"), variable = "x",
    value = c("1", "1", "2", "1"), replicate_id = NA
  )
  expect_message(
    n <- check_duplicate_rows(obs, obs_res),
    "observations has 1 row\\(s\\) repeating an earlier row in every column \\[a / x 1\\]"
  )
  expect_identical(n, 1L)
  expect_silent(n <- check_duplicate_rows(obs[-2, ], obs_res))
  expect_identical(n, 0L)
})

test_that("every copy after the first counts, and empty cells do not hide a repeat", {
  obs <- tbl(dataset_id = "a", variable = "x", value = "1", replicate_id = c(NA, NA, NA))
  expect_message(n <- check_duplicate_rows(obs, obs_res), "has 2 row\\(s\\)")
  expect_identical(n, 1L)
  expect_identical(repeated_rows(obs, obs_res), c(FALSE, TRUE, TRUE))
})

test_that("a primary key that numbers the rows does not hide a repeated record", {
  mg <- tbl(
    event_id = c("planting-0001", "planting-0002", "planting-0003"),
    sites.name = "s", mgmttype = "planting",
    min_date = c("2001-04-01", "2001-04-01", "2002-04-01")
  )
  expect_message(
    n <- check_duplicate_rows(mg, mgmt_res),
    "every column but event_id \\[s / planting 1\\]"
  )
  expect_identical(n, 1L)
})

test_that("a DOI on two citation rows warns once and names both ids", {
  ct <- tbl(
    citation_id = c("ref_10_1_ab", "smith2020", "jones2021", "lee2022", "x", "y"),
    doi = c("10.1/AB", " 10.1/ab", "10.2/cd", "10.3/ef", NA, ""),
    reference = c("long form", "short form", "a", "b", "c", "d")
  )
  expect_identical(duplicated_values(ct$doi), "10.1/ab")
  expect_message(
    n <- check_unique_values(ct, cit_res),
    "citations doi has 1 value\\(s\\) on more than one row: 10\\.1/AB \\(ref_10_1_ab = smith2020\\)"
  )
  expect_identical(n, 1L)
  # the row check cannot see this pair: the two rows differ in reference
  expect_silent(check_duplicate_rows(ct, cit_res))
  expect_silent(n <- check_unique_values(ct[-1, ], cit_res))
  expect_identical(n, 0L)
  expect_identical(check_unique_values(ct, obs_res), 0L)
})

test_that("empty observation_level, reported_units and mgmttype warn with their count and place", {
  obs <- tbl(
    dataset_id = c("a", "a", "b"), variable = c("x", "x", "y"),
    observation_level = c("replicate", NA, "  "),
    reported_units = c("kg", "kg", NA)
  )
  msgs <- capture_messages(n <- check_expected_present(obs, obs_res))
  expect_identical(n, 2L)
  expect_match(msgs, "observation_level is empty on 2 row\\(s\\) \\[a / x 1; b / y 1\\]", all = FALSE)
  expect_match(msgs, "reported_units is empty on 1 row\\(s\\) \\[b / y 1\\]", all = FALSE)
  mg <- tbl(event_id = c("e1", "e2"), sites.name = c("s1", "s2"), mgmttype = c("harvest", NA))
  expect_message(n <- check_expected_present(mg, mgmt_res), "mgmttype is empty on 1 row\\(s\\) \\[s2 1\\]")
  expect_identical(n, 1L)
  obs$observation_level <- "replicate"
  obs$reported_units <- "kg"
  expect_silent(n <- check_expected_present(obs, obs_res))
  expect_identical(n, 0L)
  expect_identical(check_expected_present(obs, list(name = "sites")), 0L)
})

test_that("unit_status follows the variables.csv conventions", {
  st <- function(v, u) unit_status(v, u, vars)
  expect_identical(st("soc", "Mg C ha-1"), "ok")
  expect_identical(st("soc", " Mg  C ha-1 "), "ok") # whitespace only
  expect_identical(st("soc", "mg C ha-1"), "conflict") # mg is not Mg
  expect_identical(st("ch4", "kg C m-2 year-1"), "ok") # qualifier optional
  expect_identical(st("ch4", "kg C m-2 s-1 (daily mean)"), "ok")
  expect_identical(st("ch4", "g C m-2 yr-1"), "conflict") # converts, but is not declared
  expect_identical(st("n2o", "g N2O m-2 y-1"), "deferred")
  expect_identical(st("n2o", NA), "missing")
  expect_identical(st("bare", "kg"), "undeclared")
  expect_identical(st("not_declared", "kg"), "unknown") # check_foreign_keys reports it
  expect_identical(
    st(c("soc", "ch4", "soc"), c("Mg C ha-1", "g C m-2 yr-1", "Mg C ha-1")),
    c("ok", "conflict", "ok")
  )
  expect_identical(st(character(0), character(0)), character(0))
})

test_that("check_units warns per conflicting variable, names method and dataset, and only informs on published mixes", {
  obs <- tbl(
    dataset_id = c("flux_a", "pub_c", "pub_a", "pub_b", "s", "s"),
    method = c("Eddy covariance", "Chamber", "Chamber", "Chamber", NA, NA),
    variable = c("ch4", "ch4", "n2o", "n2o", "soc", "soc"),
    reported_units = c(
      "g C m-2 yr-1", "mg CH4 m-2 yr-1", "mg N2O m-2 yr-1", "g N2O m-2 y-1",
      NA, "Mg C ha-1"
    )
  )
  msgs <- capture_messages(n <- check_units(obs, obs_res, vars))
  expect_identical(n, 1L) # empty units are check_expected_present's to report
  expect_match(msgs, "WARNING: observations ch4 has 2 row\\(s\\) in units variables.csv does not declare", all = FALSE)
  expect_match(
    msgs,
    "'g C m-2 yr-1' 1 \\(Eddy covariance: flux_a\\); 'mg CH4 m-2 yr-1' 1 \\(Chamber: pub_c\\)",
    all = FALSE
  )
  expect_false(any(grepl("soc", msgs)))
  info <- grep("n2o", msgs, value = TRUE)
  expect_length(info, 1)
  expect_false(grepl("WARNING", info))
  expect_match(info, "'mg N2O m-2 yr-1' 1 \\(Chamber: pub_a\\); 'g N2O m-2 y-1' 1 \\(Chamber: pub_b\\)")
  expect_identical(
    unit_tally(tbl(dataset_id = c("d1", "d2"), reported_units = c("kg", "kg"))),
    "'kg' 2 (d1, d2)"
  )
})

test_that("check_units stays quiet without the columns or the dictionary", {
  expect_identical(check_units(tbl(x = "1"), obs_res, vars), 0L)
  expect_identical(check_units(tbl(variable = "soc", reported_units = "kg"), obs_res, NULL), 0L)
  expect_silent(check_units(tbl(variable = "soc", reported_units = "Mg C ha-1"), obs_res, vars))
  expect_message(
    n <- check_units(tbl(variable = "bare", reported_units = "kg"), obs_res, vars),
    "variables.csv gives no units for 1 variable\\(s\\) used in observations: bare"
  )
  expect_identical(n, 1L)
})
