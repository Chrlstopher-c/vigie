#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Une ligne de la file du quart.
///
/// Elle est faite pour être lue en marchant : le genre, ce qu'il déclenche, le
/// temps d'attente, et l'engagement réel. Rien n'y est replié — un mandat dont
/// il faut ouvrir la fiche pour connaître l'accès n'est pas une autorisation
/// éclairée (H-61).
struct CarteDeQuart: View {
    let point: PointDeQuart
    let rang: Int

    var body: some View {
        // Le relief s'écrit ici, en toutes lettres : `Relief` est imbriqué dans
        // un type générique, une variable calculée devrait donc en nommer la
        // spécialisation — qui n'est pas celle de cette carte.
        CarteVigie(relief: point.ecritureOuverte ? .active : .bordee(point.genre.etat)) {
            VStack(alignment: .leading, spacing: Espace.standard) {
                entete
                Text(point.titre)
                    .corpsAccentue()
                    .foregroundStyle(Couleurs.encre)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                pied
                if let engagement = point.engagement { bandeEngagement(engagement) }
            }
        }
        .apparitionDouce(rang: rang)
        .reagitAuToucher()
    }

    private var entete: some View {
        HStack(spacing: Espace.serre) {
            Image(systemName: point.genre.symbole)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(point.genre.etat.teinte)
            PastilleEtat(point.genre.libelle, etat: point.genre.etat)
            Spacer(minLength: 0)
            attente
        }
    }

    /// L'attente se recalcule toute seule : une file relue toutes les quatre
    /// secondes avec un « il y a 3 min » figé mentirait à chaque battement.
    private var attente: some View {
        TimelineView(.periodic(from: .now, by: 30)) { contexte in
            Text(libelleAttente(maintenant: contexte.date))
                .monoMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
        }
    }

    private func libelleAttente(maintenant: Date) -> String {
        guard let depuis = point.depuis else { return "date inconnue" }
        return "attend \(Fraicheur.texte(depuis: depuis, maintenant: maintenant))"
    }

    private var pied: some View {
        HStack(spacing: Espace.serre) {
            PuceMono(point.detail)
            Text(point.genre.portee)
                .legende()
                .foregroundStyle(Couleurs.texteTertiaire)
            Spacer(minLength: 0)
        }
    }

    private func bandeEngagement(_ texte: String) -> some View {
        HStack(spacing: Espace.serre) {
            Image(systemName: point.ecritureOuverte ? "pencil.circle.fill" : "info.circle")
                .font(.system(size: 11))
            Text(texte)
                .monoPetit()
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundStyle(point.genre.etat.encreSurVoile)
        .padding(.horizontal, Espace.standard)
        .padding(.vertical, Espace.serre)
        .background(
            point.genre.etat.voile,
            in: RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous)
        )
    }
}
#endif
