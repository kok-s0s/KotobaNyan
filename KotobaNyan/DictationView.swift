import SwiftUI

struct DictationView: View {
    @ObservedObject var viewModel: VocabularyViewModel
    @ObservedObject private var speech = SpeechManager.shared
    @State private var currentItem: VocabularyItem? = nil
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            speakerCard
            revealArea

            Spacer()

            controlButtons
        }
        .navigationTitle("听写")
        .onAppear { nextWord() }
    }

    private var speakerCard: some View {
        Button { playAudio() } label: {
            VStack(spacing: 14) {
                Image(systemName: speech.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, isActive: speech.isSpeaking)
                Text(speech.isSpeaking ? "播放中..." : "点击播放")
                    .font(.headline).foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(36)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color(.systemGray6)))
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var revealArea: some View {
        if isRevealed, let item = currentItem {
            VStack(spacing: 10) {
                Text(item.displayWord).font(.system(size: 40, weight: .bold))
                if !item.kanji.isEmpty && !item.kana.isEmpty {
                    Text(item.kana).font(.title3).foregroundColor(.gray)
                }
                Text(item.romaji).font(.subheadline).foregroundColor(.gray)
                Divider()
                Text(item.chinese).font(.title3).foregroundColor(.accentColor)
                if !item.english.isEmpty {
                    Text(item.english).font(.subheadline).foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            Button {
                withAnimation(.spring(response: 0.3)) { isRevealed = true }
            } label: {
                Text("揭示词汇")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button { playAudio() } label: {
                Label("重播", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
            Button { nextWord() } label: {
                Label("下一个", systemImage: "forward.fill")
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(12)
            }
        }
        .padding(.bottom)
    }

    private func playAudio() {
        guard let item = currentItem else { return }
        let text = !item.kana.isEmpty ? item.kana : item.displayWord
        SpeechManager.shared.speak(text: text)
    }

    private func nextWord() {
        SpeechManager.shared.stop()
        withAnimation { isRevealed = false }
        guard !viewModel.items.isEmpty else { return }
        currentItem = viewModel.items.randomElement()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playAudio() }
    }
}
