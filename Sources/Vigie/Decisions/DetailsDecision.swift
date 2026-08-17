// Le contenu propre à chaque nature de décision. Trois circuits séparés côté
// serveur, trois lectures séparées ici : un mandat ouvre une équipe, une
// rallonge règle un fil, un arbitrage arrête un travail déjà en cours.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct DetailMandat: View {
    let proposition: PropositionApi

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text(proposition.projet)
                .corpsAccentue()
                .foregroundStyle(Couleurs.encre)
            // H-61 : le droit réel au même rang que le titre, jamais replié.
            bandeDroit
            Text(proposition.objectif)
                .corps()
                .foregroundStyle(Couleurs.texteSecondaire)
                .multilineTextAlignment(.leading)
            LigneCleValeur("Budget", valeur: Lisible.montant(proposition.budgetMaxUsd))
            LigneCleValeur("Moteur", valeur: Lisible.moteur(modele: proposition.modele, effort: proposition.effort))
            LigneCleValeur("Périmètre", valeur: proposition.perimetre, derniere: proposition.critereArret == nil)
            if let critere = proposition.critereArret {
                LigneCleValeur("Critère d'arrêt", valeur: critere, derniere: true)
            }
        }
    }

    /// `☠` `perimetre` est DESCRIPTIF et ne verrouille rien — seul `acces` porte
    /// le droit. Les afficher au même niveau ferait croire à deux garanties.
    private var bandeDroit: some View {
        let ecrit = proposition.acces.ouvreLEcriture
        return HStack(spacing: Espace.serre) {
            Image(systemName: ecrit ? "pencil.circle.fill" : "eye.circle")
                .font(.system(size: 12, weight: .semibold))
            Text(Lisible.portee(proposition.acces))
                .corpsAccentue()
            Spacer(minLength: 0)
        }
        .foregroundStyle((ecrit ? EtatSemantique.danger : .sain).encreSurVoile)
        .padding(.horizontal, Espace.standard)
        .padding(.vertical, Espace.serre)
        .background(
            (ecrit ? EtatSemantique.danger : .sain).voile,
            in: RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous)
        )
    }
}

struct DetailRallonge: View {
    let demande: RallongeApi

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text(Lisible.objetRallonge(demande))
                .corpsAccentue()
                .foregroundStyle(Couleurs.encre)
            Text(demande.motif)
                .corps()
                .foregroundStyle(Couleurs.texteSecondaire)
            // `☠` Les deux volets sont indépendants : n'afficher que ce qui est
            // réellement demandé. Un plafond fabriqué à « 0 » ou « hérité »
            // ferait accorder un réglage que personne n'a demandé.
            if let plage = Lisible.plage(debut: demande.fenetreDebut, fin: demande.fenetreFin) {
                LigneCleValeur("Plage", valeur: plage)
            }
            if let duree = Lisible.duree(debut: demande.fenetreDebut, fin: demande.fenetreFin) {
                LigneCleValeur("Durée", valeur: duree)
            }
            if let objectif = demande.fenetreObjectif {
                LigneCleValeur("Objectif", valeur: objectif)
            }
            LigneCleValeur("Ouvre une équipe", valeur: "non — réglage du fil", derniere: true)
        }
    }
}

struct DetailArbitrage: View {
    let mission: MissionApi

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            Text(mission.title)
                .corpsAccentue()
                .foregroundStyle(Couleurs.encre)
            if let libelle = mission.inspection.libelle {
                Text(libelle)
                    .corps()
                    .foregroundStyle(Couleurs.texteSecondaire)
            }
            if let motif = mission.inspection.motif {
                Text(motif)
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
            LigneCleValeur("Projet", valeur: mission.project)
            LigneCleValeur("Verdict", valeur: mission.inspection.lastVerdict?.rawValue ?? "—", derniere: true)
        }
    }
}
#endif
