// Le bloc en cours de frappe — le seul régime où la cadence de 400 ms se
// justifie (voir `Cadence.Regime.generation`). Rendu à chaque sondage, donc
// re-analysé en markdown à chaque fois : `AnalyseurMarkdown` est pur et rapide
// sur un texte de quelques lignes, et un bloc encore ouvert (code non refermé,
// tableau incomplet) n'est pas une erreur, voir `BlocMarkdown.code(ouvert:)`.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct BlocPartielVue: View {
    let partiel: PartielApi

    var body: some View {
        BulleAgent {
            VStack(alignment: .leading, spacing: Espace.serre) {
                contenu
                Respiration(teinte: Couleurs.texteTertiaire)
            }
        }
        .id("partiel-en-cours")
    }

    @ViewBuilder private var contenu: some View {
        switch partiel.type {
        case .reflexion:
            VStack(alignment: .leading, spacing: Espace.fin) {
                HStack(spacing: Espace.serre) {
                    Image(systemName: "bubble.left.and.text.bubble.right").font(.system(size: 10.5))
                    Text("Raisonnement").legende()
                }
                .foregroundStyle(Couleurs.texteTertiaire)
                Text(partiel.contenu)
                    .secondaire()
                    .foregroundStyle(Couleurs.texteSecondaire)
                    .italic()
            }
        default:
            RenduMarkdown(partiel.contenu)
        }
    }
}
#endif
