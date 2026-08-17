#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le seul domaine autorisé à toucher `UNUserNotificationCenter`. Hors barre : on y arrive depuis les Réglages par
/// `NavigationLink(value: Domaine.alerte)`. Il branche `DelegueApplication.ecouteur` et lit `FaitNotifie`.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Alerte ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("alerte") { … }`,
///    jamais par un `Timer` à elle.
public struct AlerteEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.alerte)
            EtatVide(
                symbole: "bell.badge.fill",
                titre: "Alerte",
                explication: "L'état du canal d'alerte s'affichera ici : dernier réveil réel, "
                    + "dernier rattrapage, alarme de silence."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
