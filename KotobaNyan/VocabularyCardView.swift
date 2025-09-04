import SwiftUI
import Foundation

struct VocabularyCardView: View {
    let item: VocabularyItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.kanji.isEmpty ? item.kana : item.kanji)
                    .font(.title)
                    .bold()
                    .onTapGesture {
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
