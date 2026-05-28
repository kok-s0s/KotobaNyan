import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VocabularyViewModel()
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue

    var body: some View {
        TabView {
            BrowseView(viewModel: viewModel)
                .tabItem { Label("词库", systemImage: "books.vertical") }

            JishoSearchView()
                .tabItem { Label("查词", systemImage: "magnifyingglass") }

            PracticeView(viewModel: viewModel)
                .tabItem { Label("练习", systemImage: "pencil.and.outline") }

            FavoritesView(viewModel: viewModel)
                .tabItem { Label("收藏", systemImage: "heart") }
        }
        .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
    }
}

#Preview {
    ContentView()
}
