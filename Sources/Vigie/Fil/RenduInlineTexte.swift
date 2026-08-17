// Étage inline du rendu markdown : `[FragmentTexte]` → `Text`.
//
// Choix assumé (voir la consigne de `AnalyseurMarkdown`) : chaque fragment
// devient un `AttributedString` porteur d'un `InlinePresentationIntent`
// (gras/italique/code/barré) plutôt qu'un `Font` fixé en dur. `Text` sait
// rendre ces intentions sans qu'on lui impose une taille — le fragment
// HÉRITE donc du style posé par le conteneur (`.corps()`, `.titreSection()`,
// …), exactement comme le ferait `AttributedString(markdown:)`.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Concatène des fragments en un seul `Text` stylé.
func texteFragments(_ fragments: [FragmentTexte]) -> Text {
    fragments.reduce(Text(verbatim: "")) { accumule, fragment in
        accumule + Text(fragment.attribue)
    }
}

extension FragmentTexte {
    fileprivate var attribue: AttributedString {
        var chaine = AttributedString(texte)
        var intention: InlinePresentationIntent = []
        if styles.contains(.gras) { intention.insert(.stronglyEmphasized) }
        if styles.contains(.italique) { intention.insert(.emphasized) }
        if styles.contains(.code) { intention.insert(.code) }
        if styles.contains(.barre) { intention.insert(.strikethrough) }
        if !intention.isEmpty { chaine.inlinePresentationIntent = intention }
        if let lien, let cible = URL(string: lien) {
            chaine.link = cible
            chaine.foregroundColor = Couleurs.accentAppuye
            chaine.underlineStyle = .single
        }
        return chaine
    }
}
#endif
