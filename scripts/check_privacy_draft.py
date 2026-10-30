"""Keep the research privacy review honest while it is a draft (S3-EXP-01.12).

The draft inventory in `contracts/research-privacy-review.json` and the proposed manifest must agree,
the draft must not claim approval, and it must stay pinned to the manifest currently shipped so a
change to that manifest forces a new review. `check_explorer_contracts.py` separately refuses
`ExplorerBuildApproval.researchApproved = true` until an approved review matches the shipped manifest.
"""
import hashlib
import json
import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / 'contracts/research-privacy-review.json'
SHIPPED = ROOT / 'APGI-Explorer/PrivacyInfo.xcprivacy'
KIND = 'NSPrivacyCollectedDataType'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def problems(review_path=REVIEW, root=ROOT):
    review = json.loads(review_path.read_text())
    found = []
    shipped_path = root / review['privacy_manifest']
    proposed_path = root / review['proposed_manifest']
    if review['privacy_manifest_sha256'] != sha(shipped_path):
        found.append('The shipped privacy manifest changed since this review; review it again')
    if review['proposed_manifest_sha256'] != sha(proposed_path):
        found.append('The proposed manifest changed without updating proposed_manifest_sha256')
    shipped = plistlib.loads(shipped_path.read_bytes())
    proposed = plistlib.loads(proposed_path.read_bytes())
    draft = review['status'] == 'draft'
    if draft and (review['approved'] or review['reviewer'] or review['collected_data_types_declared']):
        found.append('A draft review must not claim approval, a reviewer or declared data types')
    if not draft and not (review['approved'] and review['reviewer'] and review['reviewed_at']):
        found.append('A non-draft review needs approval, a named reviewer and a date')
    if draft and shipped == proposed:
        found.append('The proposed manifest equals the shipped one; a draft must propose a change')
    if proposed.get('NSPrivacyTracking') is not False or proposed.get('NSPrivacyTrackingDomains'):
        found.append('The proposal must not enable tracking')
    declared = {e[KIND]: e for e in proposed['NSPrivacyCollectedDataTypes']}
    inventory = {item['apple_type'].split(' ')[0]: item for item in review['inventory']}
    if set(declared) != set(inventory):
        found.append(f'Inventory and proposed manifest disagree: {sorted(set(declared) ^ set(inventory))}')
    for name, entry in declared.items():
        item = inventory.get(name)
        if item is not None and entry['NSPrivacyCollectedDataTypeLinked'] != item['linked']:
            found.append(f'{name}: linked flag differs between inventory and manifest')
        if not entry['NSPrivacyCollectedDataTypePurpose']:
            found.append(f'{name}: no purpose declared')
    for entry in shipped['NSPrivacyCollectedDataTypes']:
        if entry[KIND] not in declared:
            found.append(f'The proposal drops an existing declaration: {entry[KIND]}')
    if not review['open_questions'] and draft:
        found.append('A draft should list its open questions')
    return found


if __name__ == '__main__':
    issues = problems()
    for issue in issues:
        print('ERROR:', issue)
    if issues:
        sys.exit(1)
    print('Privacy draft is consistent with the shipped manifest (draft, not approved).')
