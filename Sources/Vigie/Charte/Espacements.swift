// Échelle d'espacement, rayons et traits — valeurs relevées dans la maquette v2.
// Toute dimension hors de ces jetons est une faute de charte.
#if canImport(SwiftUI)
import SwiftUI

public enum Espace {
    /// Micro-écart : entre une étiquette et sa valeur.
    public static let fin: CGFloat = 4
    /// Écart serré : icône ↔ libellé dans un bouton.
    public static let serre: CGFloat = 7
    /// Écart standard entre éléments frères (gap 8-10 de la maquette).
    public static let standard: CGFloat = 9
    /// Écart interne d'une carte (padding 13-14).
    public static let carte: CGFloat = 14
    /// Marge d'écran horizontale (vbody 16).
    public static let ecran: CGFloat = 16
    /// Respiration entre sections.
    public static let section: CGFloat = 22
}

public enum Rayon {
    /// Tags d'outil, petits encarts mono.
    public static let etiquette: CGFloat = 6
    /// Boutons compacts, chips carrées, avatar de machine.
    public static let boutonPetit: CGFloat = 9
    /// Boutons standard, bandeaux, terminal.
    public static let bouton: CGFloat = 10
    /// Tuiles internes (jauges, stats, fil).
    public static let encart: CGFloat = 12
    /// Cartes.
    public static let carte: CGFloat = 14
    /// Champs de saisie (input-wrap).
    public static let champ: CGFloat = 16
    /// Modales, feuilles.
    public static let modale: CGFloat = 18
}

public enum Trait {
    /// Filet standard : bordures de cartes, séparateurs.
    public static let filet: CGFloat = 1
    /// Bordure appuyée : bouton destructif.
    public static let appuye: CGFloat = 1.5
    /// Bande latérale d'état d'une carte (mission active, morte, en pause).
    public static let bandeEtat: CGFloat = 4
    /// Hauteur d'une piste de jauge (usage-track).
    public static let jauge: CGFloat = 6
}

extension View {
    /// Ombre des éléments flottants (toasts, bouton de saut de fil).
    public func ombreFlottante() -> some View {
        shadow(color: Couleurs.ombrePortee, radius: 10, x: 0, y: 6)
    }

    /// Halo d'accent d'une carte active.
    public func ombreActive() -> some View {
        shadow(color: Couleurs.ombreAccent, radius: 7, x: 0, y: 3)
    }
}
#endif
