// Jauge de quota (.qrow + .usage-track) : en-tête mono libellé / pourcentage,
// piste de 6 pt, remplissage animé dont la teinte suit l'utilisation.
#if canImport(SwiftUI)
import SwiftUI

public struct JaugeQuota: View {
    private let libelle: String
    private let utilisation: Double
    private let sousTexte: String?

    /// - Parameters:
    ///   - utilisation: 0…1 ; la teinte bascule à 70 % (vigilance) et 90 % (danger).
    ///   - sousTexte: mention de reset (« reset 17:00 · dans 2 h 12 »).
    public init(_ libelle: String, utilisation: Double, sousTexte: String? = nil) {
        self.libelle = libelle
        self.utilisation = utilisation.clampeUnite()
        self.sousTexte = sousTexte
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Espace.fin) {
            HStack(alignment: .firstTextBaseline) {
                Text(libelle)
                    .monoPetit()
                    .foregroundStyle(Couleurs.texteSecondaire)
                Spacer(minLength: 0)
                Text("\(Int((utilisation * 100).rounded())) %")
                    .monoPetit()
                    .foregroundStyle(teinte)
                    .fontWeight(utilisation >= 0.9 ? .bold : .regular)
            }
            BarreProgression(fraction: utilisation, teinte: teinte)
            if let sousTexte {
                Text(sousTexte)
                    .monoMinuscule()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    private var teinte: Color {
        if utilisation >= 0.9 { return Couleurs.etatDanger }
        if utilisation >= 0.7 { return Couleurs.etatVigilance }
        return Couleurs.etatSain
    }
}

extension Double {
    fileprivate func clampeUnite() -> Double { Swift.min(Swift.max(self, 0), 1) }
}
#endif
