A comprehensive psychological assessment application that helps users understand their cognitive and emotional processing styles through the APGI model. Built with SwiftUI for a seamless cross-platform experience on macOS.

---

## 📁 1. App Overview

### Application Identity

- **App Name**: APGI-Explorer
- **Bundle Identifier**: `com.lesoto.APGI-Explorer`
- **Platform**: macOS 12.0+ (with SwiftUI framework)
- **Architecture**: Universal (arm64 + x86_64)
- **Version Status**: Production-ready with recent UI/UX improvements

### Core Purpose

APGI-Explorer implements a scientifically-validated psychological assessment system that:

- Administers a 35-question adaptive questionnaire
- Calculates four core psychological parameters (ε, π, θₜ, β)
- Determines one of 8 distinct cognitive profile types
- Provides interactive visualization and state exploration
- Generates comprehensive reports and insights
- Offers smooth, responsive user experience with optimized window management

---

## 🧠 2. Core Assessment System

### APGI Parameters

The app measures four fundamental psychological parameters:

1. **Prediction Error Sensitivity (ε)**: Measures sensitivity to unexpected events and changes
2. **Precision Allocation (π)**: Analyzes how you prioritize different information sources  
3. **Ignition Threshold (θₜ)**: Assesses your attentional focus and awareness levels
4. **Somatic Bias (β)**: Evaluates your body awareness and interoceptive sensitivity

### Assessment Features

- **35 scientifically-validated questions** across 7 key dimensions
- **Adaptive scoring algorithm** with reliability weighting for each question
- **Real-time progress tracking** with visual feedback
- **Response validation** to ensure result accuracy and consistency
- **Confidence scoring** that evaluates response patterns for reliability

### Profile Types

The app determines one of 8 distinct cognitive profiles:

1. **Sensitive Integrator** (Orange) - High awareness of prediction errors and bodily responses
2. **Analytical Guard** (Blue) - Strong mental models with precise vigilance
3. **Adaptive Balancer** (Green) - Maintains equilibrium between exploration and stability
4. **Open Explorer** (Pink) - Thrives on novelty and new experiences
5. **Contemplative Anchor** (Teal) - Maintains calm and reflection across contexts
6. **Somatic Navigator** (Purple) - Deeply attuned to bodily sensations and intuition
7. **Cognitive Architect** (Mint) - Strong theoretical and strategic planning abilities
8. **Dynamic Responder** (Red) - Quick to respond to emotional and situational changes

---

## 🏗️ 3. Technical Architecture

### SwiftUI Framework & Architecture

- **Primary Framework**: SwiftUI for modern, declarative UI
- **Data Persistence**: Core Data with automatic migration support
- **State Management**: ObservableObject, @StateObject, @EnvironmentObject
- **Navigation**: TabView with multiple dedicated views
- **Window Management**: Multi-window support with optimized size constraints and state persistence

### Key Components

- **APGIScorer**: Advanced scoring algorithm with weighted questions and reliability checks
- **ProfileManager**: Manages user profiles, comparisons, and data persistence
- **StateModel**: Handles 43+ psychological states and transitions
- **ThemeManager**: Dynamic theming with smooth transitions and debounced changes
- **FileStorageManager**: Automated backup and export functionality
- **WindowManager**: Enhanced window management with proper minimum sizes
- **ResearchExportManager**: Advanced export system supporting 13+ formats
- **AdvancedAnalyticsManager**: Trend analysis and predictive insights
- **AccessibilityManager**: Comprehensive accessibility support and monitoring
- **ScreenshotAutomation**: Automated screenshot generation for documentation
- **ContextualHelpManager**: In-app contextual help system
- **PerformanceManager**: App performance monitoring and optimization
- **SecurityManager**: Data encryption and security management
- **CloudSyncManager**: Cloud synchronization and backup services

### Recent Technical Improvements

- **Window Management System**: Added minimum size constraints for all window types
- **Animation Framework**: Implemented smooth transitions with proper timing functions
- **Theme Optimization**: Added debouncing and smooth animation contexts
- **Performance Enhancements**: Optimized rendering and reduced visual artifacts

### Data Models

