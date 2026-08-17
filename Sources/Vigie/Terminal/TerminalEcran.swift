#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le terminal tmux — là où un client natif écrase le plus nettement Safari mobile : barre d'accessoires clavier avec
/// Échap, flèches, Tab, Ctrl, et collage propre.
///
/// COQUILLE VIDE — à remplir par l'agent du domaine « Terminal ».
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("terminal") { … }`,
///    jamais par un `Timer` à elle.
public struct TerminalEcran: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.terminal)
            EtatVide(
                symbole: "terminal.fill",
                titre: "Terminal",
                explication: "Les sessions tmux et leur capture s'afficheront ici."
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
    }
}
#endif
