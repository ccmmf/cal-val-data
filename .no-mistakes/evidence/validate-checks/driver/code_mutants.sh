#!/usr/bin/env bash
# each mutant: fresh copy of base, one perl substitution in scripts/validate.R,
# confirm the substitution applied, run both targeted test files, report failing tests.
T=/tmp/nm-validate-aBGL
declare -A M
M[C1_pk_not_excluded]='s/rest <- dat\[, setdiff\(names\(dat\), pk\), drop = FALSE\]/rest <- dat/'
M[C2_doi_case_sensitive]='s/fold_value <- function\(x\) tolower\(trimws\(as.character\(x\)\)\)/fold_value <- function(x) trimws(as.character(x))/'
M[C3_doi_not_trimmed]='s/fold_value <- function\(x\) tolower\(trimws\(as.character\(x\)\)\)/fold_value <- function(x) tolower(as.character(x))/'
M[C4_blank_not_empty]='s/empty <- !is_present\(dat\[\[col\]\]\)/empty <- is.na(dat[[col]])/'
M[C5_no_ws_squash]='s/clean_unit <- function\(x\) gsub\("\\\\s\+", " ", trimws\(as.character\(x\)\)\)/clean_unit <- function(x) trimws(as.character(x))/'
M[C6_units_case_insensitive]='s/if \(u %in% accepted\) "ok"/if (tolower(u) %in% tolower(accepted)) "ok"/'
M[C7_qualifier_required]='s/accepted <- c\(parts, trimws\(sub\("\\\\s\*\\\\\(\[\^\(\)\]\*\\\\\)\$", "", parts\)\)\)/accepted <- parts/'
M[C8_source_mix_warns]='s/log_info\(\n(\s+resource\$name, v, "carries)/log_warn(\n$1/'
M[C9_count_one_copy]='s/^  duplicated\(rest\)$/  duplicated(rest) & !duplicated(rest, fromLast = TRUE)/m'
M[C10_units_not_wired]='s/^    total_warns <- total_warns \+ check_units\(dat, res, vars\)\n//m'
M[C11_dup_rows_not_wired]='s/^    total_warns <- total_warns \+ check_duplicate_rows\(dat, res\)\n//m'
for k in $(printf '%s\n' "${!M[@]}" | sort -V); do
  d=$T/cases/$k
  rm -rf "$d"; cp -r "$T/base" "$d"
  perl -0pi -e "${M[$k]}" "$d/scripts/validate.R"
  if cmp -s "$d/scripts/validate.R" "$T/base/scripts/validate.R"; then
    echo "=== $k: SUBSTITUTION DID NOT APPLY"; continue
  fi
  out=$(cd "$d" && Rscript -e '
    r <- c(as.list(suppressMessages(testthat::test_file("tests/testthat/test-validate-checks.R", reporter = "silent", stop_on_failure = FALSE))),
           as.list(suppressMessages(testthat::test_file("tests/testthat/test-integrity.R", reporter = "silent", stop_on_failure = FALSE))))
    bad <- vapply(r, function(t) any(vapply(t$results, function(x) !inherits(x, c("expectation_success", "expectation_skip")), logical(1))), logical(1))
    cat(sprintf("failing tests: %d", sum(bad)), if (any(bad)) paste0("[", paste(vapply(r[bad], function(t) t$test, ""), collapse = " | "), "]"), "\n")
  ' 2>&1 | tail -1)
  echo "=== $k: $out"
done
