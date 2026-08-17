// Tuile de statistique (.stat) : étiquette minuscule au-dessus d'un chiffre
// vedette serif. La rangée de six compteurs du Pouls, c'est elle.
#if canImport(SwiftUI)
import SwiftUI

public struct TuileStatistique: View {
    private let etiquette: String
    private let valeur: String
    private let alerte: Bool

    /// - Parameter alerte: bascule la tuile en accent (compteur qui réclame l'œil).
    public init(_ etiquette: String, valeur: String, alerte: Bool = false) {
        self.etiquette = etiquette
        self.valeur = valeur
        self.alerte = alerte
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(etiquette)
                .etiquetteMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
            Text(valeur)
                .chiffreVedette()
                .foregroundStyle(alerte ? Couleurs.accentAppuye : Couleurs.encre)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 96, alignment: .leading)
        .background(alerte ? Couleurs.accentVoile : Couleurs.surface,
                    in: RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
                .strokeBorder(alerte ? Couleurs.accentPrimaire : Couleurs.filet,
                              lineWidth: Trait.filet)
        )
        .animation(Mouvement.changementEtat, value: alerte)
        .animation(Mouvement.progression, value: valeur)
    }
}
#endif
