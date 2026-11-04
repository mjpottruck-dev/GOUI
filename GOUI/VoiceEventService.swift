import Foundation
import Speech
import AVFoundation

@MainActor
final class VoiceEventService: ObservableObject {
    @Published var isListening = false
    @Published var toastMessage: String? = nil

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    completion(false)
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
        }
    }

    func startListening(players: [Player], onEvent: @escaping (VoiceCommand) -> Void) {
        guard let recognizer, recognizer.isAvailable else {
            showToast("Speech recognition unavailable")
            return
        }

        requestPermissions { [weak self] granted in
            guard let self, granted else {
                self?.showToast("Microphone permission required")
                return
            }
            self.beginRecognition(players: players, onEvent: onEvent)
        }
    }

    private func beginRecognition(players: [Player], onEvent: @escaping (VoiceCommand) -> Void) {
        stopListening()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            try audioEngine.start()
            isListening = true
        } catch {
            showToast("Could not start audio engine")
            return
        }

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result, result.isFinal {
                let text = result.bestTranscription.formattedString.lowercased()
                if let command = self.parseCommand(text, players: players) {
                    onEvent(command)
                } else {
                    Task { @MainActor in
                        self.showToast("Couldn't understand -- try again")
                    }
                }
            }

            if error != nil || (result?.isFinal == true) {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.toastMessage = nil }
        }
    }

    // MARK: - Parse voice commands

    func parseCommand(_ text: String, players: [Player]) -> VoiceCommand? {
        let lower = text.lowercased()

        // "sub X for Y"
        if lower.contains("sub ") {
            let parts = lower.replacingOccurrences(of: "sub ", with: "").components(separatedBy: " for ")
            if parts.count == 2,
               let playerOn = fuzzyMatch(parts[0].trimmingCharacters(in: .whitespaces), in: players),
               let playerOff = fuzzyMatch(parts[1].trimmingCharacters(in: .whitespaces), in: players) {
                return .substitution(on: playerOn, off: playerOff)
            }
        }

        // "card for X"
        if lower.contains("card for ") {
            let name = lower.replacingOccurrences(of: "card for ", with: "").trimmingCharacters(in: .whitespaces)
            if let player = fuzzyMatch(name, in: players) {
                return .card(player: player)
            }
        }

        // "X scored assisted by Y"
        if lower.contains("scored") && lower.contains("assisted by") {
            let scorerPart = lower.components(separatedBy: " scored").first ?? ""
            let assistPart = lower.components(separatedBy: "assisted by ").last ?? ""
            if let scorer = fuzzyMatch(scorerPart.trimmingCharacters(in: .whitespaces), in: players),
               let assister = fuzzyMatch(assistPart.trimmingCharacters(in: .whitespaces), in: players) {
                return .goal(scorer: scorer, assist: assister)
            }
        }

        // "X scored"
        if lower.contains("scored") {
            let name = lower.replacingOccurrences(of: " scored", with: "").trimmingCharacters(in: .whitespaces)
            if let player = fuzzyMatch(name, in: players) {
                return .goal(scorer: player, assist: nil)
            }
        }

        // "X saved"
        if lower.contains("saved") {
            let name = lower.replacingOccurrences(of: " saved", with: "").trimmingCharacters(in: .whitespaces)
            if let player = fuzzyMatch(name, in: players) {
                return .save(keeper: player)
            }
        }

        // "X conceded"
        if lower.contains("conceded") {
            let name = lower.replacingOccurrences(of: " conceded", with: "").trimmingCharacters(in: .whitespaces)
            if let player = fuzzyMatch(name, in: players) {
                return .conceded(keeper: player)
            }
        }

        return nil
    }

    private func fuzzyMatch(_ input: String, in players: [Player]) -> Player? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lower.isEmpty else { return nil }

        // Exact match on first name
        if let exact = players.first(where: {
            $0.name.lowercased().split(separator: " ").first.map(String.init)?.lowercased() == lower
        }) { return exact }

        // Exact match on full name
        if let exact = players.first(where: { $0.name.lowercased() == lower }) {
            return exact
        }

        // Contains match
        if let partial = players.first(where: { $0.name.lowercased().contains(lower) }) {
            return partial
        }

        // Partial starts-with on first name
        if let starts = players.first(where: {
            $0.name.lowercased().split(separator: " ").first.map(String.init)?.hasPrefix(lower) == true
        }) { return starts }

        return nil
    }
}

enum VoiceCommand {
    case goal(scorer: Player, assist: Player?)
    case save(keeper: Player)
    case conceded(keeper: Player)
    case card(player: Player)
    case substitution(on: Player, off: Player)
}
