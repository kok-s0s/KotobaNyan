import SwiftUI

struct SceneWordsView: View {
    let scene: String
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var selectedRomaji: String? = nil

    private var selectedItem: VocabularyItem? {
        guard let r = selectedRomaji else { return nil }
        return viewModel.item(for: r)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            List(viewModel.filteredSceneItems(scene: scene)) { item in
                Button { selectedRomaji = item.romaji } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(item.displayWord).font(.headline)
                                if item.isFavorited {
                                    Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                                }
                                if item.isMastered {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
                                }
                            }
                            Text(item.chinese).font(.subheadline).foregroundColor(.accentColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(item.romaji).font(.caption).foregroundColor(.gray)
                            if item.reviewCount > 0 {
                                Image(systemName: "arrow.clockwise").font(.caption2).foregroundColor(.blue)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedRomaji == item.romaji ? Color.accentColor.opacity(0.08) : Color(.systemBackground))
            }
            .listStyle(.plain)

            if let item = selectedItem {
                VStack(spacing: 0) {
                    Divider()
                    ScrollView {
                        VocabularyCardView(item: item, viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    .frame(maxHeight: 380)
                    Button("收起") { selectedRomaji = nil }
                        .padding(.bottom, 12)
                }
                .background(Color(.systemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(scene)
        .animation(.spring(response: 0.3), value: selectedRomaji)
    }
}
