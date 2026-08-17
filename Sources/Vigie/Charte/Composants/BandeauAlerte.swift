// Bandeau d'alerte (.error-state / .linkbanner) : voile d'état, symbole,
// texte dense. C'est lui qui annonce « Lien Pi↔PC coupé — états datés ».
#if canImport(SwiftUI)
import SwiftUI

public struct BandeauAlerte: View {
    private let texte: String
    private let etat: EtatSemantique
    private let symbole: String

    /// - Parameter symbole: SF Symbol ; par défaut selon l'état.
    public init(_ texte: String, etat: EtatSemantique, symbole: String? = nil) {
        self.texte = texte
        self.etat = etat
        self.symbole = symbole ?? Self.symboleParDefaut(pour: etat)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Espace.standard) {
            Image(systemName: symbole)
                .font(.system(size: 12, weight: .medium))
                .padding(.top, 1)
            Text(texte)
                .legende()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(etat.encreSurVoile)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(etat.voile,
                    in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous))
        .apparitionDouce()
    }

    private static func symboleParDefaut(pour etat: EtatSemantique) -> String {
        switch etat {
        case .sain: "checkmark.circle"
        case .vigilance: "exclamationmark.triangle"
        case .danger: "bolt.horizontal.circle"
        case .accent: "hand.raised"
        case .neutre: "info.circle"
        }
    }
}
#endif
