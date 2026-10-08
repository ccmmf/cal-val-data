"""Navigation contracts independent of scientific report wording."""

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("check_site", ROOT / "scripts/check_site.py")
site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(site)


class NavigationTests(unittest.TestCase):
    def test_homepage_shares_readme_and_links_reference_and_overview(self):
        self.assertIn("{{< include README.md >}}", (ROOT / "index.qmd").read_text())
        readme = (ROOT / "README.md").read_text()
        for path in ("docs/data-reference.qmd", "reports/overview.qmd"):
            self.assertIn(path, readme)
            self.assertTrue((ROOT / path).is_file())

    def test_overview_preserves_report_author_and_date(self):
        overview = (ROOT / "reports/overview.qmd").read_text()
        self.assertIn('author: "Aritra Dey"', overview)
        self.assertIn("date: 2026-09-16", overview)

    def test_alt_check_distinguishes_substantive_and_decorative_images(self):
        page = site.Page('<h2 id="example">Example</h2><img src="figures/a.svg"><img src="icon.svg"><a href="#example">Example</a>')
        self.assertEqual(page.missing_alt, ["figures/a.svg"])
        self.assertIn("example", page.ids)
        self.assertIn("#example", page.links)


if __name__ == "__main__":
    unittest.main()
