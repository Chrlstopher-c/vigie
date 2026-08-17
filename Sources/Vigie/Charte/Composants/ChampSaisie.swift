// Champ de saisie (.input-wrap / .field) : enveloppe blanche à rayon 16,
// filet appuyé qui fonce au focus, étiquette et aide optionnelles, erreur inline.
#if canImport(SwiftUI)
import SwiftUI

public struct ChampSaisie: View {
    private let etiquette: String?
    private let placebo: String
    private let aide: String?
    private let erreur: String?
    private let lignes: ClosedRange<Int>
    @Binding private var texte: String
    @FocusState private var enFocus: Bool

    /// - Parameters:
    ///   - placebo: texte fantôme du champ vide.
    ///   - aide: mention grise sous le champ (hint).
    ///   - erreur: si non nil, le champ passe en faute et l'affiche.
    public init(
        _ etiquette: String? = nil,
        texte: Binding<String>,
        placebo: String = "",
        aide: String? = nil,
        erreur: String? = nil,
        lignes: ClosedRange<Int> = 1...4
    ) {
        self.etiquette = etiquette
        self._texte = texte
        self.placebo = placebo
        self.aide = aide
        self.erreur = erreur
        self.lignes = lignes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let etiquette {
                Text(etiquette)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Couleurs.texteSecondaire)
            }
            TextField(placebo, text: $texte, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(Couleurs.encre)
                .lineLimit(lignes)
                .focused($enFocus)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(Couleurs.surface,
                            in: RoundedRectangle(cornerRadius: Rayon.champ, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Rayon.champ, style: .continuous)
                        .strokeBorder(couleurBord, lineWidth: Trait.filet)
                )
                .animation(Mouvement.changementEtat, value: enFocus)
            if let erreur {
                Text(erreur)
                    .legende()
                    .foregroundStyle(Couleurs.etatDanger)
                    .padding(Espace.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Couleurs.etatDangerVoile,
                                in: RoundedRectangle(cornerRadius: Rayon.boutonPetit))
                    .apparitionDouce()
            } else if let aide {
                Text(aide)
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    private var couleurBord: Color {
        if erreur != nil { return Couleurs.etatDanger }
        return enFocus ? Couleurs.texteTertiaire : Couleurs.filetAppuye
    }
}
#endif
