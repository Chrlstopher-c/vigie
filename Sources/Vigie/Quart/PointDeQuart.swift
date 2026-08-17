#if canImport(SwiftUI)
import Foundation
import VigieNoyau

/// Les trois circuits qui réclament une décision humaine.
///
/// `☠` Ils convergent dans une seule file mais gardent chacun leur genre :
/// autoriser un mandat DÉMARRE une équipe qui dépense de l'argent réel,
/// accorder une rallonge ne fait qu'élargir l'autonomie d'un fil déjà là, et un
/// arbitrage tranche sur une équipe qui tourne en boucle. Les peindre pareil
/// ferait donner le même clic à trois engagements sans rapport.
public enum GenreDeQuart: Sendable, Hashable {
    case mandat
    case arbitrage
    case rallonge

    /// Ordre de la file. Le mandat passe devant parce que c'est le seul qui
    /// BLOQUE : tant qu'il attend, personne ne travaille dessus.
    var rang: Int {
        switch self {
        case .mandat: return 0
        case .arbitrage: return 1
        case .rallonge: return 2
        }
    }

    var libelle: String {
        switch self {
        case .mandat: return "Mandat"
        case .arbitrage: return "Arbitrage"
        case .rallonge: return "Rallonge"
        }
    }

    /// Ce que trancher ce point fait réellement — la ligne qui empêche de
    /// confondre les trois circuits.
    var portee: String {
        switch self {
        case .mandat: return "démarre une équipe"
        case .arbitrage: return "équipe en boucle"
        case .rallonge: return "n'ouvre aucune équipe"
        }
    }

    var symbole: String {
        switch self {
        case .mandat: return "hand.raised.fill"
        case .arbitrage: return "arrow.triangle.2.circlepath"
        case .rallonge: return "clock.arrow.circlepath"
        }
    }

    var etat: EtatSemantique {
        switch self {
        case .mandat: return .accent
        case .arbitrage: return .vigilance
        case .rallonge: return .neutre
        }
    }
}

/// Un point à trancher, réduit à ce qui permet de décider sans ouvrir la fiche.
public struct PointDeQuart: Identifiable, Sendable, Hashable {
    public let id: String
    public let genre: GenreDeQuart
    public let titre: String
    /// Où ça se passe : le projet, la machine, le fil.
    public let detail: String
    /// `☠` Ce que le geste ENGAGE, jamais sous un pli (H-61) : l'accès réel et
    /// le budget d'un mandat, la portée d'une rallonge, le verdict d'une
    /// inspection. C'est la seule ligne qui change ce qu'on est en train
    /// d'autoriser.
    public let engagement: String?
    /// Vrai quand le mandat ouvre l'ÉCRITURE. Change la teinte de la carte :
    /// une équipe qui modifie du code n'est pas une équipe qui lit.
    public let ecritureOuverte: Bool
    /// Instant de la demande. `nil` quand le serveur ne le date pas.
    public let depuis: Date?
}

/// Assemble la file du quart à partir des trois lectures du harness.
///
/// Pur, sans état, sans réseau : c'est la seule partie du domaine qu'on peut
/// relire sans téléphone.
public enum FileDeQuart {

    public static func composer(
        propositions: [PropositionApi],
        rallonges: [RallongeApi],
        missions: [MissionApi]
    ) -> [PointDeQuart] {
        let points = propositions.compactMap(point(mandat:))
            + missions.compactMap(point(arbitrage:))
            + rallonges.compactMap(point(rallonge:))
        return points.sorted(by: avant)
    }

    /// Genre d'abord, puis la plus ancienne demande en tête : ce qui attend
    /// depuis le plus longtemps a déjà coûté le plus d'attente.
    private static func avant(_ gauche: PointDeQuart, _ droite: PointDeQuart) -> Bool {
        guard gauche.genre.rang == droite.genre.rang else {
            return gauche.genre.rang < droite.genre.rang
        }
        return (gauche.depuis ?? .distantFuture) < (droite.depuis ?? .distantFuture)
    }

    private static func point(mandat: PropositionApi) -> PointDeQuart? {
        guard mandat.statut == .enAttente else { return nil }
        let ecriture = mandat.acces.ouvreLEcriture
        let acces = ecriture ? "écriture" : "lecture seule"
        return PointDeQuart(
            id: "mandat:\(mandat.id)",
            genre: .mandat,
            titre: mandat.objectif,
            detail: mandat.projet,
            engagement: "\(acces) · \(montant(mandat.budgetMaxUsd))",
            ecritureOuverte: ecriture,
            depuis: instant(mandat.creeA)
        )
    }

    private static func point(rallonge: RallongeApi) -> PointDeQuart? {
        guard rallonge.statut == .enAttente else { return nil }
        return PointDeQuart(
            id: "rallonge:\(rallonge.id)",
            genre: .rallonge,
            titre: rallonge.motif,
            detail: "fil \(rallonge.conversationId)",
            engagement: porteeRallonge(rallonge),
            ecritureOuverte: false,
            depuis: instant(rallonge.creeA)
        )
    }

    /// `☠` Les deux volets sont indépendants : afficher « plafond » sur une
    /// demande qui ne porte qu'une plage laisserait croire à un réglage
    /// d'équipes jamais demandé.
    private static func porteeRallonge(_ rallonge: RallongeApi) -> String {
        switch (rallonge.porteUneFenetre, rallonge.porteUnPlafond) {
        case (true, true): return "plage horaire + plafond d'équipes"
        case (true, false): return "plage horaire"
        case (false, true): return "plafond d'équipes"
        case (false, false): return "demande sans volet"
        }
    }

    private static func point(arbitrage mission: MissionApi) -> PointDeQuart? {
        guard mission.inspection.attendArbitrage else { return nil }
        let verdict = mission.inspection.lastVerdict?.rawValue ?? "verdict inconnu"
        return PointDeQuart(
            id: "arbitrage:\(mission.id)",
            genre: .arbitrage,
            titre: mission.title,
            detail: mission.project,
            engagement: mission.inspection.libelle ?? mission.inspection.motif ?? verdict,
            ecritureOuverte: false,
            depuis: mission.inspection.lastAt.map(instant)
        )
    }

    /// Le contrat ne transporte que des millisecondes epoch.
    private static func instant(_ epochMs: Int) -> Date {
        Date(timeIntervalSince1970: Double(epochMs) / 1000)
    }

    /// Un budget se lit en dollars entiers sur une file : les cents ne changent
    /// aucune décision et volent la place au reste de la ligne.
    private static func montant(_ dollars: Double) -> String {
        "\(Int(dollars.rounded())) $"
    }
}
#endif
