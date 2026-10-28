"""Offline release gates. Update pinned hashes only after intentional contract review."""
import hashlib
import json
import plistlib
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / 'APGI-Explorer'
ids = json.loads((root / 'contracts/identifiers.json').read_text())
hashes = json.loads((root / 'contracts/release-hashes.json').read_text())
for file, expected in hashes.items():
    assert hashlib.sha256((root / file).read_bytes()).hexdigest() == expected, f'Review changed release artifact: {file}'
assert ids['api'] == 'https://api.apgiframework.com'
assert ids['instrument_id'] == 'apgi-explorer-35'
assert ids['excluded_from_norms'] is True
client = (app / 'Services/APGIAPIClient.swift').read_text()
assert ids['api'] in client and ids['website'] in client
assert ids['support'] in client
model = (app / 'QuizModel.swift').read_text()
assert ids['instrument_id'] in model and 'ContinuousClock' in model
assert 'timeConsistencyScore' not in model
import sys
sys.path.insert(0, str(root / 'scripts'))
import language_policy
assert language_policy.central_labels_match(ids['score_labels']), 'ScoreLabels.swift differs from contracts/identifiers.json'
problems = language_policy.violations(approved=ids['score_labels'])
assert not problems, 'Language policy violations:\n' + '\n'.join(problems)
for file in ['ResultsView.swift', 'QuizView.swift', 'ExportView.swift', 'EnhancedProfileChart.swift', 'ComparisonChartViews.swift',
             'ReportGenerator.swift', 'Services/ResearchExportManager.swift']:
    text = (app / file).read_text()
    assert 'ScoreLabels.' in text, f'{file} must take score labels from ScoreLabels'
    assert 'option.note' not in text and 'option.tooltip' not in text
for file in [app / 'APGIScorer.swift', app / 'QuizModel.swift']:
    text = file.read_text()
    for forbidden in ['baseReliabilities', 'flaggedProfile', 'performCrossValidation', '1.96']:
        assert forbidden not in text
spotlight = (app / 'Services/SpotlightManager.swift').read_text()
assert 'indexSearchableItems' not in spotlight and 'deleteAllSearchableItems' in spotlight
handoff = (app / 'HandoffManager.swift').read_text()
assert '"sessionID"' in handoff and '"answers"' not in handoff
entitlements = plistlib.loads((app / 'APGI-Explorer.entitlements').read_bytes())
assert entitlements['com.apple.security.files.user-selected.read-write']
assert not any(k in entitlements for k in ['com.apple.security.files.downloads.read-write', 'com.apple.security.files.pictures.read-write', 'com.apple.security.assets.pictures.read-write'])
for file in list(app.rglob('*.swift')) + [app / 'Info.plist', app / 'AppStoreMetadata.json']:
    text = file.read_text()
    assert 'lesoto.github.io/APGI-Explorer' not in text and 'github.com/lesoto/APGI-Explorer' not in text
core = app / 'Core'
assert 'static let paidProductsApproved = false' in (core / 'ScoreLabels.swift').read_text(), 'Paid products must stay unapproved in this build'
assert 'static let shipped = ResearchCapability(isEnabled: false)' in (core / 'ResearchOutbox.swift').read_text(), 'Research capability must ship disabled'
keychain = (app / 'Services/Research/ResearchKeychainCredentialStore.swift').read_text()
assert 'UserDefaults' not in keychain and 'ThisDeviceOnly' in keychain, 'Research credentials: device-local Keychain only'
assert 'UserDefaults' not in (core / 'ResearchCredentials.swift').read_text()
store = (app / 'Services/StoreManager.swift').read_text()
assert store.count('eligibility.isEligible') >= 6, 'Every StoreKit entry point must enforce the eligibility gate'
assert 'RedirectRejectingDelegate()' in (core / 'APITransport.swift').read_text(), 'Production sessions must reject redirects'
assert 'ResearchOutbox' not in (app / 'QuizModel.swift').read_text() and 'PendingEvent' not in (app / 'ProfileManager.swift').read_text(), 'Personal journals must never feed the research outbox'
model_dir = app / 'APGIExplorer.xcdatamodeld'
assert 'name="PendingEvent"' in (model_dir / 'APGISignature 2.xcdatamodel/contents').read_text()
assert 'name="PendingEvent"' not in (model_dir / 'APGISignature.xcdatamodel/contents').read_text(), 'Original model version must stay unchanged'
assert 'APGISignature 2.xcdatamodel' in (model_dir / '.xccurrentversion').read_text()
print('Explorer contract gates passed: identifiers, labels, instrument/privacy hashes, scorer, Spotlight, Handoff, sandbox.')
# Source entitlements alone do not prove that Xcode embeds them in either configuration.
project = (root / 'APGI-Explorer.xcodeproj/project.pbxproj').read_text()
for configuration in ['Debug', 'Release']:
    pattern = rf'/\* {configuration} configuration for PBXNativeTarget "APGI-Explorer" \*/.*?\n\t\t\}};'
    block = re.search(pattern, project, flags=re.S)
    assert block, f'Missing {configuration} build configuration'
    for setting in ['CODE_SIGN_ENTITLEMENTS = "APGI-Explorer/APGI-Explorer.entitlements";',
                    'ENABLE_APP_SANDBOX = YES;', 'ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;',
                    'ENABLE_USER_SELECTED_FILES = readwrite;']:
        assert setting in block.group(), f'{configuration} is missing {setting}'
assert 'requestAuthorization(' not in (app / 'APGI_ExplorerApp.swift').read_text(), 'Do not prompt for notification permission at launch'
print('Runtime configuration gates passed for Debug and Release.')
