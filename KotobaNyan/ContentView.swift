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
        } catch {
            self.items = []
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
    var body: some View {
        NavigationView {
            List(viewModel.items) { item in
                NavigationLink(destination: VocabularyCardView(item: item)) {
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
            .navigationTitle("词条列表")
        }
    }
}

#Preview {
    ContentView()
}
