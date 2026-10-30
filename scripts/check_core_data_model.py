"""Resolve the Core Data model version that Xcode compiles as current and check its contents.

`.xccurrentversion` selects which `*.xcdatamodel` becomes the app's current model. The research
outbox needs `PendingEvent` in that version, the original version must stay untouched, and every
attribute `CoreDataPendingEventStore` reads or writes must exist on the entity. Parsing the XML
(not grepping it) means a selector that points at the wrong version, a renamed attribute or a
dropped uniqueness constraint fails on any platform, not only under macOS CI.
"""
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / 'APGI-Explorer/APGIExplorer.xcdatamodeld'
STORE = ROOT / 'APGI-Explorer/Services/Research/CoreDataPendingEventStore.swift'
ORIGINAL_VERSION = 'APGISignature.xcdatamodel'
ENTITY = 'PendingEvent'


def current_version(model_dir):
    selector = plistlib.loads((model_dir / '.xccurrentversion').read_bytes())['_XCCurrentVersionName']
    return selector


def entity(model_dir, version):
    contents = model_dir / version / 'contents'
    if not contents.exists():
        return None
    for node in ET.parse(contents).getroot().iter('entity'):
        if node.get('name') == ENTITY:
            return node
    return None


def attributes(node):
    return {a.get('name'): a for a in node.findall('attribute')}


def keys_used_by_store(source):
    return set(re.findall(r'forKey:\s*"(\w+)"', source)) | set(re.findall(r'NSPredicate\(format:\s*"(\w+) ', source))


def problems(model_dir=MODEL_DIR, store=STORE):
    found = []
    try:
        selected = current_version(model_dir)
    except (OSError, KeyError, plistlib.InvalidFileException) as error:
        return [f'.xccurrentversion unreadable: {error}']
    node = entity(model_dir, selected)
    if node is None:
        found.append(f'Current model version {selected!r} does not contain {ENTITY}; '
                     f'.xccurrentversion must select the version with the research outbox')
    else:
        attrs = attributes(node)
        used = keys_used_by_store(store.read_text())
        missing = sorted(used - set(attrs))
        if missing:
            found.append(f'{ENTITY} lacks attributes the Core Data store uses: {missing}')
        constraints = [c.get('value') for c in node.iter('constraint')]
        if 'eventKey' not in constraints:
            found.append(f'{ENTITY} must keep a uniqueness constraint on eventKey')
        for name in ('payloadDigest', 'sessionID', 'eventKey', 'stateRaw', 'seqNo', 'createdAt'):
            if name in attrs and attrs[name].get('optional') != 'NO':
                found.append(f'{ENTITY}.{name} must be non-optional')
        if 'payload' in attrs and attrs['payload'].get('optional') != 'YES':
            found.append(f'{ENTITY}.payload must be optional (cleared on verification)')
    if selected == ORIGINAL_VERSION:
        found.append('Original model version must not be the current version')
    if entity(model_dir, ORIGINAL_VERSION) is not None:
        found.append('Original model version must stay unchanged (it must not contain PendingEvent)')
    original = model_dir / ORIGINAL_VERSION / 'contents'
    if not original.exists():
        found.append('Original model version is missing; lightweight migration needs both versions')
    return found


if __name__ == '__main__':
    issues = problems()
    for issue in issues:
        print('ERROR:', issue)
    if issues:
        sys.exit(1)
    print('Core Data model gate passed: current version', current_version(MODEL_DIR))
