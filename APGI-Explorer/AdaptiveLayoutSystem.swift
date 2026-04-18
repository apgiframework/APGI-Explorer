import Combine
import SwiftUI

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

// MARK: - iOS/iPadOS Adaptive Layout System

/// Provides adaptive layouts and touch-optimized interactions for iOS/iPadOS
enum AdaptiveLayoutSystem {
  // MARK: - Device Detection

  static var isiPad: Bool {
    #if os(iOS)
      return UIDevice.current.userInterfaceIdiom == .pad
    #else
      return false
    #endif
  }

  static var isiPhone: Bool {
    #if os(iOS)
      return UIDevice.current.userInterfaceIdiom == .phone
    #else
      return false
    #endif
  }

  static var deviceType: DeviceType {
    #if os(iOS)
      switch UIDevice.current.userInterfaceIdiom {
      case .pad:
        return .iPad
      case .phone:
        return .iPhone
      default:
        return .unknown
      }
    #else
      return .mac
    #endif
  }

  enum DeviceType {
    case iPad
    case iPhone
    case mac
    case unknown

    var name: String {
      switch self {
      case .iPad: "iPad"
      case .iPhone: "iPhone"
      case .mac: "Mac"
      case .unknown: "Unknown"
      }
    }

    var recommendedColumns: Int {
      switch self {
      case .iPad: 3
      case .iPhone: 1
      case .mac: 4
      case .unknown: 1
      }
    }

    var recommendedItemHeight: CGFloat {
      switch self {
      case .iPad: 200
      case .iPhone: 120
      case .mac: 180
      case .unknown: 120
      }
    }
  }

  // MARK: - Screen Size Detection

  static var screenSize: CGSize {
    #if os(iOS)
      return UIScreen.main.bounds.size
    #else
      return NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
    #endif
  }

  static var isLandscape: Bool {
    screenSize.width > screenSize.height
  }

  static var isCompactWidth: Bool {
    screenSize.width < 400
  }

  static var isRegularWidth: Bool {
    screenSize.width >= 400
  }

  // MARK: - Layout Calculations

  static func columnsForHorizontalSizeClass(_ sizeClass: UserInterfaceSizeClass?) -> Int {
    switch (self.deviceType, sizeClass) {
    case (.iPad, .regular):
      self.isLandscape ? 4 : 3
    case (.iPad, .compact):
      2
    case (.iPhone, .regular):
      2
    case (.iPhone, .compact):
      1
    default:
      1
    }
  }

  static func spacingForDevice() -> CGFloat {
    switch self.deviceType {
    case .iPad:
      20
    case .iPhone:
      12
    case .mac:
      16
    case .unknown:
      12
    }
  }

  static func paddingForDevice() -> EdgeInsets {
    switch self.deviceType {
    case .iPad:
      EdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32)
    case .iPhone:
      EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    case .mac:
      EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
    case .unknown:
      EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    }
  }

  // MARK: - Touch Interaction Optimization

  static var minimumTouchTargetSize: CGFloat {
    switch deviceType {
    case .iPad:
      60  // Larger touch targets for iPad
    case .iPhone:
      44  // Standard iOS touch target
    case .mac:
      32  // Smaller targets for mouse interaction
    case .unknown:
      44
    }
  }

  static var buttonHeight: CGFloat {
    switch deviceType {
    case .iPad:
      56
    case .iPhone:
      48
    case .mac:
      40
    case .unknown:
      48
    }
  }

  static var iconSize: CGFloat {
    switch deviceType {
    case .iPad:
      32
    case .iPhone:
      24
    case .mac:
      20
    case .unknown:
      24
    }
  }
}

// MARK: - Adaptive Grid Layout

struct AdaptiveGrid<Content: View, Item: Identifiable>: View {
  let items: [Item]
  let content: (Item) -> Content
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  private var columns: [GridItem] {
    let columnCount = AdaptiveLayoutSystem.columnsForHorizontalSizeClass(self.horizontalSizeClass)
    return Array(
      repeating: GridItem(.flexible(), spacing: AdaptiveLayoutSystem.spacingForDevice()),
      count: columnCount)
  }

  var body: some View {
    LazyVGrid(columns: self.columns, spacing: AdaptiveLayoutSystem.spacingForDevice()) {
      ForEach(self.items) { item in
        self.content(item)
          .frame(minHeight: AdaptiveLayoutSystem.deviceType.recommendedItemHeight)
      }
    }
    .padding(AdaptiveLayoutSystem.paddingForDevice())
  }
}

// MARK: - Adaptive Stack Layout

struct AdaptiveStack<Content: View>: View {
  @ViewBuilder let content: Content
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    if AdaptiveLayoutSystem.isRegularWidth, self.horizontalSizeClass == .regular {
      HStack(spacing: AdaptiveLayoutSystem.spacingForDevice()) {
        self.content
      }
    } else {
      VStack(spacing: AdaptiveLayoutSystem.spacingForDevice()) {
        self.content
      }
    }
  }
}

// MARK: - Touch-Optimized Button

