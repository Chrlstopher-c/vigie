#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// L'écran d'atterrissage : la file de ce que Chris seul peut trancher, et le
/// pouls du parc au-dessus.
///
/// `☠` Ce n'est PAS le parc. Ce qui demande une décision passe avant ce qui
/// informe : la SPA ouvrait sur deux cents cartes de missions, où un mandat en
/// attente était une ligne parmi d'autres. Ici, six chiffres pour le contexte,
/// et tout le reste de l'écran pour la file.
public struct QuartEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var propositions: [PropositionApi] = []
    @State private var rallonges: [RallongeApi] = []
    @State private var missions: [MissionApi] = []
    @State private var machines: [MachineApi] = []
    @State private var comptes: [AccountApi] = []
    @State private var jauges: JaugesApi?
    @State private var releveA: Date?
    @State private var refus: ErreurApi?
    @State private var tour = 0

    /// `☠` Le parc, les comptes et les jauges ne battent qu'un tour sur cinq —
    /// vingt secondes. Six routes toutes les quatre secondes à travers le
    /// tunnel, c'est la dérive de la SPA qu'on est venu corriger ; la file, elle,
    /// bat à chaque tour parce qu'elle est la raison de l'écran.
    private static let toursParReleveDuParc = 5

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.quart, releveA: releveA)
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await relireLeMiroir() }
        .cadencePar("quart") { await battre() }
        .sensoryFeedback(Retour.alerte, trigger: file.count) { ancien, nouveau in
            nouveau > ancien
        }
    }

    // MARK: - Composition

    private var file: [PointDeQuart] {
        FileDeQuart.composer(
            propositions: propositions,
            rallonges: rallonges,
            missions: missions
        )
    }

    private var pouls: PoulsDuParc {
        PoulsDuParc(missions: missions, machines: machines, comptes: comptes, jauges: jauges)
    }

    /// Rien relu, rien reçu, aucun refus : le tout premier lancement.
    private var premierReleve: Bool {
        releveA == nil && refus == nil
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                avertissement
                BandeauPouls(pouls: pouls)
                sectionFile
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.bottom, Espace.section)
        }
        .scrollIndicators(.hidden)
        .refreshable { await battre() }
    }

    /// `☠` Les pannes de transport appartiennent au bandeau de liaison, en haut
    /// de tout écran. Répéter ici « Pi injoignable » ferait deux annonces pour
    /// un seul fait ; un refus métier, lui, n'est dit nulle part ailleurs.
    @ViewBuilder private var avertissement: some View {
        if let refus, refus.genre != .transport, !missions.isEmpty {
            BandeauAlerte(refus.message, etat: .vigilance)
        }
    }

    private var sectionFile: some View {
        SectionVigie("À trancher") {
            contenuDeLaFile
        } accessoire: {
            if !file.isEmpty {
                PastilleEtat("\(file.count)", etat: .accent)
            }
        }
    }

    @ViewBuilder private var contenuDeLaFile: some View {
        if !file.isEmpty {
            VStack(spacing: Espace.standard) {
                ForEach(Array(file.enumerated()), id: \.element.id) { rang, point in
                    NavigationLink(value: Domaine.decisions) {
                        CarteDeQuart(point: point, rang: rang)
                    }
                    .buttonStyle(.vigieCarte)
                }
            }
        } else if premierReleve {
            attente
        } else if let refus, missions.isEmpty {
            BandeauAlerte(refus.message, etat: .danger)
        } else {
            EtatVide(
                symbole: "checkmark.circle",
                titre: "Rien à trancher",
                explication: "Aucun mandat, aucune rallonge, aucun arbitrage n'attend. "
                    + "Le parc tourne sans toi."
            )
        }
    }

    /// Trois silhouettes de cartes, jamais un tourniquet : l'écran montre la
    /// forme de ce qui arrive plutôt que l'aveu qu'il ne sait rien.
    private var attente: some View {
        VStack(spacing: Espace.standard) {
            ForEach(0..<3, id: \.self) { rang in
                CarteVigie {
                    VStack(alignment: .leading, spacing: Espace.standard) {
                        SqueletteVigie(hauteur: 11)
                        SqueletteVigie(hauteur: 15)
                    }
                }
                .apparitionDouce(rang: rang)
            }
        }
    }

    // MARK: - Relevés

    @MainActor private func relireLeMiroir() async {
        await depuisMiroir([PropositionApi].self, .propositions) { propositions = $0 }
        await depuisMiroir([RallongeApi].self, .rallonges) { rallonges = $0 }
        await depuisMiroir([MissionApi].self, .missions) { missions = $0 }
        await depuisMiroir([MachineApi].self, .machines) { machines = $0 }
        await depuisMiroir([AccountApi].self, .comptes) { comptes = $0 }
        await depuisMiroir(JaugesApi.self, .jauges) { jauges = $0 }
    }

    @MainActor private func battre() async {
        tour &+= 1
        var incident = await lireLaFile()
        if tour % Self.toursParReleveDuParc == 1 {
            if incident == nil { incident = await lireLeParc() }
        }
        refus = incident
        // Ne dater que sur un tour complet : un « relevé à l'instant » posé sur
        // un échec ferait passer la donnée d'avant pour celle de maintenant.
        if incident == nil { releveA = Date() }
    }

    @MainActor private func lireLaFile() async -> ErreurApi? {
        let mandats = await lire(
            [PropositionApi].self, Route.propositions, .propositions
        ) { propositions = $0 }
        let demandes = await lire(
            [RallongeApi].self, Route.rallonges, .rallonges
        ) { rallonges = $0 }
        let equipes = await lire([MissionApi].self, Route.missions, .missions) { missions = $0 }
        return mandats ?? demandes ?? equipes
    }

    @MainActor private func lireLeParc() async -> ErreurApi? {
        let parc = await lire([MachineApi].self, Route.machines, .machines) { machines = $0 }
        let quotas = await lire([AccountApi].self, Route.comptes, .comptes) { comptes = $0 }
        let mesures = await lire(JaugesApi.self, Route.jauges, .jauges) { jauges = $0 }
        return parc ?? quotas ?? mesures
    }

    /// `☠` Les lectures sont en SÉRIE, jamais en parallèle. Six requêtes
    /// simultanées dans le tunnel Cloudflare se gênent entre elles et rendent
    /// l'écran plus lent que si on les avait enchaînées.
    @MainActor private func lire<Charge: Decodable & Sendable>(
        _ type: Charge.Type,
        _ chemin: String,
        _ cle: CleMiroir,
        _ appliquer: (Charge) -> Void
    ) async -> ErreurApi? {
        let lecture = await client.lire(type, chemin, memoriser: cle)
        if let charge = lecture.charge { appliquer(charge) }
        return lecture.erreur
    }

    @MainActor private func depuisMiroir<Charge: Decodable & Sendable>(
        _ type: Charge.Type,
        _ cle: CleMiroir,
        _ appliquer: (Charge) -> Void
    ) async {
        guard let donnee = await miroir.lire(type, cle) else { return }
        appliquer(donnee.valeur)
        // La plus ANCIENNE des sections relues : c'est elle qui dit ce que vaut
        // l'écran pris dans son ensemble.
        releveA = min(releveA ?? donnee.releveA, donnee.releveA)
    }
}
#endif
