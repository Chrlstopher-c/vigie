#if canImport(SwiftUI)
import SwiftUI

/// Feuille de lancement d'une session tmux. Un seul champ : le nom, avec
/// « claude » en repli — c'est le nom que `pi-web` donne par défaut, et le cas
/// dominant sur ce produit.
struct NouvelleSessionFeuille: View {
    let creer: @MainActor (String) async -> Void

    @State private var nom = ""
    @State private var enCours = false
    @FocusState private var enFocus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.section) {
            Text("Nouvelle session")
                .titreModale()
                .foregroundStyle(Couleurs.encre)
            ChampSaisie(
                "Nom",
                texte: $nom,
                placebo: "claude",
                aide: "Laissé vide, la session s'appellera « claude ».",
                lignes: 1...1
            )
            .focused($enFocus)
            Button {
                Task { await lancer() }
            } label: {
                Group {
                    if enCours {
                        ProgressView().tint(.white)
                    } else {
                        Text("Lancer")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.vigieAccent)
            .disabled(enCours)
            Spacer(minLength: 0)
        }
        .padding(Espace.ecran)
        .task { enFocus = true }
        .congedieLeClavierSansDefilement()
    }

    @MainActor private func lancer() async {
        guard !enCours else { return }
        enCours = true
        await creer(nom)
        enCours = false
    }
}
#endif
