# APGI Explorer — macOS Lead Architect Assessment Report

> **Authored by:** Senior macOS Lead Architect
> **Review Date:** 2026-03-01
> **Codebase Revision:** `6fbcafc` (branch `claude/macos-roadmap-design-ficOR`)
> **Platform Target:** macOS 12.0+, Universal (arm64 + x86_64)
> **Primary Framework:** SwiftUI 3.0 with AppKit interop

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [KPI Scores Table](#2-kpi-scores-table)
3. [Functional Completeness Assessment](#3-functional-completeness-assessment)
4. [Bug Inventory](#4-bug-inventory)
5. [Missing Features Log](#5-missing-features-log)
6. [Architecture Deep-Dive](#6-architecture-deep-dive)
7. [Performance Analysis](#7-performance-analysis)
8. [Security & Privacy Assessment](#8-security--privacy-assessment)
9. [UX & Apple HIG Compliance](#9-ux--apple-hig-compliance)
10. [Distribution Strategy Analysis](#10-distribution-strategy-analysis)
11. [Actionable Remediation Roadmap](#11-actionable-remediation-roadmap)
12. [Code-Level Implementation Patterns](#12-code-level-implementation-patterns)

---

## 1. Executive Summary

APGI Explorer is a psychometric assessment application for macOS (with cross-platform stubs for iOS) built on top of the APGI model — a novel psychological framework measuring four parameters: Prediction Error Sensitivity (ε), Precision Allocation (π), Ignition Threshold (θₜ), and Somatic Bias (β). The app administers a 35-question adaptive questionnaire, computes one of 8 cognitive profile types, and provides interactive visualization, state exploration, multi-format export, and iCloud sync.

**Overall Verdict: Structurally Sound Foundation, Non-Trivial Production Blockers**

The codebase demonstrates commendable architectural intent: Swift Concurrency (`async/await`) is used throughout, Keychain integration is properly implemented, StoreKit 2 is correctly wired, and CloudKit synchronization includes conflict resolution logic. The scoring engine (`APGIScorer`) is sophisticated, with weighted parameters, sigmoid transformations, cross-validation checks, and 95% confidence intervals.

However, **4 critical bugs** and **7 high-severity defects** must be remediated before any production or App Store submission is viable:

- **The theme system is bifurcated**: `ThemeManager` (key: `"theme"`) and `AppearanceSettingsView` (key: `"colorScheme"`) write to different `UserDefaults` keys, making the appearance picker non-functional.
- **PDF generation fails silently** in all non-drawing contexts because `NSGraphicsContext.current?.cgContext` returns `nil` when called from a background Task.
- **Quiz state restoration is always broken**: `[Int: Int]` answers serialized through `UserDefaults` PropertyList encoding lose integer keys (converted to strings), making the cast back to `[Int: Int]` always fail.
- **9 of the 13 advertised export formats are CSV stubs**: SPSS, Stata, R Data, Excel, XML, BibTeX, EndNote, APA Report, and MLA Report all silently export a CSV file with a misleading extension.
- **Sparkle auto-update is non-functional**: The framework is commented out with `TODO` comments and the `SUFeedURL` points to `https://example.com/appcast.xml`.

The application has no `PrivacyInfo.xcprivacy` manifest file (required for App Store submission since Xcode 15/2023), is missing 4 of 9 documented settings panels, and has no Core ML, NSViewRepresentable, or Apple Silicon-specific optimization implementations despite being listed on the roadmap.

---

## 2. KPI Scores Table

| # | KPI Dimension | Score (1–100) | Rationale |
|---|---|:---:|---|
| 1 | **Functional Completeness** | **58 / 100** | Core quiz, scoring, visualization, and Keychain/CloudKit work. However, 4 documented settings sections are absent, 9/13 export formats are CSV stubs, auto-updates are non-functional, and quiz state restoration is broken. |
| 2 | **UI/UX Consistency (HIG)** | **66 / 100** | TabView navigation, SF Symbols, Dark Mode, and keyboard shortcuts are present. AppearanceSettingsView's theme picker is disconnected from `ThemeManager`. Settings exposes 5 of 9 documented panels. `AnyView` type erasure causes layout instability. No `NSViewRepresentable` or `NSHostingView` bridge patterns beyond a single PNG render. |
| 3 | **Responsiveness & Performance** | **72 / 100** | `PerformanceManager` correctly monitors memory pressure and battery state. `LazyLoadCache` and `ImageCache` are well-implemented. Timer proxy avoids retain cycles. However, `adjustForLowMemory()` clears caches on the main thread inside a Combine sink, and `setupCache()` calls `PerformanceManager.shared.performanceMode` from a non-`@MainActor` context (data race risk). |
| 4 | **Error Handling & Resilience** | **62 / 100** | `AppError`, `CloudSyncError`, `KeychainError`, `StoreError` enums are well-typed. `createProfile()` validates inputs (CRIT-001 fix noted in code). However, PDF failure is silent (`return nil`), export format stubs hide errors behind misleading success, and `SecurityManager.shared()` is an async factory returning a new object each call — not a singleton. |
| 5 | **Overall Implementation Quality** | **64 / 100** | Swift Concurrency is used correctly throughout. Core Data stack is solid. StoreKit 2 `Transaction.updates` listener is properly structured. Key weaknesses: disconnected settings state, silent export failures, missing Privacy Manifest, commented-out Sparkle, placeholder bundle identifier in README, and no unit-testable boundary for the theme → appearance pipeline. |

**Composite Score: 64.4 / 100**

---

## 3. Functional Completeness Assessment

### 3.1 Core Assessment Engine — ✅ 88%

| Feature | Status | Notes |
|---|---|---|
| 35-question adaptive questionnaire | ✅ Implemented | Questions 1–35 across 7 parameter dimensions |
| 4 APGI parameter scoring (ε, π, θₜ, β) | ✅ Implemented | Weighted scoring with reliability coefficients |
| Sigmoid nonlinear transformation | ✅ Implemented | Per-parameter steepness tuning |
| Cross-validation checks | ✅ Implemented | Precision-threshold and epsilon-somatic consistency |
| 95% confidence intervals | ✅ Implemented | Standard error via reliability-adjusted variance |
| Response validation (straight-lining, random patterns) | ✅ Implemented | 4 distinct validity checks |
| 8 profile types | ✅ Implemented | Closeness-score pattern matching |
| Quiz pause/resume | ✅ Implemented | Paused state toggling works |
| Quiz state persistence across launches | ❌ Broken | See BUG-HIGH-003 |
| Handoff / Continuity | ✅ Implemented | `NSUserActivity` creation and restoration |
| Live score tracker during quiz | ✅ Implemented | `LiveScoreTracker` component |
| Interaction / temporal / environmental sub-scores | ⚠️ Partial | Questions 21–35 read but have no weights in `questionWeights` dict |

### 3.2 Settings Panels — ❌ 56%

| Settings Section | Status | Notes |
|---|---|---|
| General | ✅ Implemented | Auto-save, tooltips, animation speed, retention, analytics |
| Appearance | ⚠️ Broken | Color scheme picker disconnected from ThemeManager (BUG-CRIT-002) |
| Charts & Visualization | ✅ Implemented | Chart style, export quality |
| Data & Privacy | ✅ Implemented | Retention, analytics consent |
| Advanced | ✅ Implemented | Debug options, system tools |
| Cloud Sync | ❌ Missing | `CloudSyncSettingsView.swift` exists but is not in SettingsView tabs |
| Notifications | ❌ Missing | No settings panel exists |
| Window Management | ❌ Missing | No settings panel exists |
| Export & Backup | ❌ Missing | No dedicated settings tab |
| Psychological States | ❌ Missing | No settings panel exists |

### 3.3 Export Formats — ❌ 31%

| Format | Status | Notes |
|---|---|---|
| JSON | ✅ Real | Full profile data via `JSONEncoder` |
| CSV | ✅ Real | 17-column output with all APGI parameters |
| PDF | ⚠️ Broken | Graphics context nil in normal execution (BUG-CRIT-003) |
| PNG | ✅ Real | NSHostingView → NSBitmapImageRep pipeline |
| SPSS (.sav) | ❌ CSV Stub | Outputs CSV with wrong extension |
| Stata (.dta) | ❌ CSV Stub | Same as above |
| R Data (.RData) | ❌ CSV Stub | Same as above |
| Excel (.xlsx) | ❌ CSV Stub | Same as above |
| XML | ❌ CSV Stub | Same as above |
| BibTeX (.bib) | ❌ CSV Stub | Same as above |
| EndNote (.enw) | ❌ CSV Stub | Same as above |
| APA Report (.pdf) | ❌ CSV Stub | Same as above |
| MLA Report (.pdf) | ❌ CSV Stub | Same as above |

### 3.4 Cloud & Distribution — ⚠️ 55%

| Feature | Status | Notes |
|---|---|---|
| CloudKit sync (private DB) | ✅ Implemented | Zone management, conflict resolution |
| CloudKit download | ⚠️ Partial | Only id/name/dates restored; APGI scores lost (BUG-MED-005) |
| StoreKit 2 IAP | ✅ Implemented | 5 products, subscription management |
| Spotlight indexing | ✅ Implemented | `SpotlightManager.indexProfile()` |
| Handoff / Continuity | ✅ Implemented | `HandoffActivity` pattern |
| Auto-update (Sparkle) | ❌ Not Implemented | Framework commented out, placeholder feed URL |
| PrivacyInfo.xcprivacy | ❌ Missing | Required for Xcode 15+ App Store builds |
| TestFlight distribution setup | ✅ Partial | `exportOptions.plist` exists |
| Fastlane CI/CD | ✅ Partial | Fastfile present |

---

## 4. Bug Inventory

### Critical Severity

---

#### BUG-CRIT-001 — `SecurityManager.shared()` Is Not a Singleton

**Component:** `APGI-Explorer/Services/SecurityManager.swift:15`
**Severity:** Critical
**Category:** Architecture / Data Integrity

**Description:**
`SecurityManager.shared()` is declared as `static func shared() async -> SecurityManager`. Every call site that calls `await SecurityManager.shared()` receives a **brand-new instance** with its own `NSPersistentContainer`. This breaks singleton semantics, wastes memory with duplicate Core Data stacks, and produces inconsistent security state across the app.

**Reproduction Steps:**
1. Call `await SecurityManager.shared()` twice from any async context.
2. Inspect the returned instances — they are different objects with different `persistentContainer` references.

**Expected:** A single shared instance with one Core Data stack.
**Actual:** A new `SecurityManager` is created and configured on every call.

**Fix:**
```swift
actor SecurityManager {
    static let shared = SecurityManager()
    private init() {}

    private var _container: NSPersistentContainer?
    private var isConfigured = false

    func ensureConfigured() async {
        guard !isConfigured else { return }
        // ... configure once ...
        isConfigured = true
    }
}
```

---

#### BUG-CRIT-002 — Appearance Settings Picker Disconnected from ThemeManager

**Component:** `APGI-Explorer/SettingsViews/AppearanceSettingsView.swift:8` vs `APGI-Explorer/ThemeManager.swift:41`
**Severity:** Critical
**Category:** Functional / State Management

**Description:**
`AppearanceSettingsView` persists the user's color scheme selection via `@AppStorage("colorScheme")`. However, `ThemeManager` reads and writes its own key `@UserDefaults.standard` with key `"theme"`. These two `UserDefaults` keys are completely independent. A user changing the color scheme in Settings has **zero effect** on the displayed theme.

**Reproduction Steps:**
1. Launch the app and navigate to Settings → Appearance.
2. Change the Color Scheme from "System" to "Dark".
3. Observe: the app appearance does not change.
4. Navigate away and return — picker shows "Dark" but app remains in system appearance.

**Expected:** Changing the Color Scheme picker immediately applies the selected theme via `ThemeManager`.
**Actual:** `@AppStorage("colorScheme")` writes a different key than `ThemeManager` reads.

**Fix:**
Replace `@AppStorage("colorScheme")` with a binding to `ThemeManager.shared.currentTheme`, mapped through the `AppTheme` enum.

```swift
// AppearanceSettingsView.swift
@EnvironmentObject private var themeManager: ThemeManager

Picker("Color Scheme", selection: $themeManager.currentTheme) {
    Text("System").tag(AppTheme.system)
    Text("Light").tag(AppTheme.light)
    Text("Dark").tag(AppTheme.dark)
}
```

---

#### BUG-CRIT-003 — PDF Generation Always Fails (Nil Graphics Context)

**Component:** `APGI-Explorer/ProfileManager.swift:500`
**Severity:** Critical
**Category:** Functional / Export

**Description:**
`generatePDFReport(for:)` calls `NSGraphicsContext.current?.cgContext` at line 500 and immediately calls `context.beginPDFPage(nil)`. However, `NSGraphicsContext.current` is **always `nil`** when called outside of a view's `draw(_:)` method — which is the case here, since `generatePDFReport` is a plain function called from a Task or button action. The guard-less optional chain produces a `nil` context that silently aborts drawing. The `pdfDocument.dataRepresentation()` then returns `nil` (no pages were drawn), and the function returns `nil` without surfacing any error to the UI.

**Reproduction Steps:**
1. Complete a quiz to get results.
2. Tap "Export PDF".
3. No file picker appears; no error is shown; the operation silently fails.
4. Confirm: `os_log` shows "Failed to create PDF document".

**Expected:** A properly rendered PDF report saved to a temporary file and presented via a save dialog.
**Actual:** Silent failure — `nil` returned, no user feedback.

**Fix:** Use `CGContext`-based PDF drawing directly (bypassing `NSGraphicsContext`):
```swift
func generatePDFReport(for profile: QuizProfile) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let url = ExportUtilities.getTemporaryDirectory()
        .appendingPathComponent(ExportUtilities.generateExportFilename(profile: profile, format: .pdf))
    guard let ctx = CGContext(url as CFURL, mediaBox: &pageRect.mutable, nil) else { return nil }
    ctx.beginPDFPage(nil)
    // draw content using ctx directly
    ctx.endPDFPage()
    ctx.closePDF()
    return url
}
```

---

#### BUG-CRIT-004 — Nine of Thirteen Export Formats Are Silent CSV Stubs

**Component:** `APGI-Explorer/ProfileManager.swift:742–758`
**Severity:** Critical
**Category:** Functional / Export / Data Integrity

**Description:**
The `getExportURL(for:format:)` method handles `ExportFormat` cases `.spss`, `.stata`, `.rData`, `.excel`, `.xml`, `.bibTeX`, `.endNote`, `.apa`, `.mla` by executing `exportToCSV(profile:)` and writing the resulting CSV bytes to a file path with the **wrong extension** (e.g., `.sav`, `.dta`, `.RData`, `.xlsx`, `.xml`, `.bib`, `.enw`). A user who exports to SPSS receives a CSV file named `Profile_SPSS.sav` — which is incompatible with SPSS and will produce an error when opened in any statistical package.

**Reproduction Steps:**
1. Complete a quiz and navigate to Export.
2. Select "SPSS (.sav)" as the export format.
3. Inspect the exported file — it is a standard comma-separated text file, not a SPSS System File.

**Expected:** Format-specific binary output for each claimed format.
**Actual:** CSV content with a misleading file extension for 9 of 13 formats.

**Affected Formats:** SPSS, Stata, R Data, Excel (.xlsx), XML, BibTeX, EndNote, APA Report, MLA Report.

---

### High Severity

---

#### BUG-HIGH-001 — Quiz State Restoration Always Fails (UserDefaults Key Type Mismatch)

**Component:** `APGI-Explorer/QuizView.swift:219–241`
**Severity:** High
**Category:** Functional / Data Persistence

**Description:**
`saveQuizState()` stores `quizModel.answers` — typed as `[Int: Int]` — in `UserDefaults` via `UserDefaults.standard.set(state, forKey:)`. `UserDefaults` serializes this using `PropertyListSerialization`, which **converts all dictionary keys to `NSString`**. When `loadQuizState()` attempts `state["answers"] as? [Int: Int]`, the cast always fails because the actual runtime type is `[String: Int]`. The guard exits silently, the saved quiz index and answers are never restored, and the user is returned to question 1 on every re-launch.

**Reproduction Steps:**
1. Start a quiz and answer 10 questions.
2. Tap Pause (saves state).
3. Quit the app entirely and relaunch.
4. Navigate to the quiz — it starts at question 1 with no saved answers.

**Expected:** Quiz resumes at question 10 with all answers intact.
**Actual:** Quiz state is cleared; restoration silently fails.

**Fix:**
```swift
// saveQuizState: encode as JSON
if let data = try? JSONEncoder().encode(SavedQuizState(index: currentQuestionIndex, answers: quizModel.answers)) {
    UserDefaults.standard.set(data, forKey: savedQuizKey)
}

// loadQuizState: decode from JSON
if let data = UserDefaults.standard.data(forKey: savedQuizKey),
   let state = try? JSONDecoder().decode(SavedQuizState.self, from: data) {
    currentQuestionIndex = state.index
    quizModel.restoreAnswers(state.answers)
}
```

---

#### BUG-HIGH-002 — Sparkle Auto-Update Non-Functional (Placeholder Feed URL)

**Component:** `APGI-Explorer/AppDelegate.swift:1–16` and `APGI-Explorer/Info.plist:103`
**Severity:** High
**Category:** Distribution / User Trust

**Description:**
The `AppDelegate` contains commented-out Sparkle integration code with a `// TODO:` note. The `Info.plist` declares `SUFeedURL` pointing to `https://example.com/appcast.xml`. If Sparkle is ever re-enabled without updating this URL, the app will attempt to fetch a non-existent update feed. More critically: the update mechanism is entirely non-functional, meaning users on older versions will never be notified of fixes.

**Expected:** Functional Sparkle-based or App Store auto-update mechanism.
**Actual:** Auto-update is completely disabled. Documentation claims automatic delta updates.

---

#### BUG-HIGH-003 — Settings Tab Count Discrepancy (5 of 9 Implemented)

**Component:** `APGI-Explorer/SettingsView.swift:49–71`
**Severity:** High
**Category:** Functional Completeness

**Description:**
`SettingsView` defines 5 tabs via `SettingsTab` enum: `.general`, `.appearance`, `.charts`, `.privacy`, `.advanced`. The README and feature documentation describe 9 settings categories. Four panels (`CloudSyncSettingsView`, notifications, window management, export/backup) are absent from the UI. `CloudSyncSettingsView.swift` exists in the codebase but is never included in the tab enum or displayed.

---

#### BUG-HIGH-004 — `ParameterRow` Progress Bar Uses Wrong Scale (5.0 vs 100.0)

**Component:** `APGI-Explorer/ProfileManager.swift:959`
**Severity:** High
**Category:** UI / Data Visualization

**Description:**
`ParameterRow` renders a `ProgressView(value: self.value, total: 5.0)`. APGI parameter scores (`epsilon`, `precision`, etc.) are on a **0–100 scale** after sigmoid transformation. Passing a score of e.g. `62.5` with `total: 5.0` causes the progress bar to render at `>100%`, clipping to full width for any score above 5 — effectively rendering all parameter bars at maximum, providing no visual differentiation.

**Expected:** `ProgressView(value: value, total: 100.0)`.
**Actual:** `ProgressView(value: value, total: 5.0)` — all non-trivial scores appear as 100%.

---

#### BUG-HIGH-005 — Missing `PrivacyInfo.xcprivacy` Manifest File

**Component:** Project root / APGI-Explorer target
**Severity:** High
**Category:** Distribution / App Store Compliance

**Description:**
Apple requires a `PrivacyInfo.xcprivacy` file (separate from `Info.plist`) for all apps submitted to the App Store since Xcode 15 (May 2024). The project declares `NSPrivacyAccessedAPITypes` inside `Info.plist` — which satisfies legacy usage strings — but the separate Privacy Manifest file (`PrivacyInfo.xcprivacy`) is absent. App Store submission will be rejected with a privacy report violation.

**Required entries at minimum:** `UserDefaults`, `FileTimestamp`, `SystemBootTime` access categories (already declared in `Info.plist` but must also appear in the manifest).

---

#### BUG-HIGH-006 — `QuizView.mainContent` Uses AnyView Type Erasure

**Component:** `APGI-Explorer/QuizView.swift:62–68`
**Severity:** High
**Category:** Performance / SwiftUI Architecture

**Description:**
The `mainContent` computed property wraps both branches in `AnyView(...)`. AnyView suppresses SwiftUI's structural identity diffing, preventing efficient view recycling. On quiz navigation, the entire view hierarchy is torn down and rebuilt on every question change rather than updating in place. On lower-end Macs this produces visible frame drops.

**Fix:** Replace with `@ViewBuilder` or a `Group`:
```swift
@ViewBuilder
private var mainContent: some View {
    if isPaused {
        pausedContent
    } else {
        quizContent
    }
}
```

---

#### BUG-HIGH-007 — Deprecated `UserDefaults.synchronize()` in StoreManager

**Component:** `APGI-Explorer/Services/StoreManager.swift:236,242,248,252`
**Severity:** High
**Category:** API Compliance / Deprecation

**Description:**
All four `enableXxxFeatures()` methods call `UserDefaults.standard.synchronize()`. This API is deprecated since macOS 10.14 / iOS 12. The OS now handles synchronization automatically, but more importantly, feature entitlement state stored purely in `UserDefaults` (without Keychain or server-side validation) is trivially bypassable by a user editing their preferences plist. Purchase receipts should drive entitlement state, not unprotected `UserDefaults`.

---

### Medium Severity

---

#### BUG-MED-001 — CloudKit Download Loses All APGI Score Parameters

**Component:** `APGI-Explorer/Services/CloudSyncManager.swift:266–287`
**Severity:** Medium
**Category:** Data Integrity / Cloud Sync

**Description:**
`downloadProfile(_:)` creates a new `ProfileEntity` and sets only `id`, `name`, `dateCreated`, and `dateModified`. All four APGI parameters (ε, π, θₜ, β), interaction scores, temporal stability, and environmental fit are **not restored**. A profile synced from another device will appear in the profile list with zero/default scores, producing incorrect profile type classification.

**Fix:** Decode the `profileData` CKAsset (which contains the JSON-encoded profile) and populate all `ProfileEntity` fields after download.

---

#### BUG-MED-002 — `MainTabView` Creates Duplicate `ThemeManager` Reference

**Component:** `APGI-Explorer/MainTabView.swift:8`
**Severity:** Medium
**Category:** Memory / State Management

**Description:**
`MainTabView` declares `@StateObject private var themeManager = ThemeManager.shared`. Since `ThemeManager.shared` is a reference type, `@StateObject` calls `ThemeManager()` through the `wrappedValue` initializer — but `ThemeManager.init` is private and returns the singleton. This is technically safe but creates an unnecessary binding to the shared instance that bypasses the `@EnvironmentObject` already injected in `APGI_ExplorerApp`. If any child view reads from the environment object, a different publisher reference may be involved.

---

#### BUG-MED-003 — `AppearanceSettingsView` Font Size Setting Has No Effect

**Component:** `APGI-Explorer/SettingsViews/AppearanceSettingsView.swift:9,71`
**Severity:** Medium
**Category:** Functional / UX

**Description:**
The font size slider stores a value via `@AppStorage("fontSize")` but no component in the app reads this key to apply dynamic font sizing. The setting is a non-functional placeholder that creates a false expectation of dynamic type support.

---

#### BUG-MED-004 — `ContentView` NavigationStack Double-Wrapping

**Component:** `APGI-Explorer/ContentView.swift:5` and `APGI-Explorer/MainTabView.swift:16`
**Severity:** Medium
**Category:** Navigation Architecture

**Description:**
`ContentView` contains its own `NavigationStack`. `MainTabView` also wraps the States tab in a `NavigationStack`. The Home tab (`ContentView`) is not wrapped in a `NavigationStack` by `MainTabView`, so `ContentView`'s internal `NavigationStack` creates push navigation within the tab — but this is inconsistent with the States tab pattern. `NavigationLink` destinations within `ContentView` (IntroView, PsychologicalStatesView) inherit the internal stack, but `PsychologicalStatesView` already receives its own environment dependencies through the States tab. A user navigating to States from the Home tab gets a duplicate, non-environment-scoped instance.

---

#### BUG-MED-005 — `LazyLoadCache.setupCache()` Data Race on `@MainActor` Property

**Component:** `APGI-Explorer/PerformanceManager.swift:262`
**Severity:** Medium
**Category:** Concurrency / Thread Safety

**Description:**
`LazyLoadCache.init()` calls `setupCache()`, which reads `PerformanceManager.shared.performanceMode`. `PerformanceManager` is marked `@MainActor`, meaning `performanceMode` can only be safely accessed on the main actor. `LazyLoadCache` is not actor-isolated and can be initialized from any thread (e.g., from a background queue). This is a Swift Concurrency data race that may surface as crashes in strict concurrency checking mode (Swift 6).

---

#### BUG-MED-006 — `AccessibilityManager` Has No macOS VoiceOver / Reduce Motion Monitoring

**Component:** `APGI-Explorer/AccessibilityManager.swift:31–60`
**Severity:** Medium
**Category:** Accessibility / Platform Parity

**Description:**
macOS's `setupAccessibilityObservers()` only subscribes to `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`. VoiceOver status, reduce motion preference, and increase contrast are not monitored. The `voiceOverEnabled` and `reducedMotionEnabled` published properties are never set on macOS, causing the app to never adapt its animations or accessibility labels dynamically.

**Fix:**
```swift
// Add macOS-specific monitoring:
NSWorkspace.shared.notificationCenter
    .publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
    .sink { [weak self] _ in
        self?.voiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
        self?.reducedMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        self?.highContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }
    .store(in: &cancellables)
```

---

### Low Severity

---

#### BUG-LOW-001 — `AppState.hasCompletedOnboarding` Not Using `@AppStorage`

**Component:** `APGI-Explorer/AppState.swift:5–8`
**Severity:** Low
**Category:** Code Quality / Consistency

**Description:**
`hasCompletedOnboarding` is a manually-synchronized `@Published` property with a `didSet` block. Every other preference in the app uses `@AppStorage`. The manual `UserDefaults.standard.set(...)` call in `didSet` is functionally equivalent but inconsistent and potentially race-prone if two threads call `completeOnboarding()` simultaneously.

---

#### BUG-LOW-002 — Bundle Identifier Placeholder in README

**Component:** `README.md:11`
**Severity:** Low
**Category:** Documentation

**Description:**
README states bundle identifier as `com.yourcompany.APGI-Explorer`. The `Info.plist` correctly uses `$(PRODUCT_BUNDLE_IDENTIFIER)` (build-time variable), but the README placeholder will mislead anyone configuring CloudKit, push notifications, or App Store Connect.

---

#### BUG-LOW-003 — `isOnBatteryPower()` Returns True for Any Battery-Equipped Mac

**Component:** `APGI-Explorer/PerformanceManager.swift:105–118`
**Severity:** Low
**Category:** Logic / Performance Management

**Description:**
`isOnBatteryPower()` returns `true` if the Mac has an internal battery source registered by IOKit — regardless of whether the Mac is currently **plugged in** or running on battery. A plugged-in MacBook Pro will incorrectly enter `.memory` performance mode. The IOKit key `kIOPSPowerSourceStateKey` with value `kIOPSBatteryPowerValue` should be checked instead.

---

#### BUG-LOW-004 — `ColorConstants` / `LayoutConstants` Not Verified Against Adaptive Layout

**Component:** `APGI-Explorer/ViewConstants.swift`
**Severity:** Low
**Category:** UX / Responsive Layout

**Description:**
Constants such as `iconFontSize`, `horizontalPadding`, and `topPadding` are hardcoded values with no adaptation for compact vs. regular size classes or very large font sizes (WCAG 2.1 AA requires content to reflow at 400% zoom without loss of content or functionality).

---

## 5. Missing Features Log

| # | Feature | Documented / Expected | Current State | Priority |
|---|---|---|---|---|
| MF-001 | **Sparkle Auto-Update** | README §11, AppDelegate TODOs | Commented out; placeholder feed URL | P0 — Blocks release |
| MF-002 | **PrivacyInfo.xcprivacy Manifest** | Required by Apple (Xcode 15+) | Not present | P0 — App Store rejection |
| MF-003 | **Cloud Sync Settings Panel** | README §6, `CloudSyncSettingsView.swift` exists | Tab omitted from `SettingsTab` enum | P1 |
| MF-004 | **Notifications Settings Panel** | README §6 | No UI or code exists | P1 |
| MF-005 | **Window Management Settings Panel** | README §6 | No UI or code exists | P1 |
| MF-006 | **Export & Backup Settings Panel** | README §6 | No UI or code exists | P1 |
| MF-007 | **Real SPSS Export** | README, ResearchExportManager | CSV stub with `.sav` extension | P1 |
| MF-008 | **Real Stata Export** | README, ResearchExportManager | CSV stub with `.dta` extension | P1 |
| MF-009 | **Real R Data Export** | README, ResearchExportManager | CSV stub with `.RData` extension | P1 |
| MF-010 | **Real Excel Export** | README, ResearchExportManager | CSV stub with `.xlsx` extension | P1 |
| MF-011 | **Real XML Export** | README, ResearchExportManager | CSV stub with `.xml` extension | P1 |
| MF-012 | **Real APA / MLA Report Export** | README, ResearchExportManager | CSV stub with `.pdf` extension | P1 |
| MF-013 | **Real BibTeX / EndNote Export** | README, ResearchExportManager | CSV stubs | P2 |
| MF-014 | **Core ML On-Device AI** | Technology Roadmap | No `.mlmodel` files, no framework usage | P2 |
| MF-015 | **NSViewRepresentable Bridge Patterns** | Architecture requirements | Only basic `NSHostingView` usage in PNG export | P2 |
| MF-016 | **Apple Silicon Specific Optimizations** | Roadmap, Architecture | No `#if arch(arm64)` conditional paths | P2 |
| MF-017 | **Psychological States Settings Panel** | README §6 | No UI or code exists | P2 |
| MF-018 | **Widget / App Extension** | Roadmap | Not implemented | P3 |
| MF-019 | **Dynamic Font Size Application** | `AppearanceSettingsView` slider | Key stored, never read | P2 |
| MF-020 | **CloudKit Full Profile Download** | CloudSyncManager | Only id/name/dates restored; APGI scores lost | P1 |
| MF-021 | **macOS VoiceOver Status Monitoring** | `AccessibilityManager` | Not wired on macOS | P2 |
| MF-022 | **Purchase Entitlement in Keychain** | Security best practice | Stored only in unprotected `UserDefaults` | P1 |
| MF-023 | **`os_log` Subsystem / Category Structured Logging** | Architecture requirements | Most uses are bare `os_log()` without subsystem/category | P2 |
| MF-024 | **Instruments Signpost Integration** | Performance requirements | No `os_signpost` usage | P3 |
| MF-025 | **LLDB Custom Type Summaries** | Debugging requirements | No `.lldbinit` or type summary definitions | P3 |

---

## 6. Architecture Deep-Dive

### 6.1 SwiftUI / AppKit Hybrid Architecture

The app is primarily SwiftUI with minimal AppKit exposure. AppKit surfaces appear at three specific points:

1. **ThemeManager** — `NSAnimationContext` + `NSWindow.appearance` for smooth theme transitions. This is appropriate and correct.
2. **ProfileManager.createNSImage(from:)** — `NSHostingView` render path for PNG export. Correctly uses `bitmapImageRepForCachingDisplay`.
3. **AppDelegate** — Minimal `NSApplicationDelegate` stub; currently provides no value beyond Sparkle integration placeholder.

**What is missing:** There are no `NSViewRepresentable` wrappers for any custom AppKit components. The app documents "complex document-based workflows" but has no `NSDocument` subclass, no `NSPersistentDocument`, and no `UndoManager` integration. If document-based editing is a future requirement, this architecture gap must be addressed before state management grows further.

**Battle-Tested NSViewRepresentable Pattern (for future custom NSView components):**

```swift
struct CustomNSViewRepresentable: NSViewRepresentable {
    @Binding var value: Double

    func makeNSView(context: Context) -> CustomNSView {
        let view = CustomNSView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: CustomNSView, context: Context) {
        // Always dispatch layout-affecting updates to main
        nsView.setValue(value, animated: context.transaction.animation != nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CustomNSViewDelegate {
        var parent: CustomNSViewRepresentable
        init(_ parent: CustomNSViewRepresentable) { self.parent = parent }

        func customViewDidChange(_ value: Double) {
            // Update binding on main actor
            DispatchQueue.main.async {
                self.parent.value = value
            }
        }
    }

    static func dismantleNSView(_ nsView: CustomNSView, coordinator: Coordinator) {
        // Critical: break delegate reference to prevent retain cycles
        nsView.delegate = nil
    }
}
```

### 6.2 State Management

The app uses a clean three-layer state model:

| Layer | Mechanism | Correct? |
|---|---|---|
| App-level | `@StateObject` in `APGIExplorerApp` + `@EnvironmentObject` propagation | ✅ |
| View-local | `@State`, `@StateObject` | ✅ |
| Persistence | `@AppStorage`, CoreData via `PersistenceController` | ✅ |
| Settings sync | `ThemeManager` ↔ `AppearanceSettingsView` | ❌ Disconnected |

**Critical observation:** `ProfileManager` is `@MainActor` and its `createProfile()` / `loadProfiles()` methods are correctly `async`. However, `ProfileManager.enhancedProfile(from:)` calls `APGIScorer().calculateRobustScore(answers:)` synchronously on the `@MainActor`. The scorer involves non-trivial CPU work (sigmoid calculations, cross-validation loops). For 35 questions this is fast enough, but for batch analytics (processing all profiles), this will block the main thread.

**Recommended pattern for CPU-bound scoring:**
```swift
func enhancedProfile(from results: [String: Int]) async -> APGIProfile {
    await Task.detached(priority: .userInitiated) {
        APGIScorer().calculateRobustScore(answers: self.mapResultsToAnswers(results))
    }.value
}
```

### 6.3 Core Data Architecture

`PersistenceController.shared` properly uses a single `NSPersistentContainer` with an in-memory fallback for previews. However:

- **Migration strategy:** `NSMigratePersistentStoresAutomatically = true` and `NSInferMappingModelAutomatically = true` are the defaults — fine for v1, but must be replaced with explicit migration policies before any schema change in production.
- **Background context:** All Core Data operations in `CloudSyncManager.downloadProfile()` use `container.viewContext` (the main-thread context) directly from within `async` code. This can cause main thread I/O stalls. The pattern should use `container.newBackgroundContext()` and merge changes via `NSManagedObjectContext.mergeChanges`.

---

## 7. Performance Analysis

### 7.1 Memory Management

| Component | Pattern | Assessment |
|---|---|---|
| `PerformanceManager` | `DispatchSourceMemoryPressure` → adjust cache limits | ✅ Correct |
| `LazyLoadCache` | `NSCache` with `NSCacheDelegate` | ✅ Correct; delegate strongly retained via `objc_setAssociatedObject` |
| `MemoryMonitor` | `DispatchSource` with `[weak self]` in event handler | ✅ No retain cycle |
| `CloudSyncManager` subscriptions | `AnyCancellable` set stored in instance | ✅ |
| `ThemeManager.themeChangeCancellable` | Cancels previous before storing new | ✅ Debounced correctly |
| `PerformanceTimer` | `PerformanceTimerProxy` NSObject target | ✅ No retain cycle |
| `StoreManager.updateListenerTask` | `Task<Void, Error>?` stored and cancelled in `deinit` | ✅ |

**Identified retain cycle risk:**
`ImageCache.loadImageFromNetwork(url:)` stores a strong reference to `self` inside the `URLSession.data(from:)` closure via implicit capture. Since `ImageCache` is a singleton, this is not a leak but may keep response data alive longer than needed. Use `[weak self]` explicitly.

### 7.2 Launch Time

The `APGIExplorerApp.init()` performs the following on the launch critical path (main thread):

1. Requests notification authorization (async — correct)
2. Schedules automatic backups via `DispatchQueue.main.async` (deferred — correct)
3. Starts screenshot automation if launched with `--screenshot-mode`

The `ProfileManager.init()` fires `Task { await loadProfiles() }` — a `@MainActor` async task. Core Data fetch on first launch reads from disk on the main actor's executor. For small datasets this is fine; for large profile libraries, move the fetch to a background context.

**Instruments validation checklist for launch:**
- [ ] Time Profiler: Confirm `applicationDidFinishLaunching` < 400 ms
- [ ] Core Data: Verify `fetchRequest` uses a background context
- [ ] Leaks: Run with Large Object Allocation instrument

### 7.3 GCD / Swift Concurrency QoS Assessment

| Usage | Current QoS | Recommended |
|---|---|---|
| CloudKit sync (`SyncCoordinator`) | `.utility` | ✅ Correct |
| Profile fetch | `@MainActor` | Should be `.userInitiated` on background context |
| Backup scheduling | `DispatchQueue.main` | Should be `.background` |
| Score calculation | `@MainActor` (implicit) | `.userInitiated` background Task |
| Image cache network load | URLSession (system-managed) | ✅ |

---

## 8. Security & Privacy Assessment

### 8.1 Keychain Implementation

`KeychainManager` uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — the correct accessibility constant for health/psychological data. The `store()` method performs `SecItemDelete` before `SecItemAdd`, which is an atomic-safe pattern. No CryptoKit encryption layer is applied on top of Keychain storage; for psychological assessment data, this is acceptable since Keychain itself provides encryption at rest.

**Gap:** Purchase entitlement state (`premium_features_enabled`, etc.) is stored in unprotected `UserDefaults` rather than Keychain. A sophisticated user can bypass IAP by editing `~/Library/Preferences/com.lesoto.APGI-Explorer.plist`. Entitlement flags must be stored in Keychain and verified against StoreKit transaction receipts.

### 8.2 App Transport Security

`Info.plist` correctly sets `NSAllowsArbitraryLoads = false` with `NSAllowsLocalNetworking = true`. No insecure HTTP connections are permitted.

### 8.3 App Sandbox

The app declares file-system usage descriptions for Desktop, Documents, Downloads, Network Volumes, and Removable Volumes. All are appropriate for an app that reads/writes user data and performs exports. No unnecessary entitlements observed.

### 8.4 Privacy Manifest (Gap)

Required `PrivacyInfo.xcprivacy` entries for App Store submission:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>CA92.1</string></array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>35F9.1</string></array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>1B78.1</string></array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
```

### 8.5 Data Encryption at Rest

All profile data is stored via Core Data with file-system level encryption. No additional AES-256 layer is applied in code. For academic/clinical use cases with sensitive psychological data, consider adding `NSPersistentStore` file-protection attributes:

```swift
storeDescription.setOption(FileProtectionType.completeUnlessOpen as NSObject,
                           forKey: NSPersistentStoreFileProtectionKey)
```

---

## 9. UX & Apple HIG Compliance

### 9.1 Navigation Architecture

| HIG Requirement | Status |
|---|---|
| Tab bar with ≤5 items on macOS | ✅ (5 tabs) |
| Settings accessed via ⌘, | ✅ `Settings { SettingsView() }` scene |
| NavigationSplitView for Settings (macOS) | ✅ |
| MenuBarExtra for menu bar presence | ✅ |
| Window minimum size constraints | ✅ (`minWidth: 800, minHeight: 600`) |

### 9.2 SF Symbols Usage

SF Symbols are used consistently throughout: `brain.head.profile`, `house.fill`, `chart.scatter`, `person.2.fill`, `gearshape.fill`, etc. No custom icon SVGs were found — all imagery relies on the system symbol library. This is the correct approach for macOS HIG compliance.

### 9.3 Dark Mode

`ThemeManager` correctly sets `NSWindow.appearance` per window. `ContentView` uses `.foregroundColor(.primary)` / `.foregroundColor(.secondary)` semantic colors that adapt to dark mode. No hardcoded `Color(r:g:b:)` values observed in navigation views.

**Exception:** `ContentView` uses `Color.blue.opacity(...)` and `Color.purple.opacity(...)` as gradient colors — these do not fully adapt to Dark Mode since `Color.blue` is not a semantic system color. Should use `Color.accentColor` or custom asset catalog colors.

### 9.4 Keyboard Navigation

`MenuCommands` implements `⌘1`, `⌘2`, `⌘,` (settings). The `KeyboardNavigationModifier` provides tab-order navigation. VoiceOver labels are applied to interactive elements in `QuestionView`. The toolbar "Pause" button has a `Label` with both icon and text for screen reader accessibility.

**Gap:** No `focusable()` or `.focused()` modifiers are used for custom interactive elements — tabbing through `QuestionOptionRow` choices requires the user to click rather than navigate with arrow keys.

### 9.5 Onboarding

`OnboardingView` correctly gates behind `hasCompletedOnboarding`. The minimum frame size of `800×600` is enforced. No white flash on onboarding load was observed in the code path (opacity transitions are applied).

---

## 10. Distribution Strategy Analysis

### 10.1 Mac App Store vs. Direct Distribution

| Factor | Mac App Store | Direct (Notarized) |
|---|---|---|
| Reach | ✅ Widest | Narrower |
| Update delivery | ✅ Automatic via StoreKit | Requires Sparkle (currently broken) |
| IAP (StoreKit 2) | ✅ Supported | ❌ Not available |
| Sandboxing | Required | Optional |
| CloudKit | ✅ Included | Requires explicit entitlement |
| Privacy review | ✅ Built-in | Manual |
| Distribution cost | 30% commission | 0% |
| Gating features | ✅ IAP works | Must use alternative payment |

**Recommendation:** Mac App Store is the correct primary channel given: (a) StoreKit 2 IAP is already implemented, (b) CloudKit integration is configured, and (c) the app is already sandboxed. Direct notarized distribution can serve enterprise/academic deployments where IAP is unnecessary.

### 10.2 StoreKit 2 Integration Assessment

The `StoreManager` implementation is well-structured:
- `Transaction.updates` listener correctly runs as a detached task that persists for the app's lifetime.
- `checkVerified(_:)` properly throws on unverified transactions, refusing to deliver unverified product entitlements.
- `AppStore.sync()` is called on restore — correct pattern.
- Subscription status checks against `Product.SubscriptionInfo.Status` state machine — correctly handles `.inGracePeriod` as active.

**Gap:** Subscription product sorting uses `.displayPrice` (string comparison), not numeric price. This may sort "$9.99" before "$4.99" in some locales.

### 10.3 Apple Silicon Readiness

The project targets Universal (arm64 + x86_64). No Rosetta-incompatible frameworks are detected. `IOKit.ps` (used for battery detection) is available on Apple Silicon. No x86-specific assembly or framework dependencies were found.

**Optimization opportunity:** Core ML models for on-device psychological pattern prediction (roadmap item) would run natively on the Neural Engine on Apple Silicon, providing 10–15× performance improvements over CPU inference.

---

## 11. Actionable Remediation Roadmap

### Sprint 1 — Critical Blockers (1–2 weeks)

| # | Action | Component | Owner |
|---|---|---|---|
| R-001 | Fix `SecurityManager` to be a proper singleton actor | `SecurityManager.swift` | Backend |
| R-002 | Wire `AppearanceSettingsView` color picker to `ThemeManager` | `AppearanceSettingsView.swift` | UI |
| R-003 | Fix PDF generation with direct `CGContext` API | `ProfileManager.swift:generatePDFReport` | Export |
| R-004 | Either implement or disable all stub export formats with honest error messaging | `ProfileManager.swift:getExportURL` | Export |
| R-005 | Fix quiz state serialization with `Codable` + `JSONEncoder` | `QuizView.swift` | Core |
| R-006 | Create `PrivacyInfo.xcprivacy` file and add to Xcode target | Project root | DevOps |

### Sprint 2 — High-Priority Gaps (2–3 weeks)

| # | Action | Component | Owner |
|---|---|---|---|
| R-007 | Add `CloudSyncSettingsView`, Notifications, WindowManagement, Export/Backup tabs to `SettingsTab` enum | `SettingsView.swift` | UI |
| R-008 | Fix `ParameterRow` progress bar scale to `total: 100.0` | `ProfileManager.swift:959` | UI |
| R-009 | Move purchase entitlement flags to Keychain | `StoreManager.swift` | Security |
| R-010 | Fix `CloudSyncManager.downloadProfile()` to restore all APGI fields | `CloudSyncManager.swift` | Cloud |
| R-011 | Replace `AnyView` in `QuizView.mainContent` with `@ViewBuilder` | `QuizView.swift` | Performance |
| R-012 | Remove deprecated `UserDefaults.synchronize()` calls | `StoreManager.swift` | API |
| R-013 | Integrate or definitively remove Sparkle; update `SUFeedURL` | `AppDelegate.swift`, `Info.plist` | Release |

### Sprint 3 — Feature Completeness (3–4 weeks)

| # | Action | Component | Owner |
|---|---|---|---|
| R-014 | Implement real CSV → SPSS/Stata/R/Excel conversion or integrate `TabularData` framework | `ResearchExportManager.swift` | Export |
| R-015 | Connect `@AppStorage("fontSize")` to dynamic `Font` environment value | App-wide | UI |
| R-016 | Add macOS VoiceOver / reduce motion monitoring to `AccessibilityManager` | `AccessibilityManager.swift` | Accessibility |
| R-017 | Fix `isOnBatteryPower()` to check power source state, not just presence | `PerformanceManager.swift` | Performance |
| R-018 | Offload `APGIScorer.calculateRobustScore` to background task | `ProfileManager.swift` | Performance |
| R-019 | Move Core Data fetches off main actor in `CloudSyncManager` | `CloudSyncManager.swift` | Performance |
| R-020 | Add `NSViewRepresentable` bridge for at least one native AppKit component | New component | Architecture |

### Sprint 4 — Future-Proofing (4–6 weeks)

| # | Action | Component | Owner |
|---|---|---|---|
| R-021 | Integrate Core ML for on-device profile prediction | New `CoreMLManager.swift` | AI/ML |
| R-022 | Add `os_signpost` instrumentation to critical paths | Multiple | Performance |
| R-023 | Implement explicit Core Data migration policies for schema v2 | `PersistenceController.swift` | Data |
| R-024 | Add Swift 6 strict concurrency annotations and fix data races | Global | Architecture |
| R-025 | Implement Widget extension for quick profile summary | New target | Platform |

---

## 12. Code-Level Implementation Patterns

### 12.1 Correct NSHostingView Pattern for PNG Export

The current implementation in `ProfileManager.createNSImage(from:)` is correct and can serve as the canonical pattern:

```swift
// Battle-tested SwiftUI → NSImage render
private func createNSImage(from view: some View) -> NSImage? {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
    // Critical: force layout before capturing
    hostingView.layoutSubtreeIfNeeded()

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        return nil
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    let image = NSImage(size: hostingView.bounds.size)
    image.addRepresentation(rep)
    return image
}
```

### 12.2 Correct os_log Structured Logging Pattern

Replace bare `os_log(...)` calls with subsystem-scoped loggers:

```swift
// Define once per module
extension Logger {
    static let profile = Logger(subsystem: "com.lesoto.APGI-Explorer", category: "Profile")
    static let sync = Logger(subsystem: "com.lesoto.APGI-Explorer", category: "CloudSync")
    static let store = Logger(subsystem: "com.lesoto.APGI-Explorer", category: "StoreKit")
    static let security = Logger(subsystem: "com.lesoto.APGI-Explorer", category: "Security")
}

// Usage (privacy-safe):
Logger.profile.error("Failed to save PDF: \(error.localizedDescription, privacy: .public)")
Logger.sync.info("Profile synced: \(profileID, privacy: .private(mask: .hash))")
```

### 12.3 Core ML Integration Skeleton

For roadmap item MF-014, the pattern for on-device profile type prediction:

```swift
import CoreML
import CreateML

actor ProfilePredictionEngine {
    private let model: APGIProfileClassifier

    init() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all  // Neural Engine on Apple Silicon
        self.model = try APGIProfileClassifier(configuration: config)
    }

    func predict(epsilon: Double, precision: Double, threshold: Double, somatic: Double) async throws -> APGIProfileType {
        let input = APGIProfileClassifierInput(
            epsilon: epsilon,
            precision: precision,
            threshold: threshold,
            somaticBias: somatic
        )
        let output = try model.prediction(input: input)
        return APGIProfileType(rawValue: output.profileType) ?? .adaptiveBalancer
    }
}
```

### 12.4 StoreKit 2 Entitlement via Keychain

```swift
// Secure entitlement storage
actor EntitlementManager {
    private let keychain = KeychainManager.shared

    func grantEntitlement(_ product: StoreManager.ProductID, transaction: Transaction) throws {
        let payload = EntitlementPayload(
            productID: product.rawValue,
            transactionID: transaction.id,
            expirationDate: transaction.expirationDate,
            grantedAt: Date()
        )
        try keychain.storeCodable(payload, forKey: "entitlement.\(product.rawValue)")
    }

    func hasActiveEntitlement(for product: StoreManager.ProductID) -> Bool {
        guard let payload = try? keychain.retrieveCodable(EntitlementPayload.self,
                                                          forKey: "entitlement.\(product.rawValue)") else {
            return false
        }
        if let expiry = payload.expirationDate {
            return expiry > Date()
        }
        return true  // Non-consumable, no expiry
    }
}
```

### 12.5 Swift Concurrency-Safe `APGIScorer` Invocation

```swift
// Move CPU-bound scoring off @MainActor
@MainActor
func createProfile(name: String, answers: [Int: Int]) async throws -> QuizProfile {
    // Validate on main actor
    guard !name.isEmpty else { throw AppError.invalidParameters }

    // Score on background task
    let profile = try await Task.detached(priority: .userInitiated) {
        APGIScorer().calculateRobustScore(answers: answers)
    }.value

    // Save back on main actor
    return try await persistence.saveProfile(QuizProfile(name: name, apgiProfile: profile))
}
```

---

*End of APGI Explorer macOS Lead Architect Assessment Report*
*Generated: 2026-03-01 | Revision: `6fbcafc` | Branch: `claude/macos-roadmap-design-ficOR`*
