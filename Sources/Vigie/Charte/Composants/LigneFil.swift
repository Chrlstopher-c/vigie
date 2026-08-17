// Ligne du fil de mission (.fitem) : horodatage mono à gauche, étiquette
// d'outil teintée par genre, corps du texte. Le fond passe en voile accent
// quand l'évènement attend un arbitrage.
#if canImport(SwiftUI)
import SwiftUI

public struct LigneFil: View {
    private let horodatage: String
    private let etiquette: String?
    private let genre: GenreEvenement
    private let texte: String
    private let rang: Int

    /// - Parameters:
    ///   - horodatage: « HH:MM:SS », déjà formaté par le domaine appelant.
    ///   - rang: position dans la vague d'apparition (cascade).
    public init(
        horodatage: String,
        etiquette: String? = nil,
        genre: GenreEvenement = .activite,
        texte: String,
        rang: Int = 0
    ) {
        self.horodatage = horodatage
        self.etiquette = etiquette
        self.genre = genre
        self.texte = texte
        self.rang = rang
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Espace.standard) {
            Text(horodatage)
                .monoMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: Espace.fin) {
                if let etiquette {
                    EtiquetteOutil(etiquette, genre: genre)
                }
                Text(texte)
                    .font(.system(size: 12))
                    .lineSpacing(3)
                    .foregroundStyle(Couleurs.encre)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Espace.serre)
        .background(genre == .autorisationAttente ? Couleurs.accentVoile : .clear)
        .apparitionDouce(rang: rang)
    }
}
#endif
