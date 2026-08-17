#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// Le détail d'une équipe : son mandat, sa consommation, son fil, ses
/// sous-agents, et les gestes de pilotage.
///
/// `☠` Les gestes ne sont pas optimistes et ne recalculent aucun état : après
/// une écriture, on relit la mission. Un bouton qui repeint l'écran tout seul
/// finit par afficher une équipe en pause qui tourne encore.
struct EquipeEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    let identifiant: String

    @State private var mission: MissionApi?
    @State private var releveA: Date?
    @State private var refus: ErreurApi?
    @State private var geste: String?

    var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(titre: mission?.project ?? "Équipe", releveA: releveA)
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await ouvrir() }
        .cadencePar("equipe.\(identifiant)") { await battre() }
    }

    @ViewBuilder private var corps: some View {
        if let mission {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.section) {
                    if let refus, refus.genre != .transport {
                        BandeauAlerte(refus.message, etat: .vigilance)
                    }
                    enTete(mission)
                    GestesEquipe(mission: mission, enCours: $geste, apres: { await battre() })
                    sectionMandat(mission)
                    sectionConsommation(mission)
                    sectionDepot(mission)
                    sectionSousAgents(mission)
                    sectionFil(mission)
                }
                .padding(.horizontal, Espace.ecran)
                .padding(.vertical, Espace.standard)
            }
            .scrollIndicators(.hidden)
            .refreshable { await battre() }
        } else if let refus {
            BandeauAlerte(refus.message, etat: .danger)
                .padding(Espace.ecran)
        } else {
            CarteVigie { SqueletteVigie(hauteur: 15) }
                .padding(Espace.ecran)
        }
    }

    // MARK: - Sections

    private func enTete(_ mission: MissionApi) -> some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text(mission.title)
                .titreSection()
                .foregroundStyle(Couleurs.encre)
            HStack(spacing: Espace.serre) {
                PastilleEtat(EtatEquipe(mission.state).libelle, etat: semantique(mission))
                if let anciennete = EtatEquipe.anciennete(mission) {
                    Text(anciennete)
                        .monoMinuscule()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func sectionMandat(_ mission: MissionApi) -> some View {
        SectionVigie("Mandat") {
            CarteVigie {
                VStack(spacing: 0) {
                    LigneCleValeur("But", valeur: lisible(mission.mandate.but))
                    LigneCleValeur("Critère d'arrêt", valeur: lisible(mission.mandate.critere))
                    LigneCleValeur("Machine", valeur: mission.machine ?? "—")
                    LigneCleValeur("Compte", valeur: mission.account)
                    LigneCleValeur("Moteur", valeur: mission.model, derniere: true)
                }
            }
        }
    }

    private func sectionConsommation(_ mission: MissionApi) -> some View {
        SectionVigie("Consommation") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.standard) {
                    JaugeQuota(
                        "Contexte",
                        utilisation: Double(mission.ctx) / 100,
                        sousTexte: ConsommationEquipe.tokensLisibles(mission.ctxTokens)
                    )
                    LigneCleValeur("Dépense", valeur: ConsommationEquipe.montant(mission.cost))
                    LigneCleValeur("Prochaine inspection", valeur: prochainSeuil(mission), derniere: true)
                }
            }
        }
    }

    /// `nil` = tous les paliers sont passés. Ce n'est pas une alerte, c'est une
    /// échéance : aucun montant n'est mauvais en soi.
    private func prochainSeuil(_ mission: MissionApi) -> String {
        guard let seuil = ConsommationEquipe.prochainSeuil(mission.cost) else {
            return "tous les paliers passés"
        }
        return ConsommationEquipe.montant(seuil)
    }

    private func sectionDepot(_ mission: MissionApi) -> some View {
        let constat = ConstatDepot.lire(mission.git)
        return SectionVigie("Dépôt") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.serre) {
                    LigneCleValeur("Travail non commité", valeur: constat.valeur)
                    LigneCleValeur("Branche", valeur: constat.releve?.branche ?? mission.branch)
                    LigneCleValeur("Worktree", valeur: mission.worktree, derniere: true)
                    if let avertissement = constat.avertissement {
                        Text(avertissement)
                            .legende()
                            .foregroundStyle(EtatSemantique.vigilance.teinte)
                    }
                }
            }
        }
    }

    @ViewBuilder private func sectionSousAgents(_ mission: MissionApi) -> some View {
        if !mission.subagents.isEmpty {
            SectionVigie("Sous-agents") {
                CarteVigie {
                    VStack(spacing: 0) {
                        ForEach(Array(mission.subagents.enumerated()), id: \.element.id) { rang, agent in
                            LigneCleValeur(
                                agent.name,
                                valeur: agent.feedUnavailable ? "sans relevé" : agent.action,
                                teinteValeur: agent.feedUnavailable
                                    ? Couleurs.texteTertiaire : Couleurs.encre,
                                derniere: rang == mission.subagents.count - 1
                            )
                        }
                    }
                }
            }
        }
    }

    /// `☠` `FeedEventApi` n'a aucun identifiant : la clé est synthétisée par
    /// `EvenementFilMission.indexer`, faute de quoi SwiftUI change l'identité
    /// des lignes à chaque relevé — blocs repliés, défilement rejeté.
    @ViewBuilder private func sectionFil(_ mission: MissionApi) -> some View {
        if !mission.feed.isEmpty {
            SectionVigie("Fil de l'équipe") {
                CarteVigie {
                    VStack(alignment: .leading, spacing: Espace.serre) {
                        ForEach(Array(FeedEventApi.indexer(mission.feed).enumerated()),
                                id: \.element.id) { (rang: Int, ligne: EvenementFilMission) in
                            LigneFil(
                                horodatage: ligne.evenement.ts,
                                etiquette: ligne.evenement.tool,
                                genre: genre(ligne.evenement),
                                texte: LibelleOutil.resume(ligne.evenement),
                                rang: rang
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Relevés

    private func lisible(_ texte: String) -> String {
        texte.isEmpty ? "—" : texte
    }

    /// `☠` Une autorisation RÉSOLUE SEULE par le lead et une autorisation qui
    /// attend un arbitrage ne se peignent pas pareil : la seconde bloque le
    /// travail, la première n'est qu'une trace.
    private func genre(_ evenement: FeedEventApi) -> GenreEvenement {
        switch evenement.type {
        case .permission:
            return evenement.pending == true ? .autorisationAttente : .autorisationAuto
        case .systeme: return .systeme
        case .instruction: return .instruction
        default: return .activite
        }
    }

    private func semantique(_ mission: MissionApi) -> EtatSemantique {
        switch EtatEquipe(mission.state).ton {
        case .attente: return .accent
        case .actif: return .sain
        case .veille: return .vigilance
        case .alerte: return .danger
        case .clos, .neutre: return .neutre
        }
    }

    private func ouvrir() async {
        guard let cache = await miroir.lire(MissionApi.self, .mission(identifiant)) else { return }
        mission = cache.valeur
        releveA = cache.releveA
    }

    @MainActor private func battre() async {
        let lecture = await client.lire(
            MissionApi.self, Route.mission(identifiant), memoriser: .mission(identifiant)
        )
        if let charge = lecture.charge {
            mission = charge
            releveA = Date()
        }
        refus = lecture.erreur
    }
}
#endif
