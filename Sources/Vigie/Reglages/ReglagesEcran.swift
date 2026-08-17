#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Adresse du Pi, session, réglages de l'orchestrateur, canal d'alerte et
/// échéance de signature. Racine du domaine `Réglages`.
///
/// Contrat de cette racine, tenu par `Domaine.racine` :
///  - elle s'instancie SANS argument ;
///  - tout ce dont elle a besoin vient de l'environnement :
///    `@Environment(\.clientPi)`, `@Environment(\.miroir)`,
///    `@Environment(Cadence.self)`, `@Environment(Liaison.self)` ;
///  - elle lit le miroir AVANT le réseau, et n'affiche jamais d'attente quand
///    une donnée datée existe ;
///  - elle se branche sur la minuterie par `.cadencePar("reglages") { … }`,
///    jamais par un `Timer` à elle.
///
/// `☠` Régime `.aLaDemande` et non `.repos` : le catalogue de modèles et les
/// comptes Claude Code ne bougent pas toutes les quatre secondes. Un aller-
/// retour à l'ouverture, un autre au retour au premier plan ou au tiré pour
/// rafraîchir — jamais une boucle pour un écran de réglages.
public struct ReglagesEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var modeles: [ModeleApi] = []
    @State private var comptes: [CompteClaudeApi] = []
    @State private var toast: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.reglages)
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .congedieLeClavier()
        .toastVigie(message: $toast)
        .task { await depuisMiroir() }
        .cadencePar("reglages", regime: .aLaDemande) { await rafraichir() }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                SectionServeur(toast: poser)
                SectionOrchestrateur(modeles: modeles, comptes: comptes, bascule: bascule)
                SectionAlerte()
                SectionAPropos()
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.bottom, Espace.section)
        }
        .scrollIndicators(.hidden)
        .refreshable { await rafraichir() }
    }

    @MainActor private func poser(_ message: String) {
        toast = message
    }

    // MARK: - Relevés

    @MainActor private func depuisMiroir() async {
        if let donnee = await miroir.lire([ModeleApi].self, .modeles) {
            modeles = donnee.valeur
        }
        if let donnee = await miroir.lire(ComptesClaudeApi.self, .comptesClaude) {
            comptes = donnee.valeur.accounts ?? []
        }
    }

    @MainActor private func rafraichir() async {
        let lecture = await client.lire([ModeleApi].self, Route.modeles, memoriser: .modeles)
        if let charge = lecture.charge { modeles = charge }
        switch await client.lirePoste(ComptesClaudeApi.self, Route.comptesClaude, memoriser: .comptesClaude) {
        case .fraiche(let charge):
            comptes = charge.accounts ?? []
        case .pcAbsent, .refus, .echec:
            break
        }
    }

    // MARK: - Gestes

    @MainActor private func bascule(_ compte: CompteClaudeApi) async {
        let corps: CorpsJSON = ["account": .texte(compte.id)]
        switch await client.ordonner(BasculeCompteApi.self, Route.basculerCompteClaude, corps) {
        case .fraiche(let accuse):
            poser(accuse.status == "already_active" ? "Déjà le compte actif" : "Compte changé")
            await rafraichir()
        case .pcAbsent(let message), .refus(let message):
            poser(message)
        case .echec(let erreur):
            poser(erreur.message)
        }
    }
}
#endif
