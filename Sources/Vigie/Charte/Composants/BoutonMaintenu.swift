// Bouton à maintien (.arm-track) : l'action engageante ne part qu'après 1,5 s
// de pression continue — le remplissage rouge matérialise l'armement, lâcher
// avant la fin annule. Réservé aux gestes irréversibles.
#if canImport(SwiftUI)
import SwiftUI

public struct BoutonMaintenu: View {
    private static let dureeArmement: Double = 1.5

    private let libelle: String
    private let libelleArme: String
    private let action: () -> Void
    @State private var progression: CGFloat = 0
    @State private var arme = false

    public init(_ libelle: String, libelleArme: String = "Armé", action: @escaping () -> Void) {
        self.libelle = libelle
        self.libelleArme = libelleArme
        self.action = action
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
                    .fill(Couleurs.etatDangerVoile)
                RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
                    .fill(Couleurs.etatDanger)
                    .frame(width: geo.size.width * progression)
                Text(arme ? libelleArme : libelle)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(arme ? .white : Couleurs.etatDanger)
                    .frame(maxWidth: .infinity)
                    .animation(Mouvement.changementEtat, value: arme)
            }
        }
        .frame(height: 46)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous))
        .onLongPressGesture(
            minimumDuration: Self.dureeArmement,
            perform: declencher,
            onPressingChanged: pressionChangee
        )
        .sensoryFeedback(.success, trigger: arme)
    }

    private func declencher() {
        arme = true
        progression = 1
        action()
    }

    private func pressionChangee(_ appuye: Bool) {
        if appuye {
            withAnimation(.linear(duration: Self.dureeArmement)) { progression = 1 }
        } else if !arme {
            withAnimation(Mouvement.reponseImmediate) { progression = 0 }
        }
    }
}
#endif
