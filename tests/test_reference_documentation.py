import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReferenceDocumentationTests(unittest.TestCase):
    def test_text_identifiers_and_dates_match_schema(self):
        package = json.loads((ROOT / 'datapackage.json').read_text())
        reference = (ROOT / 'docs/data-reference.qmd').read_text()
        resources = {r['name']: r for r in package['resources']}
        for table, names in [('observations', ['replicate_id', 'min_date', 'max_date']),
                             ('managements', ['min_date', 'max_date'])]:
            fields = {f['name']: f for f in resources[table]['schema']['fields']}
            for name in names:
                self.assertEqual(fields[name]['type'], 'string')
        self.assertIn('| `replicate_id` | string |', reference)
        self.assertEqual(reference.count('| `min_date`, `max_date` | string |'), 2)
        self.assertIn('mixed date encodings', reference)

    def test_workflow_does_not_claim_validation_is_approval(self):
        reference = (ROOT / 'docs/data-reference.qmd').read_text()
        readme = (ROOT / 'README.md').read_text()
        self.assertIn('warn mode', reference)
        self.assertIn('review skips and warnings', reference)
        self.assertIn('successful execution alone does not approve', readme)
        self.assertIn("-p 'test_*.py'", reference)
        self.assertNotIn('Data_License-CC--BY', readme)


if __name__ == '__main__':
    unittest.main()
