// Section « Orchestrateur » des Réglages : le profil par défaut d'un nouveau
// fil (modèle, effort, mode rapide, ultracode — voir `PreferencesOrchestrateur`),
// et la bascule de compte Claude Code sur le poste de travail.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct SectionOrchestrateur: View {
    let modeles: [ModeleApi]
    let comptes: [CompteClaudeApi]
    let bascule: @MainActor (CompteClaudeApi) async -> Void

    @State private var modeleId: String? = PreferencesOrchestrateur.modele
    @State private var effort: String? = PreferencesOrchestrateur.effort
    @State private var modeRapide = PreferencesOrchestrateur.modeRapide
    @State private var ultracode = PreferencesOrchestrateur.ultracode
    @State private var compteAConfirmer: CompteClaudeApi?
    @State private var basculeEnCours = false

    private var modeleActuel: ModeleApi? {
        PreferencesOrchestrateur.modeleCourant(dans: modeles)
    }

    var body: some View {
        SectionVigie("Orchestrateur") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.carte) {
                    if modeles.isEmpty {
                        EtatVide(
                            symbole: "cpu",
                            titre: "Catalogue indisponible",
                            explication: "Le Pi n'a pas encore rendu la liste des modèles."
                        )
                    } else {
                        blocModele
                        FiletHorizontal()
                        blocEffort
                        FiletHorizontal()
                        blocBascules
                    }
                }
            }
            FiletHorizontal().padding(.vertical, Espace.fin)
            blocComptes
        }
        .confirmationDialog(
            "Changer de compte Claude Code",
            isPresented: confirmationPresentee,
            titleVisibility: .visible
        ) {
            boutonsConfirmation
        } message: {
            Text("Les sessions tmux en cours vont être redémarrées pour charger le nouveau compte.")
        }
    }

    // MARK: - Modèle et effort

    private var blocModele: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text("Modèle par défaut").etiquette().foregroundStyle(Couleurs.texteTertiaire)
            ScrollView(.horizontal) {
                HStack(spacing: Espace.serre) {
                    ForEach(modeles) { modele in
                        PuceFiltre(modele.label, active: modele.id == modeleActuel?.id) {
                            choisirModele(modele)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder private var blocEffort: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text("Niveau d'effort").etiquette().foregroundStyle(Couleurs.texteTertiaire)
            if let modele = modeleActuel, !modele.effort.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: Espace.serre) {
                        ForEach(modele.effort, id: \.self) { niveau in
                            PuceFiltre(niveau, active: niveau == effort) { choisirEffort(niveau) }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                Text("Ce modèle refuse le paramètre d'effort.")
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    private var blocBascules: some View {
        VStack(alignment: .leading, spacing: 0) {
            BasculeVigie(
                "Mode rapide",
                sousLibelle: modeleActuel?.fastMode == true
                    ? nil : "réservé à la famille Opus récente",
                active: $modeRapide
            )
            .disabled(modeleActuel?.fastMode != true)
            .onChange(of: modeRapide) { _, valeur in PreferencesOrchestrateur.modeRapide = valeur }
            FiletHorizontal()
            BasculeVigie(
                "Ultracode",
                sousLibelle: modeleActuel?.ultracode == true
                    ? "xhigh + orchestration de workflows" : "exige un modèle qui l'accepte",
                active: $ultracode
            )
            .disabled(modeleActuel?.ultracode != true)
            .onChange(of: ultracode) { _, valeur in PreferencesOrchestrateur.ultracode = valeur }
        }
        .sensoryFeedback(Retour.selection, trigger: modeRapide)
        .sensoryFeedback(Retour.selection, trigger: ultracode)
    }

    private func choisirModele(_ modele: ModeleApi) {
        modeleId = modele.id
        PreferencesOrchestrateur.modele = modele.id
        effort = PreferencesOrchestrateur.effortCoherent(pour: modele)
        PreferencesOrchestrateur.effort = effort
        if modele.fastMode != true { modeRapide = false }
        if modele.ultracode != true { ultracode = false }
    }

    private func choisirEffort(_ niveau: String) {
        effort = niveau
        PreferencesOrchestrateur.effort = niveau
    }

    // MARK: - Comptes Claude Code

    private var blocComptes: some View {
        SectionVigie("Compte Claude Code") {
            if comptes.isEmpty {
                EtatVide(
                    symbole: "person.crop.circle.badge.questionmark",
                    titre: "Aucun compte lu",
                    explication: "Le poste de travail doit être en ligne pour lister les comptes."
                )
            } else {
                VStack(spacing: Espace.standard) {
                    ForEach(comptes) { compte in ligneCompte(compte) }
                }
            }
        }
    }

    private func ligneCompte(_ compte: CompteClaudeApi) -> some View {
        CarteVigie(relief: compte.active ? .active : .standard) {
            HStack(spacing: Espace.standard) {
                Text(compte.label).monoDonnee().foregroundStyle(Couleurs.encre)
                Spacer(minLength: 0)
                if compte.active {
                    PastilleEtat("actif", etat: .sain)
                } else {
                    Button("Activer") { compteAConfirmer = compte }
                        .buttonStyle(.vigieSecondaire)
                        .disabled(basculeEnCours)
                }
            }
        }
    }

    private var confirmationPresentee: Binding<Bool> {
        Binding(get: { compteAConfirmer != nil }, set: { present in if !present { compteAConfirmer = nil } })
    }

    @ViewBuilder private var boutonsConfirmation: some View {
        Button("Changer de compte", role: .destructive) {
            guard let compte = compteAConfirmer else { return }
            compteAConfirmer = nil
            Task {
                basculeEnCours = true
                await bascule(compte)
                basculeEnCours = false
            }
        }
        Button("Annuler", role: .cancel) { compteAConfirmer = nil }
    }
}
#endif
