// Étiquette d'outil du fil de mission (.tool-tag) : mono compact, teinte selon
// le genre d'évènement — l'œil trie le fil à la couleur avant de lire.
#if canImport(SwiftUI)
import SwiftUI

public enum GenreEvenement: Sendable {
    /// Appel d'outil ordinaire (Read, Bash…).
    case activite
    /// Autorisation résolue seule par le lead.
    case autorisationAuto
    /// Autorisation en attente d'arbitrage humain.
    case autorisationAttente
    /// Évènement système (pause, atterrissage, reprise).
    case systeme
    /// Instruction envoyée par Chris.
    case instruction

    var fond: Color {
        switch self {
        case .activite: Couleurs.fondProfond
        case .autorisationAuto: Couleurs.etatSainVoile
        case .autorisationAttente: Couleurs.accentPrimaire
        case .systeme: Couleurs.etatVigilanceVoile
        case .instruction: Couleurs.encre
        }
    }

    var encre: Color {
        switch self {
        case .activite: Couleurs.texteSecondaire
        case .autorisationAuto: Couleurs.etatSain
        case .autorisationAttente: .white
        case .systeme: Couleurs.encreVigilance
        case .instruction: Couleurs.texteSurSombre
        }
    }
}

public struct EtiquetteOutil: View {
    private let texte: String
    private let genre: GenreEvenement

    public init(_ texte: String, genre: GenreEvenement) {
        self.texte = texte
        self.genre = genre
    }

    public var body: some View {
        Text(texte)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(genre.encre)
            .padding(.horizontal, 7)
            .padding(.vertical, 1.5)
            .background(genre.fond,
                        in: RoundedRectangle(cornerRadius: Rayon.etiquette, style: .continuous))
    }
}
#endif
