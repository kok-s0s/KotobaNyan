//
//  KotobaNyanApp.swift
//  KotobaNyan
//
//  Created by kok-s0s on 2025/9/2.
//

import SwiftUI

@main
struct KotobaNyanApp: App {
    init() {
        DatabaseManager.shared.importCSVIfNeeded()
    }
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    var body: some Scene {
        WindowGroup {
            JishoSearchView()
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
    }
}
