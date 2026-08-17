#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Le bandeau d'état de liaison, visible en permanence, en haut de tout écran.
///
/// Il répond à une seule question, et il doit y répondre sans qu'on la pose :
/// **est-ce que ce que je regarde est frais ?** Un écran qui ne le dit pas
/// oblige à deviner, et une donnée de la veille prise pour l'instant présent est
/// pire qu'un écran vide.
///
/// `☠` Les trois régimes ne sont pas trois niveaux de gravité. « PC éteint » est
/// le fonctionnement NORMAL des nuits : le Pi répond, le registre est à jour, le
/// poste de travail dort. Le peindre en rouge ferait chercher une panne trois
/// cent soixante-cinq nuits par an.
public struct BandeauLien: View {
    @Environment(Liaison.self) private var liaison

    public init() {}

    public var body: some View {
        HStack(spacing: Espace.serre) {
            PointVital(etat: etat, vivant: liaison.regime == .nominal)
            Text(liaison.libelle)
                .etiquette()
                .foregroundStyle(etat.encreSurVoile)
            if let precision = liaison.precision {
                PointSeparateur()
                Text(precision)
                    .monoMinuscule()
                    .foregroundStyle(Couleurs.texteTertiaire)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.vertical, Espace.serre)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(etat.voile)
        .overlay(alignment: .bottom) { FiletHorizontal() }
        .animation(Mouvement.changementEtat, value: liaison.regime)
    }

    private var etat: EtatSemantique {
        switch liaison.regime {
        case .nominal: return .sain
        case .posteEteint: return .vigilance
        case .perdue: return .danger
        case .sessionRequise: return .accent
        }
    }
}
#endif
