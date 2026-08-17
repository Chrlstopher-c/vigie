// Section « À propos » des Réglages : version, identifiant du bundle, et
// l'échéance de la signature — l'information la plus utile de l'écran, la
// signature en free provisioning expirant tous les sept jours SANS AVERTIR.
// Le diagnostic caché s'ouvre par un appui long sur la ligne de version,
// jamais par un bouton : voir `feuille(presentee:)` en bas de fichier.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct SectionAPropos: View {
    @State private var expiration: Date?
    @State private var diagnosticVisible = false

    var body: some View {
        SectionVigie("À propos") {
            CarteVigie {
                VStack(spacing: 0) {
                    LigneCleValeur("Bundle", valeur: Self.bundleId)
                    ligneVersion
                    blocExpiration
                }
            }
        }
        .task { chargerExpiration() }
        .sensoryFeedback(Retour.engagement, trigger: diagnosticVisible) { _, nouveau in nouveau }
        .feuille(presentee: $diagnosticVisible, hauteurs: [.large]) { DiagnosticEcran() }
    }

    private var ligneVersion: some View {
        LigneCleValeur("Version", valeur: "\(Self.version) (\(Self.build))")
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.6) { diagnosticVisible = true }
    }

    @ViewBuilder private var blocExpiration: some View {
        if let expiration {
            VStack(alignment: .leading, spacing: Espace.fin) {
                JaugeQuota(
                    "Signature",
                    utilisation: Self.fractionEcoulee(jusqua: expiration),
                    sousTexte: Self.libelleExpiration(jusqua: expiration)
                )
            }
            .padding(.top, Espace.standard)
        } else {
            LigneCleValeur("Signature", valeur: "illisible", teinteValeur: Couleurs.texteTertiaire, derniere: true)
        }
    }

    // MARK: - Lecture disque

    /// `☠` Un profil illisible n'est pas une panne : l'app tourne quand même,
    /// on perd seulement l'avertissement — voir `ExpirationSignature.lire`.
    private func chargerExpiration() {
        guard let url = Bundle.main.url(
            forResource: ExpirationSignature.nomFichier,
            withExtension: ExpirationSignature.extensionFichier
        ) else {
            Trace.info("reglages", "profil de provisionnement absent du bundle")
            return
        }
        do {
            expiration = ExpirationSignature.lire(try Data(contentsOf: url))
        } catch {
            Trace.erreur("reglages", "profil de provisionnement illisible", error)
        }
    }

    // MARK: - Mise en forme

    private static func fractionEcoulee(jusqua expiration: Date) -> Double {
        let joursRestants = expiration.timeIntervalSinceNow / 86_400
        return min(max(1 - joursRestants / 7, 0), 1)
    }

    private static func libelleExpiration(jusqua expiration: Date) -> String {
        let joursRestants = expiration.timeIntervalSinceNow / 86_400
        guard joursRestants > 0 else { return "expirée — resigner l'IPA sans délai" }
        if joursRestants < 1 {
            return "expire dans \(Int((joursRestants * 24).rounded())) h"
        }
        return "expire dans \(Int(joursRestants.rounded(.down))) j"
    }

    private static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private static var bundleId: String {
        Bundle.main.bundleIdentifier ?? "—"
    }
}
#endif