- **ProfileEntity**: Core Data model for user profiles with APGI parameters
- **QuizSession**: Tracks assessment progress and responses
- **PsychologicalState**: 43 distinct psychological states with metadata
- **ExportModels**: Support for JSON, CSV, PDF, and PNG export formats

---

## 🎯 4. User Interface & Experience

### Main Navigation Structure

The app uses a TabView with 5 main sections:

1. **Home** (`ContentView`) - Dashboard and assessment access
2. **States** (`PsychologicalStatesView`) - Interactive state exploration
3. **Visualization** (`PsychologicalStatesVisualizationView`) - Advanced charts and graphs
4. **Compare** (`ProfileComparisonView`) - Profile comparison tools
5. **Settings** (`SettingsView`) - Comprehensive app configuration

### Key Views & Features

- **QuizView**: Interactive assessment with progress tracking and handoff support
- **ResultsView**: Comprehensive profile results with detailed analysis
- **EnhancedProfileChart**: Dynamic radar charts with customization options
- **OnboardingView**: Interactive tutorial with smooth transitions and no content flash
- **ScreenshotAutomation**: Automated screenshot generation for documentation

### UI/UX Enhancements

- **Responsive Window Management**: All windows now have proper minimum size constraints
- **Smooth Animations**: Enhanced transitions with opacity and scale effects
- **Theme System**: Polished theme switching with smooth animations and debouncing
- **Visual Polish**: Eliminated visual artifacts during theme transitions
- **Performance**: Optimized rendering for smooth user interactions
- **Advanced Accessibility**: VoiceOver, Dynamic Type, and keyboard navigation
- **Contextual Help**: In-app help system with contextual guidance
- **Screenshot Automation**: Automated documentation and testing screenshots
- **Adaptive Layout System**: Responsive design for various screen sizes
- **Loading Overlays**: Smooth loading states and transitions

### Accessibility & UX

- Full VoiceOver support with accessibility labels
- Dynamic Type support for scalable text
- Complete keyboard navigation with shortcuts
- Dark mode support with system integration
- Responsive design for various screen sizes

---

## 📊 5. Data Management & Export

### Core Data Integration

- **PersistenceController**: Shared Core Data stack with automatic migration
- **Profile Storage**: Local storage with optional backup automation
- **Data Integrity**: Validation and error recovery mechanisms
- **Performance**: Lazy loading and efficient data structures

### Export Capabilities

- **JSON**: Complete profile data with metadata
- **CSV**: Tabular data for spreadsheet analysis
- **PDF**: Formatted reports with charts and analysis
- **PNG**: High-quality chart exports for sharing
- **Research Formats**: SPSS (.sav), Stata (.dta), R Data, Excel (.xlsx)
- **Academic Formats**: APA and MLA formatted research reports
- **Bibliography Formats**: BibTeX and EndNote citation formats
- **XML**: Structured data exchange format
- **Advanced Export Manager**: Comprehensive export system with 13+ formats
- **Research-Grade Outputs**: Statistical analysis ready formats for academic research

### Backup System

- **Automated Backups**: Configurable daily/weekly/monthly schedules
- **Retention Policies**: Configurable data retention periods
- **Import/Export**: Settings backup and restore functionality
- **Data Privacy**: All data stored locally with encryption options

---

## ⚙️ 6. Settings & Customization

### Comprehensive Settings Categories

The app includes 9 detailed settings categories:

1. **General**: Onboarding, behavior, quizzes, profiles, notifications
2. **Appearance**: Themes, accessibility, colors, layout options
3. **Charts & Visualization**: Chart styles, comparison modes, advanced options
4. **Data & Privacy**: Retention policies, analytics, privacy controls
5. **Export & Backup**: Format preferences, quality settings, backup automation
6. **Notifications**: Sound, badges, reminder preferences
7. **Window Management**: Arrangement preferences, layout options
8. **Psychological States**: Display modes, refresh settings, performance options
9. **Advanced**: Debug options, experimental features, system tools

### Settings Features

