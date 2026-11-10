# Local stand-in for the three cal-val workbooks. Each workbook id maps to a folder of
# <tab>.csv files under GS4_FAKE_DIR (wb1, wb2, wb3, in 000-config.yml order).
# Cell typing follows the Sheets API: a number cell is a correctly rounded double, an
# "NA" cell is text, an empty cell is missing, a column mixing number and text cells
# arrives as a list column, and columns named in <tab>.text_columns are plain-text cells.
.ids <- c("1pXiZUkNP50WXbmAztoEgUJ6rpQNyewmobCuaFHL8UjQ" = "wb1",
          "1UXKQy0EUEtPBHIjtuf6d-cdQf6sSq0wiZfC_sW_13S0" = "wb2",
          "148G8IyaeqXhqCvY42G3vI9V3WJk4Uypsgd_3Pb5A8_0" = "wb3")
.dir <- function(ss) file.path(Sys.getenv("GS4_FAKE_DIR"), .ids[[ss]])
gs4_get <- function(ss) {
  list(sheets = data.frame(name = sub("\\.csv$", "", list.files(.dir(ss), pattern = "\\.csv$")), stringsAsFactors = FALSE))
}
.num_re <- "^-?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$"
read_sheet <- function(ss, sheet, range = NULL, col_names = TRUE, col_types = NULL, skip = 0, guess_max = 1000, ...) {
  path <- file.path(.dir(ss), paste0(sheet, ".csv"))
  if (!is.null(range)) {
    return(readr::read_csv(path, col_names = FALSE, n_max = 5, col_types = readr::cols(.default = "c"), na = "", progress = FALSE))
  }
  tc <- sub("\\.csv$", ".text_columns", path)
  text_cols <- if (file.exists(tc)) readLines(tc) else character(0)
  guessed <- readr::read_csv(path, skip = skip, guess_max = guess_max, na = "", show_col_types = FALSE, progress = FALSE)
  raw <- readr::read_csv(path, skip = skip, col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  for (nm in names(raw)) {
    x <- raw[[nm]]
    if (nm %in% text_cols) { guessed[[nm]] <- x; next }
    present <- !is.na(x); isnum <- present & grepl(.num_re, x)
    if (any(isnum) && all(isnum[present])) {
      guessed[[nm]] <- as.numeric(x)
    } else if (any(isnum)) {
      guessed[[nm]] <- lapply(seq_along(x), function(i) if (isnum[i]) as.numeric(x[i]) else x[i])
    }
  }
  guessed
}
