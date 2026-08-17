#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le parc matériel : état, métriques à la demande, comptes Claude, bascule de compte, réveil par paquet magique.
/// L'extinction reste hors périmètre v1.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Machines ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("machines") { … }`,
///    jamais par un `Timer` à elle.
public struct MachinesEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.machines)
            EtatVide(
                symbole: "desktopcomputer",
                titre: "Machines",
                explication: "L'état des machines et leurs métriques s'afficheront ici."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
