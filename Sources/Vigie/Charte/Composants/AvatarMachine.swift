// Avatar de machine (brand-mark) : carré arrondi encre portant les initiales
// mono du nom d'hôte, point d'état optionnel en coin.
#if canImport(SwiftUI)
import SwiftUI

public struct AvatarMachine: View {
    private let nom: String
    private let cote: CGFloat
    private let etat: EtatSemantique?

    /// - Parameters:
    ///   - nom: nom d'hôte ; seules les deux premières lettres s'affichent.
    ///   - etat: si non nil, point d'état posé sur le coin bas-droit.
    public init(nom: String, cote: CGFloat = 28, etat: EtatSemantique? = nil) {
        self.nom = nom
        self.cote = cote
        self.etat = etat
    }

    public var body: some View {
        Text(initiales)
            .font(.system(size: cote * 0.38, weight: .semibold, design: .monospaced))
            .foregroundStyle(Couleurs.texteSurSombre)
            .frame(width: cote, height: cote)
            .background(Couleurs.encre,
                        in: RoundedRectangle(cornerRadius: cote * 0.25, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if let etat {
                    PointVital(etat: etat, vivant: etat == .sain)
                        .overlay(Circle().strokeBorder(Couleurs.fond, lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }
    }

    private var initiales: String {
        String(nom.uppercased().prefix(2))
    }
}
#endif
