#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Adresse du Pi, session, seuils, accès à l'état du canal d'alerte et à l'échéance de signature.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Réglages ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("reglages") { … }`,
///    jamais par un `Timer` à elle.
public struct ReglagesEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.reglages)
            EtatVide(
                symbole: "gearshape.fill",
                titre: "Réglages",
                explication: "Les réglages de Vigie s'afficheront ici."
            )
            // `Alerte` n'est pas dans la barre : ce lien est son SEUL accès.
            // À conserver en remplissant cet écran.
            NavigationLink(value: Domaine.alerte) {
                Text("État du canal d'alerte")
                    .libelleBouton()
            }
            .buttonStyle(.vigieSecondaire)
            .padding(.horizontal, Espace.ecran)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
