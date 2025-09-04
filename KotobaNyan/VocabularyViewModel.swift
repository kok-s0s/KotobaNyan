import Foundation
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
