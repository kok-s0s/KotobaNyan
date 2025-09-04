//
//  DatabaseManager.swift
//  KotobaNyan
//
//  Created by kok-s0s on 2025/9/4.
//

import SQLite
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    let db: Connection

    let vocabulary = Table("vocabulary")
    let romaji = Expression<String>("romaji")
    let kana = Expression<String>("kana")
    let kanji = Expression<String?>("kanji")
    let chinese = Expression<String?>("chinese")
    let english = Expression<String?>("english")
    let example = Expression<String?>("example")
    let cn_meaning = Expression<String?>("cn_meaning")
    let jp_meaning = Expression<String?>("jp_meaning")
    let scene = Expression<String?>("scene")

    private init() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = url.appendingPathComponent("kotobanyan.sqlite3").path
        db = try! Connection(dbPath)
        try! db.run(vocabulary.create(ifNotExists: true) { t in
            t.column(romaji, primaryKey: true)
            t.column(kana)
            t.column(kanji)
            t.column(chinese)
            t.column(english)
            t.column(example)
            t.column(cn_meaning)
            t.column(jp_meaning)
            t.column(scene)
        })
    }

    func importCSVIfNeeded() {
        let importedKey = "csvImported"
        if UserDefaults.standard.bool(forKey: importedKey) { return }
        guard let csvPath = Bundle.main.path(forResource: "scene", ofType: "csv") else { return }
        guard let csvString = try? String(contentsOfFile: csvPath, encoding: .utf8) else { return }
        let lines = csvString.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return }
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
            if fields.count < 9 { continue }
            let romaji = fields[0].trimmingCharacters(in: .whitespaces)
            let kana = fields[1].trimmingCharacters(in: .whitespaces)
            let kanji = fields[2].trimmingCharacters(in: .whitespaces)
            let chinese = fields[3].trimmingCharacters(in: .whitespaces)
            let english = fields[4].trimmingCharacters(in: .whitespaces)
            let example = fields[5].trimmingCharacters(in: .whitespaces)
            let cn_meaning = fields[6].trimmingCharacters(in: .whitespaces)
            let jp_meaning = fields[7].trimmingCharacters(in: .whitespaces)
            let scene = fields[8].trimmingCharacters(in: .whitespaces)
            do {
                try db.run(vocabulary.insert(or: .ignore,
                    self.romaji <- romaji,
                    self.kana <- kana,
                    self.kanji <- kanji,
                    self.chinese <- chinese,
                    self.english <- english,
                    self.example <- example,
                    self.cn_meaning <- cn_meaning,
                    self.jp_meaning <- jp_meaning,
                    self.scene <- scene
                ))
            } catch {
                // 忽略插入错误
            }
        }
        UserDefaults.standard.set(true, forKey: importedKey)
    }
}
