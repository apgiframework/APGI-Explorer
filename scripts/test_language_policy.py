"""Behaviour of the lexical language policy (a source scan, not visual QA)."""
import tempfile
import unittest
from pathlib import Path

import language_policy as policy

APPROVED = policy.approved_labels()


def scan(text, name='View.swift'):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / name
        path.write_text(text)
        return policy.violations([path], APPROVED)


class LanguagePolicyTests(unittest.TestCase):
    def test_runtime_sources_are_clean(self):
        self.assertEqual(policy.violations(), [])
        self.assertTrue(policy.central_labels_match())

    def test_retired_labels_are_rejected(self):
        for label in policy.RETIRED:
            self.assertTrue(scan(f'Text("{label} (ε)")'), label)

    def test_new_unapproved_reported_literal_is_rejected(self):
        self.assertTrue(scan('Text("Reported mood stability")'))
        self.assertTrue(scan('let s = "Reported something else: \\(x)"'))

    def test_approved_label_literal_outside_central_file_is_rejected(self):
        self.assertTrue(scan('Text("Reported attentional threshold")'))
        self.assertEqual(scan('Text(ScoreLabels.threshold)'), [])

    def test_comments_are_ignored(self):
        self.assertEqual(scan('// Reported mood stability is discussed here\nlet a = 1'), [])
        self.assertEqual(scan('/* Somatic Bias (β) was renamed */\nlet a = 1'), [])

    def test_central_file_may_hold_the_approved_labels(self):
        self.assertEqual(scan('static let a = "Reported attentional threshold"', 'ScoreLabels.swift'), [])

    def test_url_with_double_slash_is_not_a_comment(self):
        self.assertTrue(scan('let u = "https://x.test"; Text("Ignition Threshold")'))


if __name__ == '__main__':
    unittest.main()
