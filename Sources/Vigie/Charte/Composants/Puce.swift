// Puces : la puce mono d'information (.chip — noms de missions, quotas) et
// la puce de filtre sélectionnable (.fchip — tout / activité / autorisations).
#if canImport(SwiftUI)
import SwiftUI

/// Puce mono passive : fond creusé, coins 7 pt.
public struct PuceMono: View {
    private let texte: String

    public init(_ texte: String) {
        self.texte = texte
    }

    public var body: some View {
        Text(texte)
            .monoPetit()
            .foregroundStyle(Couleurs.texteSecondaire)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Couleurs.fondCreuse,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

/// Puce de filtre : capsule bordée, inversée en encre quand active.
public struct PuceFiltre: View {
    private let texte: String
    private let active: Bool
    private let action: () -> Void

    public init(_ texte: String, active: Bool, action: @escaping () -> Void) {
        self.texte = texte
        self.active = active
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(texte)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(active ? Couleurs.texteSurSombre : Couleurs.texteSecondaire)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(active ? Couleurs.encre : Couleurs.surface, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        active ? Couleurs.encre : Couleurs.filet,
                        lineWidth: Trait.filet
                    )
                )
        }
        .buttonStyle(.plain)
        .animation(Mouvement.changementEtat, value: active)
    }
}
#endif
