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
