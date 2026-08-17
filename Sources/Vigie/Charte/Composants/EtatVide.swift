// État vide (.empty-state) : symbole discret, titre court, phrase d'explication.
// Un écran vide dit toujours pourquoi il est vide et ce qui le remplira.
#if canImport(SwiftUI)
import SwiftUI

public struct EtatVide: View {
    private let symbole: String
    private let titre: String
    private let explication: String

    /// - Parameter symbole: nom SF Symbols (ex. « tray », « checkmark.circle »).
    public init(symbole: String, titre: String, explication: String) {
        self.symbole = symbole
        self.titre = titre
        self.explication = explication
    }

    public var body: some View {
        VStack(spacing: Espace.standard) {
            Image(systemName: symbole)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Couleurs.texteTertiaire.opacity(0.6))
            Text(titre)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Couleurs.texteSecondaire)
            Text(explication)
                .legende()
                .foregroundStyle(Couleurs.texteTertiaire)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .apparitionDouce()
    }
}
#endif
