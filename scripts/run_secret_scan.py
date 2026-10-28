"""Run the checksum-pinned Gitleaks binary over the working tree with redacted output.

CI downloads gitleaks, verifies PINNED_SHA256 and passes the binary path. Findings are
printed redacted (rule, file, line) and never echo the matched value.
"""
import argparse
import json
import subprocess
import tempfile
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def scan(binary, target=ROOT, config=ROOT / '.gitleaks.toml'):
    """Return (exit_code, findings, stderr). Findings never contain the matched secret."""
    with tempfile.TemporaryDirectory() as tmp:
        report = Path(tmp) / 'report.json'
        result = subprocess.run(
            [str(binary), 'dir', str(target), '--config', str(config), '--redact=100', '--no-banner',
             '--no-color', '--exit-code', '1', '--report-format', 'json', '--report-path', str(report)],
            capture_output=True, text=True)
        findings = json.loads(report.read_text() or '[]') if report.exists() else []
    return result.returncode, findings, result.stderr


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--gitleaks', default='gitleaks')
    args = parser.parse_args()
    code, findings, err = scan(args.gitleaks)
    if code not in (0, 1):
        print('gitleaks failed to run:', err.strip()[:500])
        sys.exit(2)
    for f in findings:
        print(f"{f['RuleID']}: {f['File']}:{f['StartLine']}")
    if findings:
        print(f'{len(findings)} potential secret(s) found (values redacted).')
        sys.exit(1)
    print('Secret scan passed.')
