import SwiftUI

@main
struct APGI_SignatureApp: App {
    @StateObject private var dependencies = AppDependencies.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAppDependencies(dependencies)
        }
    }
}
