// Section d'écran : un titre serif (sec-title) et son contenu, avec la
// respiration standard. L'accessoire optionnel se pose à droite du titre
// (une pastille, un bouton compact).
#if canImport(SwiftUI)
import SwiftUI

public struct SectionVigie<Contenu: View, Accessoire: View>: View {
    private let titre: String
    private let accessoire: Accessoire
    private let contenu: Contenu

    public init(
        _ titre: String,
        @ViewBuilder contenu: () -> Contenu,
        @ViewBuilder accessoire: () -> Accessoire
    ) {
        self.titre = titre
        self.contenu = contenu()
        self.accessoire = accessoire()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            HStack(spacing: Espace.standard) {
                Text(titre)
                    .titreSection()
                    .foregroundStyle(Couleurs.encre)
                accessoire
            }
            contenu
        }
        .padding(.bottom, Espace.section - Espace.standard)
    }
}

extension SectionVigie where Accessoire == EmptyView {
    public init(_ titre: String, @ViewBuilder contenu: () -> Contenu) {
        self.init(titre, contenu: contenu, accessoire: { EmptyView() })
    }
}
#endif
