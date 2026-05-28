import SwiftUI

struct JishoSearchView: View {
    @State private var searchText = ""
    @State private var results: [JishoWord] = []
    @State private var isLoading = false
    @State private var selectedWord: JishoWord? = nil
    @State private var errorMessage: String? = nil
    @State private var lastRequestTime: Date? = nil
    @State private var showSettings = false
    @State private var showAI = false
    let minRequestInterval: TimeInterval = 1.0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                errorLabel
                aiButton

                if let word = selectedWord ?? sortedResults.first {
                    wordDetailCard(word)
                }

                if sortedResults.count > 1 {
                    List(Array(sortedResults.dropFirst().enumerated()), id: \.element.id) { _, word in
                        Button { selectedWord = word } label: {
                            wordRow(word)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("在线查词")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showAI) { AIImageRecognitionView() }
        }
    }

    // MARK: - Components

    private var searchBar: some View {
        HStack {
            TextField("日语 / 假名 / 英文...", text: $searchText)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .submitLabel(.search)
                .onSubmit { searchJisho() }
            if isLoading {
                ProgressView().padding(.trailing, 8)
            } else {
                Button { searchJisho() } label: {
                    Image(systemName: "magnifyingglass").font(.title2).padding(8)
                }
            }
        }
        .padding([.horizontal, .top], 16)
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let msg = errorMessage {
            Text(msg).foregroundColor(.red).font(.footnote)
                .padding(.horizontal, 16).padding(.top, 2)
        }
    }

    private var aiButton: some View {
        Button { showAI = true } label: {
            HStack {
                Image(systemName: "camera.viewfinder")
                Text("AI 识图查词")
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func wordDetailCard(_ word: JishoWord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(word.japanese, id: \.reading) { jp in
                            HStack(spacing: 8) {
                                Text(jp.word ?? jp.reading ?? "-")
                                    .font(.title).bold()
                                if let reading = jp.reading, reading != jp.word {
                                    Text(reading).font(.title3).foregroundColor(.gray)
                                }
                                if let reading = jp.reading {
                                    Button { SpeechManager.shared.speak(text: reading) } label: {
                                        Image(systemName: "speaker.wave.2.fill").foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if word.is_common == true {
                            Label("常用", systemImage: "star.fill").font(.caption).foregroundColor(.green)
                        }
                        if let jlpt = word.jlpt {
                            ForEach(jlpt, id: \.self) { tag in
                                Text(tag.uppercased()).font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15)).cornerRadius(6)
                            }
                        }
                    }
                }
                Divider()
                ForEach(word.senses.indices, id: \.self) { idx in
                    let sense = word.senses[idx]
                    VStack(alignment: .leading, spacing: 2) {
                        Text("释义：\(sense.english_definitions.joined(separator: ", "))").font(.body)
                        if !sense.parts_of_speech.isEmpty {
                            Text("词性：\(sense.parts_of_speech.joined(separator: ", "))")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                        if let info = sense.info, !info.isEmpty {
                            Text("备注：\(info.joined(separator: ", "))")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    if idx < word.senses.count - 1 { Divider() }
                }
                Button("收起") { selectedWord = nil }
                    .font(.subheadline).padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
        .frame(maxHeight: 300)
    }

    @ViewBuilder
    private func wordRow(_ word: JishoWord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(word.japanese.first?.word ?? word.japanese.first?.reading ?? "-").font(.headline)
                if let reading = word.japanese.first?.reading, reading != word.japanese.first?.word {
                    Text(reading).font(.subheadline).foregroundColor(.gray)
                }
                if word.is_common == true { Text("常用").font(.caption2).foregroundColor(.green) }
                if let jlpt = word.jlpt?.first { Text(jlpt.uppercased()).font(.caption2).foregroundColor(.blue) }
            }
            if let sense = word.senses.first {
                Text(sense.english_definitions.joined(separator: ", "))
                    .font(.subheadline).foregroundColor(.accentColor)
            }
        }
    }

    // MARK: - Logic

    private var sortedResults: [JishoWord] {
        let kw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kw.isEmpty else { return results }
        let exact = results.filter { $0.japanese.contains { $0.word == kw || $0.reading == kw } }
        let rest = results.filter { !$0.japanese.contains { $0.word == kw || $0.reading == kw } }
        return exact + rest
    }

    private func searchJisho() {
        guard !isLoading else { return }
        let now = Date()
        if let last = lastRequestTime, now.timeIntervalSince(last) < minRequestInterval {
            errorMessage = "操作过于频繁，请稍后再试。"
            return
        }
        let kw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kw.isEmpty else { results = []; errorMessage = nil; return }
        isLoading = true
        errorMessage = nil
        lastRequestTime = now
        JishoAPIManager.shared.search(keyword: kw) { words, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.results = []
                    self.errorMessage = error.errorDescription
                } else {
                    self.results = words
                    self.errorMessage = words.isEmpty ? "未找到相关词条。" : nil
                }
            }
        }
    }
}

#Preview {
    JishoSearchView()
}
