// Rendu des listes markdown : puce ou numéro, imbrication à plat via
// `EntreeListe.niveau`, case à cocher pour une liste de tâches.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

extension RenduMarkdown {

    func vueListe(_ entrees: [EntreeListe]) -> some View {
        VStack(alignment: .leading, spacing: Espace.serre) {
            ForEach(Array(entrees.enumerated()), id: \.offset) { _, entree in
                vueEntree(entree)
            }
        }
    }

    private func vueEntree(_ entree: EntreeListe) -> some View {
        HStack(alignment: .top, spacing: Espace.serre) {
            marqueur(entree)
            texteFragments(entree.contenu)
                .corps()
                .foregroundStyle(Couleurs.encre)
                .strikethrough(entree.cochee == true)
                .opacity(entree.cochee == true ? 0.6 : 1)
        }
        .padding(.leading, CGFloat(entree.niveau) * 16)
    }

    @ViewBuilder
    private func marqueur(_ entree: EntreeListe) -> some View {
        if let cochee = entree.cochee {
            Image(systemName: cochee ? "checkmark.square.fill" : "square")
                .font(.system(size: 12))
                .foregroundStyle(cochee ? Couleurs.etatSain : Couleurs.texteTertiaire)
                .frame(width: 16, alignment: .center)
                .padding(.top, 2)
        } else {
            Text(entree.puce)
                .monoPetit()
                .foregroundStyle(Couleurs.texteSecondaire)
                .frame(minWidth: 16, alignment: .trailing)
        }
    }
}
#endif
