#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Les fils de l'orchestrateur : liste, fil segmenté, bloc partiel jeton par jeton, composeur avec STOP, pièces jointes
/// chargées par `ClientPi`. Le rendu markdown est le poste sous-estimé de ce domaine.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Fil ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("fil") { … }`,
///    jamais par un `Timer` à elle.
public struct FilEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.fil)
            EtatVide(
                symbole: "bubble.left.and.bubble.right.fill",
                titre: "Fil",
                explication: "Les fils de l'orchestrateur s'afficheront ici."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
