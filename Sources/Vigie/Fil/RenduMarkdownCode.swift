// Rendu des blocs de code. Réutilise `ZoneTerminal` de la charte, le seul
// îlot sombre de l'app — le bloc de code EST un terminal, visuellement.
#if canImport(SwiftUI)
import SwiftUI

extension RenduMarkdown {

    func vueCode(langage: String?, texte: String, ouvert: Bool) -> some View {
        VStack(alignment: .leading, spacing: Espace.fin) {
            if langage != nil || ouvert {
                enTeteCode(langage: langage, ouvert: ouvert)
            }
            ZoneTerminal(texte, repliement: true)
        }
    }

    private func enTeteCode(langage: String?, ouvert: Bool) -> some View {
        HStack(spacing: Espace.serre) {
            if let langage {
                PuceMono(langage)
            }
            Spacer(minLength: 0)
            // `ouvert` = la clôture n'est pas encore arrivée : le régime NORMAL
            // pendant que l'orchestrateur écrit, pas une erreur de syntaxe.
            if ouvert {
                PointVital(etat: .neutre, vivant: true)
            }
        }
    }
}
#endif
