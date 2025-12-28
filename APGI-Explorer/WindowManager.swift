// WindowManager.swift

#if os(macOS)
import AppKit
import SwiftUI
import Combine

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var activeWindows: [WindowType: NSWindow] = [:]
    
    private init() {}
    
    // MARK: - Window Types
    
    enum WindowType: String, CaseIterable {
        case main = "main"
        case stateExplorer = "state-explorer"
        case profileComparison = "profile-comparison"
        case settings = "settings"
        case about = "about"
        case quiz = "quiz"
        case reports = "reports"
        
        var title: String {
            switch self {
            case .main: return "APGI Explorer"
            case .stateExplorer: return "State Explorer"
            case .profileComparison: return "Profile Comparison"
            case .settings: return "Settings"
            case .about: return "About"
            case .quiz: return "Assessment Quiz"
            case .reports: return "Reports"
            }
        }
        
        var defaultSize: CGSize {
            switch self {
            case .main: return CGSize(width: 1000, height: 700)
            case .stateExplorer: return CGSize(width: 1200, height: 800)
            case .profileComparison: return CGSize(width: 1400, height: 900)
            case .settings: return CGSize(width: 600, height: 500)
            case .about: return CGSize(width: 500, height: 400)
            case .quiz: return CGSize(width: 900, height: 700)
            case .reports: return CGSize(width: 1000, height: 800)
            }
        }
    }
    
    // MARK: - Window Creation
    
    func openWindow<Content: View>(
        type: WindowType,
        @ViewBuilder content: () -> Content
    ) {
        // Check if window already exists
        if let existingWindow = activeWindows[type] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: type.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = type.title
        window.center()
        window.setFrameAutosaveName(type.rawValue)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content())
        window.makeKeyAndOrderFront(nil)
        
        // Store reference
        activeWindows[type] = window
        
        // Set up window delegate
        let delegate = WindowDelegate { [weak self] in
            self?.activeWindows.removeValue(forKey: type)
        }
        window.delegate = delegate
        objc_setAssociatedObject(window, &associatedDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeWindow(type: WindowType) {
        activeWindows[type]?.close()
        activeWindows.removeValue(forKey: type)
    }
    
    func closeAllWindows() {
        activeWindows.values.forEach { $0.close() }
        activeWindows.removeAll()
    }
    
    // MARK: - Window Arrangement
    
    func arrangeWindows(_ arrangement: WindowArrangement) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        switch arrangement {
        case .cascade:
            arrangeCascade(in: screenFrame)
        case .tile:
            arrangeTile(in: screenFrame)
        case .sideBySide:
            arrangeSideBySide(in: screenFrame)
        }
    }
    
    func arrangeWindowsWithUserPreference() {
        let preference = UserDefaultsManager.shared.windowArrangementPreference
        arrangeWindows(preference)
    }
    
    private func arrangeCascade(in frame: CGRect) {
        var offset: CGFloat = 0
        for window in activeWindows.values {
            let size = window.frame.size
            let origin = CGPoint(
                x: frame.origin.x + offset,
                y: frame.origin.y + frame.height - size.height - offset
            )
            window.setFrame(CGRect(origin: origin, size: size), display: true, animate: true)
            offset += 30
        }
    }
    
    private func arrangeTile(in frame: CGRect) {
        let windows = Array(activeWindows.values)
        let count = windows.count
        
        guard count > 0 else { return }
        
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))
        
        let tileWidth = frame.width / CGFloat(cols)
        let tileHeight = frame.height / CGFloat(rows)
        
        for (index, window) in windows.enumerated() {
            let col = index % cols
            let row = index / cols
            
            let origin = CGPoint(
                x: frame.origin.x + CGFloat(col) * tileWidth,
                y: frame.origin.y + frame.height - CGFloat(row + 1) * tileHeight
            )
            let size = CGSize(width: tileWidth, height: tileHeight)
            
            window.setFrame(CGRect(origin: origin, size: size), display: true, animate: true)
        }
    }
    
    private func arrangeSideBySide(in frame: CGRect) {
        let windows = Array(activeWindows.values)
        guard windows.count >= 2 else { return }
        
        let halfWidth = frame.width / 2
        
        windows[0].setFrame(
            CGRect(x: frame.origin.x, y: frame.origin.y, width: halfWidth, height: frame.height),
            display: true,
            animate: true
        )
        
        windows[1].setFrame(
            CGRect(x: frame.origin.x + halfWidth, y: frame.origin.y, width: halfWidth, height: frame.height),
            display: true,
            animate: true
        )
    }
    
    // MARK: - Fullscreen
    
    func toggleFullscreen(type: WindowType) {
        guard let window = activeWindows[type] else { return }
        window.toggleFullScreen(nil)
    }
}

// WindowArrangement is defined in UserDefaultsManager.swift

// MARK: - Window Delegate

private var associatedDelegateKey: UInt8 = 0

class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// MARK: - SwiftUI Integration

struct WindowAccessor: ViewModifier {
    let windowType: WindowManager.WindowType
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Window setup if needed
            }
    }
}

extension View {
    func windowType(_ type: WindowManager.WindowType) -> some View {
        modifier(WindowAccessor(windowType: type))
    }
}

#endif