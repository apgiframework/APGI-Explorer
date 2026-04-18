# APGI Explorer macOS Production-Readiness Audit

Date: 2026-04-18  
Auditor: GPT-5.3-Codex (senior macOS engineering + QA review)

## Scope and methodology

This assessment is based on **repository-level static analysis** and command-line validation in the provided environment.

- ✅ Source walkthrough of core app, services, settings, and help/documentation modules.
- ✅ Consistency checks against README/App Store claims.
- ⚠️ GUI runtime tests, Instruments profiling, accessibility inspector, and end-to-end macOS interaction tests were **not executable** in this Linux container.

The findings below prioritize production hardening only (no net-new product scope).

---

## Executive summary

APGI Explorer is architecturally ambitious and includes many production-oriented modules (CloudKit sync, export, backups, crash reporting, settings surfaces, help system). However, multiple user-facing flows are still partially stubbed, several settings are disconnected from canonical behavior, and there are correctness/security gaps that prevent a true production-grade designation.

### Overall health score: **66 / 100**

**Justification**

- **Strengths**: broad feature surface, test suite presence, modular services, Core Data + CloudKit integration, explicit privacy screens.
- **Deficits**: crash-prone storage initialization, unimplemented action handlers in surfaced UI, recovery actions that throw `notImplemented`, placeholder crash signal handler, settings key drift, and release-readiness mismatch in user support/help links.

### Quality band interpretation

- **66/100 = Functional but flawed** (usable baseline, but critical and high-priority production blockers remain).

---

## Severity and priority rubric

- **Critical (P0/P1)**: crash/data-loss/security-risk.
- **High (P1/P2)**: core workflow broken or materially misleading.
- **Medium (P2/P3)**: secondary functional, UX, or maintainability issues.
- **Low (P3/P4)**: cosmetic/documentation/polish gaps.

---

## Prioritized bug and gap backlog

| ID | Title | Dimension(s) | Severity | Priority | Why it matters | Evidence |
|---|---|---|---|---|---|---|
| F-001 | Fatal crash when Documents directory lookup fails | Functional, Stability | **Critical** | **P0** | `fatalError` causes hard termination instead of recoverable error handling. | `FileStorageManager.documentsDirectory` uses `fatalError(...)`. |
| F-002 | Crash/signal hook is effectively a placeholder and can mask real signal behavior | Functional, Stability, Security | **High** | **P1** | Custom local `signal` function does not install OS-level handlers, so crash capture behavior differs from intent and may break diagnostics. | `CrashReportingManager.swift` defines private `signal(_:_: )` stub. |
| F-003 | Export/backup settings buttons are visible but unimplemented | Functional, Missing Features | **High** | **P1** | “Backup Now / Export All Profiles / Import Profiles” appear production-ready but do nothing. | `SettingsView.swift` button handlers contain placeholder comments. |
| F-004 | Data privacy actions “Export” and “Delete” are confirmed but unimplemented | Functional, Security/Privacy | **High** | **P1** | Privacy compliance and user trust impacted when data rights actions are non-functional. | `DataPrivacySettingsView.swift` alert handlers contain placeholder comments. |
| F-005 | File operation recovery advertises options that throw `notImplemented` | Functional, Reliability, UX | **High** | **P1** | Recovery UX promises remediation but fails for multiple suggested actions. | `FileOperationRecoveryManager.performRecoveryAction` throws `.notImplemented` for several cases. |
| F-006 | Settings key mismatch causes toggles to diverge from app behavior | Functional, UX | **High** | **P1** | Users can set values in one key while core managers read another key. | `GeneralSettingsView` uses `enableAnalytics`; `UserDefaultsManager` uses `analyticsEnabled`. `NotificationsSettingsView` uses `enableQuizReminders`; manager uses `quizReminderEnabled`. |
| F-007 | Cloud Sync options shown as disabled constants (“Auto-sync”, “Sync over cellular”) | Missing Settings, UX | **Medium** | **P2** | UI implies configurability that is not actually implemented. | `CloudSyncSettingsView` uses `.constant(true/false)` and `.disabled(true)`. |
| F-008 | Cloud sync info hardcodes environment as “Development” | Functional, UX, Documentation | **Medium** | **P2** | Production builds can misreport environment and mislead support/debugging. | `CloudSyncSettingsView` info row hardcodes `Environment: Development`. |
| F-009 | Menu bar “New Profile” action is TODO | Missing Features, UX | **Medium** | **P2** | Primary action exposed in menu bar has no behavior. | `MenuBarView.swift` TODO comment in action. |
| F-010 | Help menu contains placeholder bug-report URL | Documentation & Help, UX | **Medium** | **P2** | “Report a Bug” opens a non-real repo path (`yourrepo`). | `MenuCommands.swift` uses `https://github.com/yourrepo/issues`. |
| F-011 | App help/support URLs are inconsistent with App Store metadata endpoints | Documentation & Help, UX | **Medium** | **P2** | In-app support destinations differ from metadata canonical URLs, increasing support fragmentation. | `MenuCommands.swift` vs `AppStoreMetadata.json` URLs. |
| F-012 | Screenshot automation engine core capture path is stubbed (`nil`) | Functional, Missing Features | **Medium** | **P2** | Module is advertised; default capture path cannot produce images without external override. | `ScreenshotAutomationEngine.captureScreenImage()` returns `nil`. |
| F-013 | Screenshot automation “setResolution” is placeholder | Functional, Performance | **Low** | **P3** | Generated artifacts may not match requested device targets. | `ScreenshotAutomationEngine.setResolution` placeholder comment. |
| F-014 | Advanced “Clear All Data” performs broad batch deletes without post-delete validation/reporting | Security/Privacy, Stability | **Medium** | **P2** | Destructive operation lacks robust completion guarantees and user-visible success/failure granularity. | `AdvancedSettingsView.clearAllData()` loops all entities and logs errors only. |
| F-015 | “Privacy Policy Accepted” is an editable toggle | UI/UX, Compliance | **Medium** | **P3** | Acceptance should generally be an explicit consent flow artifact, not a free toggle in settings. | `DataPrivacySettingsView` exposes direct toggle. |
| F-016 | README claims “production-ready” and “95%+ coverage”, but code contains multiple user-facing stubs/TODOs | Documentation | **Medium** | **P2** | Overstated readiness increases release risk and expectation mismatch. | `README.md` claims vs TODO/placeholders in settings/menu/screenshot systems. |
| F-017 | Crash report storage writes raw stack traces to Documents without retention controls in module | Security/Privacy, Performance | **Low** | **P3** | Sensitive diagnostic content may persist indefinitely and grow over time. | `CrashReportingManager.saveCrashReport` writes files; no in-module retention policy. |
| F-018 | AppDelegate auto-update hook remains TODO | Missing Features | **Low** | **P4** | Release maintenance/update behavior incomplete if expected in shipped channel. | `AppDelegate.swift` TODO. |

