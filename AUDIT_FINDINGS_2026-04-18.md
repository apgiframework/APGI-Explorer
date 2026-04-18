# APGI Explorer macOS QA Audit (Static + Repository-Based)

Date: 2026-04-18  
Auditor: GPT-5.3-Codex (senior macOS dev + QA perspective)

## Scope & Method

This audit was performed by source inspection in the provided repository and command-line checks. No macOS GUI runtime execution was possible in this Linux container, so findings focus on verifiable implementation defects, unimplemented flows, and high-risk architectural issues.

## Overall Health Score

**64 / 100**

- The app appears feature-rich and structurally mature, but core areas advertised as complete still contain placeholders, TODOs, disabled settings, and action handlers that are not implemented.
- Data safety and reliability are weakened by crash-prone code paths and destructive/reset actions with broad impact.

## Severity / Priority Rubric

- **Critical**: crash, data loss, or security vulnerability.
- **High**: core feature broken or effectively unavailable.
- **Medium**: non-core functionality/UX defects, partial implementation.
- **Low**: cosmetic, copy, documentation/help polish.

---

## Prioritized Findings

### 1) Fatal crash path when Documents directory is unavailable
- **Area**: Functional Bugs / Stability
- **Severity**: **Critical**
- **Priority**: **P0**
- **Evidence**: `FileStorageManager` uses `fatalError("Unable to access Documents directory")` during lazy initialization.
- **Impact**: Hard crash can occur at app initialization and backup/export flow initialization, violating graceful degradation.
- **Recommendation**: Replace `fatalError` with thrown error propagation + user-visible recovery path (sandbox denial guidance, alternate directory chooser).

### 2) Settings actions are wired in UI but not implemented
- **Area**: Functional Bugs / Missing Features
- **Severity**: **High**
- **Priority**: **P1**
- **Evidence**:
  - `ExportBackupSettingsView`: “Backup Now”, “Export All Profiles”, “Import Profiles” button actions are placeholders.
  - `DataPrivacySettingsView`: export/delete confirmation handlers are empty comments.
  - `MenuBarView`: “New Profile” button TODO.
- **Impact**: Core flows appear available but are non-functional, damaging user trust and blocking key workflows.
- **Recommendation**: Implement action handlers end-to-end and add user feedback (progress, success/failure banners).

### 3) File recovery framework advertises options that throw `notImplemented`
- **Area**: Functional Bugs / Reliability
- **Severity**: **High**
- **Priority**: **P1**
- **Evidence**: `FileOperationRecoveryManager.performRecoveryAction` throws `.notImplemented` for multiple offered actions (different location, permissions, format, restart app).
- **Impact**: Error-recovery UX promises remediation but fails at runtime for several options.
- **Recommendation**: Either implement each recovery action or hide/disable unavailable actions and provide clear copy.

### 4) Settings persistence key mismatch creates ineffective toggles
- **Area**: Functional Bugs / UX Consistency
- **Severity**: **Medium**
- **Priority**: **P1**
- **Evidence**:
  - `GeneralSettingsView` uses `@AppStorage("enableAnalytics")`, while shared manager uses `analyticsEnabled` key.
  - `NotificationsSettingsView` uses `enableQuizReminders`, while shared manager key is `quizReminderEnabled`.
- **Impact**: Users may toggle settings that do not affect app behavior, causing silent configuration drift.
- **Recommendation**: Centralize keys in one source of truth and migrate old keys in a one-time upgrade routine.

### 5) Cloud sync settings are presented but disabled / static constants
- **Area**: Missing Settings / UX
- **Severity**: **Medium**
- **Priority**: **P2**
- **Evidence**: `CloudSyncSettingsView` shows “Auto-sync” and “Sync over cellular data” as constants and disabled controls.
- **Impact**: Settings pane suggests configurability that does not exist.
- **Recommendation**: Implement real persisted toggles with capability checks; otherwise relabel as “Info” not “Options”.

### 6) Image cache disk persistence is incomplete and can collide by filename
- **Area**: Performance / Stability
- **Severity**: **Medium**
- **Priority**: **P2**
- **Evidence**:
  - `saveImageToDisk` intentionally unimplemented.
  - Disk keying uses `url.lastPathComponent`, causing collisions for distinct URLs sharing a filename.
- **Impact**: Cache misses/redundant network fetches and possible wrong-image reads.
- **Recommendation**: Implement deterministic hash-based cache keys and complete disk write path.

### 7) Help and support endpoints are placeholder-quality
- **Area**: Documentation & Help / Trust
- **Severity**: **Low**
- **Priority**: **P3**
- **Evidence**: Menu links target `https://apgi-explorer.com/help` and `https://github.com/yourrepo/issues` (placeholder repository path).
- **Impact**: Broken help/reporting path in production degrades supportability.
- **Recommendation**: Replace with verified live links and add in-app diagnostics bundle for bug reports.

### 8) App delegate includes unimplemented updater hook
- **Area**: Missing Features
- **Severity**: **Low**
- **Priority**: **P3**
- **Evidence**: `applicationDidFinishLaunching` contains TODO for auto-update functionality.
- **Impact**: Claimed release/update maturity is not fully reflected in code.
- **Recommendation**: Integrate Sparkle or remove claims from documentation until complete.

---

## Six-Dimension Assessment

### A) Functional Bugs
- Several visible controls are non-operational placeholders.
- Crash-prone `fatalError` path exists in core storage bootstrap.

### B) UI/UX Issues
- Settings inconsistencies (toggle labels imply behavior not backed by implementation).
- Disabled pseudo-settings in cloud sync reduce clarity and violate expectation matching.

### C) Performance & Stability
- Incomplete disk caching and potential filename collisions reduce efficiency.
- Recovery subsystem incomplete for promised remediation actions.

### D) Missing Settings & Features
- Multiple settings categories exist, but some critical handlers are stubbed.
- MenuBar “New Profile” missing despite being surfaced as a primary action.

### E) Security & Privacy
- Privacy controls exist, but consistency between consent toggles and centralized secure-storage systems should be validated and unified.
- No direct critical vulnerability observed from static pass, but implementation cohesion is incomplete.

### F) Documentation & Help
- README claims “production-ready” and broad completeness, but codebase shows placeholders/TODOs in user-facing features.
- Help/bug-report links are not release-quality.

---

## Path to 90+ (Actionable)

1. **Crash elimination first (P0)**
   - Remove `fatalError` and add robust storage permission fallback.
2. **Close all placeholder actions (P1)**
   - Implement backup/export/import/data-deletion/new-profile flows with test coverage.
3. **Reconcile settings model (P1)**
   - One canonical settings registry + migration map + regression tests.
4. **Finish recovery pathways (P1/P2)**
   - Implement or remove unsupported recovery options.
5. **Harden cache architecture (P2)**
   - Add disk write support and content-addressed keys.
6. **Release-quality help & support (P3)**
   - Replace placeholder URLs, add in-app help indexing and diagnostics export.
7. **Documentation truthfulness pass (P3)**
   - Align README claims with actual delivered functionality and known limitations.

