// Bulles du fil de conversation. L'utilisateur parle en encre sur bulle
// asymétrique (coin bas-droit cassé) ; l'agent répond à nu sur le fond —
// exactement la maquette (.bubble-u / .bubble-a). L'appel d'outil est un
// encart mono bordé au fil du texte.
#if canImport(SwiftUI)
import SwiftUI

/// Message de Chris : aligné à droite, 84 % de largeur max.
public struct BulleUtilisateur: View {
    private let texte: String

    public init(_ texte: String) {
        self.texte = texte
    }

    public var body: some View {
        Text(texte)
            .corps()
            .foregroundStyle(Couleurs.texteSurSombre)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                Couleurs.encre,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 14, bottomLeadingRadius: 14,
                    bottomTrailingRadius: 4, topTrailingRadius: 14,
                    style: .continuous
                )
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 54)
            .apparitionDouce()
    }
}

/// Réponse de l'agent : contenu à nu, pleine largeur — le rendu markdown
/// du domaine Fil se glisse dans `contenu`.
public struct BulleAgent<Contenu: View>: View {
    private let contenu: Contenu

    public init(@ViewBuilder contenu: () -> Contenu) {
        self.contenu = contenu()
    }

    public var body: some View {
        contenu
            .corps()
            .foregroundStyle(Couleurs.encre)
            .frame(maxWidth: .infinity, alignment: .leading)
            .apparitionDouce()
    }
}

/// Appel d'outil au fil de la réponse (bubble-a .tool).
public struct EncartOutil: View {
    private let texte: String

    public init(_ texte: String) {
        self.texte = texte
    }

    public var body: some View {
        Text(texte)
            .monoDonnee()
            .foregroundStyle(Couleurs.texteSecondaire)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Couleurs.surface,
                        in: RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
                    .strokeBorder(Couleurs.filet, lineWidth: Trait.filet)
            )
            .apparitionDouce()
    }
}
#endif
