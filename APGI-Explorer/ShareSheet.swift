import SwiftUI

struct ShareSheet: View {
    var items: [Any]
    
    var body: some View {
        if let url = items.first as? URL {
            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .presentationDetents([.medium, .large])
        } else if let string = items.first as? String {
            ShareLink(item: string) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .presentationDetents([.medium, .large])
        } else {
            Text("Sharing not available for this item")
        }
    }
}
