import AVFoundation

/// Short sound effects. Silent when Sound is off in Settings or the ringer switch is muted.
///
/// Plays preloaded buffers through one running `AVAudioEngine`: much lower latency than restarting an
/// `AVAudioPlayer`, and no work on the main thread beyond scheduling a buffer.
@MainActor
final class SoundPlayer {
    enum Effect: String, CaseIterable { case flap, score, crash }

    private struct Voice {
        let node: AVAudioPlayerNode
        let buffer: AVAudioPCMBuffer
    }

    private let engine = AVAudioEngine()
    private var voices: [Effect: Voice] = [:]

    init() {
        // Ambient: respects the silent switch and lets the player's music keep playing.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf"),
                  let file = try? AVAudioFile(forReading: url),
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                frameCapacity: AVAudioFrameCount(file.length)),
                  (try? file.read(into: buffer)) != nil else { continue }
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
            voices[effect] = Voice(node: node, buffer: buffer)
        }
        engine.prepare()
    }

    func play(_ effect: Effect) {
        guard UserDefaults.standard.bool(forKey: SettingsKey.sound),
              let voice = voices[effect],
              startEngineIfNeeded() else { return }
        // Restarts the effect if it is still sounding, like rewinding a player.
        voice.node.scheduleBuffer(voice.buffer, at: nil, options: .interrupts)
        // Always call play(): after an interruption isPlaying can stay true on a node that has stopped.
        voice.node.play()
    }

    /// Starts the audio hardware before play begins, so the first flap is not late.
    func warmUp() {
        guard UserDefaults.standard.bool(forKey: SettingsKey.sound) else { return }
        _ = startEngineIfNeeded()
    }

    /// Starts the engine on first use and again after an interruption or a route change stopped it.
    /// A player node must never be started while the engine is stopped.
    private func startEngineIfNeeded() -> Bool {
        if !engine.isRunning { try? engine.start() }
        return engine.isRunning
    }
}
