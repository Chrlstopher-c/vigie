#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le détail d'une session tmux : la capture du panneau, rafraîchie tant que
/// l'écran est regardé, et le composeur qui envoie au shell distant.
///
/// `☠` Régime `.generation` (400 ms) plutôt que `.repos` : c'est le seul autre
/// endroit de l'app, avec un fil en train de générer, où quelqu'un regarde
/// l'écran changer en direct. Se désabonne automatiquement en quittant l'écran
/// (`cadencePar`), donc jamais actif en même temps que la liste.
struct SessionEcran: View {
    let nom: String

    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir
    @Environment(Cadence.self) private var cadence
    @Environment(\.dismiss) private var fermer

    @State private var captureEpuree = ""
    @State private var releveA: Date?
    @State private var posteAbsent = false
    @State private var messageAvertissement: String?
    @State private var saisie = ""
    @State private var enEnvoi = false
    @State private var ctrlArme = false
    @State private var collePresenceBas = true
    @State private var confirmationTerminer = false
    @State private var toast: String?

    private static let ancreBas = "ancre-bas"
    private static let seuilPresenceBas: CGFloat = 48

    private var identifiantCadence: String { "terminal-session-\(nom)" }

    var body: some View {
        VStack(spacing: 0) {
            entete
            panneauCapture
            composeur
        }
        .background(Couleurs.fond)
        .task { await relireLeMiroir() }
        .cadencePar(identifiantCadence, regime: .generation) { await battre() }
        .congedieLeClavier()
        .toastVigie(message: $toast)
        .confirmationDialog(
            "Terminer la session « \(nom) » ?",
            isPresented: $confirmationTerminer,
            titleVisibility: .visible
        ) {
            Button("Terminer", role: .destructive) { Task { await terminerEtRevenir() } }
            Button("Annuler", role: .cancel) {}
        }
    }

    // MARK: - En-tête

