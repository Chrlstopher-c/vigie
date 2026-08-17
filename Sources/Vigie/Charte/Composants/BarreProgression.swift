// Barre de progression nue (usage-track / usage-fill) et indicateur d'activité.
// La barre déterminée anime sa largeur ; l'indéterminée fait glisser un reflet.
#if canImport(SwiftUI)
import SwiftUI

/// Piste capsule de 6 pt dont le remplissage suit `fraction` (0…1).
public struct BarreProgression: View {
    private let fraction: Double
    private let teinte: Color

    public init(fraction: Double, teinte: Color = Couleurs.etatSain) {
        self.fraction = min(max(fraction, 0), 1)
        self.teinte = teinte
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Couleurs.fondCreuse)
                Capsule()
                    .fill(teinte)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: Trait.jauge)
        .animation(Mouvement.progression, value: fraction)
        .animation(Mouvement.progression, value: teinte)
    }
}

/// Barre indéterminée : reflet qui balaie la piste (skeleton shimmer, 1.4 s).
public struct BarreIndeterminee: View {
    @State private var phase: CGFloat = -1

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Couleurs.fondCreuse)
                Capsule()
                    .fill(Couleurs.filetAppuye)
                    .frame(width: geo.size.width * 0.35)
                    .offset(x: phase * geo.size.width)
            }
        }
        .frame(height: Trait.jauge)
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

/// Indicateur d'activité circulaire — arc qui tourne, jamais le spinner système.
public struct IndicateurActivite: View {
    private let diametre: CGFloat

    public init(diametre: CGFloat = 16) {
        self.diametre = diametre
    }

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(Couleurs.accentPrimaire,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: diametre, height: diametre)
            .rotationContinue()
    }
}
#endif