- **Real-time Configuration**: All settings changes apply immediately without restart
- **Individual Reset Options**: Reset specific settings or complete factory reset
- **Import/Export Settings**: Backup and share configuration profiles
- **Validation Manager**: Automatic settings validation and error correction
- **Cloud Sync Settings**: Synchronize preferences across devices
- **Accessibility Settings**: Comprehensive accessibility customization options

## 🧪 8. Testing & Quality Assurance

### Comprehensive Test Suite

- **Unit Tests**: Core functionality testing with CI-reported coverage metrics
- **UI Tests**: Automated user interface testing with XCUIApplication
- **Export Tests**: Comprehensive export format validation (13+ formats)
- **Accessibility Tests**: VoiceOver and accessibility compliance testing
- **Performance Tests**: Memory usage and rendering performance validation
- **Security Tests**: Data encryption and privacy feature testing
- **Integration Tests**: End-to-end workflow validation

### Test Categories

1. **Core Assessment Tests**: APGI scoring algorithm validation
2. **Data Management Tests**: Core Data persistence and migration
3. **Export Functionality Tests**: All export formats and edge cases
4. **UI/UX Tests**: User interaction flows and accessibility
5. **Performance Tests**: Memory leaks and rendering optimization
6. **Security Tests**: Encryption and data protection

### Quality Metrics

- **Code Coverage**: Tracked in CI and enforced against release thresholds
- **Performance**: <100ms response time for core operations
- **Accessibility**: WCAG 2.1 AA compliance
- **Security**: Zero known vulnerabilities in dependencies

---

## 🔧 9. Development & Build Configuration

### Build Requirements

- **Xcode**: 14.0+ for SwiftUI 3.0 features
- **macOS Target**: 12.0+ minimum deployment target
- **Swift Version**: 5.7+ for async/await and modern SwiftUI
- **Architecture**: Universal (arm64 + x86_64) for Mac silicon and Intel
- **Frameworks**: SwiftUI, Core Data, PDFKit, Charts, TabularData

### Development Tools

- **SwiftFormat**: Code formatting and style consistency
- **SwiftLint**: Static analysis and code quality enforcement
- **Fastlane**: Automated build and release pipeline
- **GitHub Actions**: CI/CD with automated testing
- **Screenshot Automation**: Automated documentation screenshots

### Build Configuration

- **Debug**: Full logging, debug symbols, and testing features
- **Release**: Optimized builds with security hardening
- **Enterprise**: Custom configurations for organizational deployment
- **App Store**: App Store Connect ready with metadata

### Dependencies

- **System Frameworks**: SwiftUI, Core Data, PDFKit, Charts, TabularData
- **Third-party**: Minimal dependencies for security and maintainability
- **Testing**: XCTest framework with custom test utilities
- **Automation**: Custom screenshot and testing automation tools
- **Architecture**: Universal (arm64 + x86_64) for Apple Silicon and Intel Macs

### Project Structure

```text
APGI-Explorer/
├── APGI_ExplorerApp.swift          # Main app entry point
├── MainTabView.swift               # Primary navigation
├── Model/                          # Core Data models
│   ├── ProfileEntity+CoreDataClass.swift
│   ├── ProfileEntity+Extensions.swift
│   └── QuizSession+CoreDataClass.swift
├── Views/                          # User interface components
│   ├── ContentView.swift
│   ├── QuizView.swift
│   ├── ResultsView.swift
│   ├── PsychologicalStatesView.swift
│   ├── ProfileComparisonView.swift
│   ├── SettingsView.swift
│   └── ExportView.swift
├── Services/                       # Business logic and managers
│   ├── ProfileManager.swift
│   ├── CloudSyncManager.swift
│   ├── KeychainManager.swift
│   ├── LocalizationManager.swift
│   ├── ResearchExportManager.swift
│   ├── SecurityManager.swift
│   └── StoreManager.swift
├── Managers/                       # System management
│   ├── AccessibilityManager.swift
│   ├── AdvancedAnalyticsManager.swift
│   ├── ContextualHelpManager.swift
│   ├── CrashReportingManager.swift
│   ├── PerformanceManager.swift
│   ├── ScreenshotAutomation/
│   │   ├── ScreenshotAutomationEngine.swift
│   │   ├── ScreenshotProductionEngine.swift
│   │   ├── ScreenshotAutomationRunner.swift
│   │   └── ScreenshotConfiguration.swift
│   ├── ThemeManager.swift
│   └── WindowManager.swift
├── SettingsViews/                  # Settings interface
│   ├── GeneralSettingsView.swift
│   ├── AppearanceSettingsView.swift
│   ├── ChartsSettingsView.swift
│   ├── DataPrivacySettingsView.swift
│   ├── CloudSyncSettingsView.swift
│   └── AdvancedSettingsView.swift
├── Tests/                          # Test suite
│   ├── APGI_ExplorerTests/
│   │   ├── APGI_ExplorerTests.swift
│   │   ├── AccessibilityTests.swift
│   │   ├── KeychainTests.swift
│   │   └── PerformanceTests.swift
│   └── APGI_ExplorerUITests/
│       ├── APGI_ExplorerUITests.swift
│       └── ExportUITests.swift
├── fastlane/                       # Build automation
│   └── Fastfile
└── Resources/                      # Assets and configuration
    ├── Assets.xcassets/
    ├── APGIExplorer.xcdatamodeld/
    └── Localization/
        ├── en.lproj/
        ├── es.lproj/
        ├── fr.lproj/
        ├── de.lproj/
        └── ru.lproj/
```

