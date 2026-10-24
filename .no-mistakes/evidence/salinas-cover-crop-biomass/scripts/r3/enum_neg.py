import sys, json, csv, shutil, os, collections
from frictionless import Package, system
src, mode = sys.argv[1], sys.argv[2]
dst = src + "-" + mode
shutil.rmtree(dst, ignore_errors=True); shutil.copytree(src, dst, ignore=shutil.ignore_patterns(".git"))
os.chdir(dst)
if mode == "enum-removed":
    dp = json.load(open("datapackage.json"))
    for r in dp["resources"]:
        for f in r["schema"]["fields"]:
            if f["name"] == "fill_status" and "enum" in f.get("constraints", {}):
                f["constraints"]["enum"].remove("FILLED_PUBLICATION_FIGURE")
    json.dump(dp, open("datapackage.json", "w"), indent=2)
    print("scenario: FILLED_PUBLICATION_FIGURE removed from the fill_status enum (scratch copy of HEAD)")
else:
    p = "data/observations.csv"; rows = list(csv.reader(open(p, newline="")))
    h = rows[0]; done = False
    for r in rows[1:]:
        if not done and r[h.index("variable")] == "cover_crop_shoot_dry_matter_Mg_ha":
            r[h.index("fill_status")] = "FILLED_PUBLICATION_FIGUR"; done = True
            print("scenario: one cover crop row (%s year %s) with misspelled fill_status FILLED_PUBLICATION_FIGUR, committed schema" % (r[h.index("treatment_id")], r[h.index("study_year")]))
    csv.writer(open(p, "w", newline=""), lineterminator="\n").writerows(rows)
with system.use_context(trusted=True):
    rep = Package("datapackage.json").get_resource("observations").validate()
errs = [e for t in rep.tasks for e in t.errors]
print("observations valid:", rep.valid, "| errors:", len(errs), collections.Counter((e.type, getattr(e, "field_name", None)) for e in errs))
for e in errs[:2]: print("  e.g.", e.type, "row", getattr(e, "row_number", None), repr(getattr(e, "cell", None)))
shutil.rmtree(dst)
