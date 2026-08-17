// Pastille d'état (.badge) et point vital (.sdot / dot-live) : les deux
// témoins d'état les plus fréquents de l'app.
#if canImport(SwiftUI)
import SwiftUI

/// Capsule d'état : voile de fond + encre lisible (« actif », « saturé », « périmé »).
public struct PastilleEtat: View {
    private let texte: String
    private let etat: EtatSemantique

    public init(_ texte: String, etat: EtatSemantique) {
        self.texte = texte
        self.etat = etat
    }

    public var body: some View {
        Text(texte)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(etat.encreSurVoile)
            .padding(.horizontal, 8)
            .padding(.vertical, 2.5)
            .background(etat.voile, in: Capsule())
            .animation(Mouvement.changementEtat, value: texte)
    }
}

/// Point d'état de 8 pt. `vivant` le fait respirer (mission active, lien établi).
public struct PointVital: View {
    private let etat: EtatSemantique
    private let vivant: Bool

    public init(etat: EtatSemantique, vivant: Bool = false) {
        self.etat = etat
        self.vivant = vivant
    }

    public var body: some View {
        Circle()
            .fill(etat.teinte)
            .frame(width: 8, height: 8)
            .modifier(PulsationSiVivant(vivant: vivant))
            .animation(Mouvement.changementEtat, value: vivant)
    }
}

private struct PulsationSiVivant: ViewModifier {
    let vivant: Bool

    func body(content: Content) -> some View {
        if vivant { content.pulsationVitale() } else { content }
    }
}
#endif
