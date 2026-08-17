import Foundation

/// Traduit un fait du contrat en projet de notification.
///
/// Tout est ici, et rien n'est dans le code qui parle à `UserNotifications` :
/// le libellé d'un mandat se relit et s'éprouve sur une machine sans iPhone.
public enum TraductionAlerte {

    // MARK: - Faits du harness (`GET /notifications`)

    public static func projet(pour fait: NotificationApi) -> ProjetNotification {
        var donnees: [String: String] = [ProjetNotification.Cle.genre: genre(de: fait).rawValue]
        if let fil = fait.conversationId { donnees[ProjetNotification.Cle.fil] = fil }
        if let mission = fait.missionId { donnees[ProjetNotification.Cle.mission] = mission }
        return ProjetNotification(
            identifiant: "fait.\(fait.id)",
            genre: genre(de: fait),
            titre: fait.title,
            corps: fait.body,
            // Regroupement par fil : dix équipes d'un même fil se replient sous
            // un seul résumé au lieu d'inonder l'écran verrouillé.
            fil: fait.conversationId.map { "fil.\($0)" },
            donnees: donnees,
            insistance: .active
        )
    }

    private static func genre(de fait: NotificationApi) -> GenreAlerte {
        switch fait.type {
        case .equipeTerminee: return .equipe
        case .equipeEchouee: return .echec
        default: return .parc
        }
    }

    // MARK: - Mandats en attente (`GET /orchestrator/propositions`)

    /// `☠` Le droit RÉEL (`acces`) est dans le SOUS-TITRE, pas noyé dans le
    /// corps : une autorisation donnée depuis l'écran verrouillé se décide sur
    /// les deux premières lignes. « lecture » et « écriture » n'engagent pas la
    /// même chose et doivent se lire sans déplier.
    public static func projet(pour mandat: PropositionApi) -> ProjetNotification {
        var donnees = [
            ProjetNotification.Cle.proposition: mandat.id,
            ProjetNotification.Cle.genre: GenreAlerte.mandat.rawValue,
        ]
        if let fil = mandat.conversationId { donnees[ProjetNotification.Cle.fil] = fil }
        let droit = mandat.acces.ouvreLEcriture ? "écriture" : "lecture seule"
        return ProjetNotification(
            identifiant: "mandat.\(mandat.id)",
            genre: .mandat,
            titre: "Autorisation demandée",
            sousTitre: "\(mandat.projet) · \(droit) · \(somme(mandat.budgetMaxUsd))",
            corps: mandat.objectif,
            fil: "mandat",
            donnees: donnees,
            insistance: .active
        )
    }

    // MARK: - Rallonges en attente (`GET /orchestrator/rallonges`)

    public static func projet(pour rallonge: RallongeApi) -> ProjetNotification {
        let donnees = [
            ProjetNotification.Cle.rallonge: rallonge.id,
            ProjetNotification.Cle.fil: rallonge.conversationId,
            ProjetNotification.Cle.genre: GenreAlerte.rallonge.rawValue,
        ]
        return ProjetNotification(
            identifiant: "rallonge.\(rallonge.id)",
            genre: .rallonge,
            titre: "Autonomie demandée",
            sousTitre: portee(de: rallonge),
            corps: rallonge.motif,
            fil: "rallonge",
            donnees: donnees,
            insistance: .active
        )
    }

    /// Les deux volets sont indépendants : dire lequel est demandé change ce
    /// qu'on accorde. « Plage + plafond » n'est pas « plafond ».
    private static func portee(de rallonge: RallongeApi) -> String {
        switch (rallonge.porteUneFenetre, rallonge.porteUnPlafond) {
        case (true, true): return "plage et plafond d'équipes"
        case (true, false): return "plage d'autonomie"
        case (false, true): return "plafond d'équipes"
        case (false, false): return "réglage d'autonomie"
        }
    }

    /// Montant en français : virgule décimale, dollar suffixé. Écrit à la main
    /// plutôt qu'avec un `NumberFormatter` — aucun formateur de Foundation n'est
    /// `Sendable`, et cette fonction est appelée depuis un réveil de fond.
    static func somme(_ valeur: Double) -> String {
        let centimes = Int((valeur * 100).rounded())
        let entier = centimes / 100
        let reste = abs(centimes % 100)
        return "\(entier),\(String(format: "%02d", reste)) $"
    }
}
