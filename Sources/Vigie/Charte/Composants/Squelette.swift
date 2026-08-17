// Squelette de chargement (.skeleton) : bloc crème traversé d'un reflet.
// Réservé au tout premier remplissage d'une zone — dès qu'un miroir existe,
// on montre la donnée datée, pas un squelette.
#if canImport(SwiftUI)
import SwiftUI

public struct SqueletteVigie: View {
    private let hauteur: CGFloat
    @State private var phase: CGFloat = -1

    public init(hauteur: CGFloat = 14) {
        self.hauteur = hauteur
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Couleurs.fondCreuse)
            .frame(height: hauteur)
            .overlay(reflet)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }

    private var reflet: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Couleurs.fondProfond, .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.6)
            .offset(x: phase * geo.size.width)
        }
    }
}
#endif
