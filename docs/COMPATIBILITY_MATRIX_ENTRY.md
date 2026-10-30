# Scientific model compatibility matrix — APGI-Explorer entry (S1-CMP-01.4)

The parent matrix (S1-CMP-01) is not in this repository. This entry is the text to
copy into it, and `scripts/check_explorer_contracts.py` verifies the classification
below against the source on every CI run.

| Component | Classification | Not a… | Evidence |
| --- | --- | --- | --- |
| `APGI-Explorer/Core/APGIScorer.swift` | **Instrument scoring key** for the exploratory 35-item self-report questionnaire `apgi-explorer-35` | scientific model, validated measure, norm-referenced score, or source of reliability or confidence intervals | The file header states "Descriptive scoring key for the exploratory local instrument, not a scientific model." The scorer returns equal-weight item means on a 12.5–87.5 display scale; items 7 and 9 are nominal and excluded; subscales are independent (no cross-subscale terms). |
| Server scoring (`apgi-api` `explorer_contract.score_answers`) | Same instrument scoring key, applied server-side to research sessions | scientific model | Mirrors the client key; only four allow-listed fields leave the server. |

Compatibility with any APGI model version: **none is claimed.** Explorer sessions carry
`analysis_mode: exploratory` and are excluded from norms.

## Entry status

| Field | Value |
| --- | --- |
| Parent matrix | **Not in this repository.** Copying this entry into S1-CMP-01 and verifying its acceptance needs access to that matrix; it has not been done. |
| Classified source | `APGI-Explorer/Core/APGIScorer.swift` |
| Source fingerprint (SHA-256) | `743cbea9d1b9e9f9a665a5de505cfaf68abbe23454056d3f7644547cdfdb9e2b` |
| Kept current by | `scripts/check_explorer_contracts.py` fails when the scorer's bytes no longer match this fingerprint. Whoever changes the scorer re-reads the classification above, updates it if needed, and then updates the fingerprint. |
| Server-side counterpart | `apgi-api` `app/services/explorer_contract.py` `score_answers`; its result is exercised by `tests/integration/test_explorer_contract.py` and `tests/integration/test_explorer_swift_vectors.py`. |
