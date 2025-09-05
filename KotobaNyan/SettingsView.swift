import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "跟随系统 (Auto)"
        case .light: return "浅色模式 (Light mode)"
        case .dark: return "深色模式 (Dark mode)"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("主题设置")) {
                    ForEach(AppTheme.allCases) { theme in
                        HStack {
                            Text(theme.displayName)
                            Spacer()
                            if appTheme == theme.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appTheme = theme.rawValue
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
