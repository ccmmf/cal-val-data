"""Evidence figures and report wording checked against committed targets."""

import csv
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


figures = load_script("build_evidence_figures")


class DocumentationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with figures.SOURCE.open(newline="", encoding="utf-8") as source:
            cls.rows = list(csv.DictReader(source))

    def test_grid_preserves_six_eligible_two_sign_check_ten_unselected_cells(self):
        image = figures.evidence_grid(self.rows, "test")
        ET.fromstring(image)
        self.assertEqual(image.count("L · Likelihood eligible"), 6)
        self.assertEqual(image.count("S · Sign check"), 2)
        self.assertEqual(image.count("— · No selected target"), 10)
        self.assertIn("Cayuela 2017", image)

    def test_assumed_spreads_have_no_forest_uncertainty_bars(self):
        image = figures.lrr_forest(self.rows, "test")
        elements = list(ET.fromstring(image).iter())
        self.assertEqual(sum(e.tag.endswith("circle") for e in elements), 7)
        self.assertEqual(sum(e.tag.endswith("path") for e in elements), 2)
        self.assertEqual(image.count('stroke-width="4"'), 7)
        labels = [e.text for e in elements if e.tag.endswith("text")
                  and e.text and e.text.startswith(("L ·", "S ·"))]
        self.assertTrue(all("EF level" not in label for label in labels))

    def test_forest_rejects_sd_mislabeled_as_mean_precision(self):
        row = dict(next(r for r in self.rows if r["source_id"] == "Bai_2023_OA_SOC"))
        row["spread_type"] = "sd"
        with self.assertRaisesRegex(ValueError, "Expected an SE"):
            figures.lrr_forest([row], "test")

    def test_assumed_spreads_remain_sign_checks(self):
        rows = [r for r in self.rows if r["use"] == "sign_check"]
        self.assertEqual(len(rows), 2)
        self.assertTrue(all("assumed" in r["spread_type"] for r in rows))
        report = (ROOT / "reports/statewide-evidence.qmd").read_text()
        self.assertIn("0.707 (assumed sensitivity scale)", report)
        self.assertNotIn("0.707 (SE, expert prior)", report)

    def test_ef_level_preserves_scale_and_precision(self):
        row = next(r for r in self.rows if r["source_id"] == "Cayuela_2017_EFmed_target")
        self.assertEqual(float(row["center"]), 0.5)
        self.assertEqual(float(row["spread"]), 0.06122)
        self.assertEqual(row["scale/units"], "percent of N applied")
        report = (ROOT / "reports/statewide-evidence.qmd").read_text()
        self.assertIn("0.50 | 0.0612", report)
        self.assertIn("EF slope", report)

    def test_report_evidence_count_matches_snapshot(self):
        with (ROOT / "data_raw/statewide_benchmarking/extracted_evidence.csv").open(newline="") as source:
            count = sum(1 for _ in csv.DictReader(source))
        report = (ROOT / "reports/statewide-evidence.qmd").read_text()
        self.assertIn(f"contains {count} evidence rows", report)


if __name__ == "__main__":
    unittest.main()
