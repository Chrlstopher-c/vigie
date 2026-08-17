// Le vocabulaire d'état partagé par tous les composants : chaque état porte
// sa teinte pleine, son voile de fond et son encre lisible sur ce voile.
#if canImport(SwiftUI)
import SwiftUI

public enum EtatSemantique: Sendable {
    /// Nominal : lien établi, mission terminée proprement, quota confortable.
    case sain
    /// Attention sans urgence : pause, atterrissage, quota qui monte.
    case vigilance
    /// Rupture : lien coupé, mission morte, quota saturé.
    case danger
    /// Réclame une décision humaine : escalade, mandat en attente.
    case accent
    /// Purement informatif.
    case neutre

    /// Teinte pleine — points, bandes latérales, traits.
    public var teinte: Color {
        switch self {
        case .sain: Couleurs.etatSain
        case .vigilance: Couleurs.etatVigilance
        case .danger: Couleurs.etatDanger
        case .accent: Couleurs.accentPrimaire
        case .neutre: Couleurs.texteTertiaire
        }
    }

    /// Voile de fond — pastilles, bandeaux.
    public var voile: Color {
        switch self {
        case .sain: Couleurs.etatSainVoile
        case .vigilance: Couleurs.etatVigilanceVoile
        case .danger: Couleurs.etatDangerVoile
        case .accent: Couleurs.accentVoile
        case .neutre: Couleurs.fondProfond
        }
    }

    /// Encre lisible posée sur le voile.
    public var encreSurVoile: Color {
        switch self {
        case .sain: Couleurs.etatSain
        case .vigilance: Couleurs.encreVigilance
        case .danger: Couleurs.etatDanger
        case .accent: Couleurs.accentAppuye
        case .neutre: Couleurs.texteSecondaire
        }
    }
}
#endif
