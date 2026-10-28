"""Lexical language policy for runtime Swift sources.

This is a source scan, not visual QA and not a scientific-language audit: it cannot see
text assembled at runtime or rendered by system frameworks.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RETIRED = ['Prediction Error Sensitivity', 'Precision Allocation', 'Ignition Threshold', 'Somatic Bias']
CORE_LABELS = ROOT / 'APGI-Explorer/Core/ScoreLabels.swift'
REPORTED = re.compile(r'Reported [A-Za-z][A-Za-z-]*(?: [A-Za-z][A-Za-z-]*){0,5}')


def approved_labels():
    return json.loads((ROOT / 'contracts/identifiers.json').read_text())['score_labels']


def runtime_sources():
    return [p for p in sorted((ROOT / 'APGI-Explorer').rglob('*.swift'))]


def strip_comments(text):
    """Drop // and /* */ comments so prose in comments does not trip the gate."""
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return '\n'.join(re.sub(r'(?<![:"])//.*$', '', line) for line in text.split('\n'))


def violations(files=None, approved=None):
    """Return human-readable violations across runtime sources."""
    approved = approved or approved_labels()
    problems = []
    for path in files if files is not None else runtime_sources():
        text = strip_comments(path.read_text())
        rel = path.relative_to(ROOT) if path.is_absolute() and ROOT in path.parents else path
        for label in RETIRED:
            if label in text:
                problems.append(f'{rel}: retired display label "{label}"')
        if path.name == 'ScoreLabels.swift':
            continue
        for match in REPORTED.finditer(text):
            # Longest approved label that prefixes the match is accepted only inside the central file.
            if any(match.group(0).startswith(label) for label in approved):
                problems.append(f'{rel}: approved label literal outside ScoreLabels: "{match.group(0)}"')
            else:
                problems.append(f'{rel}: unapproved "Reported ..." literal "{match.group(0)}"')
    return problems


def central_labels_match(approved=None):
    approved = approved or approved_labels()
    text = CORE_LABELS.read_text()
    declared = re.findall(r'static let (?!approved)\w+ = "([^"]+)"', text)
    return declared == approved
