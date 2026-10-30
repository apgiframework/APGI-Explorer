"""The model gate fails on the reconciliation mistakes it exists to catch."""
import shutil
import tempfile
import unittest
from pathlib import Path

import check_core_data_model as gate


class ModelGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.model = self.tmp / 'APGIExplorer.xcdatamodeld'
        shutil.copytree(gate.MODEL_DIR, self.model)

    def test_repository_model_passes(self):
        self.assertEqual(gate.problems(), [])

    def test_selector_pointing_at_the_original_version_is_rejected(self):
        path = self.model / '.xccurrentversion'
        path.write_text(path.read_text().replace('APGISignature 2.xcdatamodel', gate.ORIGINAL_VERSION))
        text = '\n'.join(gate.problems(self.model))
        self.assertIn('does not contain PendingEvent', text)
        self.assertIn('Original model version must not be the current version', text)

    def test_selector_pointing_at_a_missing_version_is_rejected(self):
        path = self.model / '.xccurrentversion'
        path.write_text(path.read_text().replace('APGISignature 2.xcdatamodel', 'Nope.xcdatamodel'))
        self.assertIn('does not contain PendingEvent', '\n'.join(gate.problems(self.model)))

    def test_missing_attribute_is_rejected(self):
        contents = self.model / 'APGISignature 2.xcdatamodel/contents'
        contents.write_text(contents.read_text().replace('name="nextAttemptAt"', 'name="renamed"'))
        self.assertIn('nextAttemptAt', '\n'.join(gate.problems(self.model)))

    def test_dropped_uniqueness_constraint_is_rejected(self):
        contents = self.model / 'APGISignature 2.xcdatamodel/contents'
        contents.write_text(contents.read_text().replace('<constraint value="eventKey"/>', '<constraint value="seqNo"/>'))
        self.assertIn('uniqueness constraint', '\n'.join(gate.problems(self.model)))

    def test_pending_event_added_to_the_original_version_is_rejected(self):
        v1 = self.model / 'APGISignature.xcdatamodel/contents'
        v2 = self.model / 'APGISignature 2.xcdatamodel/contents'
        v1.write_text(v2.read_text())
        self.assertIn('must stay unchanged', '\n'.join(gate.problems(self.model)))


if __name__ == '__main__':
    unittest.main()
