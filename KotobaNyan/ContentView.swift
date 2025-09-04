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
        } catch {
            self.items = []
            self.filteredItems = []
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
                        let text = item.kanji.isEmpty ? item.kana : item.kanji
                        SpeechManager.shared.speak(text: text)
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
    var body: some View {
        NavigationView {
            ZStack {
                // 背景点击收起词卡和键盘
                Color(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSearchFocused = false
                        selectedItem = nil
                    }
                VStack(spacing: 0) {
                    // 搜索框
                    TextField("输入词条前缀...", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding([.horizontal, .top])
                        .focused($isSearchFocused)
                        .submitLabel(.done)
                        .onChange(of: searchText) { newValue in
                            viewModel.search(prefix: newValue)
                            selectedItem = nil
                        }
                        .onSubmit {
                            isSearchFocused = false
                        }
                    // 匹配结果列表
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
            .navigationTitle("词条搜索")
        }
    }
}

#Preview {
    ContentView()
}
