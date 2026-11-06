# Application Validation Profile — APGI-Explorer (A07)

<!-- Generated from contracts/validation-profile.json by scripts/check_validation_profile.py --write. Do not edit by hand. -->

Specification: APGI-VAL-SPEC-1.2 (Draft for approval). Status: **Draft: owner and approver sign-off pending**.

| Field | Value |
| --- | --- |
| Repository | apgiframework/APGI-Explorer |
| App version | 1.0 (1) |
| Release owner | PENDING: assign |
| Platforms | macOS (Swift 5 app target); Linux/macOS (portable Core package) |
| Data classes | personal questionnaire answers (local only); research events (disabled in this release) |
| Interfaces | GET https://api.apgiframework.com/v1/meta; research API (disabled) |
| Declared Protocol v1.2 definitions | None. Explorer implements no protocol definition. |
| Approved exclusions | None approved yet. Rows marked Not applicable (declared) need owner approval. |

Statuses are evidence-based. "Implemented" means the repository contains the control and a CI check or test exercises it. It does not mean the specification owner has approved it.

| Requirement | A07 | Status | Test set | Evidence | Gap and required work |
| --- | --- | --- | --- | --- | --- |
| ACQ-001 | – | Not applicable | n/a | — | Explorer performs no hardware acquisition. |
| API-001 | C | Implemented | TC-API-01 | `contracts/openapi-v1.json`<br>`contracts/api-contract-pin.json`<br>`scripts/generate_api_client.py`<br>`scripts/check_api_contract_pin.py` | Generated catalogs are checked against the pinned OpenAPI snapshot and the apgi-api commit. Deployed consumer-contract evidence is pending. |
| API-002 | C | Partial | TC-SEC-01 | `APGI-Explorer/Core/ResearchCredentials.swift`<br>`APGI-Explorer/Services/Research/ResearchKeychainCredentialStore.swift` | Device-local credentials and refresh rotation exist. Live authorization review pending; research disabled. |
| API-003 | R | Partial | TC-SEC-01 | `APGI-Explorer/Services/KeychainManager.swift`<br>`.gitleaks.toml`<br>`contracts/proposed-PrivacyInfo.research.xcprivacy` | Tokens live in Keychain, the transport rejects non-HTTPS origins, secret scan in CI. At-rest encryption of local session data is not separately evidenced. |
| API-004 | C | Partial | TC-API-02 | `APGI-Explorer/Core/APITransport.swift`<br>`APGI-Explorer/Services/ExplorerAPIStatus.swift` | Errors are surfaced as named states. Redaction of server excerpts needs a test. |
| CLI-001 | R | Partial | TC-CLI-01 | `APGI-Explorer/Core/APGIScorer.swift`<br>`APGI-Explorer/AccessibilityManager.swift`<br>`APGI-Explorer/PrivacyPolicyView.swift`<br>`APGI-Explorer/Info.plist`<br>`APGI-ExplorerUITests/APGI_ExplorerUITests.swift` | Reference scoring, privacy manifest and accessibility support exist. The declared accessibility level is [CONFIRM] and no accessibility report is retained. |
| CON-001 | R | Partial | TC-CON-01 | `APGI-Explorer/Core/ResearchWorkflow.swift`<br>`Tests/ExplorerCoreTests/WorkflowTests.swift`<br>`Tests/ExplorerCoreTests/Fixtures/consent-texts-approved-for-test.json` | Four-purpose versioned consent validation blocks enrolment and upload. Consent texts are drafts and research is disabled pending S1-PRV-06 approval. |
| CON-002 | R | Partial | TC-CON-02 | `APGI-Explorer/Core/ResearchOutbox.swift`<br>`Tests/ExplorerCoreTests/OutboxTests.swift` | Local copy is deleted only after server_verified acknowledgement. Server-side withdrawal orchestration and backup policy are external. |
| DAT-001 | C | Partial | TC-DAT-01 | `APGI-Explorer/Core/APGIScorer.swift`<br>`Tests/ExplorerCoreTests/ScorerTests.swift`<br>`Tests/ExplorerCoreTests/Fixtures/item-bank.json` | Scorer rejects incomplete, unknown-ID and out-of-range input. Golden dataset approval by the scientific authority is pending. |
| DAT-002 | – | Not applicable | n/a | `Tests/ExplorerCoreTests/OutboxTests.swift` | Marked a dash for A07. Outbox duplicate and lost-ack handling is tested anyway. |
| DAT-003 | C | Partial | TC-DAT-03 | `APGI-Explorer/FileStorageManager.swift`<br>`APGI-Explorer/UserDataExport.swift`<br>`APGI-Explorer/Core/ResearchOutbox.swift` | Local deletion and export exist. No approved per-data-class retention and recovery rules. |
| DAT-004 | R | Partial | TC-DAT-04 | `contracts/explorer-instrument-pin.json`<br>`contracts/release-hashes.json`<br>`APGI-Explorer/Core/ResearchContract.swift` | Instrument bank is versioned, checksummed and bound to every research event. License and full processing history are not recorded in results. |
| IMP-001 | R | Partial | TC-IMP-01 | `.github/workflows/ci.yml`<br>`.swift-version`<br>`Package.swift`<br>`contracts/release-hashes.json` | Source commit and contract hashes are pinned. No release-bound build record, artifact digests or SBOM for a candidate. |
| IMP-002 | R | Partial | TC-IMP-01 | `scripts/run_secret_scan.py`<br>`.gitleaks.toml`<br>`APGI-Explorer/Services/KeychainManager.swift`<br>`scripts/verify_app_entitlements.py` | Secret scan, Keychain storage and sandbox entitlement verification exist. Production-credential review against deployed auth is pending. |
| IMP-003 | R | Partial | TC-IMP-01 | `APGI-Explorer/CrashReportingManager.swift`<br>`docs/RUNTIME_VERIFICATION.md` | Crash reporting exists. No fault-injection evidence that operational alerts and handoff work. |
| INT-001 | R | Implemented | TC-INT-01 | `contracts/explorer-research-v1.json`<br>`contracts/api-contract-pin.json`<br>`Tests/ExplorerCoreTests/TypedSchemaTests.swift`<br>`Tests/ExplorerCoreTests/Fixtures/upload-vectors.json` | Sealed research contract is hash-pinned to apgi-api and shared vectors match. Protocol-version field requirement awaits the canonical schemas. |
| INT-002 | R | Blocked | TC-INT-01 | `Tests/ExplorerCoreTests/WorkflowTests.swift` | Needs a pinned release set across all components. Only an in-memory API simulation exists. |
| INT-003 | R | Implemented | TC-INT-01 | `APGI-Explorer/Core/APGIScorer.swift`<br>`Tests/ExplorerCoreTests/Fixtures/score-allowlist.json`<br>`Tests/ExplorerCoreTests/ScorerTests.swift` | Scorer returns explicit errors; research scores outside the allow-list are rejected. No substitute values. |
| INT-004 | R | Partial | TC-INT-02 | `Tests/ExplorerCoreTests/Fixtures/score-allowlist.json`<br>`Tests/ExplorerCoreTests/ScorerTests.swift` | Displayed values come from the scorer or the allow-listed server score. Retained comparison at displayed precision against upstream artifacts is pending. |
| PRO-001 | C | Partial | TC-PRO-01 | `Package.swift`<br>`contracts/api-contract-pin.json` | Explorer implements no Protocol v1.2 definition. It consumes a pinned apgi-api contract; the Protocol v1.2 to Explorer map needs the approved definitions. |
| PRO-002 | C | Partial | TC-PRO-02 | `APGI-Explorer/Core/ResearchContract.swift`<br>`Tests/ExplorerCoreTests/ResearchContractTests.swift` | Pinned research contract and bank hash are verified before use; no Protocol definition loader exists to test. |
| PRO-003 | – | Not applicable | n/a | `APGI-Explorer/Core/ResearchOutbox.swift` | Marked a dash for A07. Outbox idempotency is covered under DAT/INT. |
| PRO-004 | R | Implemented | TC-PRO-01 | `docs/VALIDATION_PROFILE.md`<br>`contracts/validation-profile.json` | Profile added in this change. Owner and approver sign-off are still pending. |
| REL-001 | R | Partial | TC-REL-01 | `.github/workflows/release.yml`<br>`.github/required-checks.json` | CI definitions exist. Branch protection is not enforced and no approved immutable candidate record exists. |
| REL-002 | R | Partial | TC-REL-01 | `README.md`<br>`docs/MERGE_CONFLICT_PLAYBOOK.md`<br>`build_and_notarize.sh` | Install and build steps exist. No candidate-specific rollback record. |
| REL-003 | R | Partial | TC-REG-01 | `docs/EXPLORER_AUDIT.md`<br>`.github/workflows/ci.yml` | Audit and CI exist. No per-change validation-impact assessment trail. |
| REL-004 | R | Partial | TC-REL-02 | `docs/COMPATIBILITY_MATRIX_ENTRY.md`<br>`contracts/api-contract-pin.json` | App 1.0, bank 1.0.0 and pinned contract are recorded. Compatibility with Protocol v1.2 is not claimed or tested. |
| REL-005 | R | Blocked | TC-REL-02 | — | No release certificate or archival deposit plan. Certificate-before-deposit rule needs an owner and process. |
| REP-001 | C | Implemented | TC-REP-01 | `contracts/release-hashes.json`<br>`contracts/explorer-instrument-pin.json`<br>`scripts/check_explorer_contracts.py` | Instrument bank and contract artifacts are SHA-256 pinned and CI-verified. Protocol lock and OpenTimestamps proof are external. |
| REP-002 | C | Partial | TC-REP-02 | `Tests/ExplorerCoreTests/Fixtures/canonical-vectors.json`<br>`scripts/generate_swift_vectors.py` | Scorer is deterministic with no randomness. Shared Swift/Python vectors are reproducible. Cross-platform numerical comparison is limited to the portable Linux job. |
| REP-003 | – | Not applicable | n/a | — | Marked a dash for A07. Explorer performs no power or sample-size calculation. |
| REP-004 | – | Not applicable | n/a | `APGI-Explorer/Core/APGIScorer.swift` | Marked a dash for A07. Personal snapshots carry analysis_mode=exploratory. |
| REP-005 | – | Not applicable | n/a | — | Marked a dash for A07. |
| SCI-001 | C | Implemented | TC-SCI-01 | `APGI-Explorer/Core/APGIScorer.swift`<br>`Tests/ExplorerCoreTests/ScorerTests.swift`<br>`docs/COMPATIBILITY_MATRIX_ENTRY.md` | APGIScorer is an instrument scoring key, not an equation implementation. Parent matrix copy (S1-CMP-01.4) is external. |
| SCI-002 | R | Not applicable (declared) | TC-SCI-01 | `docs/VALIDATION_PROFILE.md` | Explorer implements no dynamic threshold equation. Exclusion needs owner approval in the profile. |
| SCI-003 | R | Not applicable (declared) | TC-SCI-03 | `docs/VALIDATION_PROFILE.md` | No timescale hierarchy implemented. Exclusion needs owner approval. |
| SCI-004 | R | Partial | TC-SCI-04 | `contracts/identifiers.json`<br>`APGI-Explorer/Core/ScoreLabels.swift`<br>`scripts/language_policy.py` | Display labels are descriptive and policy-checked. The controlled Notation Appendix is external; symbol-to-notation map not yet verified. |
| SCI-005 | C | Partial | TC-SCI-04 | `contracts/explorer-instrument-pin.json`<br>`APGI-Explorer/Core/APGIScorer.swift` | Scoring constants (1-4 responses, 12.5-87.5 display scale) are documented in code. No provenance label registry (derived/calibrated/assumed) exists. |
| SCI-006 | R | Implemented | TC-SCI-04 | `scripts/language_policy.py`<br>`contracts/identifiers.json` | Canonical name enforced by the language policy gate. Archive and remote metadata not verified. |
| SCI-007 | R | Partial | TC-SCI-05 | `scripts/language_policy.py`<br>`APGI-Explorer/Core/ScoreLabels.swift`<br>`docs/EXPLORER_AUDIT.md` | User-visible text is label-policed and framed as exploratory. No CLM-nnn claim register or statement-to-claim map yet; that register is external. |
| VAL-001 | – | Not applicable | n/a | — | Explorer makes no registered validation decision. |
