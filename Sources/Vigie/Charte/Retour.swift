// Retour haptique — la dimension qu'aucune interface web ne peut atteindre,
// et le premier signal qui distingue une app native sur cette plateforme.
//
// Deux étages : le vocabulaire système (sensoryFeedback) pour les gestes
// courants, et Core Haptics pour les moments qui méritent une texture propre.
// Le second est porté du banc d'essai EchoLabs, où les motifs ont été éprouvés
// sur l'appareil.
#if canImport(SwiftUI)
import CoreHaptics
import SwiftUI

public enum Retour {
    /// Sélection d'un filtre, d'un onglet, d'une ligne.
    public static let selection = SensoryFeedback.selection
    /// Une écriture a abouti : mandat autorisé, message envoyé.
    public static let succes = SensoryFeedback.success
    /// Un refus serveur, un conflit, une saisie invalide.
    public static let echec = SensoryFeedback.error
    /// Attention sans échec : quota qui bascule, liaison perdue.
    public static let alerte = SensoryFeedback.warning
    /// Contact léger d'un élément qui se pose.
    public static let contact = SensoryFeedback.impact(weight: .light)
    /// Contact franc d'un geste engageant.
    public static let engagement = SensoryFeedback.impact(weight: .heavy)
}

/// Motifs Core Haptics composés, pour les instants qui ne se contentent pas
/// d'un tic système. Intensité **et** netteté modulées — hors de portée
/// d'UIFeedbackGenerator.
@MainActor
public final class Texture {
    public static let partagee = Texture()

    private var moteur: CHHapticEngine?
    private let supporte = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {}

    public func preparer() {
        guard supporte, moteur == nil else { return }
        do {
            let moteur = try CHHapticEngine()
            moteur.playsHapticsOnly = true
            moteur.isAutoShutdownEnabled = true
            try moteur.start()
            self.moteur = moteur
        } catch {
            moteur = nil
        }
    }

    /// Montée continue puis éclat — une décision qui prend effet, une équipe
    /// qui part. Le motif le plus marquant du répertoire, à ne pas galvauder.
    public func acquiescement() {
        jouer(montee() + [transitoire(0.5, 1, 0.95)])
    }

    /// Rafale décroissante — quelque chose se referme, une équipe s'arrête.
    public func extinction() {
        jouer((0..<9).map { rang in
            let avancee = Float(rang) / 8
            return transitoire(Double(rang) * 0.05, 1 - avancee * 0.85, 0.9 - avancee * 0.7)
        })
    }

    /// Deux battements — une alerte qui demande le regard sans l'exiger.
    public func battement() {
        jouer([transitoire(0, 0.85, 0.4), transitoire(0.16, 0.55, 0.3)])
    }

    private func montee() -> [CHHapticEvent] {
        [CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                .init(parameterID: .hapticIntensity, value: 0.35),
                .init(parameterID: .hapticSharpness, value: 0.1),
            ],
            relativeTime: 0,
            duration: 0.45
        )]
    }

    private func transitoire(
        _ instant: TimeInterval,
        _ intensite: Float,
        _ nettete: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                .init(parameterID: .hapticIntensity, value: intensite),
                .init(parameterID: .hapticSharpness, value: nettete),
            ],
            relativeTime: instant
        )
    }

    private func jouer(_ evenements: [CHHapticEvent]) {
        guard let moteur else { return }
        do {
            try moteur.start()
            let motif = try CHHapticPattern(events: evenements, parameters: [])
            try moteur.makePlayer(with: motif).start(atTime: CHHapticTimeImmediate)
        } catch {
            // Un motif perdu n'est jamais une raison d'interrompre un geste.
        }
    }
}
#endif
