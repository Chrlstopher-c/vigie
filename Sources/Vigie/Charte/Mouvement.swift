// Vocabulaire d'animation de Vigie — « async dans les mouvements » :
// rien n'apparaît brutalement, rien ne saute. Chaque courbe est nommée par
// intention ; la courbe signature (.2,.8,.2,1) vient des keyframes msgIn/modalIn
// de la maquette. 60 Hz sur A12 : uniquement opacité et transformations.
#if canImport(SwiftUI)
import SwiftUI

public enum Mouvement {
    /// Retour immédiat d'un contrôle sous le doigt (pression, bascule).
    public static let reponseImmediate: Animation = .easeOut(duration: 0.15)
    /// Changement d'état en place : couleur de pastille, filtre actif.
    public static let changementEtat: Animation = .easeInOut(duration: 0.2)
    /// Entrée d'un élément dans un flux (message, carte, ligne de fil).
    public static let apparition: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.35)
    /// Poussée d'écran, montée de feuille ou de modale.
    public static let transitionEcran: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.3)
    /// Progression d'une jauge ou d'une barre vers sa nouvelle valeur.
    public static let progression: Animation = .easeInOut(duration: 0.3)
    /// Respiration des attentes longues (point vital, squelettes).
    public static let chargementLong: Animation = .easeInOut(duration: 1).repeatForever(autoreverses: true)

    /// Décalage entre éléments d'une même vague d'apparition.
    public static let pasCascade: Double = 0.05

    /// Apparition retardée selon le rang dans la liste, plafonnée pour que
    /// le douzième élément n'attende pas une demi-seconde.
    public static func cascade(_ rang: Int) -> Animation {
        apparition.delay(Double(min(rang, 12)) * pasCascade)
    }
}

/// Fait entrer la vue en fondu + translation de 6 pt (keyframe msgIn),
/// avec cascade optionnelle selon le rang.
private struct ApparitionDouce: ViewModifier {
    let rang: Int
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 6)
            .onAppear {
                withAnimation(Mouvement.cascade(rang)) { visible = true }
            }
    }
}

/// Pulsation lente d'un témoin vivant (dot-live : opacité 1 ↔ 0.35).
private struct PulsationVitale: ViewModifier {
    @State private var attenue = false

    func body(content: Content) -> some View {
        content
            .opacity(attenue ? 0.35 : 1)
            .onAppear {
                withAnimation(Mouvement.chargementLong) { attenue = true }
            }
    }
}

/// Rotation continue d'un indicateur d'activité (spin 1.2 s linéaire).
private struct RotationContinue: ViewModifier {
    @State private var enRotation = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(enRotation ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    enRotation = true
                }
            }
    }
}

extension View {
    /// Entrée standard de tout contenu : fondu + 6 pt de translation.
    public func apparitionDouce(rang: Int = 0) -> some View {
        modifier(ApparitionDouce(rang: rang))
    }

    /// Témoin vivant qui respire (lien établi, mission active).
    public func pulsationVitale() -> some View {
        modifier(PulsationVitale())
    }

    /// À poser sur une icône pour en faire un indicateur d'activité.
    public func rotationContinue() -> some View {
        modifier(RotationContinue())
    }
}
#endif