struct TouchOptimizedButton<Label: View>: View {
  let action: () -> Void
  @ViewBuilder let label: Label

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    Button(action: self.action) {
      self.label
        .frame(minHeight: AdaptiveLayoutSystem.minimumTouchTargetSize)
        .frame(maxWidth: self.horizontalSizeClass == .regular ? .infinity : nil)
    }
    .buttonStyle(TouchOptimizedButtonStyle())
  }
}

struct TouchOptimizedButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, LayoutConstants.buttonPadding)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius)
          .fill(
            configuration.isPressed
              ? AppColors.buttonBackground.opacity(0.8) : AppColors.buttonBackground)
      )
      .foregroundColor(AppColors.buttonText)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

// MARK: - Adaptive Card View

struct AdaptiveCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(LayoutConstants.mediumSpacing)
      .background(
        RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius * 2)
          .fill(PlatformColor.adaptiveBackground)
          .shadow(
            color: .black.opacity(ColorConstants.shadowOpacity),
            radius: LayoutConstants.buttonShadowRadius * 2, x: 0, y: 4)
      )
  }
}

// MARK: - Adaptive Navigation View

struct AdaptiveNavigationView<Content: View>: View {
  @ViewBuilder let content: Content
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    if AdaptiveLayoutSystem.isiPad, self.horizontalSizeClass == .regular {
      NavigationSplitView {
        // Sidebar for iPad
        SidebarView()
      } detail: {
        self.content
      }
    } else {
      NavigationView {
        self.content
      }
      #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
      #endif
    }
  }
}

// MARK: - Sidebar View for iPad

struct SidebarView: View {
  var body: some View {
    List {
      NavigationLink("Profiles", destination: ProfileListView())
      NavigationLink("Quiz", destination: AdaptiveQuizView())
      NavigationLink("Analytics", destination: AnalyticsView())
      NavigationLink("Settings", destination: AdaptiveSettingsView())
    }
    .navigationTitle("APGI Explorer")
    .listStyle(SidebarListStyle())
  }
}

// MARK: - Gesture Handling

struct TouchOptimizedGesture<Content: View>: View {
  let content: Content
  let onTap: () -> Void
  let onLongPress: (() -> Void)?

  @State private var isPressed = false

  init(
    content: Content,
    onTap: @escaping () -> Void,
    onLongPress: (() -> Void)? = nil
  ) {
    self.content = content
    self.onTap = onTap
    self.onLongPress = onLongPress
  }

  var body: some View {
    self.content
      .scaleEffect(self.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: self.isPressed)
      .onTapGesture {
        self.onTap()
        // Provide haptic feedback on iOS
        #if os(iOS)
          let impact = UIImpactFeedbackGenerator(style: .light)
          impact.impactOccurred()
        #endif
      }
      .onLongPressGesture(
        minimumDuration: 0.5,
        maximumDistance: 10,
        pressing: { pressing in
          self.isPressed = pressing
        },
        perform: {
          self.onLongPress?()
          #if os(iOS)
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
          #endif
        }
      )
  }
}

// MARK: - Adaptive Sheet Presentation

struct AdaptiveSheet<SheetContent: View>: ViewModifier {
  let content: SheetContent
  let isPresented: Binding<Bool>

  func body(content: Content) -> some View {
    if AdaptiveLayoutSystem.isiPad {
      content
        .sheet(isPresented: self.isPresented) {
          self.content
            .frame(minWidth: 400, minHeight: 300)
            .padding()
        }
    } else {
      content
        .sheet(isPresented: self.isPresented) {
          NavigationView {
            self.content
              #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                  ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                      self.isPresented.wrappedValue = false
                    }
                  }
                }
              #endif
          }
        }
    }
  }
}

// MARK: - View Extensions

extension View {
  func adaptiveSheet(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> some View
  ) -> some View {
    modifier(AdaptiveSheet(content: content(), isPresented: isPresented))
  }

  func touchOptimized(
    onTap: @escaping () -> Void,
    onLongPress: (() -> Void)? = nil
  ) -> some View {
    TouchOptimizedGesture(content: self, onTap: onTap, onLongPress: onLongPress)
  }

  func adaptiveCard() -> some View {
    modifier(AdaptiveCard())
  }

  func adaptivePadding() -> some View {
    padding(AdaptiveLayoutSystem.paddingForDevice())
  }

  func adaptiveSpacing() -> some View {
    padding(AdaptiveLayoutSystem.spacingForDevice())
  }
}

// MARK: - Placeholder Views

struct ProfileListView: View {
  var body: some View {
    Text("Profile List")
      .navigationTitle("Profiles")
  }
}

struct AdaptiveQuizView: View {
  var body: some View {
    Text("Quiz")
      .navigationTitle("Quiz")
  }
}

struct AnalyticsView: View {
  var body: some View {
    Text("Analytics")
      .navigationTitle("Analytics")
  }
}

struct AdaptiveSettingsView: View {
  var body: some View {
    Text("Settings")
      .navigationTitle("Settings")
  }
}
