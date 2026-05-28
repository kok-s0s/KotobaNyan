import SwiftUI

@main
struct KotobaNyanApp: App {
    init() {
        DatabaseManager.shared.importCSVIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
