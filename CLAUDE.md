# CLAUDE.md — APGI-Explorer Psychological Assessment App

APGI-Explorer is a comprehensive psychological assessment application built with SwiftUI for macOS that helps users understand their cognitive and emotional processing styles through the APGI (Active Precision, Goal, and Interception) model.

---

## 📁 1. App Overview

### Application Identity
- **App Name**: APGI-Explorer
- **Bundle Identifier**: `com.yourcompany.APGI-Explorer` (to be configured)
- **Platform**: macOS 12.0+ (with SwiftUI framework)
- **Architecture**: Universal (arm64 + x86_64)

### Core Purpose
APGI-Explorer implements a scientifically-validated psychological assessment system that:
- Administers a 35-question adaptive questionnaire
- Calculates four core psychological parameters (ε, π, θₜ, β)
- Determines one of 8 distinct cognitive profile types
- Provides interactive visualization and state exploration
- Generates comprehensive reports and insights

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
- **Window Management**: Multi-window support for macOS with state persistence

### Key Components
- **APGIScorer**: Advanced scoring algorithm with weighted questions and reliability checks
- **ProfileManager**: Manages user profiles, comparisons, and data persistence
- **StateModel**: Handles 43+ psychological states and transitions
- **ThemeManager**: Dynamic theming with light/dark/system modes
- **FileStorageManager**: Automated backup and export functionality

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
- **OnboardingView**: Interactive tutorial and APGI framework introduction
- **ScreenshotAutomation**: Automated screenshot generation for documentation

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

### Real-time Configuration
- All settings changes apply immediately without restart
- Individual setting reset or complete factory reset options
- Import/export settings for backup and sharing
- Persistent storage using @AppStorage and UserDefaults

---

## 🔧 7. Development & Build Configuration

### Build Requirements
- **Xcode**: 14.0+ for SwiftUI 3.0 features
- **macOS Target**: 12.0+ minimum deployment target
- **Swift Version**: 5.7+ for async/await and modern SwiftUI
- **Architecture**: Universal (arm64 + x86_64) for Apple Silicon and Intel Macs

### Project Structure
```
APGI-Explorer/
├── APGI_ExplorerApp.swift          # Main app entry point
├── MainTabView.swift               # Primary navigation
├── Model/                          # Core Data models
│   ├── ProfileEntity+CoreDataClass.swift
│   ├── ProfileEntity+Extensions.swift
│   └── QuizSession+CoreDataClass.swift
├── Views/                          # SwiftUI views
│   ├── ContentView.swift           # Home dashboard
│   ├── QuizView.swift              # Assessment interface
│   ├── ResultsView.swift           # Results display
│   ├── SettingsView.swift          # App configuration
│   └── PsychologicalStatesView.swift
├── Services/                       # Business logic
│   ├── APGIScorer.swift           # Scoring algorithm
│   ├── ProfileManager.swift        # Profile management
│   ├── StateModel.swift           # State management
│   └── FileStorageManager.swift   # Data persistence
└── Utilities/                      # Helper components
    ├── ThemeManager.swift          # Theming system
    ├── AnalyticsService.swift      # Usage analytics
    └── ScreenshotAutomation.swift # Documentation tool
```

### Debug Features
- **Screenshot Automation**: Automated screenshot generation for documentation
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
2. Include **Privacy Manifest** (`PrivacyInfo.xcprivacy`)
3. Declare data use in **App Store Connect > App Privacy**
4. Comply with **App Store Review Guidelines** for health/psychological apps

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

### Privacy Manifest Requirements
```xml
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyCollectedData</key>
<array>
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeEmailAddress</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
  </dict>
</array>
<key>NSPrivacyRequiredReasons</key>
<array>
  <string>CA92.1</string> <!-- Authentication -->
</array>
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
- [ ] Includes privacy manifest with accurate data declarations
- [ ] Complies with macOS Human Interface Guidelines

### Accessibility & UX
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

---

## 🚀 12. Future Enhancements

### Planned Features
- **iOS/iPadOS Companion**: Cross-platform assessment continuity
- **Cloud Sync**: Optional iCloud synchronization for multi-device support
- **Advanced Analytics**: Enhanced insights and trend analysis
- **Research Integration**: Export formats for academic research
- **Multi-language Support**: Localization for international users

### Technical Improvements
- **Machine Learning**: Enhanced pattern recognition in assessment data
- **Real-time Collaboration**: Multi-user assessment sessions
- **Advanced Visualizations**: 3D state space exploration
- **API Integration**: Third-party wellness app connectivity  
