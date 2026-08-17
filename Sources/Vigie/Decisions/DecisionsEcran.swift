#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// La file de ce que Chris seul peut trancher — le domaine prioritaire.
///
/// `☠` Elle réunit trois circuits que le serveur tient séparés (mandats,
/// rallonges, arbitrages d'inspection) sans jamais les fondre : chaque carte
/// garde son objet d'origine, ses libellés et ses routes. C'est l'ordre qui est
/// commun, pas la nature — et l'ordre est structurel, jamais monétaire.
public struct DecisionsEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var propositions: [PropositionApi] = []
    @State private var rallonges: [RallongeApi] = []
    @State private var missions: [MissionApi] = []
    @State private var releveA: Date?
    @State private var refus: ErreurApi?
    @State private var arbitrage: Arbitrage?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.decisions, releveA: releveA) {
                if !file.isEmpty { PastilleEtat("\(file.count)", etat: .accent) }
            }
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await amorcer() }
        .cadencePar("decisions") { await battre() }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.standard) {
                avertissement
                contenu
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.vertical, Espace.standard)
        }
        .scrollIndicators(.hidden)
        .refreshable { await battre() }
    }

    // MARK: - Composition

    /// Les cartes tranchées restent affichées, tamponnées, jusqu'au relevé
    /// suivant : les faire disparaître à la seconde du clic ne laisse pas voir
    /// ce qui a été décidé, et deux gestes rapides deviennent indiscernables.
    private var file: [Decision] {
        let mandats = propositions.map(Decision.mandat)
        let demandes = rallonges.map(Decision.rallonge)
        let arbitrages = missions
            .filter(\.inspection.attendArbitrage)
            .map(Decision.arbitrage)
        return (mandats + demandes + arbitrages).trieesParUrgence()
    }

    @ViewBuilder private var avertissement: some View {
        if let refus, refus.genre != .transport {
            BandeauAlerte(refus.message, etat: .vigilance)
        }
    }

    @ViewBuilder private var contenu: some View {
        if let arbitrage, !file.isEmpty {
            VStack(spacing: Espace.standard) {
                ForEach(Array(file.enumerated()), id: \.element.id) { rang, decision in
                    CarteDecision(
                        decision: decision,
                        rang: rang,
                        occupee: arbitrage.enCours != nil || arbitrage.estTranchee(decision),
                        conduite: arbitrage.conduite(pour: decision),
                        accorder: { await trancher { await arbitrage.approuver(decision) } },
                        refuser: { await trancher { await arbitrage.refuser(decision) } }
                    )
                }
            }
        } else if releveA == nil && refus == nil {
            attente
        } else {
            EtatVide(
                symbole: "checkmark.circle",
                titre: "Rien à trancher",
                explication: "Aucun mandat, aucune rallonge, aucun arbitrage n'attend. "
                    + "Le parc tourne sans toi."
            )
        }
    }

    private var attente: some View {
        VStack(spacing: Espace.standard) {
            ForEach(0..<2, id: \.self) { rang in
                CarteVigie {
                    VStack(alignment: .leading, spacing: Espace.standard) {
                        SqueletteVigie(hauteur: 11)
                        SqueletteVigie(hauteur: 15)
                        SqueletteVigie(hauteur: 11)
                    }
                }
                .apparitionDouce(rang: rang)
            }
        }
    }

    // MARK: - Relevés

    private func amorcer() async {
        if arbitrage == nil { arbitrage = Arbitrage(client: client) }
        await depuisMiroir([PropositionApi].self, .propositions) { propositions = $0 }
        await depuisMiroir([RallongeApi].self, .rallonges) { rallonges = $0 }
        await depuisMiroir([MissionApi].self, .missions) { missions = $0 }
    }

    /// Un geste tranché est suivi d'un relevé immédiat : c'est le serveur qui
    /// dit ce qui reste dans la file, jamais une déduction locale.
    private func trancher(_ geste: () async -> Void) async {
        await geste()
        await battre()
    }

    @MainActor private func battre() async {
        let mandats = await lire([PropositionApi].self, Route.propositions, .propositions) {
            propositions = $0
        }
        let demandes = await lire([RallongeApi].self, Route.rallonges, .rallonges) { rallonges = $0 }
        let equipes = await lire([MissionApi].self, Route.missions, .missions) { missions = $0 }
        refus = mandats ?? demandes ?? equipes
        if refus == nil { releveA = Date() }
    }

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
        releveA = min(releveA ?? donnee.releveA, donnee.releveA)
    }
}
#endif
