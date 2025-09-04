import SwiftUI
import Foundation

struct SceneWordsView: View {
    let scene: String
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var selectedItem: VocabularyItem? = nil
    var body: some View {
        VStack {
            List(viewModel.filteredSceneItems(scene: scene)) { item in
                Button(action: {
                    selectedItem = item
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.kanji.isEmpty ? item.kana : item.kanji)
                                .font(.headline)
                            Text(item.chinese)
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                        Text(item.romaji)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(.plain)
            if let item = selectedItem {
                VStack {
                    VocabularyCardView(item: item)
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 8)
                    Button("收起词卡") {
                        selectedItem = nil
                    }
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle(scene)
    }
}
