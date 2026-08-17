#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Missions, détail d'équipe, sous-agents. `state` se décode TEL QUEL, jamais recalculé depuis `etatHarness` : le
/// recalculer rejoue la panne #30.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Parc ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("parc") { … }`,
///    jamais par un `Timer` à elle.
public struct ParcEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.parc)
            EtatVide(
                symbole: "square.stack.3d.up.fill",
                titre: "Parc",
                explication: "Les missions et leurs équipes s'afficheront ici."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
