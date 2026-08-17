// Matières et profondeur.
//
// La maquette web n'a qu'un plan : des rectangles blancs sur du crème. iOS en a
// trois — le fond, la surface, et ce qui flotte au-dessus en laissant deviner
// ce qu'il cache. C'est cette troisième couche qui manque le plus à une
// transposition littérale du web.
#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Barre flottante : matière translucide, filet, et l'ombre qui la décolle.
    /// Pour les en-têtes, les barres d'action et tout ce qui surplombe du
    /// contenu défilant.
    func matiereFlottante(coins: CGFloat = Rayon.carte) -> some View {
        background(.regularMaterial, in: .rect(cornerRadius: coins))
            .overlay {
                RoundedRectangle(cornerRadius: coins)
                    .strokeBorder(Couleurs.filet.opacity(0.7), lineWidth: 0.5)
            }
            .shadow(color: Couleurs.ombrePortee.opacity(0.5), radius: 18, y: 8)
    }

    /// Élévation d'une carte selon son rang d'attention. Deux ombres
    /// superposées : une courte et dense qui pose le contact, une longue et
    /// diffuse qui donne la hauteur. C'est ce qui sépare une ombre iOS d'un
    /// `box-shadow` par défaut.
    func elevation(_ niveau: Elevation = .posee) -> some View {
        shadow(color: niveau.contact, radius: niveau.rayonCourt, y: niveau.decalageCourt)
            .shadow(color: niveau.diffuse, radius: niveau.rayonLong, y: niveau.decalageLong)
    }

    /// Halo d'accent pour une carte qui réclame une décision : l'orange à
    /// faible opacité, diffusé large. Se substitue à une bordure épaisse, qui
    /// alourdit.
    func haloAttention(actif: Bool = true) -> some View {
        shadow(
            color: actif ? Couleurs.ombreAccent : .clear,
            radius: actif ? 22 : 0,
            y: 6
        )
    }
}

public enum Elevation: Sendable {
    /// Posée sur le fond : cartes de liste.
    case posee
    /// Détachée : carte sélectionnée, élément saisi par un geste.
    case detachee
    /// En vol : feuille, menu contextuel, élément déplacé.
    case enVol

    var contact: Color {
        Couleurs.ombrePortee.opacity(self == .posee ? 0.10 : 0.14)
    }

    var diffuse: Color {
        switch self {
        case .posee: Couleurs.ombrePortee.opacity(0.06)
        case .detachee: Couleurs.ombrePortee.opacity(0.12)
        case .enVol: Couleurs.ombrePortee.opacity(0.20)
        }
    }

    var rayonCourt: CGFloat { self == .posee ? 2 : 3 }
    var decalageCourt: CGFloat { 1 }

    var rayonLong: CGFloat {
        switch self {
        case .posee: 8
        case .detachee: 16
        case .enVol: 30
        }
    }

    var decalageLong: CGFloat {
        switch self {
        case .posee: 3
        case .detachee: 8
        case .enVol: 16
        }
    }
}

/// Voile animé posé derrière les zones qui doivent respirer — l'accueil, un
/// écran vide. Trois taches de couleur qui dérivent lentement, à peine
/// perceptibles sur le crème.
///
/// `⚠` `MeshGradient` est une nouveauté iOS 18 rendue par Metal. Sur A12 elle
/// tient les 60 Hz en pleine largeur, mais uniquement floutée et à faible
/// opacité : à pleine intensité elle trahit la sobriété de la charte.
public struct VoileVivant: View {
    private let teintes: [Color]

    public init(teintes: [Color] = [Couleurs.accentVoile, Couleurs.fondCreuse, Couleurs.fond]) {
        self.teintes = teintes
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { contexte in
            let t = contexte.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: sommets(a: t), colors: palette)
                .blur(radius: 40)
                .opacity(0.55)
        }
        .allowsHitTesting(false)
    }

    private var palette: [Color] {
        let base = Couleurs.fond
        let voile = teintes.first ?? Couleurs.accentVoile
        let creuse = teintes.count > 1 ? teintes[1] : Couleurs.fondCreuse
        return [base, voile, base, creuse, voile, base, base, creuse, base]
    }

    private func sommets(a temps: TimeInterval) -> [SIMD2<Float>] {
        let x = Float(sin(temps * 0.11) * 0.10)
        let y = Float(cos(temps * 0.08) * 0.09)
        return [
            SIMD2(0, 0), SIMD2(0.5 + x, 0), SIMD2(1, 0),
            SIMD2(0, 0.5 + y), SIMD2(0.5 + y, 0.5 - x), SIMD2(1, 0.5 - y),
            SIMD2(0, 1), SIMD2(0.5 - x, 1), SIMD2(1, 1),
        ]
    }
}
#endif
