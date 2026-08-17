#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// L'en-tête commun à toutes les racines de domaine : le titre, et à droite ce
/// que le domaine veut y mettre.
///
/// Vit dans la coquille et non dans la charte : c'est du mobilier de navigation,
/// il connaît `Domaine`. La charte, elle, ne connaît aucun domaine.
public struct EnteteDomaine<Accessoire: View>: View {
    private let titre: String
    private let releveA: Date?
    private let accessoire: Accessoire

    public init(
        _ domaine: Domaine,
        releveA: Date? = nil,
        @ViewBuilder accessoire: () -> Accessoire = { EmptyView() }
    ) {
        titre = domaine.titre
        self.releveA = releveA
        self.accessoire = accessoire()
    }

    public init(
        titre: String,
        releveA: Date? = nil,
        @ViewBuilder accessoire: () -> Accessoire = { EmptyView() }
    ) {
        self.titre = titre
        self.releveA = releveA
        self.accessoire = accessoire()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Espace.standard) {
            Text(titre)
                .titreEcran()
                .foregroundStyle(Couleurs.encre)
            Spacer(minLength: 0)
            // La fraîcheur au même rang que le titre : l'âge de la donnée n'est
            // pas une mention de bas de page, c'est ce qui dit si l'écran vaut
            // qu'on s'y fie.
            if let releveA { IndicateurFraicheur(releveA: releveA) }
            accessoire
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.vertical, Espace.standard)
    }
}
#endif
