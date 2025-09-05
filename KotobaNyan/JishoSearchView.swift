import SwiftUI

struct JishoSearchView: View {
    @State private var searchText: String = ""
    @State private var results: [JishoWord] = []
    @State private var isLoading = false
    @State private var selectedWord: JishoWord? = nil
    @State private var showLocal = false
    @State private var errorMessage: String? = nil
    @State private var lastRequestTime: Date? = nil
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @State private var showSettings = false
    let minRequestInterval: TimeInterval = 1.0 // 1秒冷却

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    TextField("输入日语/英文/假名...", text: $searchText)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .submitLabel(.search)
                        .onSubmit {
                            searchJisho()
                        }
                    Button(action: { searchJisho() }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding(8)
                    }
                    if isLoading {
                        ProgressView().padding(.trailing, 8)
                    }
                }
                .padding([.horizontal, .top], 16)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                        .transition(.opacity)
                }
                Button(action: { showLocal = true }) {
                    HStack {
                        Image(systemName: "books.vertical")
                        Text("本地词库/分类词汇")
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                if let word = selectedWord ?? sortedResults.first {
                    // 详细卡片
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    ForEach(word.japanese, id: \.reading) { jp in
                                        HStack {
                                            Text(jp.word ?? jp.reading ?? "-")
                                                .font(.title)
                                                .bold()
                                            if let reading = jp.reading, reading != jp.word {
                                                Text(reading)
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                            }
                                            if let reading = jp.reading {
                                                Button(action: { SpeechManager.shared.speak(text: reading) }) {
                                                    Image(systemName: "speaker.wave.2.fill")
                                                }
                                            }
                                        }
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    if word.is_common == true {
                                        Label("常用词", systemImage: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    if let jlpt = word.jlpt {
                                        ForEach(jlpt, id: \.self) { tag in
                                            Text(tag.uppercased())
                                                .font(.caption2)
                                                .padding(4)
                                                .background(Color.blue.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                    }
                                    if let tags = word.tags {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption2)
                                                .padding(4)
                                                .background(Color.orange.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                            Divider()
                            ForEach(word.senses.indices, id: \.self) { idx in
                                let sense = word.senses[idx]
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("释义：" + sense.english_definitions.joined(separator: ", "))
                                        .font(.body)
                                    if !sense.parts_of_speech.isEmpty {
                                        Text("词性：" + sense.parts_of_speech.joined(separator: ", "))
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    if let info = sense.info, !info.isEmpty {
                                        Text("补充：" + info.joined(separator: ", "))
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    if let links = sense.links, !links.isEmpty {
                                        ForEach(links, id: \.url) { link in
                                            if let text = link.text, let url = link.url, url.hasPrefix("http") {
                                                Link(text, destination: URL(string: url)!)
                                                    .font(.footnote)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                Divider()
                            }
                            Button("收起释义卡片") { selectedWord = nil }
                                .padding(.top, 8)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 2))
                        .padding(.horizontal, 16)
                    }
                    .frame(maxHeight: 350)
                }
                // 简要列表
                List(Array(sortedResults.enumerated()).dropFirst(), id: \.element.id) { idx, word in
                    Button(action: { selectedWord = word }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(word.japanese.first?.word ?? word.japanese.first?.reading ?? "-")
                                    .font(.headline)
                                if let reading = word.japanese.first?.reading, reading != word.japanese.first?.word {
                                    Text(reading)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                if word.is_common == true {
                                    Text("常用")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                                if let jlpt = word.jlpt?.first {
                                    Text(jlpt.uppercased())
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            if let sense = word.senses.first {
                                Text(sense.english_definitions.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
                Spacer()
            }
            .navigationTitle("日语查词")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showLocal) {
                ContentView()
            }
        }
        .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
    }
    
    // 新增：优先显示完全匹配的词条
    private var sortedResults: [JishoWord] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return results }
        let exact = results.filter { word in
            word.japanese.contains(where: { $0.word == keyword || $0.reading == keyword })
        }
        let others = results.filter { word in
            !word.japanese.contains(where: { $0.word == keyword || $0.reading == keyword })
        }
        return exact + others
    }
    
    private func searchJisho() {
        let now = Date()
        if isLoading { return } // 节流：请求中禁止重复
        if let last = lastRequestTime, now.timeIntervalSince(last) < minRequestInterval {
            errorMessage = "操作过于频繁，请稍后再试。"
            return
        }
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        lastRequestTime = now
        JishoAPIManager.shared.search(keyword: keyword) { words, error in
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
