// Section « Serveur » des Réglages : adresse du Pi, état de la liaison,
// déconnexion. L'adresse est ADOSSÉE à `Cablage.changerAdresse`, jamais à une
// copie locale de la logique déjà écrite pour `EcranConnexion`.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct SectionServeur: View {
    @Environment(Cablage.self) private var cablage
    @Environment(Liaison.self) private var liaison
    @Environment(\.clientPi) private var client

    @State private var adresse = ""
    @State private var erreur: String?
    @State private var enCours = false
    let toast: @MainActor (String) -> Void

    var body: some View {
        SectionVigie("Serveur") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.carte) {
                    champAdresse
                    raccourcisAdresse
                    if let erreur {
                        BandeauAlerte(erreur, etat: .danger, symbole: "exclamationmark.triangle.fill")
                    }
                    boutonAppliquer
                    FiletHorizontal()
                    ligneLiaison
                    boutonDeconnexion
                }
            }
        }
        .onAppear { adresse = cablage.adresse.absoluteString }
    }

    private var champAdresse: some View {
        ChampSaisie(
            "Adresse du Pi",
            texte: $adresse,
            placebo: "https://…",
            aide: "Tunnel Cloudflare par défaut. Bascule sur l'adresse LAN quand il est coupé."
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(.URL)
    }

    /// Les deux raccourcis documentés par `Cablage` : le tunnel de
    /// `deploy-web-pi.sh`, et le repli LAN saisi ici et nulle part ailleurs.
    private var raccourcisAdresse: some View {
        HStack(spacing: Espace.standard) {
            Button("Tunnel par défaut") { adresse = Cablage.adresseParDefaut.absoluteString }
                .buttonStyle(.vigieSecondaire)
            Button("Repli LAN") { adresse = "http://vigie.local:8766" }
                .buttonStyle(.vigieSecondaire)
        }
    }

    private var boutonAppliquer: some View {
        Button {
            Task { await appliquer() }
        } label: {
            HStack(spacing: Espace.serre) {
                if enCours { IndicateurActivite(diametre: 13) }
                Text(enCours ? "Application…" : "Appliquer l'adresse")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.vigiePrimaire)
        .disabled(enCours || adresse.isEmpty)
    }

    private var ligneLiaison: some View {
        HStack {
            Text("Liaison").secondaire().foregroundStyle(Couleurs.texteTertiaire)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                PastilleEtat(liaison.libelle, etat: etatLiaison)
                if let precision = liaison.precision {
                    Text(precision).legende().foregroundStyle(Couleurs.texteTertiaire)
                }
            }
        }
    }

    private var etatLiaison: EtatSemantique {
        switch liaison.regime {
        case .nominal: return .sain
        case .posteEteint: return .vigilance
        case .perdue: return .danger
        case .sessionRequise: return .accent
        }
    }

    /// `☠` Efface le jeton du trousseau ET le miroir (`fermerSession`) — voir
    /// `ClientPi`. Maintien plutôt que confirmation : c'est le geste destructif
    /// engageant que la charte réserve à `BoutonMaintenu`.
    private var boutonDeconnexion: some View {
        BoutonMaintenu("Maintenir pour se déconnecter", libelleArme: "Déconnexion…") {
            Task {
                await client.fermerSession()
                liaison.exigerSession()
            }
        }
    }

    private func appliquer() async {
        let propre = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: propre), url.scheme != nil, url.host != nil else {
            erreur = "Adresse inutilisable."
            return
        }
        erreur = nil
        enCours = true
        if url != cablage.adresse {
            await cablage.changerAdresse(url)
        }
        enCours = false
        toast("Adresse appliquée")
    }
}
#endif
