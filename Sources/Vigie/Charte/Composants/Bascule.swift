// Bascule de réglage (.switch) : libellé + sous-libellé à gauche, interrupteur
// teinté accent à droite — la rangée entière des écrans Paramètres.
#if canImport(SwiftUI)
import SwiftUI

public struct BasculeVigie: View {
    private let libelle: String
    private let sousLibelle: String?
    @Binding private var active: Bool

    public init(_ libelle: String, sousLibelle: String? = nil, active: Binding<Bool>) {
        self.libelle = libelle
        self.sousLibelle = sousLibelle
        self._active = active
    }

    public var body: some View {
        Toggle(isOn: $active.animation(Mouvement.changementEtat)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(libelle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Couleurs.encre)
                if let sousLibelle {
                    Text(sousLibelle)
                        .legende()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
            }
        }
        .tint(Couleurs.accentPrimaire)
        .padding(.vertical, Espace.standard)
    }
}
#endif
