#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Une ligne de la liste des sessions tmux : nom, état d'attache, âge.
struct CarteSession: View {
    let session: SessionTmuxApi

    var body: some View {
        CarteVigie {
            HStack(spacing: Espace.standard) {
                PointVital(etat: session.attached ? .sain : .neutre, vivant: session.attached)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .monoDonnee()
                        .foregroundStyle(Couleurs.encre)
                    Text(age)
                        .legende()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
                Spacer(minLength: Espace.standard)
                PastilleEtat(session.attached ? "Attachée" : "Détachée", etat: session.attached ? .sain : .neutre)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    /// `created` est en secondes epoch (tmux), `Fraicheur` attend une `Date`.
    private var age: String {
        Fraicheur.texte(depuis: Date(timeIntervalSince1970: Double(session.created)))
    }
}
#endif
