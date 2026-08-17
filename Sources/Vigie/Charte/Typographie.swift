// Échelle typographique de Vigie. Trois familles, comme la maquette :
// serif pour les titres et les chiffres vedettes (Source Serif 4 → New York,
// le serif système iOS, seul repli qui ne coûte aucun embarquement de police),
// sans (Inter → SF Pro) pour le corps, mono (JetBrains Mono → SF Mono) pour la donnée.
// Ces modificateurs ne posent JAMAIS de couleur : la couleur appartient à l'appelant.
#if canImport(SwiftUI)
import SwiftUI

extension View {

    // MARK: Serif — titres et chiffres

    /// Titre d'écran (h1 de la maquette, 19 px desktop).
    public func titreEcran() -> some View {
        font(.system(size: 19, weight: .medium, design: .serif))
    }

    /// Titre de modale ou de fiche.
    public func titreModale() -> some View {
        font(.system(size: 16, weight: .medium, design: .serif))
    }

    /// Titre de section (sec-title).
    public func titreSection() -> some View {
        font(.system(size: 14, weight: .medium, design: .serif))
    }

    /// Chiffre vedette d'une tuile de statistique (stat .v, 22 px).
    public func chiffreVedette() -> some View {
        font(.system(size: 22, weight: .medium, design: .serif))
    }

    /// Valeur d'une jauge (gauge .gv, 16 px).
    public func chiffreJauge() -> some View {
        font(.system(size: 16, weight: .regular, design: .serif))
    }

    // MARK: Sans — le corps

    /// Corps de lecture : bulles, descriptions (13.5 px, interligne aéré).
    public func corps() -> some View {
        font(.system(size: 13.5)).lineSpacing(4)
    }

    /// Corps accentué : titres de cartes de mission (13.5 px semibold).
    public func corpsAccentue() -> some View {
        font(.system(size: 13.5, weight: .semibold)).lineSpacing(3)
    }

    /// Texte secondaire : sous-titres, extraits, métadonnées lisibles (12.5 px).
    public func secondaire() -> some View {
        font(.system(size: 12.5)).lineSpacing(3)
    }

    /// Légende : hints, mentions sous un champ (11 px).
    public func legende() -> some View {
        font(.system(size: 11)).lineSpacing(2.5)
    }

    /// Libellé de bouton standard (12.5 px medium).
    public func libelleBouton() -> some View {
        font(.system(size: 12.5, weight: .medium))
    }

    /// Étiquette de rubrique : MAJUSCULES espacées (nav-label, stat .k).
    public func etiquette() -> some View {
        font(.system(size: 10, weight: .medium)).kerning(0.8).textCase(.uppercase)
    }

    /// Étiquette minuscule au-dessus d'un chiffre vedette.
    public func etiquetteMinuscule() -> some View {
        font(.system(size: 9.5, weight: .medium)).kerning(0.7).textCase(.uppercase)
    }

    // MARK: Mono — la donnée

    /// Donnée mono standard : valeurs clé-valeur, chemins (11.5 px).
    public func monoDonnee() -> some View {
        font(.system(size: 11.5, design: .monospaced))
    }

    /// Mono compact : chips, quotas, tags d'outil (10.5 px).
    public func monoPetit() -> some View {
        font(.system(size: 10.5, design: .monospaced))
    }

    /// Mono minuscule : horodatages du fil, méta de sidebar (9.5 px).
    public func monoMinuscule() -> some View {
        font(.system(size: 9.5, design: .monospaced))
    }

    /// Corps du terminal (13 px, interligne 1.7 comme le .codeblock).
    ///
    /// `☠` La teinte est posée ici et non par l'appelant : c'est le seul style
    /// destiné à un fond sombre, et sans elle le texte hérite de l'encre par
    /// défaut — exactement la couleur du fond du terminal. Noir sur noir.
    public func terminal() -> some View {
        font(.system(size: 13, design: .monospaced))
            .lineSpacing(6)
            .foregroundStyle(Couleurs.terminalTexte)
    }
}
#endif
