import json
import shutil
import tempfile
import unittest
from pathlib import Path

import check_privacy_draft as gate


class PrivacyDraftTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root, True)
        for rel in ('contracts', 'APGI-Explorer'):
            (self.root / rel).mkdir()
        for rel in ('contracts/research-privacy-review.json', 'contracts/proposed-PrivacyInfo.research.xcprivacy',
                    'APGI-Explorer/PrivacyInfo.xcprivacy'):
            shutil.copy(gate.ROOT / rel, self.root / rel)
        self.review = self.root / 'contracts/research-privacy-review.json'

    def edit(self, **changes):
        data = json.loads(self.review.read_text())
        data.update(changes)
        self.review.write_text(json.dumps(data))

    def test_repository_draft_is_consistent(self):
        self.assertEqual(gate.problems(), [])

    def test_draft_cannot_claim_approval(self):
        self.edit(approved=True)
        self.assertIn('must not claim approval', ' '.join(gate.problems(self.review, self.root)))
        self.edit(approved=False, collected_data_types_declared=True)
        self.assertIn('must not claim approval', ' '.join(gate.problems(self.review, self.root)))

    def test_changed_shipped_manifest_forces_a_new_review(self):
        manifest = self.root / 'APGI-Explorer/PrivacyInfo.xcprivacy'
        manifest.write_text(manifest.read_text() + '\n')
        self.assertIn('shipped privacy manifest changed', ' '.join(gate.problems(self.review, self.root)))

    def test_inventory_and_proposal_must_agree(self):
        data = json.loads(self.review.read_text())
        data['inventory'] = data['inventory'][:-1]
        self.review.write_text(json.dumps(data))
        self.assertIn('disagree', ' '.join(gate.problems(self.review, self.root)))


if __name__ == '__main__':
    unittest.main()
