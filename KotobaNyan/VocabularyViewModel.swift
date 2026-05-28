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
    let isFavorited: Bool
    let isMastered: Bool
    let reviewCount: Int
    let easeFactor: Double
    let reviewInterval: Int
    let nextReviewDate: String?

    var displayWord: String { kanji.isEmpty ? kana : kanji }
}

class VocabularyViewModel: ObservableObject {
    @Published var items: [VocabularyItem] = []
    @Published var filteredItems: [VocabularyItem] = []
    @Published var scenes: [String] = []
    @Published var favoriteItems: [VocabularyItem] = []
    @Published var dueItems: [VocabularyItem] = []

    init() { fetchAll() }

    func fetchAll() {
        let all = DatabaseManager.shared.fetchAll()
        items = all
        filteredItems = all
        scenes = Array(Set(all.map { $0.scene })).filter { !$0.isEmpty }.sorted()
        favoriteItems = all.filter { $0.isFavorited }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        dueItems = all.filter { item in
            item.reviewCount > 0 &&
            ((item.nextReviewDate ?? "") <= today)
        }
    }

    func search(prefix: String) {
        let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { filteredItems = items; return }
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

    func item(for romaji: String) -> VocabularyItem? {
        items.first { $0.romaji == romaji }
    }

    func toggleFavorite(_ item: VocabularyItem) {
        DatabaseManager.shared.setFavorite(romaji: item.romaji, value: !item.isFavorited)
        fetchAll()
    }

    func toggleMastered(_ item: VocabularyItem) {
        DatabaseManager.shared.setMastered(romaji: item.romaji, value: !item.isMastered)
        fetchAll()
    }

    func addToReview(_ item: VocabularyItem) {
        guard item.reviewCount == 0 else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        DatabaseManager.shared.updateReview(
            romaji: item.romaji,
            count: 1,
            easeFactor: item.easeFactor,
            interval: 1,
            nextDate: formatter.string(from: Date())
        )
        fetchAll()
    }

    // SM-2 spaced repetition. quality: 0=Again, 1=Hard, 2=Good, 3=Easy
    func submitReview(_ item: VocabularyItem, quality: Int) {
        let sm2Grade = [1, 3, 4, 5][quality]
        let newCount = item.reviewCount + 1
        var newInterval: Int
        var newEF = item.easeFactor

        if sm2Grade < 3 {
            newInterval = 1
        } else {
            switch item.reviewCount {
            case 0, 1: newInterval = 1
            case 2: newInterval = 6
            default: newInterval = max(1, Int(Double(item.reviewInterval) * item.easeFactor))
            }
            let q = Double(sm2Grade)
            newEF = item.easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
            newEF = max(1.3, newEF)
        }

        let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        DatabaseManager.shared.updateReview(
            romaji: item.romaji,
            count: newCount,
            easeFactor: newEF,
            interval: newInterval,
            nextDate: formatter.string(from: nextDate)
        )
        fetchAll()
    }
}