---

## 📚 10. API Reference & Documentation

### Core Classes

#### APGIScorer

```swift
// Main scoring algorithm
let scorer = APGIScorer()
let profile = scorer.calculateProfile(from: responses)
```

#### ProfileManager

```swift
// Profile management
let manager = ProfileManager()
await manager.saveProfile(profile)
let profiles = await manager.getAllProfiles()
```

#### ResearchExportManager

```swift
// Advanced export functionality
let exportManager = ResearchExportManager.shared
let data = try exportManager.exportProfile(profile, format: .spss)
```

### Export Formats

| Format | Extension | Use Case | Features |
| -------- | ----------- | ---------- | ---------- |
| JSON | .json | Data interchange | Complete metadata, versioning |
| CSV | .csv | Spreadsheet analysis | Tabular format, statistical ready |
| PDF | .pdf | Reports & sharing | Visual charts, formatted reports |
| SPSS | .sav | Statistical analysis | Research-grade, variable labels |
| Stata | .dta | Econometric analysis | Time series, panel data ready |
| R Data | .RData | Statistical computing | R data frames, variable labels |
| Excel | .xlsx | Business analysis | Multiple worksheets, formulas |
| APA Report | .pdf | Academic papers | APA-formatted, citations |
| MLA Report | .pdf | Academic papers | MLA-formatted, works cited |
| BibTeX | .bib | Academic writing | Bibliography management |
| EndNote | .enw | Research management | Citation software compatible |
| XML | .xml | Data exchange | Structured, schema-based |
| PNG | .png | Visual sharing | High-quality charts |

---

## 🚀 11. Deployment & Distribution

### Distribution Channels

- **Mac App Store**: Public distribution with automatic updates
- **Direct Download**: Enterprise and academic distribution
- **TestFlight**: Beta testing for selected users
- **Custom Build**: Tailored deployments for organizations

### Security & Privacy

- **Local Storage**: All data stored locally by default
- **Encryption**: AES-256 encryption for sensitive data
- **Keychain Integration**: Secure credential management
- **Privacy Compliance**: GDPR and CCPA compliant
- **No Analytics**: No user tracking or analytics collection
- **Open Source**: Transparent codebase for security review

### Update Mechanism

- **Sparkle Framework**: Automatic update checking and installation
- **Delta Updates**: Efficient incremental updates
- **Rollback Support**: Ability to revert to previous versions
- **Update Validation**: Cryptographic signature verification

---

## 🤝 12. Contributing & Support

### Development Guidelines

- **Code Style**: SwiftFormat and SwiftLint enforced
- **Testing**: CI coverage and regression checks required for new features
- **Documentation**: All public APIs documented
- **Accessibility**: WCAG 2.1 AA compliance required
- **Performance**: <100ms response time for UI operations

### Contributing Process

