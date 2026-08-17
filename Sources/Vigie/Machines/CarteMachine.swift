// Une machine du parc : son état, sa charge, ce qu'elle porte.
//
// `☠` Une machine hors ligne n'est PAS peinte en rouge. Le poste de travail
// éteint la nuit est le régime nominal, ses équipes repartent à son retour
// (H-75) : la webapp peignait ça en panne, ce qui apprenait à ignorer le rouge.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct CarteMachine: View {
    let machine: MachineApi
    let metriques: MetriquesHote?
    let equipes: Int

    var body: some View {
        CarteVigie(relief: .bordee(etat)) {
            VStack(alignment: .leading, spacing: Espace.carte) {
                entete
                if let metriques {
                    mesures(metriques)
                } else {
                    Text(SanteMachine.motif(enLigne: machine.enLigne, metriques: nil)
                         ?? "Hors ligne — aucun relevé.")
                        .legende()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
                if let motif = SanteMachine.motif(enLigne: machine.enLigne, metriques: metriques),
                   metriques != nil {
                    Text(motif)
                        .legende()
                        .foregroundStyle(etat.teinte)
                }
            }
        }
    }

    private var entete: some View {
        HStack(spacing: Espace.standard) {
            AvatarMachine(nom: machine.id, etat: etat)
            VStack(alignment: .leading, spacing: 2) {
                Text(machine.id)
                    .corpsAccentue()
                    .foregroundStyle(Couleurs.encre)
                Text(libelleCharge)
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
            Spacer(minLength: 0)
            PastilleEtat(libelleEtat, etat: etat)
        }
    }

    private func mesures(_ metriques: MetriquesHote) -> some View {
        VStack(spacing: 0) {
            LigneCleValeur("Processeur", valeur: FormatMachine.pourcentage(metriques.cpuPct))
            LigneCleValeur(
                "Mémoire",
                valeur: FormatMachine.memoire(utiliseeMo: metriques.memUtiliseeMo, totaleMo: metriques.memTotaleMo)
            )
            LigneCleValeur(
                "Disque",
                valeur: FormatMachine.disque(utiliseGo: metriques.disqueUtiliseGo, totalGo: metriques.disqueTotalGo)
            )
            LigneCleValeur("Température", valeur: FormatMachine.temperature(metriques.tempCpuC))
            LigneCleValeur("En marche depuis", valeur: FormatMachine.duree(metriques.uptimeS), derniere: true)
        }
    }

    private var libelleCharge: String {
        equipes == 0 ? "aucune équipe" : "\(equipes) équipe\(equipes > 1 ? "s" : "")"
    }

    private var libelleEtat: String {
        switch SanteMachine.degre(enLigne: machine.enLigne, metriques: metriques) {
        case .horsLigne: return "hors ligne"
        case .sansReleve: return "sans relevé"
        case .sain: return "en ligne"
        case .vigilance: return "sous tension"
        case .danger: return "saturée"
        }
    }

    private var etat: EtatSemantique {
        switch SanteMachine.degre(enLigne: machine.enLigne, metriques: metriques) {
        case .horsLigne, .sansReleve: return .neutre
        case .sain: return .sain
        case .vigilance: return .vigilance
        case .danger: return .danger
        }
    }
}

/// Une ligne de quota. `☠` En pourcentage, jamais en dollars : sur abonnement,
/// les champs en dollars de l'API d'usage sont nuls, et une jauge bâtie dessus
/// afficherait zéro en laissant saturer le quota sans prévenir.
struct LigneCompte: View {
    let compte: AccountApi
    let derniere: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.serre) {
            HStack(spacing: Espace.serre) {
                Text(compte.label)
                    .corpsAccentue()
                    .foregroundStyle(Couleurs.encre)
                if compte.isUsingOverage {
                    // `☠` Distinct du statut : la session continue, elle coûte
                    // de l'argent réel. « rejeté » se lirait comme un arrêt.
                    PastilleEtat("dépassement payant", etat: .danger)
                }
                Spacer(minLength: 0)
                Text(compte.plan.isEmpty ? "plan inconnu" : compte.plan)
                    .monoMinuscule()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
            JaugeQuota(
                "5 h",
                utilisation: Double(compte.fiveHour.util) / 100,
                sousTexte: sousTexte(compte.fiveHour)
            )
            JaugeQuota(
                "7 j",
                utilisation: Double(compte.sevenDay.util) / 100,
                sousTexte: sousTexte(compte.sevenDay)
            )
            if !derniere { FiletHorizontal() }
        }
        .padding(.vertical, Espace.serre)
    }

    /// Les deux mentions se complètent : « dans 3 h 30 » dit s'il faut attendre,
    /// « 22:30 » dit s'il faut aller dormir.
    private func sousTexte(_ fenetre: FenetreApi) -> String {
        guard let heure = fenetre.resetAt else { return fenetre.resetLabel }
        return "\(fenetre.resetLabel) · \(heure)"
    }
}
#endif
