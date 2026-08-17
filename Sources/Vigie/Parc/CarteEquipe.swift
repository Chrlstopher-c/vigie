// Une équipe dans la liste du parc : ce qu'elle fait, ce qu'elle coûte, ce
// qu'elle risque de perdre.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct CarteEquipe: View {
    let mission: MissionApi

    private var etat: EtatEquipe { EtatEquipe(mission.state) }

    var body: some View {
        CarteVigie(relief: .bordee(semantique)) {
            VStack(alignment: .leading, spacing: Espace.standard) {
                entete
                Text(mission.title)
                    .corpsAccentue()
                    .foregroundStyle(Couleurs.encre)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                pied
                if let avertissement = ConstatDepot.lire(mission.git).avertissement {
                    Text(avertissement)
                        .legende()
                        .foregroundStyle(EtatSemantique.vigilance.teinte)
                }
            }
        }
    }

    private var entete: some View {
        HStack(spacing: Espace.serre) {
            PointVital(etat: semantique, vivant: etat.respire)
            Text(etat.libelle)
                .etiquette()
                .foregroundStyle(semantique.teinte)
            Spacer(minLength: 0)
            if let anciennete = EtatEquipe.anciennete(mission) {
                Text(anciennete)
                    .monoMinuscule()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    private var pied: some View {
        HStack(spacing: Espace.serre) {
            PuceMono(mission.project)
            if let machine = mission.machine { PuceMono(machine) }
            Spacer(minLength: 0)
            Text(ConsommationEquipe.montant(mission.cost))
                .monoPetit()
                .foregroundStyle(Couleurs.texteSecondaire)
            Text(ConsommationEquipe.contexteLisible(mission))
                .monoPetit()
                .foregroundStyle(teinteContexte)
        }
    }

    private var teinteContexte: Color {
        guard ConsommationEquipe.mesure(mission.ctxTokens) else { return Couleurs.texteTertiaire }
        switch ConsommationEquipe.tonContexte(mission.ctx) {
        case .alerte: return EtatSemantique.danger.teinte
        case .veille: return EtatSemantique.vigilance.teinte
        default: return Couleurs.texteSecondaire
        }
    }

    /// La traduction du ton d'équipe en couleur de charte. `☠` Terminée et
    /// « au repos » restent NEUTRES : elles n'appellent rien, et c'est ce qui
    /// rend les états qui appellent lisibles d'un coup d'œil.
    private var semantique: EtatSemantique {
        switch etat.ton {
        case .attente: return .accent
        case .actif: return .sain
        case .veille: return .vigilance
        case .alerte: return .danger
        case .clos, .neutre: return .neutre
        }
    }
}
#endif
