# Explorer audit — October 27, 2026

## Current result

The macOS app has a working HTTP client targeting `https://api.apgiframework.com`.
Launch and Settings → General request `/v1/meta`. Personal answers, item histories
and scores are not included in network requests. Settings displays HTTP/network
failures while the personal questionnaire continues offline.

This is a personal exploratory release. It does **not** implement the blocked
research release in the supplied register. All StoreKit products and local
research scoring are disabled. No research uploader or participant registration
runs, and no pre-existing profile can enter a research session.

## Live API evidence

Read-only requests were made against the canonical host during this audit:

| Endpoint | Result | Consequence |
| --- | --- | --- |
| `/openapi.json` | HTTP 200, OpenAPI 3.1 | Deployed contract pinned in `contracts/openapi-v1.json` |
| `/v1/meta` | HTTP 500, `INTERNAL_SERVER_ERROR`, request ID `553943f8-aa25-46d9-8e65-2bb1fc1defe3` | Release metadata cannot currently load |
| `/v1/version` | HTTP 401, `authentication_required` | Generated operation exists but is not required by the public connection check |

The pinned contract exposes participants, two consent types, studies, batteries,
trial ingestion and completion. It does not expose the complete Explorer research
contract required by the register:

- A retrievable, server-pinned 35-item bank with its canonical hash, version and item options.
- Four-purpose, locale-specific versioned consent copy and the product/research consent rules requested by the register. The deployed consent enum has only `research_participation` and `data_sharing`.
- The requested event sequence/idempotency acknowledgement with a `server_verified` condition before local deletion.
- A published allow-list connecting server-returned score fields to approved user-facing labels.
- An Explorer remote-configuration contract defining `validation_results` and research enablement. Unknown or malformed fields cannot enable either feature in this client.

These dependencies must be defined and deployed before enabling research. The
client never invents routes or silently substitutes bundled questions or local
scores. The existing server trial-ingestion endpoint alone is insufficient to
prove the register's exactly-once, verified-upload acceptance criterion.

## Code changes and acceptance coverage

