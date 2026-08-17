// Rendu des tableaux markdown — le bloc qui justifie à lui seul l'analyseur
// maison (voir `AnalyseurTableau`). `Grid` dimensionne les colonnes à leur
// contenu ; le défilement horizontal absorbe un tableau plus large que l'écran
// plutôt que de le tasser illisible.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

extension RenduMarkdown {

    func vueTableau(_ table: TableauMarkdown) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .topLeading, horizontalSpacing: Espace.carte, verticalSpacing: Espace.serre) {
                GridRow {
                    ForEach(Array(table.entete.enumerated()), id: \.offset) { indice, contenu in
                        celluleTableau(contenu, alignement: table.alignement(indice), entete: true)
                    }
                }
                Divider().gridCellColumns(table.colonnes)
                ForEach(Array(table.lignes.enumerated()), id: \.offset) { _, ligne in
                    GridRow {
                        ForEach(Array(ligne.enumerated()), id: \.offset) { indice, contenu in
                            celluleTableau(contenu, alignement: table.alignement(indice), entete: false)
                        }
                    }
                }
            }
            .padding(Espace.carte)
        }
        .background(Couleurs.surface, in: RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
                .strokeBorder(Couleurs.filet, lineWidth: Trait.filet)
        )
    }

    private func celluleTableau(
        _ contenu: [FragmentTexte],
        alignement: AlignementColonne,
        entete: Bool
    ) -> some View {
        Group {
            if entete {
                texteFragments(contenu).corpsAccentue().foregroundStyle(Couleurs.encre)
            } else {
                texteFragments(contenu).secondaire().foregroundStyle(Couleurs.texteSecondaire)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignementSwiftUI(alignement))
    }

    private func alignementSwiftUI(_ alignement: AlignementColonne) -> Alignment {
        switch alignement {
        case .gauche: return .leading
        case .centre: return .center
        case .droite: return .trailing
        }
    }
}
#endif
