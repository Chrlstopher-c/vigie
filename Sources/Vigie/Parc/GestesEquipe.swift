// Le pilotage d'une équipe : pause, reprise, interruption, inspection, fin.
//
// `☠` Deux distinctions que l'écran doit rendre évidentes, sous peine de faire
// perdre du travail :
//   · INTERROMPRE coupe le tour en vol, la session reste vivante et le contexte
//     est préservé — c'est réversible.
//   · TERMINER ferme l'équipe. Le travail non commité du worktree part avec, et
//     c'est irréversible : geste armé + Face ID, jamais un simple bouton.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct GestesEquipe: View {
    @Environment(\.clientPi) private var client

    let mission: MissionApi
    @Binding var enCours: String?
    let apres: () async -> Void

    @State private var retour: String?

    private var etat: EtatEquipe { EtatEquipe(mission.state) }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            if etat.pilotable {
                rangeeReversible
                rangeeIrreversible
            }
            if let retour {
                Text(retour)
                    .legende()
                    .foregroundStyle(Couleurs.texteSecondaire)
            }
        }
    }

    private var rangeeReversible: some View {
        HStack(spacing: Espace.standard) {
            if etat.enPause {
                Button("Reprendre") { lancer("reprise", Route.reprendreMission(mission.id)) }
                    .buttonStyle(.vigieSecondaire)
            } else {
                Button("Mettre en pause") { lancer("pause", Route.mettreEnPauseMission(mission.id)) }
                    .buttonStyle(.vigieSecondaire)
            }
            if etat.tourEnVol {
                // Coupe le tour, pas la session : le contexte reste (H-57).
                Button("Interrompre") { lancer("interruption", Route.interrompreMission(mission.id)) }
                    .buttonStyle(.vigieSecondaire)
            }
        }
        .disabled(enCours != nil)
    }

    private var rangeeIrreversible: some View {
        HStack(spacing: Espace.standard) {
            Button("Inspecter") { lancer("inspection", Route.inspecterMission(mission.id)) }
                .buttonStyle(.vigieSecondaire)
                .disabled(enCours != nil)
            BoutonMaintenu("Terminer l'équipe", libelleArme: "Relâche pour terminer") {
                Task { await terminer() }
            }
            .disabled(enCours != nil)
        }
    }

    // MARK: - Ordres

    private func lancer(_ nom: String, _ chemin: String) {
        Task { await ecrire(nom, chemin) }
    }

    private func ecrire(_ nom: String, _ chemin: String) async {
        guard enCours == nil else { return }
        enCours = nom
        defer { enCours = nil }
        switch await client.ecrire(chemin) {
        case .success(let accuse):
            // L'effet est le mot du serveur : lui seul sait ce qui s'est passé.
            retour = accuse.effet.isEmpty ? "\(nom) prise en compte." : accuse.effet
            await apres()
        case .failure(let erreur):
            retour = erreur.message
        }
    }

    /// `☠` Le seul geste du domaine qui détruit : la garde biométrique s'ajoute
    /// au maintien du doigt. Un `uncommitted` non nul est rappelé dans le motif
    /// — c'est ce qui sera perdu.
    private func terminer() async {
        let enJeu = ConstatDepot.lire(mission.git).travailEnJeu
        let motif = enJeu
            ? "Terminer \(mission.title) — du travail non commité sera perdu"
            : "Terminer \(mission.title)"
        if case .refusee(let raison) = await GardeFaceID.exiger(motif) {
            retour = "Rien n'a été transmis : \(raison)"
            return
        }
        await ecrire("fin", Route.terminerMission(mission.id))
    }
}
#endif