| Register items | Result / evidence |
| --- | --- |
| S0-IDN-10.1–10.2; S1-EXP-03.8 | Canonical identifiers in `contracts/identifiers.json` and `APGIIdentifiers`. Help/updates point to `apgiframework.com`; source/support use the organisation repository. No old personal-account URL in runtime sources/metadata. Retiring old hosting and the personal repository still requires account access. |
| S1-CMP-01.4 | `APGIScorer` explicitly identified as an instrument scoring key, not a scientific model. |
| S1-LNG-04; S1-EXP-01.1–01.4; S3-PR6-01 | Four requested descriptive labels applied to personal result, comparison, export and chart surfaces. Eight group names now describe response patterns. Unsupported personality strengths, clinical/state predispositions and state likelihoods removed from result interpretation. State-reference visuals are labelled illustrative, not self-report. |
| S1-EXP-01.5; S3-PR6-02 | Spotlight writes removed. All app-owned legacy entries purged on launch, not merely left stale. Handoff carries a session ID only and is not eligible for search. |
| S1-EXP-01.6 and children; S3-PR6-03 | All five products remain disabled regardless of legacy entitlements. Loading, purchasing and delivery cannot enable features. Restoring does not contact StoreKit or unlock features. App Store Connect delisting remains external. |
| S1-EXP-01.7 | API metadata parser accepts only Boolean release flags and fails closed. Paid products remain hard-disabled in this release even if a flag is true; no scientific validation gate can be bypassed by a flag. Server-side flag semantics remain undefined. |
| S1-EXP-02.1–02.5 | `Result<APGIProfile, ScoringError>` contains an explicit error for incomplete, unknown-ID or out-of-range inputs. No numeric fallback. Exactly the item-ID set 1–35 is required. Invented reliability, CIs, nonlinear boosts and cross-subscale adjustments removed. No response-pattern heuristic rejects valid uniform answers or changes scores. |
| S1-EXP-02.6 | Local scorer explicitly rejects a research request. This release has no research questionnaire route. |
| S1-EXP-03.1–03.3; S3-EXP-01.8 | Item value, prior value, sequence and monotonic latency persist per local session in Core Data `QuizSession.jsonData`; resumable draft remains local. Timing uses `ContinuousClock`, resets on item presentation and resume. Placeholder timing confidence and unused reliability machinery retired. |
| S1-EXP-03.4 | Stored aggregates are rendered directly, never expanded into invented answers. New saved aggregates match displayed summaries to integer rounding. Legacy totals cannot be reconstructed into valid individual responses. |
| S1-EXP-03.5 | Option notes and interpretive tooltips are absent from the questionnaire. Emerging-score feedback removed during administration. |
| S1-EXP-03.6 | Items 7 and 9 remain required and journalled as nominal selections, excluded from ordinal numeric averages. |
| S1-EXP-03.7; S3-PR6-05 | Reproducible generated public metadata/version Swift operations from the pinned live OpenAPI snapshot. This is a deliberately limited public surface, not a complete research SDK. |
| S1-EXP-04 | Removed blanket Downloads/Pictures and photo-library write entitlements. User-selected read/write and outbound network access remain. |
| S1-EXP-05; S3-EXP-01.1 | Personal snapshots identify `apgi-explorer-35`, `analysis_mode=exploratory`, excluded from norms. No research export/personal import conversion occurs. |
| S3-EXP-01, .2–.7, .9–.12; S3-PR6-04, -06, -09 | Research release not shipped: consent, pinned bank, `PendingEvent`, authenticated background upload/backoff, verified acknowledgements, server-score allow-list and end-to-end offline acceptance remain dependent on the server/consent contracts above. No research tokens are collected or persisted. Privacy manifests remain unchanged because research data collection is not enabled. |
| S3-PR6-10 | Appendix/framework fixture parity is external to this repository and requires the qualified mathematical reference contract. No simulator parity claim is made. |
| XC-CI-08 and children | Native Xcode build/test workflows replace nonexistent SwiftPM/UI-test invocations. Offline gates check generated client drift, canonical identifiers, approved labels, local instrument-source fingerprint and privacy-manifest fingerprints. XCTest covers invalid inputs, independent subscales, nominal choices, local journal persistence, API failures and export correctness. A canonical server bank hash, full research-contract tests and branch-protection requirements remain external. |

## Personal scoring contract

Complete valid personal responses use equal-weight item averages on the existing
12.5, 37.5, 62.5, 87.5 display scale. Items 7 and 9 do not enter an ordinal mean.
The seven groups are independent. There are no empirically estimated reliability
weights, sigmoid transformations, interaction-derived boosts, confidence
intervals or normative interpretations. These changes alter older scores; old
aggregate-only data is displayed as recorded and cannot be retroactively rescored.

New results and local reports identify their exploratory limits. The report's
invented normative anchor at 50 and unvalidated analytics forecasts are removed.

## Additional defects corrected

- Export UI assigned a specialised export URL to a shadowed local variable,
  causing sharing to fail after successful file creation. The URL now reaches
  the share sheet.
- Text R scripts were labelled binary `.RData`; they now export as `.R` source
  with an explicit script description.
- Incomplete SPSS/Stata writers produced misleading files. Both formats now
  reject export and are removed from selectable statistical formats.
- All specialised `ProfileManager` exports use the same writer as the export
  UI; duplicate CSV-as-XLSX and CSV-as-statistical-file implementations are gone.
- Export filenames cannot contain path separators or traversal segments.
- CSV and XML escape names correctly, and descriptive exports no longer relabel
  questionnaire dimensions as autonomy, purposefulness, self-acceptance or growth.
- The basic PDF export now emits real PDF bytes rather than plain text with a `.pdf` extension.
- The saved-result confirmation retains the actual name after clearing the field.
- README and store metadata no longer claim validation, cloud sync or an unrelated
  “Adult Psychological Growth Inventory.” Metadata copy is English until reviewed
  translations are supplied.

