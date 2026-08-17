// Carte d'un mandat proposé, au fil de la conversation.
//
// `☠` Le contenu de l'évènement n'est que l'IDENTIFIANT de la proposition —
// voir `SegmentFil.mandat`. La carte se remplit en croisant avec le miroir des
// propositions (`CleMiroir.propositions`, alimenté par le domaine Décisions) ;
// sans correspondance, elle reste honnête plutôt que de rien montrer.
// Trancher le mandat n'est PAS le rôle de cet écran : H-61 veut l'accès au
// même rang que le titre, ce que fait déjà la carte de Décisions — on y renvoie.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct VueMandatFil: View {
    let identifiant: String
    let at: Int
    let connue: PropositionApi?

    var body: some View {
        NavigationLink(value: Domaine.decisions) {
            CarteVigie(relief: .bordee(.accent)) {
                VStack(alignment: .leading, spacing: Espace.fin) {
                    HStack(spacing: Espace.serre) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Couleurs.accentPrimaire)
                        Text("Mandat proposé")
                            .etiquette()
                            .foregroundStyle(Couleurs.accentPrimaire)
                        Spacer(minLength: 0)
                        Text(heureFil(at))
                            .monoMinuscule()
                            .foregroundStyle(Couleurs.texteTertiaire)
                    }
                    contenu
                }
            }
        }
        .buttonStyle(.plain)
        .apparitionDouce()
    }

    @ViewBuilder private var contenu: some View {
        if let connue {
            Text(connue.projet).corpsAccentue().foregroundStyle(Couleurs.encre)
            Text(connue.objectif).secondaire().foregroundStyle(Couleurs.texteSecondaire).lineLimit(2)
            Text(LisiblePortee.portee(connue.acces))
                .legende()
                .foregroundStyle(Couleurs.texteTertiaire)
        } else {
            Text("« \(identifiant) » — ouvre Décisions pour voir le détail et trancher.")
                .secondaire()
                .foregroundStyle(Couleurs.texteSecondaire)
        }
    }
}

/// Le droit accordé, en toutes lettres — même règle que le domaine Décisions
/// (H-61), reformulée ici plutôt qu'importée : deux domaines ne partagent pas
/// leurs internes, seulement le contrat qu'ils lisent tous les deux.
private enum LisiblePortee {
    static func portee(_ acces: AccesMandatApi) -> String {
        acces.ouvreLEcriture
            ? "Modifie les fichiers du projet et peut commiter."
            : "Lit et rapporte. Ne modifie aucun fichier."
    }
}
#endif
