"""Refresh the Explorer research contract artifacts from an apgi-api checkout.

Run with the API's Python environment (it imports the API application):
    /path/to/api-venv/bin/python scripts/refresh_research_contract.py --api ../apgi-api

Writes contracts/explorer-research-v1.json (OpenAPI extract), contracts/explorer-instrument-pin.json
(item-bank hash pin) and the Swift test fixtures, then run scripts/generate_api_client.py.
Review the diff: a changed bank hash is an intentional instrument change.

With --check nothing is written: the artifacts are regenerated in memory and compared with the
checked-in files, which is how CI proves they still come from the pinned apgi-api commit
(scripts/check_api_contract_pin.py).
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESEARCH_PATHS = {
    '/v1/explorer/config', '/v1/consent-texts', '/v1/instruments/apgi-explorer-35',
    '/v1/instruments/apgi-explorer-35/score-allowlist',
    '/v1/participant-sessions/{participant_session_id}/events',
    '/v1/participant-sessions/{participant_session_id}/explorer-result',
    '/v1/participants/{participant_id}/consents', '/v1/participants/{participant_id}/consents/revoke',
    '/v1/participants/{participant_id}/consents/status', '/v1/auth/refresh',
}


def refs(node, found):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == '$ref':
                found.add(value.split('/')[-1])
            else:
                refs(value, found)
    elif isinstance(node, list):
        for value in node:
            refs(value, found)


def build(api):
    """Regenerate every artifact from an apgi-api checkout; returns {repo-relative path: text}."""
    sys.path.insert(0, str(Path(api).resolve()))
    from app.main import create_app
    from app.services import explorer_contract as contract

    spec = create_app(test_mode=True).openapi()
    paths = {p: spec['paths'][p] for p in sorted(RESEARCH_PATHS)}
    wanted, seen = set(), set()
    refs(paths, wanted)
    schemas = spec['components']['schemas']
    while wanted - seen:
        name = (wanted - seen).pop()
        seen.add(name)
        refs(schemas[name], wanted)
    extract = {'openapi': spec['openapi'],
               'info': {'title': 'Explorer research contract (extract of apgi-api, not yet deployed)',
                        'version': spec['info']['version']},
               'paths': paths,
               'components': {'schemas': {n: schemas[n] for n in sorted(seen)},
                              'securitySchemes': spec['components'].get('securitySchemes', {})}}
    bank = dict(contract.item_bank())
    pin = {'instrument_id': bank['instrument_id'], 'bank_version': bank['bank_version'],
           'sha256': bank['sha256'], 'item_count': len(bank['items'])}
    texts = [dict(t, status='approved') for t in contract.consent_texts()]  # test-only approval
    allow = {'fields': [{'field': e['field'], 'label': e['label']} for e in contract.SCORE_ALLOWLIST.values()]}
    return {
        'contracts/explorer-research-v1.json': json.dumps(extract, indent=2, sort_keys=True),
        'contracts/explorer-instrument-pin.json': json.dumps(pin, indent=2) + '\n',
        'Tests/ExplorerCoreTests/Fixtures/item-bank.json': json.dumps(bank, ensure_ascii=False, indent=1),
        'Tests/ExplorerCoreTests/Fixtures/consent-texts-approved-for-test.json': json.dumps(texts, ensure_ascii=False, indent=1),
        'Tests/ExplorerCoreTests/Fixtures/score-allowlist.json': json.dumps(allow, indent=1),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--api', required=True, help='path to an apgi-api checkout')
    parser.add_argument('--check', action='store_true', help='compare with the checked-in files instead of writing')
    args = parser.parse_args()
    outputs = build(args.api)
    if args.check:
        drifted = [name for name, text in outputs.items() if (ROOT / name).read_text() != text]
        if drifted:
            raise SystemExit('Checked-in contract artifacts differ from the pinned apgi-api commit:\n  ' + '\n  '.join(drifted))
        print('contract artifacts reproduce from the pinned apgi-api commit')
        return
    for name, text in outputs.items():
        (ROOT / name).write_text(text)
    print('refreshed; bank sha256', json.loads(outputs['contracts/explorer-instrument-pin.json'])['sha256'])


if __name__ == '__main__':
    main()
