import SwiftUI

struct BrowseView: View {
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var searchText = ""
    @State private var selectedRomaji: String? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var showSettings = false
    let gridColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var selectedItem: VocabularyItem? {
        guard let r = selectedRomaji else { return nil }
        return viewModel.item(for: r)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResults
                } else {
                    categoryGrid
                }
            }
            .navigationTitle("词库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var searchBar: some View {
        TextField("搜索词汇（假名/汉字/拼音/中文）...", text: $searchText)
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .padding([.horizontal, .top], 16)
            .focused($isSearchFocused)
            .submitLabel(.done)
            .onChange(of: searchText) { newValue in
                viewModel.search(prefix: newValue)
                selectedRomaji = nil
            }
            .onSubmit { isSearchFocused = false }
    }

    private var searchResults: some View {
        VStack(spacing: 0) {
            List(viewModel.filteredItems) { item in
                Button {
                    selectedRomaji = item.romaji
                    isSearchFocused = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayWord).font(.headline)
                            Text(item.chinese).font(.subheadline).foregroundColor(.accentColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if item.isFavorited {
                                Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                            }
                            Text(item.scene).font(.caption).foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(maxHeight: 320)

            if let item = selectedItem {
                VStack(spacing: 0) {
                    ScrollView {
                        VocabularyCardView(item: item, viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    .frame(maxHeight: 380)
                    Button("收起词卡") { selectedRomaji = nil }
                        .padding(.bottom, 12)
                }
                .background(Color(.systemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .animation(.spring(response: 0.3), value: selectedRomaji)
    }

    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 14) {
                ForEach(viewModel.scenes, id: \.self) { scene in
                    NavigationLink(destination: SceneWordsView(scene: scene, viewModel: viewModel)) {
                        SceneCategoryCard(
                            scene: scene,
                            count: viewModel.filteredSceneItems(scene: scene).count
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
    }
}

struct SceneCategoryCard: View {
    let scene: String
    let count: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.accentColor.opacity(0.15))
            .frame(height: 110)
            .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            .overlay(
                VStack(spacing: 6) {
                    Text(scene)
                        .font(.title3).bold()
                        .foregroundColor(.accentColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    Text("\(count) 词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}
