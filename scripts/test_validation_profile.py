import copy
import json
import unittest

import check_validation_profile as c


class ValidationProfileTests(unittest.TestCase):
    def setUp(self):
        self.profile = json.loads(c.PROFILE.read_text())

    def test_repository_profile_is_clean(self):
        self.assertEqual(c.problems(self.profile), [])
        self.assertEqual(c.required_check_problems(), [])

    def test_missing_row_is_reported(self):
        p = copy.deepcopy(self.profile)
        del p['requirements']['CON-001']
        self.assertTrue(any('CON-001' in m for m in c.problems(p)))

    def test_implemented_requires_evidence(self):
        p = copy.deepcopy(self.profile)
        p['requirements']['INT-001']['evidence'] = []
        self.assertTrue(any('without evidence' in m for m in c.problems(p)))

    def test_bad_evidence_path_is_reported(self):
        p = copy.deepcopy(self.profile)
        p['requirements']['REL-001']['evidence'] = ['no/such/file']
        self.assertTrue(any('not found' in m for m in c.problems(p)))

    def test_dash_cannot_claim_status(self):
        p = copy.deepcopy(self.profile)
        p['requirements']['ACQ-001']['status'] = 'Implemented'
        self.assertTrue(any('dash' in m for m in c.problems(p)))

    def test_rendered_doc_is_current(self):
        self.assertEqual(c.DOC.read_text(), c.render(self.profile))


if __name__ == '__main__':
    unittest.main()
