#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// Le pouls du parc en six chiffres.
///
/// `☠` Six, et pas la liste des équipes. L'écran d'atterrissage répond à
/// « est-ce que quelque chose demande ma main », pas à « où en est chacune des
/// deux cents missions » — cette question-là a son domaine. Un chiffre qui ne
/// change jamais l'ordre du jour n'a rien à faire ici.
public struct PoulsDuParc: Sendable, Equatable {
    public let equipes: Int
    public let bloquees: Int
    public let machinesEnLigne: Int
    public let machinesTotal: Int
    public let coutUsd: Double
    /// Utilisation de la fenêtre 5 h la plus chargée. `nil` = aucune mesure.
    public let quotaPct: Int?
    /// `☠` Distinct de la saturation : la session CONTINUE en dépassement
    /// payant. Afficher un arrêt là où de l'argent se dépense serait doublement
    /// faux.
    public let enDepassement: Bool
    public let contextePct: Int?
    public let sessionOrchestrateur: Bool

    public init(
        missions: [MissionApi],
        machines: [MachineApi],
        comptes: [AccountApi],
        jauges: JaugesApi?
    ) {
        let vivantes = missions.filter { $0.state.estVivante }
        equipes = vivantes.count
        bloquees = missions.filter { $0.state == .requiertAction }.count
        machinesEnLigne = machines.filter(\.enLigne).count
        machinesTotal = machines.count
        coutUsd = vivantes.reduce(0) { $0 + $1.cost }
        quotaPct = comptes.map(\.fiveHour.util).max()
        enDepassement = comptes.contains(where: \.isUsingOverage)
        contextePct = jauges?.contextPct
        sessionOrchestrateur = jauges?.active ?? false
    }
}

/// La grille de six tuiles. Chacune ne s'allume que si elle réclame l'œil :
/// une rangée entièrement orange ne signale plus rien.
struct BandeauPouls: View {
    let pouls: PoulsDuParc

    private let colonnes = Array(
        repeating: GridItem(.flexible(), spacing: Espace.standard),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: colonnes, spacing: Espace.standard) {
            ForEach(Array(tuiles.enumerated()), id: \.element.cle) { rang, tuile in
                TuileStatistique(tuile.cle, valeur: tuile.valeur, alerte: tuile.alerte)
                    .apparitionDouce(rang: rang)
            }
        }
    }

    private struct Tuile {
        let cle: String
        let valeur: String
        let alerte: Bool
    }

    private var tuiles: [Tuile] {
        [
            Tuile(cle: "Équipes", valeur: "\(pouls.equipes)", alerte: false),
            Tuile(cle: "Bloquées", valeur: "\(pouls.bloquees)", alerte: pouls.bloquees > 0),
            Tuile(cle: "Machines", valeur: machines, alerte: false),
            Tuile(cle: "Dépense", valeur: cout, alerte: false),
            Tuile(cle: "Quota 5 h", valeur: quota, alerte: quotaTendu),
            Tuile(cle: "Contexte", valeur: contexte, alerte: contexteTendu),
        ]
    }

    /// Une machine éteinte est le régime NORMAL des nuits : le rapport se lit,
    /// il ne s'alarme pas.
    private var machines: String {
        guard pouls.machinesTotal > 0 else { return "—" }
        return "\(pouls.machinesEnLigne)/\(pouls.machinesTotal)"
    }

    /// Les cents ne changent aucune décision et volent la place au chiffre.
    private var cout: String {
        "\(Int(pouls.coutUsd.rounded())) $"
    }

    private var quota: String {
        guard let pct = pouls.quotaPct else { return "—" }
        return "\(pct) %"
    }

    private var quotaTendu: Bool {
        pouls.enDepassement || (pouls.quotaPct ?? 0) >= 90
    }

    /// « au repos » plutôt qu'un zéro : une session orchestrateur pas encore
    /// ouverte n'a pas un contexte vide, elle n'en a pas.
    private var contexte: String {
        guard let pct = pouls.contextePct else {
            return pouls.sessionOrchestrateur ? "—" : "repos"
        }
        return "\(pct) %"
    }

    private var contexteTendu: Bool {
        (pouls.contextePct ?? 0) >= 80
    }
}
#endif