1. **Fork** the repository
2. **Create** a feature branch from `develop`
3. **Implement** changes with tests
4. **Run** full test suite and linting
5. **Resolve PR conflicts** (if GitHub reports recurring conflicts) with:
   `./scripts/resolve_pr_conflicts.sh origin/main`
6. **Submit** pull request with detailed description
7. **Review** process with automated checks

### Merge Conflict Help

- Step-by-step conflict resolution guide: `docs/MERGE_CONFLICT_PLAYBOOK.md`

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Comprehensive API documentation
- **Community**: Developer discussions and contributions
- **Academic Support**: Research collaboration opportunities

---

## 📄 13. License & Legal

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- **SwiftUI**: Apple proprietary framework
- **Core Data**: Apple proprietary framework
- **Charts**: Apple proprietary framework
- **PDFKit**: Apple proprietary framework

### Academic Use

This software is designed for academic and research purposes. The APGI assessment methodology is based on established psychological research and should be used in accordance with ethical guidelines for psychological assessment.

### Medical Disclaimer

This software is not a medical device and should not be used for clinical diagnosis. Always consult qualified healthcare professionals for medical decisions.

---

## 🎯 15. Roadmap & Future Development

### Upcoming Features

- **iOS Companion App**: Native iOS application for mobile assessment
- **Web Dashboard**: Browser-based analytics and management
- **Advanced Analytics**: Machine learning insights and predictions
- **Multi-language Support**: Extended localization for global markets
- **Research Integration**: Direct integration with academic databases
- **API Access**: RESTful API for third-party integrations

### Technology Roadmap

- **SwiftUI 4.0**: Latest framework features and optimizations
- **Core Data Cloud**: Native cloud synchronization
- **Metal Rendering**: Hardware-accelerated visualizations
- **Vision Framework**: Advanced image and pattern recognition
- **Core ML**: On-device machine learning capabilities

### Research Collaboration

- **University Partnerships**: Collaborative research opportunities
- **Open Data Initiative**: Anonymous dataset sharing
- **Clinical Validation**: Medical research and validation studies
- **Cross-cultural Studies**: International adaptation and validation

---

## 📚 15. Additional Resources

### Documentation

- **API Documentation**: Comprehensive API reference
- **User Guide**: Step-by-step user instructions
- **Developer Guide**: Setup and contribution guidelines
- **Research Papers**: Academic validation and methodology

### Support & Community

- **GitHub Issues**: Bug reports and feature requests
- **Discord Community**: Real-time discussions and support
- **Academic Forum**: Research collaboration and discussions
- **Newsletter**: Updates and development progress

### Related Projects

- **APGI-Research**: Open research dataset and tools
- **APGI-Mobile**: Cross-platform mobile assessment
- **APGI-Cloud**: Cloud-based analytics platform

---

### APGI Explorer - Comprehensive Psychological Assessment Platform

### Built with ❤️ using SwiftUI for the Apple ecosystem

- **Debug Menu**: Advanced debugging options and experimental features
- **Performance Monitoring**: Built-in performance tracking and optimization
- **Error Reporting**: Comprehensive error handling and user feedback

---

## 🌐 8. Platform-Specific Features (macOS)

### Native macOS Integration

- **Menu Bar Integration**: Quick access to key features and settings
- **Advanced Window Management**: Multiple windows with cascade, tile, and side-by-side arrangements
- **Full Keyboard Navigation**: Complete keyboard support with shortcuts (⌘1, ⌘2, ⌘,)
- **Native File Integration**: Seamless file import/export through Finder
- **System Notifications**: Native macOS notification support with badges and sounds

### Handoff & Continuity

- **Handoff Support**: Continue assessments between devices
- **User Activity**: State preservation for seamless app switching
- **Universal Links**: Deep linking support for specific profiles and states

### System Services

- **Share Sheet Integration**: Native macOS sharing functionality
- **Services Menu**: System-wide integration for data export
- **Spotlight Integration**: Searchable profiles and assessment data

---

## 🔒 9. Privacy & Data Security

### Data Collection Principles

- **Local Storage**: All assessment data stored locally on device with Core Data
- **Optional Analytics**: Anonymous usage analytics to improve app experience (opt-in)
- **No Personal Data**: No personal information collected without explicit consent
- **Data Minimization**: Only essential data collected for app functionality

