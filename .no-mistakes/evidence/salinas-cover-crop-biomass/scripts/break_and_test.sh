#!/bin/bash
# copy the snapshot, apply one mutation, run the Salinas testthat file
set -u
S=/tmp/nmtest-W6td
name=$1; shift
rm -rf $S/mut && cp -r $S/repo $S/mut
python3 - "$@" <<'PY'
import csv, sys, json
mode = sys.argv[1]
if mode in ("value", "ci", "fill"):
    p = "/tmp/nmtest-W6td/mut/data/observations.csv"
    rows = list(csv.reader(open(p, newline="")))
    h = rows[0]; V = h.index("variable"); T = h.index("treatment_id"); Y = h.index("study_year")
    for r in rows[1:]:
        if r[V] == "cover_crop_shoot_dry_matter_Mg_ha" and r[T] == "socs_sys6" and r[Y] == "5":
            if mode == "value": r[h.index("value")] = "%.2f" % (float(r[h.index("value")]) + 0.05)
            if mode == "ci":
                a = json.loads(r[h.index("attributes_json")]); a.pop("ci95_lower", None); a.pop("ci95_upper", None)
                r[h.index("attributes_json")] = json.dumps(a, separators=(",", ":"))
            if mode == "fill": r[h.index("fill_status")] = "FILLED_PUBLICATION_TABLE"
            print("mutated observations", r[T], "year", r[Y], "->", mode)
    csv.writer(open(p, "w", newline=""), lineterminator="\n").writerows(rows)
if mode == "redigitize":
    p = "/tmp/nmtest-W6td/mut/data_raw/white_salinas_2020/brennan_boyd_2012_fig5_digitized.csv"
    rows = list(csv.reader(open(p, newline="")))
    h = rows[0]
    for r in rows[1:]:
        if r[0] == "socs_sys8" and r[h.index("year")] == "2":
            r[h.index("value_Mg_ha")] = "%.2f" % (float(r[h.index("value_Mg_ha")]) - 0.1)
            print("mutated digitizer output socs_sys8 year 2 (re-digitization not carried to workbook)")
    csv.writer(open(p, "w", newline=""), lineterminator="\n").writerows(rows)
PY
cd $S/mut && Rscript -e 'res <- as.data.frame(testthat::test_file("tests/testthat/test-white-salinas.R", reporter = "silent", stop_on_failure = FALSE)); print(res[, c("test", "failed")], row.names = FALSE)' 2>&1 | sed 's/^/  /'
