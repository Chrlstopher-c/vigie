#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Rangée de raccourcis Ctrl, affichée quand le modificateur « ctrl » de
/// `BarreTerminal` est armé.
///
/// Le clavier iOS n'a pas de touche Ctrl : composer Ctrl-lettre est exactement
/// ce qu'un navigateur mobile ne peut pas offrir à tmux. `ToucheTerminal`
/// fournit déjà les quatre raccourcis à portée de pouce ; cette rangée ne fait
/// que les présenter et refermer l'armement une fois l'un d'eux choisi.
struct RangeeControleArme: View {
    let annuler: @MainActor () -> Void
    let envoyer: @MainActor (String) async -> Void

    var body: some View {
        HStack(spacing: Espace.serre) {
            ForEach(ToucheTerminal.raccourcisFrequents, id: \.libelle) { raccourci in
                bouton(raccourci)
            }
            Spacer(minLength: 0)
            Button("Annuler", action: annuler)
                .libelleBouton()
                .foregroundStyle(Couleurs.texteTertiaire)
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.vertical, Espace.serre)
        .background(Couleurs.fondCreuse)
        .overlay(alignment: .top) { FiletHorizontal() }
    }

    private func bouton(_ raccourci: (libelle: String, lettre: Character, effet: String)) -> some View {
        Button {
            guard let sequence = ToucheTerminal.sequenceControle(raccourci.lettre) else { return }
            Task { await envoyer(sequence) }
            annuler()
        } label: {
            Text(raccourci.libelle)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Couleurs.encre)
                .frame(minWidth: 44, minHeight: 34)
                .background(Couleurs.surface, in: RoundedRectangle(cornerRadius: Rayon.boutonPetit))
                .overlay {
                    RoundedRectangle(cornerRadius: Rayon.boutonPetit)
                        .strokeBorder(Couleurs.filetAppuye, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .reagitAuToucher(echelle: 0.92)
        .accessibilityLabel(raccourci.effet)
    }
}
#endif
