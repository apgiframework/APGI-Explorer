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
for file in [app / 'Core/APGIScorer.swift', app / 'QuizModel.swift']:
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
import json as _json
pin = _json.loads((root / 'contracts/explorer-instrument-pin.json').read_text())
sys.path.insert(0, str(root / 'scripts'))
def _canonical(value):
    return _json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
fixture = _json.loads((root / 'Tests/ExplorerCoreTests/Fixtures/item-bank.json').read_text())
unsigned = {k: v for k, v in fixture.items() if k != 'sha256'}
assert hashlib.sha256(_canonical(unsigned).encode()).hexdigest() == fixture['sha256'] == pin['sha256'], 'Pinned server bank hash differs from the verified fixture bank'
assert pin['instrument_id'] == ids['instrument_id'] and pin['item_count'] == 35
matrix = (root / 'docs/COMPATIBILITY_MATRIX_ENTRY.md').read_text()
assert 'Instrument scoring key' in matrix and 'not a scientific model' in (app / 'Core/APGIScorer.swift').read_text()
scorer_sha = hashlib.sha256((app / 'Core/APGIScorer.swift').read_bytes()).hexdigest()
assert f'`{scorer_sha}`' in matrix, 'APGIScorer.swift changed: re-read docs/COMPATIBILITY_MATRIX_ENTRY.md, then update its fingerprint'
for personal in ['FileStorageManager.swift', 'HandoffManager.swift', 'ProfileManager.swift', 'QuizModel.swift', 'SettingsView.swift', 'MenuCommands.swift']:
    text = (app / personal).read_text()
    for research in ['ResearchWorkflow', 'ResearchRecorder', 'UploadCoordinator', 'PendingEvent', 'ResearchModel']:
        assert research not in text, f'{personal} must not touch the research path ({research})'
approval = (core / 'ScoreLabels.swift').read_text()
assert 'static let researchApproved = false' in approval or (root / 'contracts/research-privacy-review.json').exists(), 'Research cannot be approved before the privacy manifest is reviewed (S3-EXP-01.12)'
if 'static let researchApproved = true' in approval:
    review = _json.loads((root / 'contracts/research-privacy-review.json').read_text())
    manifest = (app / 'PrivacyInfo.xcprivacy').read_bytes()
    assert review['privacy_manifest_sha256'] == hashlib.sha256(manifest).hexdigest(), 'Privacy manifest changed since its research review'
    assert review['collected_data_types_declared'] is True
assert 'ResearchModel.shared' in (app / 'SettingsViews/GeneralSettingsView.swift').read_text() or 'ResearchEntryView' in (app / 'SettingsViews/GeneralSettingsView.swift').read_text(), 'Research feature flag must be wired into the app'
# Research test-build harness (item 6): the acceptance flag is command-line only and Debug-only.
test_build = (core / 'ResearchTestBuild.swift').read_text()
assert '#if !DEBUG && APGI_RESEARCH_TEST_BUILD' in test_build and '#error(' in test_build, 'Release builds must reject the acceptance flag'
assert '#if DEBUG && APGI_RESEARCH_TEST_BUILD' in test_build
assert 'APGI_RESEARCH_TEST_BUILD' not in (root / 'APGI-Explorer.xcodeproj/project.pbxproj').read_text(), \
    'The acceptance flag must never be written into the Xcode project (Release would inherit it)'
assert 'ResearchTestBuild.resolve' in (app / 'Services/Research/ResearchModel.swift').read_text()
assert 'ExplorerBuildApproval.researchApproved' not in (app / 'Services/Research/ResearchModel.swift').read_text().split('func refreshAvailability')[1], \
    'Availability must go through ResearchTestBuild.resolve'
# The Core Data model gate parses the model XML (item 2) instead of only grepping it.
import check_core_data_model
assert not check_core_data_model.problems(), check_core_data_model.problems()
import check_privacy_draft
assert not check_privacy_draft.problems(), check_privacy_draft.problems()
assert (root / 'APGI-ExplorerUITests').is_dir() and 'APGI-ExplorerUITests' in (root / 'APGI-Explorer.xcodeproj/project.pbxproj').read_text(), \
    'APGI-ExplorerUITests must be a registered Xcode target'
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
