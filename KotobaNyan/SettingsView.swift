import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
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
    @AppStorage("speechRate") private var speechRate: String = SpeechRate.normal.rawValue

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外观")) {
                    ForEach(AppTheme.allCases) { theme in
                        HStack {
                            Text(theme.displayName)
                            Spacer()
                            if appTheme == theme.rawValue {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { appTheme = theme.rawValue }
                    }
                }

                Section(header: Text("语速")) {
                    ForEach(SpeechRate.allCases, id: \.self) { rate in
                        HStack {
                            Text(rate.rawValue)
                            Spacer()
                            if speechRate == rate.rawValue {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { speechRate = rate.rawValue }
                    }
                }

                Section(header: Text("词库信息")) {
                    HStack {
                        Text("总词汇数")
                        Spacer()
                        Text("\(DatabaseManager.shared.fetchAll().count) 个")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
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
