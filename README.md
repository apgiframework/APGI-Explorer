# APGI Explorer

A comprehensive psychological assessment application that helps users understand their cognitive and emotional processing styles through the APGI model. Built with SwiftUI for a seamless cross-platform experience on macOS.

---

## 📁 1. App Overview

### Application Identity

- **App Name**: APGI-Explorer
- **Bundle Identifier**: `com.yourcompany.APGI-Explorer` (to be configured)
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

- **Unit Tests**: Core functionality testing with 95%+ coverage
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

- **Code Coverage**: 95%+ for critical components
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
- **Testing**: 95%+ coverage required for new features
- **Documentation**: All public APIs documented
- **Accessibility**: WCAG 2.1 AA compliance required
- **Performance**: <100ms response time for UI operations

### Contributing Process

1. **Fork** the repository
2. **Create** a feature branch from `develop`
3. **Implement** changes with tests
4. **Run** full test suite and linting
5. **Submit** pull request with detailed description
6. **Review** process with automated checks

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

## ✅ 11. Validation Checklist

### App Functionality

- [ ] Assessment completes successfully with valid scoring
- [ ] All 8 profile types display correctly with accurate analysis
- [ ] Interactive visualizations render properly across all chart types
- [ ] Export functionality works for JSON, CSV, PDF, and PNG formats
- [ ] Settings persist correctly across app restarts

### Platform Requirements

- [ ] Runs on both Apple Silicon and Intel Macs
- [ ] Passes App Store validation (if applicable)
- [ ] Notarized for direct distribution
- [ ] Complies with macOS Human Interface Guidelines

### Accessibility & UX (Validation)

- [ ] Tested with VoiceOver and keyboard-only navigation
- [ ] Dynamic Type support for scalable text
- [ ] Dark mode compatibility with system integration
- [ ] Responsive design for various screen sizes
- [ ] Performance optimization for smooth interactions

### Data & Privacy

- [ ] All data stored locally with proper encryption
- [ ] User consent obtained for any analytics
- [ ] Clear data export and deletion options
- [ ] GDPR compliance for data protection
- [ ] Transparent privacy policy and data handling

## App Store Connect In-App Purchase Setup Instructions

## Products to Register

### 1. Premium Monthly Subscription

- **Product ID**: `com.lesoto.APGI-Explorer.premium.monthly`
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Premium Monthly
- **Price Tier**: 4 ($4.99/month)
- **Duration**: 1 Month

### 2. Premium Yearly Subscription

- **Product ID**: `com.lesoto.APGI-Explorer.premium.yearly`
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Premium Yearly
- **Price Tier**: 39 ($39.99/year)
- **Duration**: 1 Year

### 3. Professional Features

- **Product ID**: `com.lesoto.APGI-Explorer.professional`
- **Type**: Consumable
- **Reference Name**: Professional Features
- **Price Tier**: 19 ($3.99)

### 4. Research Pack

- **Product ID**: `com.lesoto.APGI-Explorer.research.pack`
- **Type**: Consumable
- **Reference Name**: Research Pack
- **Price Tier**: 29 ($5.99)

### 5. Unlimited Profiles

- **Product ID**: `com.lesoto.APGI-Explorer.unlimited.profiles`
- **Type**: Consumable
- **Reference Name**: Unlimited Profiles
- **Price Tier**: 9 ($0.99)

## Steps to Register

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app "APGI Explorer"
3. Navigate to "Monetization" → "In-App Purchases"
4. Click "+" to create a new in-app purchase
5. Select the appropriate type and fill in the details above
6. Set up pricing and availability
7. Submit for review

## Testing

After registering the products, test in sandbox environment:

1. Create a sandbox tester account
2. Use the StoreManager.shared.loadProducts() method
3. Verify products appear in the UI
4. Test purchase flow with sandbox account

## Important Notes

- Product IDs must match exactly as defined in StoreManager.swift
- All products should be available worldwide
- Subscription products need shared secret for server-side validation
- Test thoroughly in sandbox before production release

## 🚀 Getting Started

### Prerequisites

- macOS 12.0+ or iOS 15.0+
- Xcode 14.0+ (for development)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/APGI-Explorer.git
   cd APGI-Explorer
   ```

2. Open `APGI-Explorer.xcodeproj` in Xcode
3. Build and run the project (⌘R)

## 📚 13. Additional Resources

- **API Documentation**: Comprehensive API reference
- **User Guide**: Step-by-step user instructions
- **Developer Guide**: Setup and contribution guidelines
- **Research Papers**: Academic validation and methodology

- **GitHub Issues**: Bug reports and feature requests
- **Discord Community**: Real-time discussions and support
- **Academic Forum**: Research collaboration and discussions
- **Newsletter**: Updates and development progress

- **APGI-Research**: Open research dataset and tools
- **APGI-Mobile**: Cross-platform mobile assessment
- **APGI-Cloud**: Cloud-based analytics platform

- **Dark Mode**: Complete dark theme support with system integration
- **Responsive Design**: Optimized for both mouse and touch interactions

### Integration & APIs

- **File System Integration**: Direct access to system file dialogs
- **Notification System**: Native system notifications with custom actions
- **Window Management**: Advanced multi-window support with state persistence
- **Keyboard Shortcuts**: Comprehensive keyboard navigation and shortcuts
- **System Services**: Integration with macOS system services and sharing
