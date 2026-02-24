import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

#if os(macOS)
    struct ShareSheet: NSViewRepresentable {
        var items: [Any]

        func makeNSView(context _: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                let sharingPicker = NSSharingServicePicker(items: items)
                sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
            }
            return view
        }

        func updateNSView(_: NSView, context _: Context) {
            // No updates needed
        }
    }
#else
    struct ShareSheet: UIViewControllerRepresentable {
        var items: [Any]

        func makeUIViewController(context _: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: self.items, applicationActivities: nil)
        }

        func updateUIViewController(_: UIActivityViewController, context _: Context) {
            // No updates needed
        }
    }
#endif
