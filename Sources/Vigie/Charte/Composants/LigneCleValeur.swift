// Ligne clé-valeur (.kv de la maquette) : clé grise à gauche, valeur mono
// à droite, filet sous chaque ligne sauf la dernière.
#if canImport(SwiftUI)
import SwiftUI

public struct LigneCleValeur: View {
    private let cle: String
    private let valeur: String
    private let teinteValeur: Color
    private let derniere: Bool

    /// - Parameters:
    ///   - teinteValeur: par défaut l'encre ; passer une teinte d'état pour signaler.
    ///   - derniere: supprime le filet de fermeture sur la dernière ligne d'un bloc.
    public init(
        _ cle: String,
        valeur: String,
        teinteValeur: Color = Couleurs.encre,
        derniere: Bool = false
    ) {
        self.cle = cle
        self.valeur = valeur
        self.teinteValeur = teinteValeur
        self.derniere = derniere
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Espace.carte) {
                Text(cle)
                    .secondaire()
                    .foregroundStyle(Couleurs.texteTertiaire)
                Spacer(minLength: 0)
                Text(valeur)
                    .monoDonnee()
                    .foregroundStyle(teinteValeur)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, Espace.serre)
            if !derniere { FiletHorizontal() }
        }
        .animation(Mouvement.changementEtat, value: valeur)
    }
}
#endif
