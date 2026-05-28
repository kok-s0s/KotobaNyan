import SwiftUI

enum QuizMode: String, CaseIterable {
    case jpToCn = "日 → 中"
    case cnToJp = "中 → 日"
}

struct QuizView: View {
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var mode: QuizMode = .jpToCn
    @State private var question: VocabularyItem? = nil
    @State private var options: [String] = []
    @State private var selectedAnswer: String? = nil
    @State private var score = 0
    @State private var total = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("模式", selection: $mode) {
                ForEach(QuizMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: mode) { _ in resetAndNext() }

            HStack {
                Text("得分：\(score) / \(total)")
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                if total > 0 {
                    let pct = Int(Double(score) / Double(total) * 100)
                    Text("\(pct)%").font(.subheadline)
                        .foregroundColor(pct >= 70 ? .green : .orange)
                }
            }
            .padding(.horizontal)

            Spacer()

            if let q = question {
                questionCard(q)
                Spacer()
                optionsGrid(q)
            } else {
                Text("词汇量不足（至少需要 4 个词汇）")
                    .foregroundColor(.secondary)
            }

            Spacer()

            if selectedAnswer != nil {
                Button("下一题") { nextQuestion() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .navigationTitle("测验")
        .onAppear { nextQuestion() }
    }

    // MARK: - Sub-views

    private func questionCard(_ q: VocabularyItem) -> some View {
        VStack(spacing: 10) {
            if mode == .jpToCn {
                Button {
                    let text = !q.kana.isEmpty ? q.kana : q.displayWord
                    SpeechManager.shared.speak(text: text)
                } label: {
                    VStack(spacing: 6) {
                        Text(q.displayWord).font(.system(size: 44, weight: .bold))
                        if !q.kanji.isEmpty && !q.kana.isEmpty {
                            Text(q.kana).font(.title3).foregroundColor(.gray)
                        }
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.accentColor).font(.title2)
                    }
                }
                .buttonStyle(.plain)
                Text("这个词的中文意思是？")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                Text(q.chinese).font(.system(size: 36, weight: .bold)).foregroundColor(.accentColor)
                Text("对应的日文是？").font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
        .padding(.horizontal)
    }

    private func optionsGrid(_ q: VocabularyItem) -> some View {
        let correct = mode == .jpToCn ? q.chinese : q.displayWord
        return VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                optionButton(option: option, correct: correct)
            }
        }
        .padding(.horizontal)
    }

    private func optionButton(option: String, correct: String) -> some View {
        let isAnswered = selectedAnswer != nil
        let isSelected = selectedAnswer == option
        let isCorrect = option == correct

        let bgColor: Color = {
            guard isAnswered else { return Color(.systemGray6) }
            if isCorrect { return .green.opacity(0.2) }
            if isSelected { return .red.opacity(0.2) }
            return Color(.systemGray6)
        }()

        return Button {
            guard selectedAnswer == nil else { return }
            selectedAnswer = option
            total += 1
            if option == correct { score += 1 }
        } label: {
            HStack {
                Text(option).font(.body).foregroundColor(.primary)
                Spacer()
                if isAnswered && (isSelected || isCorrect) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(bgColor)
            .cornerRadius(14)
        }
        .disabled(isAnswered)
    }

    // MARK: - Logic

    private func nextQuestion() {
        guard viewModel.items.count >= 4 else { return }
        selectedAnswer = nil
        question = viewModel.items.randomElement()
        guard let q = question else { return }

        let wrongs = Array(viewModel.items.filter { $0.romaji != q.romaji }.shuffled().prefix(3))
        let correct = mode == .jpToCn ? q.chinese : q.displayWord
        var opts = wrongs.map { mode == .jpToCn ? $0.chinese : $0.displayWord }
        opts.append(correct)
        options = opts.shuffled()
    }

    private func resetAndNext() {
        score = 0; total = 0
        nextQuestion()
    }
}
