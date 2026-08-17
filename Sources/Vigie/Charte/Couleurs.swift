// Palette sémantique de Vigie — valeurs relevées telles quelles dans
// ccremote/design-v2/index.html (DA validée par Chris : crème / serif / orange).
// Thème unique clair : la maquette n'a pas de variante sombre, on n'en invente pas.
#if canImport(SwiftUI)
import SwiftUI

public enum Couleurs {

    // MARK: Fonds — du plus proche au plus creusé
    /// Fond général de tout écran (crème). Jamais de blanc pur en fond de vue.
    public static let fond = Color(hexa: 0xFAF9F5)
    /// Zones en retrait : pistes de jauge, fond du fil, bandeaux secondaires.
    public static let fondCreuse = Color(hexa: 0xF0EEE6)
    /// Le cran encore en dessous : tags neutres, compteurs de navigation.
    public static let fondProfond = Color(hexa: 0xE9E6DB)
    /// Surface des cartes — le seul blanc pur de la palette.
    public static let surface = Color(hexa: 0xFFFFFF)

    // MARK: Encres
    /// Texte principal, boutons primaires, bulles utilisateur.
    public static let encre = Color(hexa: 0x1F1E1D)
    /// Encre enfoncée — état pressé d'un fond `encre`.
    public static let encrePressee = Color(hexa: 0x2C2A28)
    public static let texteSecondaire = Color(hexa: 0x4A4845)
    public static let texteTertiaire = Color(hexa: 0x86827B)
    /// Texte posé sur un fond `encre` ou `accentPrimaire`.
    public static let texteSurSombre = Color(hexa: 0xFAF9F5)

    // MARK: Filets
    /// Bordure standard des cartes et séparateurs.
    public static let filet = Color(hexa: 0xE5E1D8)
    /// Bordure appuyée : champs de saisie, éléments survolables.
    public static let filetAppuye = Color(hexa: 0xD8D3C6)

    // MARK: Accent — l'orange Anthropic, réservé à ce qui réclame l'attention
    public static let accentPrimaire = Color(hexa: 0xD97757)
    /// Accent enfoncé — état pressé, liens.
    public static let accentAppuye = Color(hexa: 0xC15F3C)
    /// Voile d'accent — fonds de cartes actives, pastilles.
    public static let accentVoile = Color(hexa: 0xF4E4DC)

    // MARK: États sémantiques — teinte pleine + voile de fond
    public static let etatSain = Color(hexa: 0x5E8C61)
    public static let etatSainVoile = Color(hexa: 0xE3EDE3)
    public static let etatVigilance = Color(hexa: 0xC99A2E)
    public static let etatVigilanceVoile = Color(hexa: 0xF5EACF)
    /// Texte lisible sur `etatVigilanceVoile` (le jaune plein ne contraste pas).
    public static let encreVigilance = Color(hexa: 0x8A6A12)
    public static let etatDanger = Color(hexa: 0xB5524A)
    public static let etatDangerVoile = Color(hexa: 0xE8C9C6)

    // MARK: Terminal — seul îlot sombre de l'app, repris du .codeblock de la prod
    public static let terminalFond = Color(hexa: 0x1F1E1D)
    public static let terminalTexte = Color(hexa: 0xE8E4D8)

    // MARK: Ombres
    /// Ombre portée des éléments flottants (toasts, sauts de fil).
    public static let ombrePortee = Color.black.opacity(0.18)
    /// Halo des cartes actives — l'accent à 16 %.
    public static let ombreAccent = Color(hexa: 0xD97757).opacity(0.16)
    /// Voile derrière une modale.
    public static let voileModal = Color(hexa: 0x1F1E1D).opacity(0.28)
}

extension Color {
    /// 0xRRGGBB → Color. Interne à la charte : hors d'ici, on ne parle qu'en jetons.
    fileprivate init(hexa: UInt32) {
        self.init(
            red: Double((hexa >> 16) & 0xFF) / 255,
            green: Double((hexa >> 8) & 0xFF) / 255,
            blue: Double(hexa & 0xFF) / 255
        )
    }
}
#endif