## Verification and remaining limits

Final validation passed on the local macOS arm64 host: 87 XCTest cases, zero failures,
plus one Swift Testing case. The basic PDF regression confirmed a `%PDF-` header.
Generated-client drift checks, Explorer static contract gates and `git diff --check`
also passed. The last live metadata check still returned HTTP 500.

```sh
python3 scripts/generate_api_client.py --check
python3 scripts/check_explorer_contracts.py
xcodebuild test -project APGI-Explorer.xcodeproj -scheme APGI-Explorer \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/APGI-Explorer-build CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 30 \
  -maximum-test-execution-time-allowance 60
```

Result bundle: `/tmp/APGI-Explorer-build/Logs/Test/Test-APGI-Explorer-2026.10.27_19-24-55--0400.xcresult`.
The AppIntents metadata extraction notice and Excel export subprocess QoS diagnostic
are non-failing toolchain/runtime notices; neither is presented as a visual QA pass.

Live UI inspection timed out, so no visual or interactive end-to-end UI pass is
claimed. The project has a macOS unit-test target; its UI-test source directory is
not registered as a target. CI does not pretend that nonexistent target ran.

The existing distribution workflow and account-side release settings are not a
verified App Store deployment. No release, purchase, research enrollment, data
upload, repository transfer, Pages deletion or branch-protection change was made.

## Runtime follow-up

The subsequent console-log review found that the target had not attached the
entitlements file. The original unsigned unit-test run did not verify effective
sandbox permissions. Both build configurations now attach the file and enable
outgoing networking. A signed build and bundled sandboxed API probe verified the
fix. See `RUNTIME_VERIFICATION.md` for details and the updated 88-case test result.

## Update — October 28, 2026 (portable core, outbox and server contract)

This update adds the research-mode foundations **behind a disabled capability**. It does
not ship research, enable products, or change privacy manifests.

### What exists now

| Register items | Result / evidence |
| --- | --- |
| S1-EXP-03.7; S3-PR6-05 | `scripts/generate_api_client.py` generates all 121 operations of `contracts/openapi-v1.json` into `Core/APIOperationCatalog+Generated.swift` (methods, routes, parameters, body requirement, authentication, success statuses). Lossless `APIJSONValue`; not a typed schema SDK. Authentication explicit; redirects refused (`RedirectRejectingDelegate`). `CatalogTests` compares the catalog with the pinned spec operation by operation. |
| S1-EXP-01.7 | `ProductEligibility` needs the remote `validation_results` Boolean **and** `ExplorerBuildApproval.paidProductsApproved` (false). Every `StoreManager` entry point (load, purchase, restore, entitlements, feature flags) enforces it. A positive flow exists in code but cannot run in this build and has never been exercised. |
| S3-EXP-01.4; S3-PR6-04 | `PendingEvent` entity in new model version `APGISignature 2` (original version untouched, `.xccurrentversion` selects the new one, lightweight migration). Personal journals (`QuizSession`) are never read into the outbox. |
| S3-EXP-01.5/.6 | `UploadCoordinator` (ordering within a session, exponential backoff persisted in the store, relaunch recovery, redirects rejected, payload retained on offline/HTTP/invalid ack). Only an acknowledgement matching event key, sequence and payload digest with `server_verified` clears the payload; a verified tombstone blocks re-enqueue. `BackgroundUploadSession` (Darwin-only) sends file-backed uploads on a background configuration. Transport retries still depend on the server being idempotent. |
| S3-EXP-01.7 | `ResearchKeychainCredentialStore` (device-local, `ThisDeviceOnly`, no preference-store fallback); `ResearchCredentialManager` handles expiry, refresh-token rotation, coalesced concurrent refresh and sign-out cancellation. The pinned `TokenRefreshResponse` does include a new refresh token, so rotation is supported; the adapter (`ResearchAccountClient`) is new and has not been reviewed against a live server. Handoff still carries only a session ID. |
| S3-EXP-01.2/.3/.9/.10 foundations | `ResearchBankValidator` (canonical-byte hash, 35 items, four options), `ResearchConsentValidator` (four purposes, locale, version, approval, text hash), `ResearchRecorder` (monotonic, bank items only, provenance), `ScoreAllowlist` (unknown fields, unapproved labels, nonnumeric and nonfinite values rejected). Not wired to any enrollment UI or live API. |
| XC-CI-08.1/.3/.4 | Generator coverage test; `ScoreLabels` centralises approved labels across result, export, chart and report surfaces; `scripts/language_policy.py` rejects retired labels and unapproved `Reported …` literals in all runtime sources. This is a lexical scan, not visual QA or a scientific-language audit. |
| XC-CI-08 | Release workflow uses checksum-pinned Gitleaks (redacted findings) instead of the keyword grep; exceptions are exact truncated OpenAPI example values only. Retired action versions upgraded; coverage uses OIDC and the current run's named result bundle; nightly now uses the same signing-free test command as CI. `.github/required-checks.json` records desired required checks; it does not apply branch protection. |

