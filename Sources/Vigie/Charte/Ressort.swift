// Les courbes à ressort d'iOS 17+, qui remplacent les easeInOut hérités du web.
//
// `☠` C'est le jeton qui change le plus le ressenti de toute l'app. Une courbe
// de Bézier fait glisser un objet ; un ressort lui donne une masse. Sur iOS,
// tout ce qui répond à un doigt doit avoir une masse — sinon l'interface est
// lue comme étrangère à la plateforme, quelle que soit la palette.
#if canImport(SwiftUI)
import SwiftUI

public enum Ressort {
    /// Réponse à un geste direct : pression, bascule, sélection de filtre.
    /// Sec, sans rebond — le doigt est encore sur l'écran, il ne faut pas
    /// que l'objet continue de bouger après lui.
    public static let direct: Animation = .snappy(duration: 0.28, extraBounce: 0)

    /// Entrée d'un élément dans un flux. Un rebond léger suffit à donner de la
    /// matière ; au-delà, ça devient un jouet.
    public static let entree: Animation = .spring(response: 0.42, dampingFraction: 0.78)

    /// Ouverture d'une carte, d'une feuille, d'un détail. Plus ample, parce que
    /// la distance parcourue est plus grande.
    public static let ouverture: Animation = .spring(response: 0.5, dampingFraction: 0.82)

    /// Célébration discrète : une décision prise, une équipe qui rend son
    /// rapport. Le seul endroit où le rebond est franc.
    public static let acquiescement: Animation = .bouncy(duration: 0.5, extraBounce: 0.25)

    /// Retrait : une carte que l'on écarte, une notification que l'on chasse.
    /// Plus rapide que l'entrée — on ne regarde pas partir ce qu'on a décidé.
    public static let sortie: Animation = .snappy(duration: 0.22)

    /// Suivi continu d'un geste (glissement, redimensionnement). Aucun
    /// dépassement : l'objet doit rester sous le doigt.
    public static let suiviGeste: Animation = .interactiveSpring(
        response: 0.24,
        dampingFraction: 1,
        blendDuration: 0.1
    )

    /// Cascade d'entrée, plafonnée pour que le douzième élément n'attende pas.
    public static func cascade(_ rang: Int) -> Animation {
        entree.delay(Double(min(rang, 12)) * 0.04)
    }
}
#endif
