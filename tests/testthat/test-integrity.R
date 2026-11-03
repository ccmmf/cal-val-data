# integrity checks on the generated data/*.csv. validate.R runs in warn mode so a
# workbook in progress still passes, but the column contract is asserted here and
# does fail: a column that silently stops being exported is the failure mode this
# repo has actually hit, and a warning would not have caught it. tables not yet
# generated are skipped, so a fresh clone passes cleanly.

root <- here::here()
dp <- jsonlite::read_json(
  file.path(root, "datapackage.json"),
  simplifyVector = FALSE
)

for (res in dp$resources) {
  local({
    resource <- res
    path <- file.path(root, resource$path)
    want <- vapply(resource$schema$fields, function(f) f$name, character(1))
    test_that(paste(resource$name, "has its datapackage columns"), {
      skip_if_not(file.exists(path), paste(resource$name, "not generated yet"))
      dat <- readr::read_csv(
        path,
        col_types = readr::cols(.default = readr::col_character()),
        name_repair = "minimal", progress = FALSE
      )
      missing <- setdiff(want, names(dat))
      expect_true(
        length(missing) == 0,
        info = paste(
          resource$name, "is missing columns:", paste(missing, collapse = ", ")
        )
      )
    })
  })
}

test_that("validate_data runs in warn mode without error", {
  paths <- file.path(root, vapply(dp$resources, function(r) r$path, character(1)))
  skip_if_not(any(file.exists(paths)), "no data generated yet")
  expect_error(validate_data(root = root), NA)
})

# ratchets on known warnings. validate.R only warns, so it cannot tell a known
# warning from a new one; these tests can. each known gap may shrink but not
# grow or spread to other rows. when a fix lands, lower the cap or make the
# test strict in the same change. README "Known warnings" gives the reasons.
resource_named <- function(name) Find(function(r) r$name == name, dp$resources)

test_that("observation repeats stay within the known Russell Ranch rows", {
  obs <- read_resource(dp, root, "observations")
  skip_if(is.null(obs), "observations not generated yet")
  dup <- repeated_rows(obs, resource_named("observations"))
  where <- "plot ids not carried over, ccmmf/organization#274"
  expect_identical(
    setdiff(unique(obs$dataset_id[dup]), "russell_ranch_tautges_2019"),
    character(0),
    info = paste("repeated observation rows outside the known set;", where)
  )
  expect_lte(sum(dup), 1188)
})

test_that("management repeats stay within the known Russell Ranch rows", {
  mg <- read_resource(dp, root, "managements")
  skip_if(is.null(mg), "managements not generated yet")
  dup <- repeated_rows(mg, resource_named("managements"))
  expect_identical(
    setdiff(unique(mg$sites.name[dup]), "russell_ranch_davis"),
    character(0),
    info = "repeated management rows outside the known set; ccmmf/organization#274"
  )
  expect_lte(sum(dup), 2195)
})

test_that("empty mgmttype stays within the known Delta rows", {
  mg <- read_resource(dp, root, "managements")
  skip_if(is.null(mg), "managements not generated yet")
  empty <- !is_present(mg$mgmttype)
  expect_true(
    all(startsWith(mg$event_id[empty], "delta-")),
    info = "mgmttype is empty outside the Delta (delta-) events"
  )
  expect_lte(sum(empty), 42)
})

test_that("duplicated DOIs in citations do not grow", {
  ct <- read_resource(dp, root, "citations")
  skip_if(is.null(ct), "citations not generated yet")
  expect_lte(length(duplicated_values(ct$doi)), 21)
})
