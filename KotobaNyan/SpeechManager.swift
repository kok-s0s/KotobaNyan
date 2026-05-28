import Foundation
import AVFoundation

enum SpeechRate: String, CaseIterable {
    case slow = "慢速"
    case normal = "正常"
    case fast = "快速"

    var value: Float {
        switch self {
        case .slow: return 0.3
        case .normal: return 0.5
        case .fast: return 0.7
        }
    }
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    var currentRate: Float {
        let raw = UserDefaults.standard.string(forKey: "speechRate") ?? SpeechRate.normal.rawValue
        return SpeechRate(rawValue: raw)?.value ?? SpeechRate.normal.value
    }

    func speak(text: String, language: String = "ja-JP") {
        guard !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = currentRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
