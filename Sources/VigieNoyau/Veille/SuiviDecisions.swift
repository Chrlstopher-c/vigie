import Foundation

/// Déduplication des demandes EN ATTENTE (mandats, rallonges) entre deux relevés.
///
/// `☠` Règle OPPOSÉE à celle des notifications, et c'est délibéré. Un fait du
/// harness est historique : le premier relevé après installation n'en sonne
/// AUCUN, sinon cinquante jours d'histoire tombent d'un coup. Une demande en
/// attente, elle, est un présent actionnable : trois mandats trouvés au premier
/// lancement méritent trois alertes, parce qu'ils attendent toujours.
///
/// La mémoire se borne toute seule : un identifiant disparu de la liste des
/// demandes en attente a été tranché, on l'oublie. Rien à élaguer par l'âge.
public struct SuiviDecisions: Codable, Sendable, Equatable {
    private var vus: Set<String>

    public init() {
        vus = []
    }

    /// Les identifiants jamais annoncés, dans l'ordre reçu. Effet de bord : les
    /// identifiants absents du lot sont oubliés.
    public mutating func nouveaux(_ identifiants: [String]) -> [String] {
        let presents = Set(identifiants)
        let inedits = identifiants.filter { !vus.contains($0) }
        // L'intersection AVANT l'union : ce qui n'est plus en attente sort de la
        // mémoire, ce qui vient d'arriver y entre.
        vus = vus.intersection(presents).union(presents)
        return inedits
    }

    public func dejaVu(_ identifiant: String) -> Bool {
        vus.contains(identifiant)
    }

    public var taille: Int { vus.count }
}

/// Ce que le veilleur retient d'un relevé à l'autre, en un seul objet
/// sérialisable — un seul enregistrement, donc un seul risque de désynchronisation.
public struct MemoireVeille: Codable, Sendable, Equatable {
    public var faits: FiligraneNotifications
    public var mandats: SuiviDecisions
    public var rallonges: SuiviDecisions

    public init() {
        faits = FiligraneNotifications()
        mandats = SuiviDecisions()
        rallonges = SuiviDecisions()
    }
}
