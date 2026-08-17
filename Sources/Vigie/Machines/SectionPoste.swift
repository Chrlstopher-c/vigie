// Le poste de travail : l'état du PC, son réveil, et le compte Claude actif.
//
// `☠` Ces routes sont NATIVES de pi-web (`/api/status`, `/api/wake`,
// `/api/claude-accounts`), pas des routes du harness : elles répondent 200 avec
// `pc_online: false` quand le PC dort. Un 200 n'y vaut donc pas succès, et
// c'est `posteEnLigne` qu'il faut lire, jamais le code HTTP.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct SectionPoste: View {
    @Environment(\.clientPi) private var client
    let releve: ReleveParc

    @State private var basculeEnCours: String?
    @State private var retour: String?

    var body: some View {
        SectionVigie("Poste de travail") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.carte) {
                    etatDuPoste
                    if releve.posteEnLigne == true {
                        comptesClaude
                    } else {
                        boutonReveil
                    }
                    if let retour {
                        Text(retour)
                            .legende()
                            .foregroundStyle(Couleurs.texteSecondaire)
                    }
                }
            }
        } accessoire: {
            PastilleEtat(libelleEtat, etat: etat)
        }
    }

    private var etatDuPoste: some View {
        VStack(spacing: 0) {
            LigneCleValeur("État", valeur: libelleEtat, teinteValeur: etat.teinte)
            LigneCleValeur(
                "Claude Code",
                valeur: releve.claudeEnCours == true ? "en cours" : "à l'arrêt",
                derniere: true
            )
        }
    }

    /// `☠` Le réveil est un ordre différé : le PC met des secondes à répondre au
    /// paquet magique. Annoncer « réveillé » sur l'accusé serait faux — c'est le
    /// relevé suivant qui le dira.
    private var boutonReveil: some View {
        Button("Réveiller le poste") { Task { await reveiller() } }
            .buttonStyle(.vigieSecondaire)
            .disabled(releve.reveilEnCours)
    }

    private var comptesClaude: some View {
        VStack(alignment: .leading, spacing: Espace.serre) {
            ForEach(releve.comptesClaude) { compte in
                Button { Task { await basculer(vers: compte) } } label: {
                    HStack(spacing: Espace.serre) {
                        Image(systemName: compte.active ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(compte.active ? Couleurs.accentPrimaire : Couleurs.texteTertiaire)
                        Text(compte.label)
                            .corps()
                            .foregroundStyle(Couleurs.encre)
                        Spacer(minLength: 0)
                        if basculeEnCours == compte.id {
                            Text("bascule…")
                                .monoMinuscule()
                                .foregroundStyle(Couleurs.texteTertiaire)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(compte.active || basculeEnCours != nil)
            }
        }
    }

    // MARK: - Ordres

    private func reveiller() async {
        releve.reveilEnCours = true
        defer { releve.reveilEnCours = false }
        let reponse = await client.ecrireNu(StatutPosteApi.self, Route.reveillerPoste)
        retour = reponse.echec?.message
            ?? "Paquet de réveil envoyé — le poste répondra dans les secondes qui viennent."
    }

    /// `☠` Une bascule de compte REDÉMARRE les sessions tmux qui tournaient
    /// dessus : le dire explicitement, sinon un travail en cours semble avoir
    /// disparu tout seul.
    private func basculer(vers compte: CompteClaudeApi) async {
        basculeEnCours = compte.id
        defer { basculeEnCours = nil }
        let reponse = await client.ordonner(
            BasculeCompteApi.self,
            Route.basculerCompteClaude,
            ["account": .texte(compte.id)]
        )
        if let erreur = reponse.echec {
            retour = erreur.message
            return
        }
        let relancees = reponse.charge?.restartedSessions ?? []
        retour = relancees.isEmpty
            ? "Compte basculé sur \(compte.label)."
            : "Compte basculé sur \(compte.label) — sessions relancées : \(relancees.joined(separator: ", "))."
        await releve.relever(client: client)
    }

    // MARK: - Formes

    private var libelleEtat: String {
        switch releve.posteEnLigne {
        case .some(true): return "en ligne"
        case .some(false): return "éteint"
        case nil: return "inconnu"
        }
    }

    private var etat: EtatSemantique {
        // Éteint n'est pas en panne : c'est le régime nominal de la nuit.
        releve.posteEnLigne == true ? .sain : .neutre
    }
}
#endif