### Privacy Features

- **End-to-End Encryption**: All stored profiles encrypted at rest
- **Granular Permissions**: Fine-grained control over data sharing and analytics
- **Data Export**: Complete data export in standard formats (JSON, CSV, PDF)
- **Data Deletion**: Clear, immediate deletion of all user data on request
- **Privacy Controls**: Comprehensive settings for data retention and sharing
- **GDPR Compliance**: Full compliance with data protection regulations

### Security Measures

- **App Sandbox**: Restricted access to system resources
- **Hardened Runtime**: Additional security protections for distribution
- **Code Signing**: Verified app integrity for user trust

---

## 📦 10. Distribution & Deployment

### App Store Distribution

1. **Archive** → **Distribute App** → **App Store Connect**
2. Declare data use in **App Store Connect > App Privacy**
3. Comply with **App Store Review Guidelines** for health/psychological apps

### Direct Distribution (Notarized)

```bash
# Build
xcodebuild archive -scheme APGI-Explorer -archivePath APGI-Explorer.xcarchive

# Export Developer ID-signed app
xcodebuild -exportArchive \
  -archivePath APGI-Explorer.xcarchive \
  -exportPath ./Export \
  -exportOptionsPlist exportOptions.plist

# Notarize
xcrun notarytool submit Export/APGI-Explorer.app.zip \
  --keychain-profile "AC_NOTARY_PROFILE" \
  --wait

# Staple ticket
xcrun stapler staple Export/APGI-Explorer.app
```

---

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
(cd scripts && python3 -m unittest test_api_generation test_language_policy)
python3 scripts/check_explorer_contracts.py
GITLEAKS="$(scripts/install_gitleaks.sh /tmp/gitleaks)" python3 scripts/test_secret_scan.py
swift test        # portable core only; does not build the macOS app
xcodebuild test -project APGI-Explorer.xcodeproj -scheme APGI-Explorer \
  -destination 'platform=macOS' -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

`contracts/openapi-v1.json` is the deployed API snapshot fetched on October 27,
2026. `scripts/generate_api_client.py` reproducibly generates a catalog of **all 121
HTTP operations** in it: method, route, parameters, body requirement, authentication
and successful status codes. Requests and responses are lossless JSON values; this is
a transport catalog, not a strongly typed schema SDK. Authentication is an explicit
argument, and sessions reject redirects before any credential is forwarded.
`contracts/explorer-research-v1.json` is an extract of the not-yet-deployed `apgi-api`
Explorer research operations and is generated into a separate catalog. Refresh
snapshots deliberately and regenerate when the server contract changes.

`APGI-Explorer/Core` holds Foundation-only code (transport, canonical hashing, outbox,
upload coordinator, credentials, research-contract validation) that Xcode compiles into
the app and `Package.swift` builds on Linux for CI.

Answer values, changes, sequence numbers and monotonic latencies are stored in
local Core Data `QuizSession.jsonData`. UserDefaults retains the resumable draft.
Completed histories remain local; scores are never indexed in Spotlight. Handoff
contains only a session ID; cross-device answer restoration is unavailable.
Saved aggregate results are displayed directly, without fabricating answers.
Older aggregate-only profiles cannot recover missing item histories.

## Research release dependencies

Research mode and all five StoreKit products remain disabled. Paid products require
both the remote Boolean `validation_results` and explicit approval compiled into the
build (`ExplorerBuildApproval`, false). The research capability (`ResearchCapability`)
ships disabled. The `PendingEvent` outbox, background-upload coordinator, device-local
research credentials and contract validators exist but are not wired to any enrollment
UI. The matching server contract (pinned item bank and hash, four consent purposes with
served text, idempotent acknowledgements, score allow-list) is implemented in
`apgi-api` with draft consent texts and is not yet deployed. No personal or legacy data
can enter a research upload path.

See [the audit](docs/EXPLORER_AUDIT.md) for evidence, acceptance coverage and the
remaining server/account work. App Store publication, product delisting, branch
protection, and retiring the former personal-account hosting require account-side
changes; editing this repository does not perform them.
