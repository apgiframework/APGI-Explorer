# APGI-Explorer — macOS Architecture & Quality Assessment Report

> **Classification:** Internal Technical Audit
> **Prepared by:** macOS Lead Architect (AI-assisted deep-code review)
> **Date:** 2026-02-24
> **Branch:** `claude/macos-roadmap-design-KAPkV`
> **Scope:** Full codebase review — 85 Swift source files, 10 test files, 3 CI/CD workflows, Fastfile, SwiftLint/SwiftFormat configuration, and bundled `.app` artifact

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [KPI Scores](#2-kpi-scores)
3. [Application Functional Audit](#3-application-functional-audit)
4. [Bug Inventory](#4-bug-inventory)
5. [Missing Features Log](#5-missing-features-log)
6. [Hybrid Architecture Analysis — SwiftUI + AppKit](#6-hybrid-architecture-analysis--swiftui--appkit)
7. [Performance & Concurrency Assessment](#7-performance--concurrency-assessment)
8. [Security & Privacy Analysis](#8-security--privacy-analysis)
9. [UI/UX & Human Interface Guidelines Compliance](#9-uiux--human-interface-guidelines-compliance)
10. [Testing & Quality Assurance Assessment](#10-testing--quality-assurance-assessment)
11. [Distribution Strategy Analysis](#11-distribution-strategy-analysis)
12. [Actionable Remediation Roadmap](#12-actionable-remediation-roadmap)

---

## 1. Executive Summary

APGI-Explorer is a psychological assessment platform for macOS that administers a 35-question cognitive profile questionnaire, calculates four core APGI parameters (ε, π, θₜ, β), classifies users into one of 8 profile archetypes, and provides visualization, export, and comparison features. The codebase spans ~85 Swift source files organized into views, services, managers, models, and settings subsystems, with a declared macOS 12.0+ deployment target and Universal (arm64 + x86_64) architecture.

**Overall assessment: The application demonstrates a sophisticated and ambitious feature surface with a solid architectural intent, but carries significant unresolved implementation debt across critical subsystems.** Several export formats are stubs, cloud synchronization contains race conditions with data-loss potential, the test suite has compilation errors and placeholder assertions that always pass, and multiple alert/error paths fail silently with no user feedback. The UI layer is visually polished and HIG-compliant in most areas, but inconsistent state management—mixing `@StateObject`, `@EnvironmentObject`, and singletons without a unified strategy—introduces unpredictable re-render cycles and memory pressure.

### Key Strengths
- Sophisticated APGI scoring algorithm with weighted questions and sigmoid transformations
- Comprehensive Settings surface (9 categories, real-time application)
- Keychain-backed security with CryptoKit-ready architecture
- Solid Core Data persistence with `NSPersistentCloudKitContainer` baseline
- Adaptive layout system, VoiceOver support, and Dynamic Type readiness
- CI/CD pipeline skeleton with notarization and App Store signing steps
- Fastlane integration for release automation

### Key Risks
- **Data loss risk** in `CloudSyncManager` due to a race condition on `isSyncing`
- **App crash** in `SecurityManager` — `fatalError()` on Core Data load failure
- **Silent export failures** in `ExportView`, `ResearchExportManager`, and `ProfileManager`
- **Broken tests** — `APGI_ExplorerUITests.swift` will not compile; four test methods always pass via `XCTAssertTrue(true)`
- **Incomplete format implementations** — Excel (.xlsx) falls back to CSV; SPSS uses hardcoded binary; R export produces a script, not `.RData`
- **Missing localization strings** — `OnboardingView` and `IntroView` have hard-coded English UI strings

---

## 2. KPI Scores

| # | KPI | Score | Rationale |
|---|-----|:-----:|-----------|
| 1 | **Functional Completeness** | **68 / 100** | Core quiz/scoring/results flow is solid. 3 of 13 export formats are stubs or incorrect format. Cloud sync is partially broken. Several settings panels have unreachable or no-op actions. |
| 2 | **UI/UX Consistency** | **74 / 100** | Visually polished with smooth animations, correct Dark Mode semantic colors, and SF Symbols usage. Inconsistent navigation patterns (TabView + NavigationSplitView mixed without clear hierarchy) and hard-coded English strings in onboarding lower the score. |
| 3 | **Responsiveness & Performance** | **63 / 100** | Caching strategies are present but `PerformanceManager`'s battery detection logic is inverted; a `queue.sync` call on a `.concurrent` queue creates a deadlock risk; `ProfileManager` (965 lines) creates high view-layer coupling. App launch path triggers background work within 2 seconds with no error path. |
| 4 | **Error Handling & Resilience** | **55 / 100** | `AppError` enum and `ErrorHandlingManager` are well-designed, but are bypassed in multiple critical paths. `SecurityManager` crashes via `fatalError()`. `CloudSyncManager` silently ignores `.serverRecordChanged` conflicts. `ExportView` silently swallows write errors. |
| 5 | **Overall Implementation Quality** | **65 / 100** | The architectural intent is strong and the code style is generally clean and readable. However, incomplete implementations, silent failure patterns, a broken test suite, mixed threading models, and an oversized `ProfileManager` class significantly reduce overall quality. |

**Composite Score: 65 / 100**

---

## 3. Application Functional Audit

### 3.1 Core Assessment Flow

| Feature | Status | Notes |
|---------|--------|-------|
| 35-question adaptive quiz | ✅ Implemented | `QuizModel.swift`, `QuizView.swift` |
| Real-time progress tracking | ✅ Implemented | `LiveScoreTracker.swift` |
| Response validation | ✅ Implemented | `ValidationResult` in `QuizModel` |
| Confidence/reliability scoring | ✅ Implemented | `APGIScorer` reliability weighting |
| 8 profile type classification | ✅ Implemented | `APGIProfileType.swift` |
| Handoff (Continuity) | ⚠️ Partial | `HandoffManager` — `isActive` state set but never read; 7-day cutoff hardcoded |
| Pause/Resume quiz | ❌ Missing | Not implemented in `QuizView` |

### 3.2 Visualization & Comparison

| Feature | Status | Notes |
|---------|--------|-------|
| Radar chart (profile) | ✅ Implemented | `APGIRadarChart` in `ResultsView` |
| State visualization | ✅ Implemented | `PsychologicalStatesVisualizationView` |
| Profile comparison | ✅ Implemented | `ProfileComparisonView` |
| State comparison radar | ✅ Implemented | `StateComparisonRadar` |
| Interactive state explorer | ✅ Implemented | `InteractiveStateView` |
| 3D state space exploration | ❌ Missing | Listed in roadmap, not present |

### 3.3 Export Capabilities

| Format | Status | Notes |
|--------|--------|-------|
| JSON | ✅ Implemented | Complete metadata and versioning |
| CSV | ✅ Implemented | Tabular, statistical-ready |
| PDF | ⚠️ Partial | macOS PDF path returns empty `Data` in `ResearchExportManager` line 452 |
| PNG | ✅ Implemented | High-quality chart export |
| SPSS (.sav) | ⚠️ Fragile | Hardcoded binary structure; no third-party parser — brittle |
| Stata (.dta) | ⚠️ Fragile | Similar to SPSS — binary format hardcoded |
| R Data (.RData) | ❌ Incorrect | Generates an R script, not a binary `.RData` file |
| Excel (.xlsx) | ❌ Stub | Falls back to CSV silently |
| APA Report | ⚠️ Partial | PDF path incomplete on macOS |
| MLA Report | ⚠️ Partial | PDF path incomplete on macOS |
| BibTeX (.bib) | ✅ Implemented | |
| EndNote (.enw) | ✅ Implemented | |
| XML | ✅ Implemented | |

### 3.4 Settings & Configuration

| Category | Status | Notes |
|----------|--------|-------|
| General | ✅ Implemented | |
| Appearance / Theme | ✅ Implemented | Dark Mode, semantic colors, animations |
| Charts & Visualization | ✅ Implemented | |
| Data & Privacy | ✅ Implemented | |
| Cloud Sync | ⚠️ Partial | Race condition in sync logic; conflict resolution absent |
| Advanced | ✅ Implemented | Debug and experimental feature flags |
| Window Management | ✅ Implemented | Min-size constraints, cascade/tile |
| Notifications | ✅ Implemented | |
| Localization | ⚠️ Partial | UI strings missing in onboarding/intro |

### 3.5 Platform & Native Integration

| Feature | Status | Notes |
|---------|--------|-------|
| Menu bar integration | ✅ Implemented | `MenuCommands.swift` |
| Keyboard shortcuts | ✅ Implemented | `KeyboardNavigationModifier`, ⌘1-5, ⌘, |
| Share Sheet | ✅ Implemented | `ShareSheet.swift` |
| Spotlight Integration | ❌ Missing | Referenced in README; `NSUserActivity` configured but Core Spotlight index not implemented |
| Universal Links | ❌ Missing | Referenced in README; not implemented |
| Sparkle auto-update | ❌ Missing | Referenced in README; no Sparkle dependency or `SUUpdater` configuration found |
| Services Menu | ❌ Missing | Referenced in README; no `NSServicesMenuRequestor` implementation |
| iCloud / CloudKit | ⚠️ Partial | `NSPersistentCloudKitContainer` configured but sync is broken |
| StoreKit 2 | ✅ Implemented | `StoreManager.swift` with proper async/await |

---

## 4. Bug Inventory

### 4.1 Critical Severity

> App crash, data loss, or security vulnerability. **Must be resolved before any release.**

---

**BUG-C01 — SecurityManager: Fatal crash on Core Data load failure**
- **File:** `Services/SecurityManager.swift:18–20`
- **Severity:** Critical
- **Component:** SecurityManager / Core Data
- **Reproduction:**
  1. Delete or corrupt the Core Data store on disk
  2. Launch the app
  3. SecurityManager's initializer triggers `fatalError("Unresolved error...")`
- **Expected:** Graceful error recovery with user-facing alert and fallback to in-memory store
- **Actual:** App terminates immediately

```swift
// CURRENT (line 18-20) — DO NOT SHIP
guard let container = ... else {
    fatalError("Unresolved error \(error)")
}
```

**Fix:**
```swift
// RECOMMENDED
do {
    try container.loadPersistentStores()
} catch {
    // Log to os_log, present NSAlert, fall back to in-memory store
    os_log(.fault, "Core Data load failed: %@", error.localizedDescription)
    throw SecurityManagerError.persistenceLoadFailed(error)
}
```

---

**BUG-C02 — CloudSyncManager: Race condition on `isSyncing` flag causes data loss**
- **File:** `Services/CloudSyncManager.swift:87–90`
- **Severity:** Critical
- **Component:** Cloud Sync / Concurrency
- **Reproduction:**
  1. Trigger a sync operation
  2. Immediately trigger a second sync before the first completes
  3. `isSyncing` is set to `false` before `performProfileSync()` awaits completion
- **Expected:** Second sync either queues or is correctly blocked
- **Actual:** `isSyncing` flag is cleared prematurely; concurrent writes possible; remote updates silently ignored (`.serverRecordChanged` at line 116–117)

**Fix:**
```swift
// Use an actor to serialize sync operations
actor SyncCoordinator {
    private var isSyncing = false
    func performSync(_ work: () async throws -> Void) async throws {
        guard !isSyncing else { throw SyncError.alreadyInProgress }
        isSyncing = true
        defer { isSyncing = false }
        try await work()
    }
}
```

---

**BUG-C03 — QuizView: Unprotected array index access**
- **File:** `QuizView.swift:92, 100–101`
- **Severity:** Critical
- **Component:** Quiz / UI
- **Reproduction:**
  1. Navigate to a question near the end of the quiz
  2. Rapidly tap the Next button multiple times
  3. Index advances beyond `questions.count - 1`
- **Expected:** Navigation stops at last question
- **Actual:** Index out-of-bounds crash (`EXC_BAD_INSTRUCTION`)

**Fix:**
```swift
guard currentIndex < quizModel.questions.count else { return }
let question = quizModel.questions[currentIndex]
```

---

**BUG-C04 — APGI_ExplorerUITests: Compilation failure**
- **File:** `APGI-ExplorerUITests/APGI_ExplorerUITests.swift:30`
- **Severity:** Critical
- **Component:** Test Suite
- **Reproduction:** Attempt to build the `APGI-ExplorerUITests` target
- **Expected:** Tests compile and run
- **Actual:** Build error — `mainFrame` is an undefined identifier (should be `mainWindow`)

```swift
// Line 30 — COMPILE ERROR
XCTAssertTrue(mainFrame.waitForExistence(timeout: 5))
// Fix:
XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
```

---

**BUG-C05 — CloudSyncManager: Conflict resolution absent**
- **File:** `Services/CloudSyncManager.swift:116–117`
- **Severity:** Critical
- **Component:** Cloud Sync / Data Integrity
- **Reproduction:**
  1. Edit a profile on two devices simultaneously without network
  2. Reconnect both devices
  3. CloudKit triggers `.serverRecordChanged`
- **Expected:** Merge dialog or last-write-wins with timestamp comparison
- **Actual:** Error silently accepted; server record may overwrite local data without notice

---

### 4.2 High Severity

> Significant functionality broken or degraded. **Must be resolved before public release.**

---

**BUG-H01 — ProfileManager: Silent failure on profile creation**
- **File:** `ResultsView.swift:284`
- **Severity:** High
- **Component:** Profile Persistence
- **Reproduction:** Complete a quiz when Core Data is under load or low on disk space
- **Expected:** User sees an error alert
- **Actual:** `nil` returned silently; profile never saved; no feedback to user

---

**BUG-H02 — ResearchExportManager: PDF generation returns empty `Data` on macOS**
- **File:** `Services/ResearchExportManager.swift:452`
- **Severity:** High
- **Component:** Export / PDF
- **Reproduction:** Export a profile as APA or MLA PDF on macOS
- **Expected:** Valid PDF document
- **Actual:** Empty `Data()` returned; file written is 0 bytes

---

**BUG-H03 — ExportView: Write errors silently swallowed**
- **File:** `ExportView.swift:107`
- **Severity:** High
- **Component:** Export / File I/O
- **Reproduction:** Export to a read-only or full volume
- **Expected:** Error sheet with description and retry option
- **Actual:** No feedback; user believes export succeeded

---

**BUG-H04 — ResearchExportManager: Excel export falls back to CSV without notification**
- **File:** `Services/ResearchExportManager.swift:230`
- **Severity:** High
- **Component:** Export
- **Reproduction:** Select Excel (.xlsx) from the export picker and export
- **Expected:** Valid `.xlsx` workbook
- **Actual:** CSV bytes written to a file with `.xlsx` extension

---

**BUG-H05 — PerformanceManager: Battery/power detection logic inverted**
- **File:** `PerformanceManager.swift:88–89`
- **Severity:** High
- **Component:** Performance Optimization
- **Reproduction:** Run app on a MacBook on battery power
- **Expected:** Low-power mode engages reduced animation/background activity
- **Actual:** Logic is inverted — low-power mode engaged when plugged in, disabled on battery

---

**BUG-H06 — StoreManager: Purchase receipt stored in UserDefaults without validation**
- **File:** `Services/StoreManager.swift:234–251`
- **Severity:** High
- **Component:** StoreKit / Security
- **Reproduction:** Simulate a purchase, then modify UserDefaults directly
- **Expected:** Feature access gated by StoreKit 2 verified transaction
- **Actual:** Feature flag read directly from UserDefaults — trivially bypassable

**Fix:**
```swift
// Always verify with StoreKit 2 — never trust UserDefaults for entitlements
func isFeatureUnlocked(_ feature: ProductID) async -> Bool {
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result,
           transaction.productID == feature.rawValue {
            return true
        }
    }
    return false
}
```

---

**BUG-H07 — MenuCommands: `showImportPanel`/`showExportPanel` never implemented**
- **File:** `MenuCommands.swift:49–57`
- **Severity:** High
- **Component:** Menu Bar / File Operations
- **Reproduction:** Use File > Import or File > Export from the menu bar
- **Expected:** Native file panel opens
- **Actual:** Methods are declared but bodies are empty stubs

---

**BUG-H08 — APGIScorer: Hardcoded question IDs for temporal/environmental subscores**
- **File:** `APGIScorer.swift:535–579`
- **Severity:** High
- **Component:** Scoring Algorithm
- **Reproduction:** Change question count or reorder quiz questions
- **Expected:** Subscore calculation adapts
- **Actual:** Hardcoded question IDs (26–30, etc.) silently return zero if questions don't exist

---

### 4.3 Medium Severity

> Feature degraded or user experience impaired. **Resolve before v1.0 public release.**

| ID | File | Line(s) | Description |
|----|------|---------|-------------|
| BUG-M01 | `ResultsView.swift` | 276–277 | Duplicate profile name check is case-sensitive only; "Profile" and "profile" are allowed as distinct names |
| BUG-M02 | `APGIScorer.swift` | 381, 428–431 | `applyMultiplicativeEffect()` receives empty `answers` dict — parameter is computed but never applied |
| BUG-M03 | `ProfileManager.swift` | 451–456 | `profile(from:)` creates a zero-initialized `APGIProfile` when decoding fails — silently produces garbage data |
| BUG-M04 | `ThemeManager.swift` | 41 | `UserDefaults.synchronize()` deprecated since iOS 12/macOS 10.14 — use `@AppStorage` or remove |
| BUG-M05 | `StoreManager.swift` | 82 | `DispatchQueue.main.async` used instead of `@MainActor` annotation — threading model inconsistency |
| BUG-M06 | `HandoffManager.swift` | 61 | `isActive` state variable is set but never read — dead code |
| BUG-M07 | `PerformanceManager.swift` | 152 | `queue.sync` called on `.concurrent` queue with shared `NSCache` — potential deadlock under contention |
| BUG-M08 | `ExportView.swift` | 119 | `os_log` call missing format string argument — logs malformed output |
| BUG-M09 | `DataStore.swift` | 74–80 | `UserDefaultsDataStore.getStorageInfo()` always returns zero values — stub |
| BUG-M10 | `ProfileManager.swift` | 75–78 | Range validation (0–100) applied but no semantic validation of parameter relationships |
| BUG-M11 | `WindowManager.swift` | 86, 99 | `objc_setAssociatedObject` for `WindowDelegate` — fragile retention; strong reference cycle risk |
| BUG-M12 | `CloudSyncManager.swift` | 233–246 | `CloudProfile.profileData` uses untyped `[String: Any]` dictionary — type safety absent |
| BUG-M13 | `MenuCommands.swift` | 62–66 | `tryToPerform(_:with:)` called on `NSApp` with unverified selector — unsafe at runtime |
| BUG-M14 | `AppError.swift` | 139–142 | Recovery suggestion hardcodes "30 questions" which diverges from actual quiz count |
| BUG-M15 | `Services/LocalizationManager.swift` | 76, 107–108 | `object_setClass()` and `objc_setAssociatedObject()` for Bundle swizzling — private API usage; may be rejected by App Store review |

---

### 4.4 Low Severity

| ID | File | Description |
|----|------|-------------|
| BUG-L01 | `MainTabView.swift:7` | `@StateObject var appState` duplicated when parent already owns it — redundant allocation |
| BUG-L02 | `MainTabView.swift:41–42` | Empty `onReceive` closure for theme updates — silent no-op |
| BUG-L03 | `QuizView.swift:30–35` | `onChange` receives `oldValue` but ignores it — misleading API usage |
| BUG-L04 | `ProfileManager.swift:370–392` | Parameter mapping logic duplicated across 3 methods — violates DRY |
| BUG-L05 | `PerformanceManager.swift:383–386` | `saveImageToDisk()` is a stub returning immediately |
| BUG-L06 | `HandoffManager.swift:43–46` | 7-day Handoff cutoff is hardcoded, not configurable |
| BUG-L07 | `AccessibilityManager.swift:30–48` | UIKit notification observers registered on macOS — `UIAccessibility` not available on macOS |
| BUG-L08 | `ProfileComparisonView.swift:37` | `exportData` State variable declared but never used |
| BUG-L09 | `KeychainManager.swift:39` | `SecItemDelete` called before every `SecItemAdd` — unnecessary round-trip; use `SecItemUpdate` |
| BUG-L10 | `.swiftlint.yml:77–79` | `cyclomatic_complexity` disabled in `disabled_rules` but thresholds configured below — conflicting config |

---

## 5. Missing Features Log

> Features referenced in README.md, project scope, or wireframe-implied functionality that are absent or incomplete.

| # | Feature | Priority | Affected Files | Notes |
|---|---------|----------|---------------|-------|
| MF-01 | **Quiz Pause/Resume** | High | `QuizView.swift` | No pause button or state persistence mid-quiz |
| MF-02 | **Spotlight Integration** | High | — | README states profiles are searchable; `NSUserActivity` configured but `CSSearchableItem` never indexed |
| MF-03 | **Sparkle Auto-Update** | High | — | README documents delta updates and rollback; no Sparkle SPM dependency or `SUUpdater` present |
| MF-04 | **Excel .xlsx Export** | High | `ResearchExportManager.swift:230` | Falls back to CSV silently — requires `libxlsxwriter` or equivalent |
| MF-05 | **R Data (.RData) Export** | High | `ResearchExportManager.swift:194–227` | Produces `.R` script, not binary `.RData` — requires `R` serialization format |
| MF-06 | **Universal Links / Deep Linking** | Medium | — | README documents deep link support for profiles; no `apple-app-site-association` or `onOpenURL` handler |
| MF-07 | **Services Menu Integration** | Medium | — | README documents system-wide sharing via Services; no `NSServicesMenuRequestor` conformance |
| MF-08 | **Conflict Resolution UI (CloudKit)** | High | `CloudSyncManager.swift` | `.serverRecordChanged` silently ignored — needs merge sheet |
| MF-09 | **3D State Space Visualization** | Low | — | Listed in roadmap section of README |
| MF-10 | **Core ML On-Device Inference** | Low | — | Listed in roadmap; no CoreML model bundle or `MLModel` usage found |
| MF-11 | **Localization String Files** | High | `OnboardingView.swift`, `IntroView.swift` | English strings hard-coded; `.strings` files absent from bundle for localized UI |
| MF-12 | **Privacy Manifest (`PrivacyInfo.xcprivacy`)** | Critical | — | Required by Apple since Spring 2024 for App Store submission; not present in project |
| MF-13 | **File Import from Menu Bar** | High | `MenuCommands.swift:49–57` | `showImportPanel` and `showExportPanel` are empty stubs |
| MF-14 | **macOS PDF Generation (APA/MLA)** | High | `ResearchExportManager.swift:452` | Returns empty `Data` — incomplete |
| MF-15 | **Nightly Scheduled CI Builds** | Low | `.github/workflows/` | No scheduled workflow; nightly regression detection absent |
| MF-16 | **TestFlight Beta Distribution** | Medium | `fastlane/Fastfile` | DMG upload attempted instead of `.app`/`.ipa` for TestFlight |
| MF-17 | **Settings Import/Export** | Medium | `GeneralSettingsView.swift` | Referenced in README under Settings Features; not found in implementation |
| MF-18 | **AdvancedAnalyticsManager Tests** | High | `APGI-ExplorerTests/` | Zero test coverage for core analytics feature |

---

## 6. Hybrid Architecture Analysis — SwiftUI + AppKit

### 6.1 Current Architecture Assessment

The application is built primarily in **SwiftUI** with selective AppKit integration for macOS-native behaviors. The hybrid boundary is handled correctly in most places, but several anti-patterns require remediation.

**Current dependency injection model — mixed and inconsistent:**

```
APGIExplorerApp
  └── @StateObject AppState              ← top-level, correct
  └── @EnvironmentObject ProfileManager ← injected via .environmentObject()
  └── @EnvironmentObject ThemeManager   ← injected via .environmentObject()
  └── @Environment AppDependencies      ← custom environment key

MainTabView
  └── @StateObject AppState             ← DUPLICATE — re-created, not shared
  └── @EnvironmentObject ProfileManager ← correct, received from parent
```

**Recommended unified approach using `AppDependencies` exclusively:**

```swift
// AppDependencies.swift — already exists, extend it
struct AppDependencies {
    let profileManager: ProfileManager
    let themeManager: ThemeManager
    let storeManager: StoreManager
    let cloudSyncManager: CloudSyncManager
    // Remove all separate @EnvironmentObject injections
}

// At app entry point:
@main struct APGIExplorerApp: App {
    @StateObject private var deps = AppDependencies()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appDependencies, deps)
        }
    }
}
```

### 6.2 NSViewRepresentable — Battle-Tested Pattern

For the `APGIRadarChart` and any custom `NSView`-backed drawing (e.g., future Metal rendering):

```swift
struct APGIRadarChartView: NSViewRepresentable {
    let profile: APGIProfile
    // Use a class-bound delegate to avoid retain cycles
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> APGIRadarNSView {
        let view = APGIRadarNSView()
        view.delegate = context.coordinator   // weak reference in NSView
        return view
    }

    func updateNSView(_ nsView: APGIRadarNSView, context: Context) {
        // Only trigger redraw if profile actually changed
        guard nsView.currentProfile != profile else { return }
        nsView.currentProfile = profile
        nsView.setNeedsDisplay(nsView.bounds)
    }

    func dismantleNSView(_ nsView: APGIRadarNSView, coordinator: Coordinator) {
        nsView.delegate = nil   // Break retain cycle on teardown
    }

    final class Coordinator: NSObject {
        weak var parent: APGIRadarChartView?
        init(_ parent: APGIRadarChartView) { self.parent = parent }
    }
}
```

### 6.3 NSHostingView — Embedding SwiftUI in AppKit

`ProfileManager.createNSImage()` (line 859–878) creates an `NSHostingView` without cleanup:

```swift
// PROBLEMATIC — no cleanup path
func createNSImage(from view: some View, size: CGSize) -> NSImage? {
    let hostingView = NSHostingView(rootView: view)  // Never released
    hostingView.frame = CGRect(origin: .zero, size: size)
    ...
}

// FIX — explicit lifecycle management
func renderToImage<V: View>(_ view: V, size: CGSize) -> NSImage? {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = CGRect(origin: .zero, size: size)
    defer {
        hostingView.removeFromSuperview()  // Force ARC release path
    }
    let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
    let image = NSImage(size: size)
    image.addRepresentation(bitmapRep)
    return image
}
```

### 6.4 State Integrity — SwiftUI/AppKit Boundary

When `NSWindowDelegate` callbacks need to drive SwiftUI state, always dispatch to `MainActor`:

```swift
// WindowManager.swift — safe pattern
final class WindowDelegate: NSObject, NSWindowDelegate {
    var onClose: @MainActor () -> Void = {}

    func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            self.onClose()  // Safe — always on main actor
        }
    }
}
```

---

## 7. Performance & Concurrency Assessment

### 7.1 Swift Concurrency (async/await) Adoption

**Current state:** Mixed. `StoreManager` uses clean `async/await` with `@MainActor`. `ProfileManager` mixes `DispatchQueue.main.async` with `Task {}`. `CloudSyncManager` uses `async/await` but has the `isSyncing` race condition.

**Recommended: Actor-based managers for all mutable shared state:**

```swift
// Replace ObservableObject + DispatchQueue with actor
actor ProfileStore {
    private var profiles: [APGIProfile] = []

    func save(_ profile: APGIProfile) async throws {
        // Implicit serialization — no DispatchQueue needed
        profiles.append(profile)
        try await persistToCoreData(profile)
    }

    func all() async -> [APGIProfile] { profiles }
}

// Bridge to SwiftUI via @Observable (macOS 14+) or ObservableObject wrapper
@MainActor final class ProfileViewModel: ObservableObject {
    @Published private(set) var profiles: [APGIProfile] = []
    private let store = ProfileStore()

    func loadProfiles() async {
        profiles = await store.all()
    }
}
```

### 7.2 GCD Quality of Service Tiers

Correct QoS assignment for background operations:

```swift
// FileStorageManager — backup operations
DispatchQueue.global(qos: .utility).async { ... }       // Correct: non-urgent I/O

// PerformanceManager — metrics collection
DispatchQueue.global(qos: .background).async { ... }    // Correct: lowest priority

// CloudSyncManager — user-triggered sync
DispatchQueue.global(qos: .userInitiated).async { ... } // Correct: user is waiting

// APGIScorer — quiz scoring after submission
DispatchQueue.global(qos: .userInteractive).async { ... } // INCORRECT — use .userInitiated
                                                           // Scoring takes >100ms
```

### 7.3 Memory Management — Identified Issues

| Location | Issue | Fix |
|----------|-------|-----|
| `WindowManager.swift:99` | `WindowDelegate` closure captures `self` strongly | Use `[weak self]` capture list |
| `ProfileManager.swift:859–878` | `NSHostingView` never dismantled | See `renderToImage()` fix above |
| `StateModel.swift` | `StateModelCache` — `NSCache` cost calculation not validated | Set `totalCostLimit` to `50 * 1024 * 1024` |
| `PerformanceManager.swift:152` | `queue.sync` on `.concurrent` queue | Use `queue.async` with completion or actor |

**Instruments-validated checklist:**
- [ ] Run **Leaks** instrument after completing quiz → saving profile → exporting
- [ ] Run **Allocations** instrument — watch for `NSHostingView` accumulation
- [ ] Run **Time Profiler** — `ProfileManager.enhancedProfile()` likely hot path
- [ ] Enable **Thread Sanitizer** to surface `CloudSyncManager` race condition

### 7.4 Launch Time Optimization

```swift
// APGI_ExplorerApp.swift:23–26 — deferred background work is good, but:
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    // Running screenshot mode check at +2s is arbitrary
    // Use scene phase instead:
}

// RECOMMENDED — scene phase driven
.onChange(of: scenePhase) { phase in
    if phase == .active {
        Task(priority: .background) {
            await screenshotRunner.checkAndRun()
        }
    }
}
```

---

## 8. Security & Privacy Analysis

### 8.1 App Sandbox Compliance

- **Status:** Configured (build references sandbox entitlements)
- **Risk:** `SecurityManager` fatal crash on store load may cause sandbox violation recovery failures
- **Action Required:** Validate `.entitlements` file declares only minimal required capabilities

### 8.2 Keychain Implementation

`KeychainManager.swift` correctly uses `kSecClassGenericPassword`, `kSecAttrAccessible`, and performs add/update/delete with proper `OSStatus` checking. **One optimization needed:**

```swift
// CURRENT — always delete then add (2 round-trips)
SecItemDelete(query as CFDictionary)
SecItemAdd(item as CFDictionary, nil)

// RECOMMENDED — use SecItemUpdate; fall through to SecItemAdd only on errSecItemNotFound
let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
if status == errSecItemNotFound {
    SecItemAdd(fullItem as CFDictionary, nil)
}
```

### 8.3 CryptoKit Integration

`SecurityManager` references AES-256 encryption. Validate with CryptoKit:

```swift
import CryptoKit

struct DataEncryptor {
    static func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    static func decrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// Key derivation from Keychain-stored 256-bit seed:
let key = SymmetricKey(data: keychainData)
```

### 8.4 Privacy Manifest — CRITICAL MISSING REQUIREMENT

**Apple has required `PrivacyInfo.xcprivacy` for all App Store submissions since Spring 2024.** This file is absent from the project.

```xml
<!-- Required: APGI-Explorer/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Declare UserDefaults, Core Data, Keychain usage -->
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- App-defined settings -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### 8.5 Hardcoded Authentication Tokens — Security Exposure

- **File:** `ScreenshotProductionEngine.swift:234`
- **Tokens:** `["APGI-Screenshot-2024", "PROD-SCREENSHOT-AUTH"]` are hardcoded in source
- **Risk:** These tokens are visible in any compiled binary via `strings` command and in the public repository
- **Fix:** Move to environment variables or a build-time configuration file excluded from git:

```swift
// Use Xcode build settings / xcconfig instead
static let allowedTokens: Set<String> = {
    guard let token = Bundle.main.infoDictionary?["SCREENSHOT_AUTH_TOKEN"] as? String
    else { return [] }
    return [token]
}()
```

### 8.6 Unsafe Bundle Swizzling — App Store Risk

- **File:** `Services/LocalizationManager.swift:76, 107–108`
- `object_setClass()` and `objc_setAssociatedObject()` used for runtime Bundle class swapping
- This pattern is flagged by App Store review for private API usage
- **Fix:** Use `UserDefaults.standard.set(["en"], forKey: "AppleLanguages")` + restart, or ship `.xcstrings` files with per-locale overrides

---

## 9. UI/UX & Human Interface Guidelines Compliance

### 9.1 SF Symbols Usage

SF Symbols are used throughout (confirmed in `ViewConstants.swift`, settings views, tab bar). Ensure minimum symbol availability version matches deployment target (macOS 12.0):

```swift
// Safe: all symbols used should be available in SF Symbols 2 (macOS 11+)
// Audit with: xcrun simctl list devicetypes | grep Mac
// Then verify each symbol at: https://developer.apple.com/sf-symbols/
```

### 9.2 Dark Mode / Semantic Colors

`AppColors.swift` references `Color("name")` from asset catalog with `Any/Dark` appearance slots — correct pattern. Verify all custom colors have dark variants:

- ✅ `AccentColor.colorset` — confirmed in `Assets.xcassets`
- ⚠️ Profile type colors (Orange, Blue, Green, Pink, etc.) — must verify dark-appropriate variants
- ❌ `PerformanceMetricsView.swift` — uses `.red`, `.green` literals which are not semantic

### 9.3 Keyboard-First Navigation

- `KeyboardNavigationModifier.swift` correctly implements `focusable()`, `onKeyPress()`, and `keyboardShortcut()` modifiers
- Menu bar commands (`⌘1`–`⌘5` for tabs, `⌘,` for Settings) are correctly registered
- **Missing:** Focus ring visibility is not explicitly managed; accessibility audit via Accessibility Inspector needed

### 9.4 Dynamic Type & Accessibility

- `AccessibilityManager.swift` provides `AccessibleButton`, `reduceMotion` animation guard, and accessibility label helpers — excellent
- **Issue:** `reduceMotion` returns zero-duration animation unconditionally — this may hide transitions entirely rather than substituting a non-motion alternative
- **Fix:** Substitute a cross-fade (opacity animation) instead of zero duration:

```swift
var reducedMotionAnimation: Animation {
    prefersReducedMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4)
}
```

### 9.5 Window Management

`WindowManager.swift` correctly enforces minimum sizes and supports `cascade()`, `tile()`, and side-by-side arrangements via `NSWindow` APIs. The `NSHostingController`-based multiple window approach is correct.

**HIG Compliance Checklist:**

| Requirement | Status |
|------------|--------|
| Minimum window size enforced | ✅ |
| Window title reflects document state | ✅ |
| Standard toolbar items | ✅ |
| Full-screen support | ✅ |
| Supports system Appearance override | ✅ |
| `NSUserInterfaceItemIdentifier` for state restoration | ⚠️ Partial |
| Traffic light buttons visible in full-screen | ✅ |

---

## 10. Testing & Quality Assurance Assessment

### 10.1 Test Suite Coverage Assessment

| Component | Test File | Status | Quality |
|-----------|----------|--------|---------|
| APGIScorer | `APGI_ExplorerTests.swift` | ⚠️ Thin | Only nil assertions |
| KeychainManager | `KeychainTests.swift` | ✅ Present | Good |
| SecurityManager | `SecurityManagerTests.swift` | ✅ Present | Good |
| ResearchExportManager | `ResearchExportTests.swift` | ✅ Present | Moderate |
| CloudSyncManager | `CloudSyncTests.swift` | ❌ Broken | Placeholder only |
| StoreManager | `StoreKitTests.swift` | ❌ Broken | Placeholder only |
| LocalizationManager | `LocalizationTests.swift` | ⚠️ Incomplete | No .strings file validation |
| PerformanceManager | `PerformanceTests.swift` | ✅ Present | Moderate |
| AdvancedAnalyticsManager | — | ❌ Missing | No test file |
| FileStorageManager | — | ❌ Missing | No test file |
| CrashReportingManager | — | ❌ Missing | No test file |
| ContextualHelpManager | — | ❌ Missing | No test file |
| UI Flow (quiz → results) | `APGI_ExplorerUITests.swift` | ❌ Broken | Compile error |
| Export UI | `ExportUITests.swift` | ⚠️ Broken | `menuItems` access wrong API |

### 10.2 Placeholder Tests — Must Replace

```swift
// CloudSyncTests.swift:24–51 — ALWAYS PASSES — provides zero confidence
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    expectation.fulfill()
}
wait(for: [expectation], timeout: 5.0)
XCTAssertTrue(true)  // ← This assertion is meaningless

// Fix: Use mock CKContainer and assert sync state transitions
func testSyncTriggersStateChange() async throws {
    let mockContainer = MockCloudKitContainer()
    let manager = CloudSyncManager(container: mockContainer)
    XCTAssertFalse(manager.isSyncing)
    await manager.syncProfiles()
    XCTAssertFalse(manager.isSyncing)  // Should be false after completion, not during
    XCTAssertEqual(mockContainer.saveCallCount, 1)
}
```

### 10.3 CI/CD Pipeline Issues

| Issue | File | Severity |
|-------|------|----------|
| `xcrun xccov view` deprecated | `release.yml:49–50` | Medium |
| `altool` deprecated (use `notarytool`) | `release.yml:202` | Medium |
| Notarization polls with fixed 300s wait | `release.yml:157` | Medium |
| DMG uploaded to TestFlight (wrong format) | `Fastfile:87` | High |
| No TestFlight lane | `Fastfile` | Medium |
| SwiftLint `cyclomatic_complexity` conflict | `.swiftlint.yml:28,77–79` | Low |
| `trailing_whitespace` disabled | `.swiftlint.yml:28` | Low |
| No scheduled nightly build | `.github/workflows/` | Low |

---

## 11. Distribution Strategy Analysis

### 11.1 Mac App Store vs. Direct Distribution

| Factor | Mac App Store | Direct (Notarized) |
|--------|:-------------:|:-----------------:|
| Discovery | ✅ Built-in | ❌ Manual |
| Auto-updates | ✅ Via StoreKit | ⚠️ Requires Sparkle |
| Sandbox requirement | ✅ Enforced | Optional |
| Reviewer latency | ⚠️ 1–3 days | ✅ None |
| Bundle swizzling (LocalizationManager) | ❌ Rejected | ⚠️ Risk |
| Revenue cut | ❌ 30% (15% Small Dev) | ✅ 0% |
| Privacy Manifest required | ✅ Required | ✅ Required |
| Enterprise/academic volume | ⚠️ Custom B2B | ✅ Native |

**Recommendation:** Pursue **both channels** with separate build configurations. Fix `LocalizationManager` Bundle swizzling before App Store submission. Add Sparkle for direct distribution.

### 11.2 StoreKit 2 Integration Assessment

`StoreManager.swift` correctly uses `Product.products(for:)`, `product.purchase()`, and `Transaction.currentEntitlements`. The only issue is the UserDefaults-based feature gating (see BUG-H06). Otherwise the StoreKit 2 implementation is well-structured.

### 11.3 Apple Silicon Optimization

- Universal binary (arm64 + x86_64) declared — correct
- No Rosetta-specific workarounds found — good
- **Recommended:** Add `EXCLUDED_ARCHS[sdk=macosx*] = ""` in Xcode build settings to ensure arm64 slice is always built

### 11.4 Core ML — On-Device AI Readiness

Referenced in the roadmap, not yet implemented. When adding:

```swift
import CoreML

final class APGIPredictor {
    private lazy var model: MLModel? = {
        guard let url = Bundle.main.url(forResource: "APGIProfilePredictor", withExtension: "mlmodelc")
        else { return nil }
        return try? MLModel(contentsOf: url)
    }()

    func predict(parameters: APGIParameters) async -> ProfileTypePrediction? {
        guard let model else { return nil }
        // Use MLFeatureProvider on background actor
        return await Task.detached(priority: .userInitiated) {
            // inference off main thread
        }.value
    }
}
```

### 11.5 Continuity Features

- `HandoffManager.swift` provides `NSUserActivity` with `addUserInfoEntries` — correct pattern
- **Missing:** `NSUserActivityDelegate` `userActivityWillSave(_:)` callback — activity not refreshed on state change
- **Fix:** Implement `userActivityWillSave` to always reflect current quiz progress before iOS picks up activity

---

## 12. Actionable Remediation Roadmap

### Sprint 1 — Critical Blockers (Week 1–2)

| # | Action | Owner | Files |
|---|--------|-------|-------|
| R-01 | Replace `fatalError()` in `SecurityManager` with graceful recovery | Backend | `Services/SecurityManager.swift:18–20` |
| R-02 | Fix `APGI_ExplorerUITests.swift` compilation error | QA | `APGI-ExplorerUITests/APGI_ExplorerUITests.swift:30` |
| R-03 | Add bounds check to `QuizView` question index access | UI | `QuizView.swift:92, 100–101` |
| R-04 | Implement actor-based sync coordinator in `CloudSyncManager` | Backend | `Services/CloudSyncManager.swift:87–90` |
| R-05 | Add conflict resolution UI for CloudKit `.serverRecordChanged` | Backend+UI | `Services/CloudSyncManager.swift:116–117` |
| R-06 | Add `PrivacyInfo.xcprivacy` manifest to project | Legal/Arch | New file |
| R-07 | Gate StoreKit features on `Transaction.currentEntitlements` only | Backend | `Services/StoreManager.swift:234–251` |

### Sprint 2 — High Priority (Week 3–4)

| # | Action | Owner | Files |
|---|--------|-------|-------|
| R-08 | Fix macOS PDF generation in `ResearchExportManager` | Backend | `Services/ResearchExportManager.swift:452` |
| R-09 | Replace Excel stub with real `.xlsx` generation (SwiftXLSX or similar) | Backend | `Services/ResearchExportManager.swift:230` |
| R-10 | Implement `showImportPanel` / `showExportPanel` in `MenuCommands` | UI | `MenuCommands.swift:49–57` |
| R-11 | Fix inverted battery detection in `PerformanceManager` | Backend | `PerformanceManager.swift:88–89` |
| R-12 | Replace placeholder CloudSync/StoreKit tests with real assertions | QA | `CloudSyncTests.swift`, `StoreKitTests.swift` |
| R-13 | Add error propagation and user-facing alerts in `ExportView` | UI | `ExportView.swift:107` |
| R-14 | Remove hardcoded auth tokens from `ScreenshotProductionEngine` | Security | `ScreenshotProductionEngine.swift:234` |
| R-15 | Fix Bundle swizzling in `LocalizationManager` (use `.xcstrings`) | Backend | `Services/LocalizationManager.swift:76, 107` |
| R-16 | Add localized strings to `OnboardingView` and `IntroView` | UI/i18n | `OnboardingView.swift`, `IntroView.swift` |

### Sprint 3 — Architecture Refactoring (Week 5–6)

| # | Action | Owner | Files |
|---|--------|-------|-------|
| R-17 | Split `ProfileManager` (965 lines) into `ProfileCRUDService`, `ProfileExportService`, `ProfileScoringService` | Architecture | `ProfileManager.swift` |
| R-18 | Consolidate dependency injection to `AppDependencies` only — remove redundant `@StateObject` in `MainTabView` | Architecture | `MainTabView.swift`, `AppDependencies.swift` |
| R-19 | Migrate `DispatchQueue.main.async` calls to `@MainActor` throughout | Backend | `StoreManager.swift`, `CloudSyncManager.swift` |
| R-20 | Fix `NSHostingView` lifecycle in `ProfileManager.createNSImage()` | Memory | `ProfileManager.swift:859–878` |
| R-21 | Fix `queue.sync` on concurrent queue in `PerformanceManager` | Performance | `PerformanceManager.swift:152` |
| R-22 | Remove APGIScorer hardcoded question IDs — use question metadata | Algorithm | `APGIScorer.swift:535–579` |

### Sprint 4 — Missing Features & Polish (Week 7–8)

| # | Action | Owner | Files |
|---|--------|-------|-------|
| R-23 | Implement quiz Pause/Resume with state persistence | UI | `QuizView.swift` |
| R-24 | Add `CSSearchableItem` indexing for Spotlight | Backend | New: `SpotlightManager.swift` |
| R-25 | Add Sparkle SPM dependency and `SUUpdater` configuration | Backend | `Package.swift`, `APGI_ExplorerApp.swift` |
| R-26 | Implement `userActivityWillSave` for reliable Handoff | Backend | `HandoffManager.swift` |
| R-27 | Add missing test files for AdvancedAnalyticsManager, FileStorageManager, CrashReportingManager | QA | `APGI-ExplorerTests/` |
| R-28 | Migrate CI/CD from `altool` to `notarytool` and fix DMG/TestFlight lane | DevOps | `release.yml`, `Fastfile` |
| R-29 | Substitute zero-duration `reduceMotion` with cross-fade alternative | Accessibility | `AccessibilityManager.swift` |
| R-30 | Add R proper binary serialization or clearly document `.R` script format | Backend | `ResearchExportManager.swift` |

---

## Appendix A — Instruments Validation Matrix

| Instrument | Scenario | Pass Criteria |
|------------|----------|--------------|
| Leaks | Full quiz → save → export | 0 leaks after export completes |
| Allocations | 10 profile saves in succession | < 5 MB net allocation growth |
| Time Profiler | Quiz submission → results display | < 100 ms main thread activity |
| Thread Sanitizer | Concurrent sync + profile save | 0 race conditions reported |
| Network | CloudKit sync | All operations over TLS 1.3 |
| Energy Log | 5-minute idle | CPU < 2%, memory stable |

---

## Appendix B — LLDB Debug Commands

```lldb
# Break on all AppError throws
(lldb) breakpoint set -n "AppError" -C "po error"

# Inspect CloudSyncManager state
(lldb) po CloudSyncManager.shared.isSyncing
(lldb) po CloudSyncManager.shared.lastSyncDate

# Memory graph for NSHostingView leaks
(lldb) command script import lldb.macosx.heap
(lldb) ptr_refs NSHostingView.self

# Log all os_log subsystem output
$ log stream --predicate 'subsystem == "com.yourcompany.APGI-Explorer"' --level debug
```

---

## Appendix C — Recommended os_log Integration Pattern

```swift
import os

extension Logger {
    static let quiz    = Logger(subsystem: "com.yourcompany.APGI-Explorer", category: "quiz")
    static let export  = Logger(subsystem: "com.yourcompany.APGI-Explorer", category: "export")
    static let sync    = Logger(subsystem: "com.yourcompany.APGI-Explorer", category: "cloudsync")
    static let scoring = Logger(subsystem: "com.yourcompany.APGI-Explorer", category: "scoring")
}

// Usage — structured, queryable via Console.app
Logger.scoring.info("Profile scored: type=\(profile.type, privacy: .public), ε=\(profile.epsilon, privacy: .private)")
Logger.sync.error("Sync failed: \(error.localizedDescription, privacy: .public)")
```

---

*REPORT.md generated on 2026-02-24 — APGI-Explorer macOS Architecture Review*
*Review scope: 85 Swift source files, 10 test files, 3 CI/CD workflows*
*Next review recommended after Sprint 2 remediation (estimated: 4 weeks)*
