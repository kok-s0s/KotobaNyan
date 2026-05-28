import SwiftUI

enum FavoriteFilter: String, CaseIterable {
    case all = "全部"
    case mastered = "已掌握"
    case unmastered = "未掌握"
}

struct FavoritesView: View {
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var filter: FavoriteFilter = .all
    @State private var selectedRomaji: String? = nil
    @State private var showCard = false

    private var displayItems: [VocabularyItem] {
        switch filter {
        case .all: return viewModel.favoriteItems
        case .mastered: return viewModel.favoriteItems.filter { $0.isMastered }
        case .unmastered: return viewModel.favoriteItems.filter { !$0.isMastered }
        }
    }

    private var selectedItem: VocabularyItem? {
        guard let r = selectedRomaji else { return nil }
        return viewModel.item(for: r)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("筛选", selection: $filter) {
                    ForEach(FavoriteFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                if displayItems.isEmpty {
                    emptyState
                } else {
                    List(displayItems) { item in
                        Button { selectedRomaji = item.romaji; showCard = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(item.displayWord).font(.headline)
                                        if item.isMastered {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green).font(.caption)
                                        }
                                    }
                                    Text(item.chinese).font(.subheadline).foregroundColor(.accentColor)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.scene).font(.caption).foregroundColor(.blue)
                                    if item.reviewCount > 0 {
                                        Text("复习\(item.reviewCount)次").font(.caption2).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("收藏 (\(viewModel.favoriteItems.count))")
            .sheet(isPresented: $showCard) {
                if let item = selectedItem {
                    NavigationView {
                        ScrollView {
                            VocabularyCardView(item: item, viewModel: viewModel)
                                .padding()
                        }
                        .navigationTitle(item.displayWord)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("关闭") { showCard = false }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: viewModel.favoriteItems.isEmpty ? "heart.slash" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text(viewModel.favoriteItems.isEmpty ? "还没有收藏的词汇" : "该分类下没有词汇")
                .font(.headline).foregroundColor(.secondary)
            if viewModel.favoriteItems.isEmpty {
                Text("在词卡中点击心形图标来收藏词汇")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            Spacer()
        }
    }
}
