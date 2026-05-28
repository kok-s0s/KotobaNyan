import SwiftUI

struct ReviewView: View {
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var reviewItems: [VocabularyItem] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var isFinished = false

    var body: some View {
        Group {
            if reviewItems.isEmpty {
                emptyView
            } else if isFinished || currentIndex >= reviewItems.count {
                finishedView
            } else {
                cardView(item: reviewItems[currentIndex])
            }
        }
        .navigationTitle("间隔复习")
        .onAppear {
            reviewItems = viewModel.dueItems.shuffled()
            currentIndex = 0
            isRevealed = false
            isFinished = false
        }
    }

    // MARK: - Sub-views

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            Text("今日无需复习").font(.title2).bold()
            Text("在词卡中点击「加入复习」来添加词汇")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 72))
                .foregroundColor(.orange)
            Text("今日复习完成！").font(.title2).bold()
            Text("共复习了 \(reviewItems.count) 个词汇")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func cardView(item: VocabularyItem) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("\(currentIndex + 1) / \(reviewItems.count)")
                        .font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
                ProgressView(value: Double(currentIndex + 1), total: Double(reviewItems.count))
                    .tint(.accentColor)
            }
            .padding(.horizontal).padding(.top)

            Spacer()

            // Flash card
            VStack(spacing: 16) {
                Button {
                    let text = !item.kana.isEmpty ? item.kana : item.displayWord
                    SpeechManager.shared.speak(text: text)
                } label: {
                    VStack(spacing: 6) {
                        Text(item.displayWord).font(.system(size: 52, weight: .bold))
                        if !item.kanji.isEmpty && !item.kana.isEmpty {
                            Text(item.kana).font(.title3).foregroundColor(.gray)
                        }
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.accentColor).font(.title2)
                    }
                }
                .buttonStyle(.plain)

                if isRevealed {
                    Divider().padding(.horizontal)
                    VStack(spacing: 8) {
                        Text(item.chinese).font(.title2).foregroundColor(.accentColor)
                        if !item.english.isEmpty {
                            Text(item.english).font(.headline).foregroundColor(.secondary)
                        }
                        if !item.example.isEmpty {
                            Text(item.example).font(.subheadline).foregroundColor(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray3), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)
            .animation(.spring(response: 0.3), value: isRevealed)

            Spacer()

            // Action area
            if !isRevealed {
                Button("揭示答案") { withAnimation { isRevealed = true } }
                    .buttonStyle(.borderedProminent)
                    .padding()
            } else {
                VStack(spacing: 10) {
                    Text("记忆效果如何？").font(.subheadline).foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        ratingButton("不记得", color: .red, quality: 0)
                        ratingButton("困难", color: .orange, quality: 1)
                        ratingButton("记得", color: .blue, quality: 2)
                        ratingButton("轻松", color: .green, quality: 3)
                    }
                }
                .padding()
            }
        }
    }

    private func ratingButton(_ title: String, color: Color, quality: Int) -> some View {
        Button {
            viewModel.submitReview(reviewItems[currentIndex], quality: quality)
            isRevealed = false
            if currentIndex + 1 >= reviewItems.count {
                isFinished = true
            } else {
                currentIndex += 1
            }
        } label: {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(12)
        }
    }
}
