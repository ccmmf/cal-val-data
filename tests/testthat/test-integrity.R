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
