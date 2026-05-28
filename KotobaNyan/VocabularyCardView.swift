import SwiftUI

struct VocabularyCardView: View {
    let item: VocabularyItem
    @ObservedObject var viewModel: VocabularyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        let text = !item.kana.isEmpty ? item.kana : item.displayWord
                        SpeechManager.shared.speak(text: text)
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.displayWord)
                                .font(.title)
                                .bold()
                                .foregroundColor(.primary)
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                        }
                    }
                    .buttonStyle(.plain)

                    if !item.kanji.isEmpty && !item.kana.isEmpty {
                        Text(item.kana)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Text(item.romaji)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if item.reviewCount > 0 {
                        Label("复习\(item.reviewCount)次", systemImage: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    Text(item.scene)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Text(item.chinese)
                .font(.headline)
                .foregroundColor(.accentColor)
            if !item.english.isEmpty {
                Text(item.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            if !item.example.isEmpty {
                Text("例句：\(item.example)")
                    .font(.body)
            }
            if !item.cn_meaning.isEmpty {
                Text("中文释义：\(item.cn_meaning)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if !item.jp_meaning.isEmpty {
                Text("日文释义：\(item.jp_meaning)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Action buttons
            HStack(spacing: 0) {
                actionButton(
                    title: item.isFavorited ? "已收藏" : "收藏",
                    icon: item.isFavorited ? "heart.fill" : "heart",
                    color: item.isFavorited ? .red : .secondary
                ) {
                    viewModel.toggleFavorite(item)
                }

                Spacer()

                actionButton(
                    title: item.isMastered ? "已掌握" : "标记掌握",
                    icon: item.isMastered ? "checkmark.circle.fill" : "checkmark.circle",
                    color: item.isMastered ? .green : .secondary
                ) {
                    viewModel.toggleMastered(item)
                }

                Spacer()

                if item.reviewCount == 0 {
                    actionButton(
                        title: "加入复习",
                        icon: "plus.circle",
                        color: .blue
                    ) {
                        viewModel.addToReview(item)
                    }
                } else {
                    Label("复习中", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
        )
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.footnote)
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}
