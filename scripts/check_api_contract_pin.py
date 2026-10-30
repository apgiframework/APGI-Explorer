"""Fail CI when the sealed research contract drifts from the pinned apgi-api commit.

`contracts/api-contract-pin.json` names an apgi-api commit and the SHA-256 of every artifact derived
from it (OpenAPI extract, instrument pin, item bank, consent texts, score allow-list) plus the shared
Swift/Python upload vectors. Two levels of check:

  python3 scripts/check_api_contract_pin.py
      Offline: every local artifact still has its pinned hash. Catches a hand edit or a refresh that
      was not re-pinned.
  python3 scripts/check_api_contract_pin.py --api path/to/apgi-api
      Against a checkout of the pinned commit: refreshes the artifacts in memory (refresh_research_contract.py)
      and compares them byte for byte, and requires apgi-api's copy of the upload vectors to be identical.

  python3 scripts/check_api_contract_pin.py --update --api path/to/apgi-api
      Re-pin after an intentional contract change (records the checkout's HEAD commit).
"""
import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIN = ROOT / 'contracts/api-contract-pin.json'
VECTORS = 'Tests/ExplorerCoreTests/Fixtures/upload-vectors.json'
API_VECTORS = 'tests/fixtures/explorer/upload-vectors.json'
ARTIFACTS = ['contracts/explorer-research-v1.json', 'contracts/explorer-instrument-pin.json',
             'Tests/ExplorerCoreTests/Fixtures/item-bank.json',
             'Tests/ExplorerCoreTests/Fixtures/consent-texts-approved-for-test.json',
             'Tests/ExplorerCoreTests/Fixtures/score-allowlist.json', VECTORS]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def head_commit(api):
    return subprocess.run(['git', '-C', str(api), 'rev-parse', 'HEAD'], check=True, capture_output=True,
                          text=True).stdout.strip()


def offline_problems(pin=None, root=ROOT):
    pin = pin or json.loads(PIN.read_text())
    problems = []
    if len(pin['commit']) != 40 or any(c not in '0123456789abcdef' for c in pin['commit']):
        problems.append('pin.commit must be a full 40-character commit SHA')
    if sorted(pin['files']) != sorted(ARTIFACTS):
        problems.append('pin.files must list exactly the sealed artifacts')
    for name, expected in pin['files'].items():
        if sha(root / name) != expected:
            problems.append(f'{name} differs from the pinned apgi-api commit {pin["commit"][:12]}; '
                            f'refresh from the API and re-pin (or revert the edit)')
    return problems


def online_problems(api, pin=None):
    pin = pin or json.loads(PIN.read_text())
    api = Path(api)
    problems = []
    actual = head_commit(api)
    if actual != pin['commit']:
        problems.append(f'checkout is at {actual[:12]}, the pin names {pin["commit"][:12]}')
    sys.path.insert(0, str(ROOT / 'scripts'))
    import refresh_research_contract as refresh

    for name, text in refresh.build(api).items():
        if (ROOT / name).read_text() != text:
            problems.append(f'{name} does not reproduce from the pinned apgi-api commit')
    theirs = api / API_VECTORS
    if not theirs.exists() or theirs.read_bytes() != (ROOT / VECTORS).read_bytes():
        problems.append(f'apgi-api {API_VECTORS} differs from Explorer {VECTORS}; the shared vectors must match')
    return problems


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--api')
    parser.add_argument('--update', action='store_true')
    args = parser.parse_args()
    if args.update:
        if not args.api:
            parser.error('--update needs --api')
        pin = {'repository': 'apgiframework/apgi-api', 'commit': head_commit(Path(args.api)),
               'files': {name: sha(ROOT / name) for name in ARTIFACTS}}
        found = online_problems(args.api, pin)
        if found:
            raise SystemExit('\n'.join(found))
        PIN.write_text(json.dumps(pin, indent=2) + '\n')
        print('pinned', pin['commit'])
        return
    problems = offline_problems()
    if args.api:
        problems += online_problems(args.api)
    for problem in problems:
        print('ERROR:', problem)
    if problems:
        sys.exit(1)
    print('Sealed research contract matches the pin' + (' and reproduces from apgi-api.' if args.api else '.'))


if __name__ == '__main__':
    main()
