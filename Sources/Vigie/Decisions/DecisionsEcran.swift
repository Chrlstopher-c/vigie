#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le domaine prioritaire : mandats, rallonges et arbitrages d'inspection, une seule file triée. Le champ « accès » se
/// lit au même rang que le titre (H-61) et l'approbation passe par Face ID.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Décisions ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("decisions") { … }`,
///    jamais par un `Timer` à elle.
public struct DecisionsEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.decisions)
            EtatVide(
                symbole: "hand.raised.fill",
                titre: "Décisions",
                explication: "Les mandats, rallonges et arbitrages en attente s'afficheront ici."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
