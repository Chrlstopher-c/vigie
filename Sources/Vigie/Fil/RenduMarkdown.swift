// Le rendu markdown de Vigie, étage VUES. `AnalyseurMarkdown` (VigieNoyau, pur)
// fait le travail difficile ; ce fichier ne fait que poser un `View` sur
// chaque `BlocMarkdown`. Titres, paragraphes, citations et filets ici — listes,
// tableaux et code dans leurs propres fichiers, chacun assez dense pour le
// mériter.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Rend une source markdown complète. C'est LE composant qui manque à
/// `AttributedString(markdown:)` : titres, listes, tableaux, blocs de code.
public struct RenduMarkdown: View {
    private let blocs: [BlocRange]

    public init(_ source: String) {
        blocs = AnalyseurMarkdown.blocs(source)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            ForEach(blocs) { entree in
                vue(pour: entree.bloc)
            }
        }
    }

    @ViewBuilder
    private func vue(pour bloc: BlocMarkdown) -> some View {
        switch bloc {
        case .titre(let niveau, let contenu):
            vueTitre(niveau: niveau, contenu: contenu)
        case .paragraphe(let contenu):
            texteFragments(contenu)
                .corps()
                .foregroundStyle(Couleurs.encre)
                .textSelection(.enabled)
        case .liste(let entrees):
            vueListe(entrees)
        case .code(let langage, let texte, let ouvert):
            vueCode(langage: langage, texte: texte, ouvert: ouvert)
        case .tableau(let table):
            vueTableau(table)
        case .citation(let contenu):
            vueCitation(contenu)
        case .filet:
            FiletHorizontal().padding(.vertical, Espace.fin)
        }
    }

    @ViewBuilder
    private func vueTitre(niveau: Int, contenu: [FragmentTexte]) -> some View {
        let texte = texteFragments(contenu).foregroundStyle(Couleurs.encre)
        switch niveau {
        case 1: texte.titreModale()
        case 2: texte.titreSection()
        default: texte.corpsAccentue()
        }
    }

    private func vueCitation(_ contenu: [FragmentTexte]) -> some View {
        HStack(alignment: .top, spacing: Espace.serre) {
            Rectangle()
                .fill(Couleurs.filetAppuye)
                .frame(width: 3)
            texteFragments(contenu)
                .secondaire()
                .foregroundStyle(Couleurs.texteSecondaire)
                .italic()
        }
    }
}
#endif
