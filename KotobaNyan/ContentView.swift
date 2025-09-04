//
//  ContentView.swift
//  KotobaNyan
//
//  Created by kok-s0s on 2025/9/2.
//

import SwiftUI

struct VocabularyItem: Identifiable {
    let id = UUID()
    let romaji: String
    let kana: String
    let kanji: String
    let chinese: String
    let english: String
    let example: String
    let cn_meaning: String
    let jp_meaning: String
    let scene: String
}

class VocabularyViewModel: ObservableObject {
    @Published var items: [VocabularyItem] = []
    @Published var filteredItems: [VocabularyItem] = []
    @Published var scenes: [String] = []
    init() {
        fetchAll()
    }
    func fetchAll() {
        let db = DatabaseManager.shared.db
        let table = DatabaseManager.shared.vocabulary
        let romaji = DatabaseManager.shared.romaji
        let kana = DatabaseManager.shared.kana
        let kanji = DatabaseManager.shared.kanji
        let chinese = DatabaseManager.shared.chinese
        let english = DatabaseManager.shared.english
        let example = DatabaseManager.shared.example
        let cn_meaning = DatabaseManager.shared.cn_meaning
        let jp_meaning = DatabaseManager.shared.jp_meaning
        let scene = DatabaseManager.shared.scene
        do {
            let rows = try db.prepare(table)
            self.items = rows.map { row in
                VocabularyItem(
                    romaji: row[romaji],
                    kana: row[kana],
                    kanji: row[kanji] ?? "",
                    chinese: row[chinese] ?? "",
                    english: row[english] ?? "",
                    example: row[example] ?? "",
                    cn_meaning: row[cn_meaning] ?? "",
                    jp_meaning: row[jp_meaning] ?? "",
                    scene: row[scene] ?? ""
                )
            }
            self.filteredItems = self.items
            self.scenes = Array(Set(self.items.map { $0.scene })).filter { !$0.isEmpty }.sorted()
        } catch {
            self.items = []
            self.filteredItems = []
            self.scenes = []
        }
    }
    func search(prefix: String) {
        let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.isEmpty {
            filteredItems = items
            return
        }
        filteredItems = items.filter { item in
            item.kana.hasPrefix(p) ||
            item.kanji.hasPrefix(p) ||
            item.romaji.lowercased().hasPrefix(p.lowercased()) ||
            item.chinese.hasPrefix(p) ||
            item.english.lowercased().hasPrefix(p.lowercased())
        }
    }
    func filteredSceneItems(scene: String) -> [VocabularyItem] {
        items.filter { $0.scene == scene }
    }
}

struct VocabularyCardView: View {
    let item: VocabularyItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.kanji.isEmpty ? item.kana : item.kanji)
                    .font(.title)
                    .bold()
                    .onTapGesture {
                        // 优先朗读 kana，其次 romaji，最后 kanji
                        if !item.kana.isEmpty {
                            SpeechManager.shared.speak(text: item.kana)
                        } else if !item.romaji.isEmpty {
                            SpeechManager.shared.speak(text: item.romaji)
                        } else {
                            SpeechManager.shared.speak(text: item.kanji)
                        }
                    }
                Spacer()
                Text(item.romaji)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Text(item.chinese)
                .font(.headline)
                .foregroundColor(.accentColor)
            Text(item.english)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
            Text("例句：" + item.example)
                .font(.body)
            Text("中文释义：" + item.cn_meaning)
                .font(.footnote)
                .foregroundColor(.secondary)
            Text("日文释义：" + item.jp_meaning)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack {
                Spacer()
                Text("场景：" + item.scene)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 2))
    }
}

struct ContentView: View {
    @StateObject var viewModel = VocabularyViewModel()
    @State private var searchText: String = ""
    @State private var selectedItem: VocabularyItem? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var selectedScene: String? = nil
    let gridColumns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索区
                VStack(spacing: 0) {
                    TextField("输入词条前缀...", text: $searchText)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .padding([.horizontal, .top], 16)
                        .focused($isSearchFocused)
                        .submitLabel(.done)
                        .onChange(of: searchText) { newValue in
                            viewModel.search(prefix: newValue)
                            selectedItem = nil
                        }
                        .onSubmit {
                            isSearchFocused = false
                        }
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        List(viewModel.filteredItems) { item in
                            Button(action: {
                                selectedItem = item
                                isSearchFocused = false
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
                                    Text(item.scene)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 300)
                        // 释义卡片
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
                }
                // 分类栅格区（仅在搜索框为空时显示）
                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(viewModel.scenes, id: \ .self) { scene in
                                NavigationLink(destination: SceneWordsView(scene: scene, viewModel: viewModel)) {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.accentColor.opacity(0.18))
                                        .frame(height: 120)
                                        .shadow(color: Color(.systemGray3), radius: 6, x: 0, y: 2)
                                        .overlay(
                                            GeometryReader { geometry in
                                                HStack {
                                                    Spacer(minLength: 0)
                                                    VStack {
                                                        Spacer(minLength: 0)
                                                        Text(scene)
                                                            .font(.title3)
                                                            .bold()
                                                            .foregroundColor(.accentColor)
                                                            .multilineTextAlignment(.center)
                                                            .padding(.horizontal, 12)
                                                            .padding(.top, 24) // 让文本整体向下偏移
                                                        Spacer(minLength: 0)
                                                    }
                                                    .frame(height: geometry.size.height)
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                }
                Spacer()
            }
            .navigationTitle("场景分类与搜索")
        }
    }
}

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

#Preview {
    ContentView()
}
