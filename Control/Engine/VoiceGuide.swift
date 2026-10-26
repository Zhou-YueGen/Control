import AVFoundation

/// 训练语音引导：用系统女声轻柔地播报阶段名称和倒计时数字。
/// 每次只播一句，新的一句会打断上一句，不会积压到下一个阶段。
final class VoiceGuide {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice? = VoiceGuide.preferredVoice()

    private static let numberWords = [1: "One", 2: "Two", 3: "Three", 4: "Four", 5: "Five",
                                      6: "Six", 7: "Seven", 8: "Eight", 9: "Nine", 10: "Ten"]

    func announce(_ phase: TrainingEngine.Phase) {
        switch phase {
        case .preparing: speak("Get ready")
        case .contract: speak("Contract")
        case .relax: speak("Relax")
        }
    }

    func count(_ seconds: Int) {
        guard let word = Self.numberWords[seconds] else { return }
        speak(word)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speak(_ text: String) {
        activateAudioSession()
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.08
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    /// 播报时压低其他 App 的音乐，而不是把它停掉。
    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        try? session.setActive(true)
    }

    /// 优先使用设备上质量最高的美式英语女声，没有时退回系统默认英语声音。
    private static func preferredVoice() -> AVSpeechSynthesisVoice? {
        let female = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" && $0.gender == .female }
            .max { $0.quality.rawValue < $1.quality.rawValue }
        return female
            ?? AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha")
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
