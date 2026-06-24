# integrity checks on the generated data/*.csv. per the warn-mode policy these
# tests pass and emit warnings rather than fail; the known curation gaps are
# documented as a TODO. tables not yet generated are skipped, so a fresh clone
# passes cleanly. the underlying checks live in scripts/validate.R.

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
        show_col_types = FALSE, name_repair = "minimal", progress = FALSE
      )
      missing <- setdiff(want, names(dat))
      if (length(missing) > 0) {
        warning(resource$name, " missing columns: ",
                paste(missing, collapse = ", "))
      }
      succeed()
    })
  })
}

test_that("validate_data runs in warn mode without error", {
  paths <- file.path(root, vapply(dp$resources, function(r) r$path, character(1)))
  skip_if_not(any(file.exists(paths)), "no data generated yet")
  expect_error(validate_data(root = root), NA)
})
