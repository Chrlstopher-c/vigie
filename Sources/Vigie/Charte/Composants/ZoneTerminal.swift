// Zone terminal (.codeblock) : le seul îlot sombre de l'app — encre pleine,
// texte crème chaud, mono 13, défilement horizontal sans retour à la ligne.
// Sert au terminal tmux comme aux blocs de code du markdown.
#if canImport(SwiftUI)
import SwiftUI

public struct ZoneTerminal: View {
    private let texte: String
    private let repliement: Bool

    /// - Parameter repliement: true pour les blocs de code markdown (retour à la
    ///   ligne) ; false pour le terminal (défilement horizontal, lignes intactes).
    public init(_ texte: String, repliement: Bool = false) {
        self.texte = texte
        self.repliement = repliement
    }

    public var body: some View {
        Group {
            if repliement {
                corpsTexte
            } else {
                ScrollView(.horizontal, showsIndicators: false) { corpsTexte }
            }
        }
        .background(Couleurs.terminalFond,
                    in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous))
    }

    private var corpsTexte: some View {
        Text(texte)
            .terminal()
            .foregroundStyle(Couleurs.terminalTexte)
            .textSelection(.enabled)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
