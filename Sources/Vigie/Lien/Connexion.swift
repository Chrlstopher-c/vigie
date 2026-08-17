#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// L'écran de session : le mot de passe, et l'adresse du Pi.
///
/// L'adresse est ici et pas seulement dans les réglages, parce que c'est le seul
/// écran atteignable quand rien ne répond. Un tunnel Cloudflare coupé se
/// contourne en basculant sur l'adresse LAN — encore faut-il pouvoir la saisir
/// sans passer par un écran qui exige une session.
public struct EcranConnexion: View {
    @Environment(Cablage.self) private var cablage
    @Environment(Liaison.self) private var liaison
    @Environment(\.clientPi) private var client

    @State private var motDePasse = ""
    @State private var adresse = ""
    @State private var erreur: String?
    @State private var enCours = false
    @FocusState private var focusMotDePasse: Bool

    public init() {}

    public var body: some View {
        ZStack {
            Couleurs.fond.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Espace.section) {
                entete
                formulaire
                Spacer(minLength: 0)
            }
            .padding(Espace.ecran)
        }
        .preferredColorScheme(.light)
        .onAppear {
            adresse = cablage.adresse.absoluteString
            focusMotDePasse = true
        }
    }

    private var entete: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text("Vigie")
                .titreEcran()
                .foregroundStyle(Couleurs.encre)
            Text("Le Pi demande le mot de passe de l'interface. Il est retenu par le "
                 + "trousseau : cette saisie est la seule.")
                .secondaire()
                .foregroundStyle(Couleurs.texteSecondaire)
        }
        .padding(.top, Espace.section)
    }

    private var formulaire: some View {
        CarteVigie {
            VStack(alignment: .leading, spacing: Espace.carte) {
                ChampSaisie(
                    "Adresse du Pi",
                    texte: $adresse,
                    placebo: "https://…",
                    aide: "Tunnel par défaut. Bascule sur l'adresse LAN quand il est coupé."
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

                champMotDePasse
                if let erreur { BandeauAlerte(erreur, etat: .danger, symbole: "exclamationmark.triangle.fill") }
                bouton
            }
        }
    }

    private var champMotDePasse: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Mot de passe")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Couleurs.texteSecondaire)
            SecureField("", text: $motDePasse)
                .textContentType(.password)
                .focused($focusMotDePasse)
                .corps()
                .foregroundStyle(Couleurs.encre)
                .padding(.horizontal, Espace.carte)
                .padding(.vertical, Espace.standard)
                .background(Couleurs.surface, in: RoundedRectangle(cornerRadius: Rayon.champ))
                .overlay {
                    RoundedRectangle(cornerRadius: Rayon.champ)
                        .strokeBorder(Couleurs.filetAppuye, lineWidth: Trait.filet)
                }
                .onSubmit { Task { await ouvrir() } }
        }
    }

    private var bouton: some View {
        Button {
            Task { await ouvrir() }
        } label: {
            HStack(spacing: Espace.serre) {
                if enCours { IndicateurActivite(diametre: 13) }
                Text(enCours ? "Ouverture…" : "Ouvrir la session")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.vigiePrimaire)
        .disabled(enCours || motDePasse.isEmpty)
    }

    private func ouvrir() async {
        guard !enCours, !motDePasse.isEmpty else { return }
        enCours = true
        erreur = nil
        guard await appliquerAdresse() else {
            enCours = false
            return
        }
        switch await client.ouvrirSession(motDePasse: motDePasse) {
        case .success:
            motDePasse = ""
            liaison.sessionOuverte()
        case .failure(let refus):
            erreur = refus.message
        }
        enCours = false
    }

    /// L'adresse est appliquée AVANT la tentative : sans ça, corriger l'adresse
    /// puis appuyer sur « Ouvrir » enverrait la requête à l'ancienne.
    private func appliquerAdresse() async -> Bool {
        let propre = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: propre), url.scheme != nil, url.host != nil else {
            erreur = "Adresse du Pi inutilisable."
            return false
        }
        guard url != cablage.adresse else { return true }
        await cablage.changerAdresse(url)
        return true
    }
}
#endif
