"""Validate contracts/validation-profile.json and keep docs/VALIDATION_PROFILE.md rendered from it.

Usage: check_validation_profile.py [--write]   (--write regenerates the Markdown)
Checks: every APGI-VAL-SPEC-1.2 requirement ID has exactly one row, the A07 matrix letter and status
agree, every evidence path exists, no row claims Implemented without evidence, and the
required-checks list names only jobs defined in ci.yml.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / 'contracts/validation-profile.json'
DOC = ROOT / 'docs/VALIDATION_PROFILE.md'
FAMILIES = {'PRO': 4, 'SCI': 7, 'REP': 5, 'IMP': 3, 'DAT': 4, 'API': 4, 'INT': 4, 'REL': 5,
            'CON': 2, 'ACQ': 1, 'VAL': 1, 'CLI': 1}
STATUSES = {'Implemented', 'Partial', 'Blocked', 'Not applicable', 'Not applicable (declared)'}


def expected_ids():
    return {f'{fam}-{n:03d}' for fam, count in FAMILIES.items() for n in range(1, count + 1)}


def problems(profile, root=ROOT):
    out = []
    reqs = profile['requirements']
    missing = expected_ids() - set(reqs)
    extra = set(reqs) - expected_ids()
    if missing:
        out.append(f'missing requirement rows: {sorted(missing)}')
    if extra:
        out.append(f'unknown requirement rows: {sorted(extra)}')
    for rid, row in sorted(reqs.items()):
        if row['matrix'] not in {'R', 'C', '–'}:
            out.append(f'{rid}: bad matrix letter {row["matrix"]!r}')
        if row['status'] not in STATUSES:
            out.append(f'{rid}: bad status {row["status"]!r}')
        if row['matrix'] == '–' and not row['status'].startswith('Not applicable'):
            out.append(f'{rid}: dash in matrix but status is {row["status"]!r}')
        if row['status'] == 'Implemented' and not row['evidence']:
            out.append(f'{rid}: Implemented without evidence')
        if not row['gap'].strip():
            out.append(f'{rid}: gap text is empty')
        for ev in row['evidence']:
            if not (root / ev).exists():
                out.append(f'{rid}: evidence path not found: {ev}')
    return out


def ci_job_names(root=ROOT):
    text = (root / '.github/workflows/ci.yml').read_text()
    return set(re.findall(r'^    name: (\S+)\s*$', text, re.M))


def required_check_problems(root=ROOT):
    req = json.loads((root / '.github/required-checks.json').read_text())['required_status_checks']
    return [f'required check {c!r} is not a job in ci.yml' for c in req if c not in ci_job_names(root)]


def render(profile):
    p = profile['profile']
    lines = ['# Application Validation Profile — APGI-Explorer (A07)', '',
             '<!-- Generated from contracts/validation-profile.json by scripts/check_validation_profile.py --write. Do not edit by hand. -->', '',
             f'Specification: {p["spec"]} ({p["spec_status"]}). Status: **{p["status"]}**.', '',
             '| Field | Value |', '| --- | --- |']
    for key in ['repository', 'app_version', 'release_owner']:
        lines.append(f'| {key.replace("_", " ").capitalize()} | {p[key]} |')
    for key in ['platforms', 'data_classes', 'interfaces']:
        lines.append(f'| {key.replace("_", " ").capitalize()} | {"; ".join(p[key])} |')
    lines.append(f'| Declared Protocol v1.2 definitions | {"; ".join(p["declared_protocol_definitions"]) or "None. Explorer implements no protocol definition."} |')
    lines.append(f'| Approved exclusions | {"; ".join(p["approved_exclusions"]) or "None approved yet. Rows marked Not applicable (declared) need owner approval."} |')
    lines += ['', 'Statuses are evidence-based. "Implemented" means the repository contains the control and a CI check or test exercises it. It does not mean the specification owner has approved it.', '',
              '| Requirement | A07 | Status | Test set | Evidence | Gap and required work |', '| --- | --- | --- | --- | --- | --- |']
    for rid, r in sorted(profile['requirements'].items()):
        ev = '<br>'.join(f'`{e}`' for e in r['evidence']) or '—'
        lines.append(f'| {rid} | {r["matrix"]} | {r["status"]} | {r["test_set"]} | {ev} | {r["gap"]} |')
    return '\n'.join(lines) + '\n'


def main(argv):
    profile = json.loads(PROFILE.read_text())
    found = problems(profile) + required_check_problems()
    if found:
        print('\n'.join(found))
        return 1
    text = render(profile)
    if '--write' in argv:
        DOC.write_text(text)
    elif not DOC.exists() or DOC.read_text() != text:
        print('docs/VALIDATION_PROFILE.md is stale; run scripts/check_validation_profile.py --write')
        return 1
    print(f'Validation profile gates passed: {len(profile["requirements"])} requirement rows.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
