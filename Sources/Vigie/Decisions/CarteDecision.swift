// La carte d'une décision : ce qu'on lit avant de trancher, et les deux gestes.
//
// `☠` H-61 — autorisation ÉCLAIRÉE : le droit réel (`acces`) est au même rang
// que le titre, jamais replié. Une équipe annoncée « lecture seule » recevait
// les mêmes outils qu'une équipe de modification tant que ce champ n'était pas
// montré ; le périmètre, lui, est purement descriptif et ne verrouille rien.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct CarteDecision: View {
    let decision: Decision
    let rang: Int
    let occupee: Bool
    let conduite: ConduiteApresConflit?
    let accorder: () async -> Void
    let refuser: () async -> Void

    var body: some View {
        CarteVigie(relief: ecritureOuverte ? .active : .bordee(etat)) {
            VStack(alignment: .leading, spacing: Espace.carte) {
                entete
                corpsDeLaCarte
                if let conduite { BlocConduite(conduite: conduite) }
                if conduite?.reArmable ?? true { gestes }
            }
        }
        .apparitionDouce(rang: rang)
    }

    // MARK: - En-tête

    private var entete: some View {
        HStack(spacing: Espace.serre) {
            Image(systemName: decision.genre.symbole)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(etat.teinte)
            PastilleEtat(decision.genre.titre, etat: etat)
            Spacer(minLength: 0)
            Text(Lisible.heure(millisecondes))
                .monoMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
        }
    }

    @ViewBuilder private var corpsDeLaCarte: some View {
        switch decision {
        case .mandat(let proposition): DetailMandat(proposition: proposition)
        case .rallonge(let demande): DetailRallonge(demande: demande)
        case .arbitrage(let mission): DetailArbitrage(mission: mission)
        }
    }

    // MARK: - Gestes

    /// Deux boutons, jamais un seul geste ambigu, et jamais de confirmation
    /// intermédiaire : la garde biométrique EST la confirmation.
    private var gestes: some View {
        HStack(spacing: Espace.standard) {
            Button(libelleRefus) { Task { await refuser() } }
                .buttonStyle(.vigieDestructif)
                .disabled(occupee)
            Button(libelleAccord) { Task { await accorder() } }
                .buttonStyle(.vigieAccent)
                .disabled(occupee)
        }
        .frame(maxWidth: .infinity)
        .opacity(occupee ? 0.5 : 1)
    }

    private var libelleAccord: String {
        switch decision {
        case .mandat: return "Autoriser"
        case .rallonge: return "Accorder"
        case .arbitrage: return "Laisser poursuivre"
        }
    }

    private var libelleRefus: String {
        switch decision {
        case .mandat, .rallonge: return "Refuser"
        case .arbitrage: return "Arrêter l'équipe"
        }
    }

    // MARK: - Formes

    private var etat: EtatSemantique {
        switch decision.genre {
        case .arbitrage: return .danger
        case .mandat: return .accent
        case .rallonge: return .vigilance
        }
    }

    /// Seul un mandat en écriture engage une modification de fichiers : c'est ce
    /// qui justifie le relief le plus appuyé de la charte.
    private var ecritureOuverte: Bool {
        guard case .mandat(let proposition) = decision else { return false }
        return proposition.acces.ouvreLEcriture
    }

    private var millisecondes: Int {
        switch decision {
        case .arbitrage(let mission): return mission.inspection.lastAt ?? 0
        case .mandat(let proposition): return proposition.creeA
        case .rallonge(let demande): return demande.creeA
        }
    }
}

/// Le refus du serveur, mot pour mot, et la conduite à tenir — jamais l'un sans
/// l'autre : le message dit ce qui s'est passé, jamais où aller.
private struct BlocConduite: View {
    let conduite: ConduiteApresConflit

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.fin) {
            HStack(spacing: Espace.serre) {
                PastilleEtat(conduite.titre, etat: conduite.etat)
                Spacer(minLength: 0)
                if let sceau = conduite.sceau {
                    Text(sceau)
                        .etiquetteMinuscule()
                        .foregroundStyle(conduite.etat.encreSurVoile)
                }
            }
            Text(conduite.motifServeur)
                .monoPetit()
                .foregroundStyle(Couleurs.encre)
            Text(conduite.conduite)
                .legende()
                .foregroundStyle(Couleurs.texteSecondaire)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.standard)
        .background(
            conduite.etat.voile,
            in: RoundedRectangle(cornerRadius: Rayon.encart, style: .continuous)
        )
    }
}
#endif
