#!/usr/bin/env python3
"""Build the two evidence diagrams from committed targets; --check writes nothing."""

import argparse
import csv
import hashlib
from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data_raw/statewide_benchmarking/summarized_targets.csv"
FIGURES = ROOT / "reports/figures"
COLORS = {"L": "#216653", "S": "#65458a", "—": "#eeeeee"}


def text(x, y, value, size=22, fill="#222", anchor="start"):
    return (f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}">{escape(str(value))}</text>')


def source_label(source_id):
    parts = source_id.split("_")
    year_index = next(index for index, part in enumerate(parts)
                      if len(part) == 4 and part.isdigit())
    return " & ".join(parts[:year_index]) + " " + parts[year_index]


def svg(title, description, height, marks, source_hash):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 {height}" '
            'role="img" aria-labelledby="title description">\n'
            f'<title id="title">{escape(title)}</title>\n'
            f'<desc id="description">{escape(description)}</desc>\n'
            f'<metadata>Source: summarized_targets.csv; SHA256: {source_hash}</metadata>\n'
            '<rect width="100%" height="100%" fill="white"/>\n'
            '<g font-family="Arial, sans-serif">\n'
            + "\n".join(marks) + "\n</g>\n</svg>\n")


def evidence_grid(rows, source_hash):
    practices = list(dict.fromkeys(row["practice"] for row in rows))
    outcomes = ["Soil C", "N2O", "CH4"]
    height = 180 + 86 * len(practices)
    marks = [text(20, 36, "Selected evidence by practice and outcome", 30)]
    for col, outcome in enumerate(outcomes):
        marks.append(text(425 + col * 300, 90, outcome, 26, anchor="middle"))
    for row_index, practice in enumerate(practices):
        y = 108 + 86 * row_index
        marks.append(text(20, y + 43, practice, 22))
        for col, outcome in enumerate(outcomes):
            group = [r for r in rows if r["practice"] == practice and r["outcome"] == outcome]
            selected = [r for r in group if r["use"] in ("likelihood", "sign_check")]
            code = "L" if any(r["use"] == "likelihood" for r in selected) else "S" if selected else "—"
            x = 280 + col * 300
            marks.append(f'<rect x="{x}" y="{y}" width="290" height="76" fill="{COLORS[code]}"/>')
            ink = "#222" if code == "—" else "white"
            marks.append(text(x + 145, y + 28, {"L": "L · Likelihood eligible", "S": "S · Sign check", "—": "— · No selected target"}[code], 20, ink, "middle"))
            sources = list(dict.fromkeys(source_label(r["source_id"]) for r in selected))
            label = " + ".join(sources) if selected else "No evidence curated" if not group or all(r["evidence_availability"] == "none_curated" for r in group) else "Evidence held; not selected"
            marks.append(text(x + 145, y + 57, label, 18, ink, "middle"))
    marks += [text(20, height - 36, "Letters distinguish classes without relying on color. Subclass rows are not independent constraints.", 20),
              text(20, height - 10, "Fertilizer N2O includes an EF level and crop-specific slopes; select matching observation operators.", 20)]
    return svg("Selected evidence grid", "Six practices by three outcomes; L denotes likelihood eligibility, S sign checks, and a dash no selected target.", height, marks, source_hash)


def lrr_forest(rows, source_hash):
    selected = [r for r in rows if r["scale/units"] == "LRR (dimensionless)" and r["use"] in ("likelihood", "sign_check")]
    height = 270 + len(selected) * 58
    left, right, xmin, xmax = 580, 1130, -1.9, 1.0
    position = lambda value: left + (value - xmin) / (xmax - xmin) * (right - left)
    marks = [text(20, 36, "Selected log-response-ratio targets", 30),
             text(20, 70, "Bars: approximate 95% intervals from source-derived SE. Sign checks: points only.", 22)]
    bottom = 110 + 58 * len(selected)
    for tick in (-1.5, -1, -0.5, 0, 0.5, 1):
        x = position(tick)
        marks.append(f'<line x1="{x:.2f}" x2="{x:.2f}" y1="100" y2="{bottom}" stroke="{"#444" if tick == 0 else "#ddd"}"/>')
        marks.append(text(round(x, 2), bottom + 30, tick, 20, anchor="middle"))
    for index, row in enumerate(selected):
        y = 130 + 58 * index
        center = float(row["center"])
        code = "L" if row["use"] == "likelihood" else "S"
        label = f'{code} · {row["practice"]} / {row["outcome"]}'
        if row["subclass"]:
            label += " / " + row["subclass"]
        marks.append(text(20, y + 7, label, 21))
        x = position(center)
        if code == "L":
            if row["spread_type"] != "se":
                raise ValueError(f'Expected an SE for plotted likelihood row {row["source_id"]}')
            se = float(row["spread"])
            marks.append(f'<line x1="{position(center - 1.96 * se):.2f}" x2="{position(center + 1.96 * se):.2f}" y1="{y}" y2="{y}" stroke="{COLORS[code]}" stroke-width="4"/>')
            marks.append(f'<circle cx="{x:.2f}" cy="{y}" r="7" fill="{COLORS[code]}"/>')
        else:
            marks.append(f'<path d="M {x:.2f} {y - 9} l 9 9 l -9 9 l -9 -9 Z" fill="{COLORS[code]}"/>')
    marks += [text((left + right) / 2, bottom + 65, "ln(intervention / comparator)", 22, anchor="middle"),
              text(20, height - 38, "Rice drying classes overlap: choose one applicable representation. L = eligible; S = sign check.", 20),
              text(20, height - 12, "Absolute SOC rates and EF levels/slopes are omitted because their scales differ. Stand age matters for SOC.", 20)]
    return svg("Selected log-response-ratio targets", "Seven likelihood-eligible rows have SE-derived intervals; two assumed-spread sign checks have no bars. Rows retain distinct comparators and overlapping subclasses.", height, marks, source_hash)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    with SOURCE.open(newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    outputs = {"b2-evidence-grid.svg": evidence_grid(rows, source_hash),
               "b3-selected-lrr-targets.svg": lrr_forest(rows, source_hash)}
    stale = []
    for name, content in outputs.items():
        path = FIGURES / name
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(name)
        else:
            path.write_text(content, encoding="utf-8")
    if stale:
        raise SystemExit("Regenerate stale figures: " + ", ".join(stale))
    print("Evidence figures match committed targets." if args.check else "Built two evidence figures.")


if __name__ == "__main__":
    main()
