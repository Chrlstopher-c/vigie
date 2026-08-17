#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// Le parc : toutes les équipes, groupées, et le détail de chacune.
///
/// `☠` `state` est décodé TEL QUEL, jamais recalculé depuis l'état du harness :
/// les deux machines à états se croisent, et les recombiner rejoue la panne #30.
/// Un état inconnu tombe dans « Autres états » plutôt que d'être filtré — la
/// liste est ouverte côté serveur, et une équipe disparue serait invisible.
public struct ParcEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var missions: [MissionApi] = []
    @State private var groupePar: GroupementParc = .etat
    @State private var releveA: Date?
    @State private var refus: ErreurApi?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.parc, releveA: releveA) {
                BasculeGroupement(choix: $groupePar)
            }
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await ouvrir() }
        .cadencePar("parc") { await battre() }
        .navigationDestination(for: RouteParc.self) { route in
            switch route {
            case .equipe(let identifiant):
                EquipeEcran(identifiant: identifiant)
            }
        }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                if let refus, refus.genre != .transport, missions.isEmpty {
                    BandeauAlerte(refus.message, etat: .danger)
                }
                if missions.isEmpty {
                    vide
                } else {
                    resume
                    ForEach(groupes) { groupe in
                        SectionGroupeParc(groupe: groupe)
                    }
                }
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.vertical, Espace.standard)
        }
        .scrollIndicators(.hidden)
        .refreshable { await battre() }
    }

    private var groupes: [GroupeParc] {
        switch groupePar {
        case .etat: return TriParc.groupes(missions)
        case .projet: return GroupementProjet.groupes(missions)
        }
    }

    private var resume: some View {
        Text(TriParc.resume(missions))
            .legende()
            .foregroundStyle(Couleurs.texteTertiaire)
    }

    @ViewBuilder private var vide: some View {
        if releveA == nil && refus == nil {
            VStack(spacing: Espace.standard) {
                ForEach(0..<3, id: \.self) { rang in
                    CarteVigie { SqueletteVigie(hauteur: 13) }
                        .apparitionDouce(rang: rang)
                }
            }
        } else {
            EtatVide(
                symbole: "square.stack.3d.up",
                titre: "Aucune équipe",
                explication: "Le harness n'a aucune équipe en registre."
            )
        }
    }

    // MARK: - Relevés

    private func ouvrir() async {
        guard let cache = await miroir.lire([MissionApi].self, .missions) else { return }
        missions = cache.valeur
        releveA = cache.releveA
    }

    @MainActor private func battre() async {
        let lecture = await client.lire([MissionApi].self, Route.missions, memoriser: .missions)
        if let charge = lecture.charge {
            missions = charge
            releveA = Date()
        }
        refus = lecture.erreur
    }
}

/// Par état ou par projet : deux lectures du même parc. Par état pour savoir ce
/// qui réclame, par projet pour savoir où en est un chantier.
enum GroupementParc: String, CaseIterable, Identifiable {
    case etat
    case projet

    var id: String { rawValue }

    var symbole: String {
        switch self {
        case .etat: return "circle.grid.2x2"
        case .projet: return "folder"
        }
    }
}

private struct BasculeGroupement: View {
    @Binding var choix: GroupementParc

    var body: some View {
        Button {
            withAnimation(Mouvement.changementEtat) {
                choix = choix == .etat ? .projet : .etat
            }
        } label: {
            Image(systemName: choix.symbole)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Couleurs.encre)
        }
        .sensoryFeedback(Retour.selection, trigger: choix)
    }
}

private struct SectionGroupeParc: View {
    let groupe: GroupeParc

    var body: some View {
        SectionVigie(groupe.titre) {
            VStack(spacing: Espace.standard) {
                ForEach(Array(groupe.missions.enumerated()), id: \.element.id) { rang, mission in
                    NavigationLink(value: RouteParc.equipe(mission.id)) {
                        CarteEquipe(mission: mission)
                    }
                    .buttonStyle(.plain)
                    .apparitionDouce(rang: rang)
                }
            }
        } accessoire: {
            PastilleEtat("\(groupe.missions.count)", etat: .neutre)
        }
    }
}
#endif
