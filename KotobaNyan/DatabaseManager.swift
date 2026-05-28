import SQLite
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    let db: Connection

    let vocabulary = Table("vocabulary")
    let colRomaji = Expression<String>("romaji")
    let colKana = Expression<String>("kana")
    let colKanji = Expression<String?>("kanji")
    let colChinese = Expression<String?>("chinese")
    let colEnglish = Expression<String?>("english")
    let colExample = Expression<String?>("example")
    let colCnMeaning = Expression<String?>("cn_meaning")
    let colJpMeaning = Expression<String?>("jp_meaning")
    let colScene = Expression<String?>("scene")
    let colIsFavorited = Expression<Bool>("is_favorited")
    let colIsMastered = Expression<Bool>("is_mastered")
    let colReviewCount = Expression<Int>("review_count")
    let colEaseFactor = Expression<Double>("ease_factor")
    let colReviewInterval = Expression<Int>("review_interval")
    let colNextReviewDate = Expression<String?>("next_review_date")

    private init() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        db = try! Connection(url.appendingPathComponent("kotobanyan.sqlite3").path)
        createTable()
        migrateIfNeeded()
    }

    private func createTable() {
        try! db.run(vocabulary.create(ifNotExists: true) { t in
            t.column(colRomaji, primaryKey: true)
            t.column(colKana)
            t.column(colKanji)
            t.column(colChinese)
            t.column(colEnglish)
            t.column(colExample)
            t.column(colCnMeaning)
            t.column(colJpMeaning)
            t.column(colScene)
            t.column(colIsFavorited, defaultValue: false)
            t.column(colIsMastered, defaultValue: false)
            t.column(colReviewCount, defaultValue: 0)
            t.column(colEaseFactor, defaultValue: 2.5)
            t.column(colReviewInterval, defaultValue: 1)
            t.column(colNextReviewDate)
        })
    }

    private func migrateIfNeeded() {
        let migrations = [
            "ALTER TABLE vocabulary ADD COLUMN is_favorited INTEGER NOT NULL DEFAULT 0",
            "ALTER TABLE vocabulary ADD COLUMN is_mastered INTEGER NOT NULL DEFAULT 0",
            "ALTER TABLE vocabulary ADD COLUMN review_count INTEGER NOT NULL DEFAULT 0",
            "ALTER TABLE vocabulary ADD COLUMN ease_factor REAL NOT NULL DEFAULT 2.5",
            "ALTER TABLE vocabulary ADD COLUMN review_interval INTEGER NOT NULL DEFAULT 1",
            "ALTER TABLE vocabulary ADD COLUMN next_review_date TEXT"
        ]
        for stmt in migrations {
            try? db.run(stmt)
        }
    }

    func importCSVIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "csvImported") else { return }
        guard let csvPath = Bundle.main.path(forResource: "scene", ofType: "csv"),
              let csvString = try? String(contentsOfFile: csvPath, encoding: .utf8) else { return }
        let lines = csvString.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return }
        for line in lines.dropFirst() {
            let f = line.components(separatedBy: ",")
            guard f.count >= 9 else { continue }
            func field(_ i: Int) -> String { f[i].trimmingCharacters(in: .whitespaces) }
            try? db.run(vocabulary.insert(or: .ignore,
                colRomaji <- field(0),
                colKana <- field(1),
                colKanji <- field(2).isEmpty ? nil : field(2),
                colChinese <- field(3).isEmpty ? nil : field(3),
                colEnglish <- field(4).isEmpty ? nil : field(4),
                colExample <- field(5).isEmpty ? nil : field(5),
                colCnMeaning <- field(6).isEmpty ? nil : field(6),
                colJpMeaning <- field(7).isEmpty ? nil : field(7),
                colScene <- field(8).isEmpty ? nil : field(8)
            ))
        }
        UserDefaults.standard.set(true, forKey: "csvImported")
    }

    func fetchAll() -> [VocabularyItem] {
        guard let rows = try? db.prepare(vocabulary) else { return [] }
        return rows.map { mapRow($0) }
    }

    func setFavorite(romaji: String, value: Bool) {
        try? db.run(vocabulary.filter(colRomaji == romaji).update(colIsFavorited <- value))
    }

    func setMastered(romaji: String, value: Bool) {
        try? db.run(vocabulary.filter(colRomaji == romaji).update(colIsMastered <- value))
    }

    func updateReview(romaji: String, count: Int, easeFactor: Double, interval: Int, nextDate: String) {
        try? db.run(vocabulary.filter(colRomaji == romaji).update(
            colReviewCount <- count,
            colEaseFactor <- easeFactor,
            colReviewInterval <- interval,
            colNextReviewDate <- nextDate
        ))
    }

    private func mapRow(_ row: Row) -> VocabularyItem {
        VocabularyItem(
            romaji: row[colRomaji],
            kana: row[colKana],
            kanji: row[colKanji] ?? "",
            chinese: row[colChinese] ?? "",
            english: row[colEnglish] ?? "",
            example: row[colExample] ?? "",
            cn_meaning: row[colCnMeaning] ?? "",
            jp_meaning: row[colJpMeaning] ?? "",
            scene: row[colScene] ?? "",
            isFavorited: row[colIsFavorited],
            isMastered: row[colIsMastered],
            reviewCount: row[colReviewCount],
            easeFactor: row[colEaseFactor],
            reviewInterval: row[colReviewInterval],
            nextReviewDate: row[colNextReviewDate]
        )
    }
}
