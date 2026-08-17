// Filets et séparateurs — le seul trait autorisé entre deux contenus.
#if canImport(SwiftUI)
import SwiftUI

/// Filet horizontal d'un point, couleur `filet`.
public struct FiletHorizontal: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Couleurs.filet)
            .frame(height: Trait.filet)
    }
}

/// Point séparateur entre deux métadonnées inline (divider-dot).
public struct PointSeparateur: View {
    public init() {}

    public var body: some View {
        Circle()
            .fill(Couleurs.texteTertiaire)
            .frame(width: 3, height: 3)
    }
}
#endif