### Server side (`apgi-api`, branch `claude/optimistic-bell-rpswal`)

Pinned item bank with canonical hash, four consent purposes with server-served versioned
text, idempotent journal upload with a `server_verified` acknowledgement echoing the
payload digest, and an allow-listed score read-back. Consent texts are **drafts**
awaiting S1-PRV-06 review; `research_enabled` stays false until they are approved and
`EXPLORER_RESEARCH_ENABLED=true`. None of this is deployed.

### Verified here, and what was not

Run on Linux with Swift 6.2: `swift test` (35 portable tests), a build with MainActor
default isolation, the Python generator, language-policy and secret-scan tests, the
contract gates, and the Gitleaks working-tree scan. Not run: the macOS app build, the
native `ResearchNativeTests` (Core Data persistence and migration, Keychain, StoreKit
gate), `BackgroundUploadSession`, background relaunch delivery, live upload, visual QA,
or hosted CI. Run the Xcode command in `.github/workflows/ci.yml` on macOS before merging.

### Still external

S0-IDN-10.1/.2 (disable the old Pages site; archive or transfer the personal repository),
App Store Connect delisting, branch-protection enforcement, consent text approval
(S1-PRV-06), qualified framework fixtures for S3-PR6-10, and a reviewed authentication
adapter.

## Update — October 29, 2026 (integrated research workflow, still disabled)

| Register items | Result / evidence |
| --- | --- |
| S3-EXP-01, S3-PR6-06 | `ResearchWorkflow` (Core) implements the opt-in flow: verify config and pinned bank, validate approved consent texts, sign in or register, grant purposes, create participant and session, record answers into the durable outbox, upload with acknowledgement, show allow-listed scores, withdraw. SwiftUI (`Services/Research`) provides consent, sign-in, questionnaire and result screens, reachable from Settings → General only when available. **Disabled:** `ExplorerBuildApproval.researchApproved` is false, so `ResearchModel.refreshAvailability()` returns before any network call. |
| S3-EXP-01.2 | Consent texts are fetched, validated (four purposes, locale, version, approval, text hash) and granted through the API; required purposes gate enrolment; the server's consent status is re-read before a session is created. Texts are drafts pending S1-PRV-06. |
| S3-EXP-01.3, XC-CI-08.2 | Questions render only from the fetched bank, which must match `contracts/explorer-instrument-pin.json` (generated into `ResearchPins`) and its own canonical hash. The pin is checked against the verified fixture in CI. A changed server bank is refused until the pin is reviewed and regenerated (`scripts/refresh_research_contract.py`). |
| S3-EXP-01.9 | Only allow-listed numeric fields under approved labels are displayed; unknown fields, unapproved labels and nonnumeric or nonfinite values are rejected. |
| S3-EXP-01.10 | `ResearchImportGate` admits only the server bank; `ResearchWorkflow.importLegacy` rejects personal and legacy sources; research events need research provenance; CI asserts the personal import and storage code never references the research path. There is no UI to import legacy data into research. |
| S3-EXP-01.11 | The feature flag is wired: build approval AND server `research_enabled` (which also needs study, battery and approved texts). |
| S3-EXP-01.12 | Not changed on purpose: the manifest must be reviewed against real collection when research ships. CI refuses `researchApproved = true` unless `contracts/research-privacy-review.json` matches the current manifest and declares the collected data types. |
| S3-PR6-09 | `WorkflowTests.testOfflineSessionUploadsExactlyOnceWithAllowlistedScores` runs 35 answers offline, a stored-but-unacknowledged batch, reconnect and retry, and asserts every event is stored once, in order, with allow-listed labels. This runs against an in-memory simulation of the API contract, **not** the deployed server or a native build. |
| S1-EXP-01.7 | `ProductEligibility` gate enforced at every StoreKit entry point; build approval false. |
| S1-CMP-01.4 | Classification recorded in `docs/COMPATIBILITY_MATRIX_ENTRY.md` and verified by CI. The parent matrix is not in this repository and still needs the entry copied in. |
| XC-CI-08 nightly | Root cause from the run logs (runs 40466735640 and 40653460966): `No signing certificate "Mac Development" found` on the hosted runner. The workflow now builds with `CODE_SIGNING_ALLOWED=NO`. Not yet confirmed green; the next scheduled run will show it. |
| XC-CI-08 required checks | Checked via the GitHub API: neither `main` nor any branch is protected, so **no check is required**. `.github/required-checks.json` records the intent only. |