    private var entete: some View {
        EnteteDomaine(titre: nom, releveA: releveA) {
            Button {
                confirmationTerminer = true
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(Couleurs.etatDanger)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Terminer la session")
        }
    }

    // MARK: - Capture

    private var panneauCapture: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    contenuCapture
                    Color.clear.frame(height: 1).id(Self.ancreBas)
                }
            }
            .background(Couleurs.terminalFond)
            .onScrollGeometryChange(for: CGFloat.self) { geometrie in
                geometrie.contentSize.height - geometrie.contentOffset.y - geometrie.containerSize.height
            } action: { _, distance in
                collePresenceBas = distance < Self.seuilPresenceBas
            }
            .onChange(of: captureEpuree) { _, _ in
                guard collePresenceBas else { return }
                withAnimation(Ressort.direct) { proxy.scrollTo(Self.ancreBas, anchor: .bottom) }
            }
            .overlay(alignment: .bottomTrailing) { boutonRetourBas(proxy) }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var contenuCapture: some View {
        if captureEpuree.isEmpty, releveA == nil {
            silhouetteCapture
        } else if captureEpuree.isEmpty {
            panneauVide
        } else {
            ZoneTerminal(captureEpuree, repliement: false)
        }
    }

    /// Ni tourniquet ni bloc vide : trois barres qui respirent, dans les
    /// teintes du terminal — les jetons de la charte sont calibrés pour le
    /// fond crème, `SqueletteVigie` s'y lirait mal sur `terminalFond`.
    private var silhouetteCapture: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(largeursSilhouette.enumerated()), id: \.offset) { _, largeur in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Couleurs.terminalTexte.opacity(0.14))
                    .frame(width: largeur, height: 12)
            }
        }
        .padding(Espace.ecran)
        .pulsationVitale()
    }

    private var largeursSilhouette: [CGFloat] {
        [0.7, 0.45, 0.85, 0.3, 0.6, 0.5].map { 220 * $0 }
    }

    private var panneauVide: some View {
        VStack(spacing: Espace.standard) {
            Image(systemName: "terminal")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Couleurs.terminalTexte.opacity(0.4))
            Text("Panneau vide")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Couleurs.terminalTexte.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func boutonRetourBas(_ proxy: ScrollViewProxy) -> some View {
        Group {
            if !collePresenceBas, !captureEpuree.isEmpty {
                Button {
                    withAnimation(Ressort.direct) { proxy.scrollTo(Self.ancreBas, anchor: .bottom) }
                    collePresenceBas = true
                } label: {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Couleurs.texteSurSombre)
                        .frame(width: 34, height: 34)
                        .background(Couleurs.encre, in: Circle())
                }
                .accessibilityLabel("Revenir au bas du panneau")
                .padding(12)
                .ombreFlottante()
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Ressort.direct, value: collePresenceBas)
    }

    // MARK: - Composeur

    private var composeur: some View {
        VStack(spacing: 0) {
            if let messageAvertissement {
                BandeauAlerte(messageAvertissement, etat: posteAbsent ? .neutre : .vigilance)
                    .padding(.horizontal, Espace.ecran)
                    .padding(.top, Espace.serre)
            }
            ligneSaisie
            if ctrlArme {
                RangeeControleArme(annuler: { ctrlArme = false }, envoyer: envoyerSequence)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            BarreTerminal(envoyer: gererToucheBarre)
        }
        .background(Couleurs.fond)
        .animation(Ressort.direct, value: ctrlArme)
    }

    private var ligneSaisie: some View {
        HStack(alignment: .bottom, spacing: Espace.serre) {
            ChampSaisie(texte: $saisie, placebo: "Commande…", lignes: 1...4)
            Button {
                Task { await envoyerCommande() }
            } label: {
                if enEnvoi {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                }
            }
            .buttonStyle(.vigieAccent)
            .disabled(saisieVide || enEnvoi)
            .accessibilityLabel("Envoyer")
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.top, Espace.standard)
        .padding(.bottom, Espace.serre)
    }

    private var saisieVide: Bool {
        saisie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Barre d'accessoires

    @MainActor private func gererToucheBarre(_ code: String) {
        guard code != "ctrl" else {
            ctrlArme.toggle()
            return
        }
        ctrlArme = false
        guard let touche = ToucheTerminal.pour(code: code) else { return }
        Task { await envoyerSequence(touche.sequence) }
    }

    // MARK: - Relevés et écritures

    @MainActor private func relireLeMiroir() async {
        guard let donnee = await miroir.lire(CapturePosteApi.self, .capture(session: nom)) else { return }
        appliquer(donnee.valeur)
        releveA = donnee.releveA
    }

    @MainActor private func battre() async {
        switch await client.lirePoste(CapturePosteApi.self, Route.capturerSession(nom), memoriser: .capture(session: nom)) {
        case .fraiche(let charge):
            appliquer(charge)
            posteAbsent = false
            messageAvertissement = nil
            releveA = Date()
        case .pcAbsent(let message):
            posteAbsent = true
            messageAvertissement = message
        case .refus(let message):
            posteAbsent = false
            messageAvertissement = message
        case .echec(let erreur) where erreur.genre != .transport:
            posteAbsent = false
            messageAvertissement = erreur.message
        case .echec:
            break // panne de transport : le bandeau de liaison le dit déjà
        }
    }

    private func appliquer(_ charge: CapturePosteApi) {
        guard let sortie = charge.output else { return }
        captureEpuree = EpurationAnsi.epurer(sortie)
    }

    @MainActor private func envoyerCommande() async {
        guard !saisieVide, !enEnvoi else { return }
        let texte = saisie
        saisie = ""
        ctrlArme = false
        enEnvoi = true
        await envoyer(texte)
        enEnvoi = false
    }

    @MainActor private func envoyerSequence(_ sequence: String) async {
        guard !sequence.isEmpty else { return }
        await envoyer(sequence)
    }

    /// `☠` Le serveur ajoute TOUJOURS Entrée après 200 ms (`ToucheTerminal`) :
    /// une touche de la barre valide donc autant qu'une commande tapée.
    @MainActor private func envoyer(_ octets: String) async {
        switch await client.ordonner(OrdrePosteApi.self, Route.envoyerAuTerminal(nom), ["keys": .texte(octets)]) {
        case .fraiche: break
        case .pcAbsent(let message): toast = message
        case .refus(let message): toast = message
        case .echec(let erreur) where erreur.genre != .transport: toast = erreur.message
        case .echec: break
        }
        cadence.battreMaintenant(identifiantCadence)
    }

    @MainActor private func terminerEtRevenir() async {
        _ = await client.ordonner(OrdrePosteApi.self, Route.tuerSession(nom))
        fermer()
    }
}
#endif
