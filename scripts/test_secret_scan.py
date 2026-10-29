"""Regression tests for the secret scan configuration.

Needs the pinned gitleaks binary: GITLEAKS=/path/to/gitleaks python3 scripts/test_secret_scan.py
(CI downloads and checksum-verifies it first.) Synthetic credentials are assembled at runtime
so this file is not itself a finding.
"""
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_secret_scan  # noqa: E402

BINARY = os.environ.get('GITLEAKS') or shutil.which('gitleaks')


def scan_files(files):
    with tempfile.TemporaryDirectory() as tmp:
        for name, text in files.items():
            path = Path(tmp) / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        code, findings, _ = run_secret_scan.scan(BINARY, Path(tmp), run_secret_scan.ROOT / '.gitleaks.toml')
    return code, findings


@unittest.skipUnless(BINARY, 'set GITLEAKS to the pinned gitleaks binary')
class SecretScanTests(unittest.TestCase):
    def test_ordinary_keychain_identifiers_pass(self):
        code, findings = scan_files({'Keychain.swift': '''
            private let service = "org.apgiframework.APGI-Explorer.research"
            private let account = "research-credentials"
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service, kSecAttrAccount as String: account]
            enum Keys { static let refreshToken = "refresh_token"; static let accessToken = "access_token" }
        '''})
        self.assertEqual((code, findings), (0, []))

    def test_synthetic_credential_value_is_detected_and_redacted(self):
        value = 'k3Jx9Qz7' + 'Lm2Vb8Nw4' + 'Rt6Yh1Pd5' + 'Sa0Fg7Uc3'
        code, findings = scan_files({'Config.swift': f'let apiKey = "{value}"\n'})
        self.assertEqual(code, 1)
        self.assertTrue(findings)
        self.assertNotIn(value, repr(findings), 'findings must be redacted')

    def test_only_the_exact_truncated_contract_examples_are_exempt(self):
        example = '{"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'
        code, findings = scan_files({'contracts/openapi-v1.json': example})
        self.assertEqual((code, findings), (0, []))
        different = '{"access_token": "' + 'Qm8xT2vK9p' + 'Lw3NzR7yHd' + '5BcF1gJ6Ws4' + 'Xe0Ua"}'
        for path in ('Sources/Control.swift', 'contracts/openapi-v1.json'):
            code, findings = scan_files({path: different})
            self.assertEqual(code, 1, f'a different value in {path} must be reported')
            self.assertTrue(findings)

    def test_a_credential_added_to_a_contract_file_is_not_hidden(self):
        leaked = 'Qm8xT2vK9p' + 'Lw3NzR7yHd' + '5BcF1gJ6Ws4' + 'Xe0Ua'
        text = '{"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}\n{"refresh_token": "' + leaked + '"}'
        code, findings = scan_files({'contracts/explorer-research-v1.json': text})
        self.assertEqual(code, 1)
        self.assertEqual([f['StartLine'] for f in findings], [2])


if __name__ == '__main__':
    unittest.main()