## Update — October 29, 2026 (scorer verified on Linux; corrections)

- **S1-EXP-02.1–.6, XC-CI-08.6/.7:** `APGIScorer`, `APGIProfile` and `ParameterLevel` moved into `APGI-Explorer/Core` (same module, no behaviour change). 11 new portable tests (`ScorerTests`) run the scorer's invalid-input, completeness-by-item-set, unknown-ID, out-of-range (including nominal items 7 and 9), research-refusal, uniform-answer, subscale-independence and no-invented-reliability checks on Linux in CI. The native `ExplorerContractTests` still need a macOS run.
- **Correction:** earlier text said the server refresh response does not rotate refresh tokens. The pinned `TokenRefreshResponse` requires a new `refresh_token`, so rotation is supported; `ResearchAccountClient` implements it (not exercised against a live server).
- **GitHub account references:** the only remaining `lesoto` GitHub reference was in `apgi-api` docs and is replaced with `apgiframework`. `com.lesoto…` bundle, keychain-service and StoreKit product identifiers are not GitHub accounts and were left unchanged, because changing them alters app identity, entitlements and purchases.
- **Branch protection:** still not enforced (verified via the GitHub API: `main` and the working branch are unprotected). It cannot be applied from this repository or session.
- **Hosted CI:** runs for `daf69fc` remained queued for over 40 minutes, so the macOS build and native tests are still unverified.

## Update — October 30, 2026 (hosted CI results)

Hosted runs on `aa1c60a` (main):

| Check | Result | Evidence |
| --- | --- | --- |
| Explorer release gates: `contracts`, `secret-scan` | success | run 40797010818 |
| Explorer release gates: `build-and-test` (macOS: signed sandbox build, entitlement verification, `xcodebuild test` including `ResearchNativeTests` and `ExplorerContractTests`, coverage upload) | **success** | same run, job 123195804092 |
| Swift release build | success | run 40797010883 |
| Nightly Build (previously failing on signing) | **success** | run 40839705261 |
| Explorer release gates: `portable-swift` | failure: `libxml2.so.2` missing on the runner | fixed in `aad286d` by installing the Swift runtime dependencies; re-run pending |

What this establishes: the macOS app, including the new research code, builds and its XCTest suite exits successfully on a hosted runner, and the nightly failure is resolved. What it does not establish: individual test counts were not inspected here, `BackgroundUploadSession` relaunch behaviour, live uploads, the StoreKit positive flow, visual QA, and branch-protection enforcement (branches remain unprotected).
