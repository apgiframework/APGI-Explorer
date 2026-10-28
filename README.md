# APGI Explorer

Native SwiftUI macOS client for the APGI exploratory self-report instrument.
The shipping target currently requires macOS 26.3 and a compatible Xcode SDK.

Personal mode uses 35 bundled questions and stays local. It is an exploratory
questionnaire, not a validated psychological measure, diagnostic instrument,
scientific model, or source of population norms. `APGIScorer` is the local
instrument scoring key. Items 7 and 9 are nominal choices and do not contribute
to numeric averages. All 35 valid item responses are required for a result.

The app requests public release metadata from **https://api.apgiframework.com/v1/meta**
on launch and from Settings → General → APGI API → Check connection. Requests
contain no questionnaire answers or participant credentials. Network and HTTP
errors appear in Settings; they do not interrupt personal mode. API metadata does
not enable paid products or research participation in this release.

- Website: https://apgiframework.com
- API: https://api.apgiframework.com
- Source: https://github.com/apgiframework/APGI-Explorer
- Support: https://github.com/apgiframework/APGI-Explorer/issues
- Local instrument: `apgi-explorer-35`
- Analysis mode: `exploratory`, excluded from norms

## Build and verify

```sh
python3 scripts/generate_api_client.py --check
python3 scripts/check_explorer_contracts.py
xcodebuild test -project APGI-Explorer.xcodeproj -scheme APGI-Explorer \
  -destination 'platform=macOS' -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

`contracts/openapi-v1.json` is the deployed API snapshot fetched on October 27,
2026. `scripts/generate_api_client.py` reproducibly generates the public metadata
and version operations used by this client. It does **not** generate a complete
research API SDK. Refresh the snapshot deliberately and regenerate the client
when the server contract changes.

Answer values, changes, sequence numbers and monotonic latencies are stored in
local Core Data `QuizSession.jsonData`. UserDefaults retains the resumable draft.
Completed histories remain local; scores are never indexed in Spotlight. Handoff
contains only a session ID; cross-device answer restoration is unavailable.
Saved aggregate results are displayed directly, without fabricating answers.
Older aggregate-only profiles cannot recover missing item histories.

## Research release dependencies

Research mode and all five StoreKit products remain disabled. The deployed API
currently lacks the pinned item-bank/hash, versioned consent-copy retrieval,
verified event acknowledgement and score-label allow-list contracts required by
the supplied acceptance criteria. No personal or legacy data can enter a research
upload path. Background upload, `PendingEvent`, research authentication, consent
and server score rendering are not shipped by this change.

See [the audit](docs/EXPLORER_AUDIT.md) for evidence, acceptance coverage and the
remaining server/account work. App Store publication, product delisting, branch
protection, and retiring the former personal-account hosting require account-side
changes; editing this repository does not perform them.