---

## Six-dimension assessment

## 1) Functional Bugs

**Key issues**

- Hard crash path on storage bootstrap (`fatalError`) (Critical).
- Multiple surfaced controls do not execute actual business logic (High).
- Recovery system suggests actions that intentionally fail with `.notImplemented` (High).
- Placeholder crash signal setup creates reliability ambiguity in failure capture (High).

**Production impact**

- Potential startup/operation termination.
- Broken user promises in important data workflows.
- Reduced confidence in error handling and diagnostics.

## 2) UI/UX Issues (macOS HIG + usability + accessibility)

**Key issues**

- Settings screens include disabled pseudo-options without explanation (Cloud Sync).
- Some consent states are exposed as generic toggles instead of guided compliance flows.
- Menu bar includes nonfunctional primary action.
- Help/report routes include placeholder or inconsistent endpoints.

**Production impact**

- Users cannot reliably infer which controls are actionable.
- Increased support burden and trust erosion.

## 3) Performance and Stability

**Key issues**

- Crash-report retention lifecycle is not explicit inside crash manager.
- Screenshot automation heavy use of `Thread.sleep` on synchronous paths and incomplete resolution/capture implementation.
- Recovery and destructive operations lack robust user-facing success/failure accounting.

**Production impact**

- Potential sluggishness/operational uncertainty under load and automation.

## 4) Missing Settings and Feature Completion

**Key issues**

- Export/backup/data-rights actions not implemented in settings surfaces.
- Key mismatches across settings managers lead to ineffective toggles.
- Menu bar and updater integration remain unfinished.
- Screenshot automation claims exceed default executable implementation.

**Production impact**

- Feature completeness gaps in user-visible areas despite mature navigation structure.

## 5) Security and Privacy

**Key issues**

- Privacy action handlers for export/delete are missing.
- Diagnostic data retention and lifecycle need explicit constraints.
- Consent model is fragmented across multiple keys and surfaces.

**Production impact**

- Elevated compliance and audit risk; unclear enforceability of user consent/state.

## 6) Documentation and Help

**Key issues**

- README positioning is stronger than implementation state.
- In-app support links include placeholder destination.
- “What’s New” help action is surfaced but unimplemented.

**Production impact**

- Documentation mismatch can create adoption and support friction.

---

## Actionable plan to reach 100/100

## Phase 1 — Blocker elimination (Critical/High)

1. Replace `fatalError` storage bootstrap with throwing init + graceful fallback/recovery UI.
2. Implement all surfaced privacy/export/backup actions (or hide until ready).
3. Remove or fully implement recovery actions currently throwing `.notImplemented`.
4. Fix crash hook implementation by using proper libc signal registration (or constrain scope to uncaught exceptions and document limits).
5. Unify settings keys behind a single typed settings registry and add migration for existing keys.

## Phase 2 — Reliability and UX hardening

6. Convert Cloud Sync pseudo-options to real persisted settings (or present as read-only diagnostics section).
7. Implement Menu Bar “New Profile” parity with File menu behavior.
8. Add explicit destructive-operation completion feedback with per-entity outcomes for clear-data flow.
9. Complete screenshot automation defaults (capture + resolution handling) or clearly gate behind capability checks.

## Phase 3 — Security, compliance, and documentation polish

10. Add crash-report retention policy (TTL/max files), redaction review, and user-facing diagnostics controls.
11. Replace placeholder help/bug URLs with verified production endpoints; keep App Store metadata and in-app links in sync.
12. Adjust README quality claims to verifiable metrics from CI and current implementation status.
13. Add an in-app “What’s New” implementation or remove the menu item.

---

## Suggested release gate checklist (before production sign-off)

- [ ] Zero Critical and High findings open.
- [ ] All settings toggles map to canonical keys and behavior.
- [ ] All user-facing data rights actions are implemented and tested.
- [ ] Help, support, and bug-report paths verified.
- [ ] Crash and diagnostics handling reviewed for retention/privacy.
- [ ] README and metadata reflect real shipped capabilities.
