#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// Le parc matériel : machines de travail, quotas Claude, poste de travail.
///
/// `☠` Les métriques ne battent PAS avec la minuterie. `/machines/metriques`
/// fait un aller-retour par machine, jusqu'à Cloudflare pour le VPS : la
/// webapp les sondait toutes les trois secondes, ce qui vide une batterie de
/// téléphone pour un chiffre regardé quelques secondes. Ici, à l'ouverture si
/// le relevé est périmé, et sur geste.
public struct MachinesEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var releve = ReleveParc()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.machines, releveA: releve.parcReleveA) {
                Button {
                    Task { await releve.releverMetriques(client: client) }
                } label: {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Couleurs.encre)
                }
                .disabled(releve.metriquesEnCours)
            }
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await ouvrir() }
        .cadencePar("machines") { await releve.relever(client: client) }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                avertissements
                if releve.premierRemplissage {
                    attente
                } else {
                    sectionMachines
                    sectionQuotas
                    SectionPoste(releve: releve)
                }
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.vertical, Espace.standard)
        }
        .scrollIndicators(.hidden)
        .refreshable { await releve.relever(client: client, forcerMetriques: true) }
    }

    @ViewBuilder private var avertissements: some View {
        if let echec = releve.dernierEchec {
            BandeauAlerte(echec, etat: .danger)
        } else if let mention = releve.mentionDatee {
            // Un PC absent n'est pas une panne : la donnée est vraie, datée.
            BandeauAlerte(mention, etat: .vigilance)
        }
    }

    // MARK: - Machines

    private var sectionMachines: some View {
        SectionVigie("Machines") {
            VStack(spacing: Espace.standard) {
                ForEach(Array(releve.machines.enumerated()), id: \.element.id) { rang, machine in
                    CarteMachine(
                        machine: machine,
                        metriques: releve.metriquesDe(machine.id),
                        equipes: releve.equipesDe(machine.id).count
                    )
                    .apparitionDouce(rang: rang)
                }
            }
        } accessoire: {
            Text(releve.mentionParc)
                .monoMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
        }
    }

    // MARK: - Quotas

    private var sectionQuotas: some View {
        SectionVigie("Comptes Claude") {
            CarteVigie {
                VStack(spacing: 0) {
                    ForEach(Array(releve.comptes.enumerated()), id: \.element.id) { rang, compte in
                        LigneCompte(compte: compte, derniere: rang == releve.comptes.count - 1)
                    }
                    if releve.comptes.isEmpty {
                        Text("Aucun compte connu du harness.")
                            .legende()
                            .foregroundStyle(Couleurs.texteTertiaire)
                    }
                }
            }
        } accessoire: {
            PastilleEtat(mentionQuotas, etat: releve.synthese.parcSature ? .danger : .neutre)
        }
    }

    private var mentionQuotas: String {
        let synthese = releve.synthese
        guard !synthese.aucunCompte else { return "aucun" }
        return "\(synthese.satures)/\(synthese.total) saturés"
    }

    private var attente: some View {
        VStack(spacing: Espace.standard) {
            ForEach(0..<3, id: \.self) { rang in
                CarteVigie {
                    VStack(alignment: .leading, spacing: Espace.standard) {
                        SqueletteVigie(hauteur: 13)
                        SqueletteVigie(hauteur: 11)
                    }
                }
                .apparitionDouce(rang: rang)
            }
        }
    }

    private func ouvrir() async {
        await releve.ouvrir(miroir: miroir)
        await releve.relever(client: client)
    }
}
#endif
