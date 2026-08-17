#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le terminal tmux — là où un client natif écrase le plus nettement Safari
/// mobile : envoyer un Ctrl-C à tmux depuis un navigateur mobile est
/// simplement impossible.
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("terminal") { … }`,
///    jamais par un `Timer` à elle.
public struct TerminalEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir
    @Environment(Cadence.self) private var cadence

    @State private var sessions: [SessionTmuxApi] = []
    @State private var releveA: Date?
    @State private var posteAbsent = false
    @State private var messageAvertissement: String?
    @State private var feuilleNouvelleSession = false
    @State private var sessionATerminer: String?
    @State private var toast: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            entete
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await relireLeMiroir() }
        .cadencePar("terminal") { await battre() }
        .navigationDestination(for: String.self) { nom in SessionEcran(nom: nom) }
        .feuille(presentee: $feuilleNouvelleSession) {
            NouvelleSessionFeuille(creer: creerSession)
        }
        .toastVigie(message: $toast)
        .confirmationDialog(
            "Terminer la session « \(sessionATerminer ?? "") » ?",
            isPresented: presenceSessionATerminer,
            titleVisibility: .visible
        ) {
            Button("Terminer", role: .destructive) {
                if let nom = sessionATerminer { Task { await terminerSession(nom) } }
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var entete: some View {
        EnteteDomaine(.terminal, releveA: releveA) {
            Button {
                feuilleNouvelleSession = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Couleurs.accentPrimaire)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Nouvelle session")
        }
    }

    private var presenceSessionATerminer: Binding<Bool> {
        Binding(get: { sessionATerminer != nil }, set: { present in if !present { sessionATerminer = nil } })
    }

    // MARK: - Composition

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                avertissement
                sectionSessions
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.bottom, Espace.section)
        }
        .scrollIndicators(.hidden)
        .refreshable { await battre() }
    }

    /// Un poste absent ou un refus ponctuel appartiennent ici seulement quand
    /// la liste n'est pas vide — sinon `contenuListe` porte déjà le message.
    @ViewBuilder private var avertissement: some View {
        if let messageAvertissement, !sessions.isEmpty {
            BandeauAlerte(messageAvertissement, etat: posteAbsent ? .neutre : .vigilance)
        }
    }

    private var sectionSessions: some View {
        SectionVigie("Sessions tmux") {
            contenuListe
        } accessoire: {
            if !sessions.isEmpty {
                PastilleEtat("\(sessions.count)", etat: .neutre)
            }
        }
    }

    @ViewBuilder private var contenuListe: some View {
        if !sessions.isEmpty {
            listeCartes
        } else if releveA == nil, messageAvertissement == nil {
            attente
        } else if posteAbsent {
            EtatVide(
                symbole: "moon.zzz.fill",
                titre: "Poste éteint",
                explication: messageAvertissement
                    ?? "Le poste de travail ne répond pas. Les sessions réapparaîtront à son réveil."
            )
        } else if let messageAvertissement {
            BandeauAlerte(messageAvertissement, etat: .danger)
        } else {
            EtatVide(
                symbole: "terminal.fill",
                titre: "Aucune session",
                explication: "Lance une session tmux pour ouvrir un terminal depuis ton téléphone."
            )
        }
    }

    private var listeCartes: some View {
        VStack(spacing: Espace.standard) {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { rang, session in
                HStack(spacing: Espace.serre) {
                    NavigationLink(value: session.name) {
                        CarteSession(session: session)
                    }
                    .buttonStyle(.plain)
                    Button {
                        sessionATerminer = session.name
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Couleurs.texteTertiaire)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Terminer \(session.name)")
                }
                .apparitionDouce(rang: rang)
            }
        }
    }

    /// Trois silhouettes de cartes plutôt qu'un tourniquet : l'écran montre la
    /// forme de ce qui arrive, comme le fait Quart au tout premier lancement.
    private var attente: some View {
        VStack(spacing: Espace.standard) {
            ForEach(0..<3, id: \.self) { rang in
                CarteVigie {
                    HStack(spacing: Espace.standard) {
                        SqueletteVigie(hauteur: 11).frame(width: 90)
                        Spacer(minLength: 0)
                        SqueletteVigie(hauteur: 18).frame(width: 60)
                    }
                }
                .apparitionDouce(rang: rang)
            }
        }
    }

    // MARK: - Relevés

    @MainActor private func relireLeMiroir() async {
        guard let donnee = await miroir.lire(SessionsPosteApi.self, .sessionsPoste) else { return }
        sessions = TriSessions.triees(donnee.valeur.sessions ?? [])
        releveA = donnee.releveA
    }

    @MainActor private func battre() async {
        switch await client.lirePoste(SessionsPosteApi.self, Route.sessionsPoste, memoriser: .sessionsPoste) {
        case .fraiche(let charge):
            sessions = TriSessions.triees(charge.sessions ?? [])
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

    // MARK: - Écritures

    @MainActor private func creerSession(_ nom: String) async {
        let nomFinal = nom.trimmingCharacters(in: .whitespaces).isEmpty ? "claude" : nom
        switch await client.ordonner(OrdrePosteApi.self, Route.lancerSession(nomFinal)) {
        case .fraiche:
            feuilleNouvelleSession = false
            toast = "Session \(nomFinal) lancée"
            cadence.battreMaintenant("terminal")
        case .pcAbsent(let message):
            toast = message
        case .refus(let message):
            toast = message
        case .echec(let erreur):
            toast = erreur.genre == .transport ? nil : erreur.message
        }
    }

    @MainActor private func terminerSession(_ nom: String) async {
        switch await client.ordonner(OrdrePosteApi.self, Route.tuerSession(nom)) {
        case .fraiche:
            sessions.removeAll { $0.name == nom }
            toast = "Session \(nom) terminée"
        case .pcAbsent(let message):
            toast = message
        case .refus(let message):
            toast = message
        case .echec(let erreur):
            toast = erreur.genre == .transport ? nil : erreur.message
        }
        cadence.battreMaintenant("terminal")
    }
}
#endif
