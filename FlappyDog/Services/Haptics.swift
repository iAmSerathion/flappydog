import UIKit

/// Flap tap, score tick, crash thud. Off when Haptics is off in Settings.
@MainActor
final class Haptics {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    func flap() { fire(light, 0.7) }
    func score() { fire(soft, 0.6) }
    func crash() { fire(heavy, 1) }

    /// Wakes the Taptic Engine so the next impact comes without delay. It stays ready for a few seconds.
    func prepare() {
        guard enabled else { return }
        [light, soft, heavy].forEach { $0.prepare() }
    }

    private var enabled: Bool { UserDefaults.standard.bool(forKey: SettingsKey.haptics) }

    private func fire(_ generator: UIImpactFeedbackGenerator, _ intensity: CGFloat) {
        guard enabled else { return }
        generator.impactOccurred(intensity: intensity)
        // Keep it awake for the next tap.
        generator.prepare()
    }
}
