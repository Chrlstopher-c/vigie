// Rendu d'un `BlocAgent` — les briques d'un tour de l'orchestrateur : ce
// qu'il dit (marché, à nu), ce qu'il pense (replié), ses outils (groupés,
// repliés), ses échecs et les faits du harness (toujours visibles).
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct VueBlocAgent: View {
    let bloc: BlocAgent

    var body: some View {
        switch bloc {
        case .parole(_, let texte, _):
            RenduMarkdown(texte)
        case .reflexion(_, let texte, _):
            VueReflexion(texte: texte)
        case .outils(let groupe):
            VueGroupeOutils(groupe: groupe)
        case .echec(_, let texte, _):
            BandeauAlerte(texte, etat: .danger)
        case .fait(_, let texte, let at):
            LigneFil(horodatage: heureFil(at), genre: .systeme, texte: texte)
        }
    }
}

/// Le raisonnement de l'agent. Replié par défaut : c'est ce qu'on lit en
/// creusant, pas ce qu'on vient chercher.
private struct VueReflexion: View {
    let texte: String
    @State private var deplie = false

    var body: some View {
        DisclosureGroup(isExpanded: $deplie) {
            Text(texte)
                .secondaire()
                .foregroundStyle(Couleurs.texteSecondaire)
                .italic()
                .padding(.top, Espace.fin)
        } label: {
            HStack(spacing: Espace.serre) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 10.5))
                Text("Raisonnement")
                    .legende()
            }
            .foregroundStyle(Couleurs.texteTertiaire)
        }
        .tint(Couleurs.texteTertiaire)
        .animation(Ressort.direct, value: deplie)
    }
}

/// Une rafale d'appels d'outils, résumée en une ligne. `☠` Elle se referme dès
/// que l'agent reprend la parole (voir `SegmentationFil`) : ouvrir huit cartes
/// pour un tour rendrait le fil illisible.
private struct VueGroupeOutils: View {
    let groupe: GroupeOutils
    @State private var deplie = false

    var body: some View {
        DisclosureGroup(isExpanded: $deplie) {
            VStack(alignment: .leading, spacing: Espace.serre) {
                ForEach(groupe.appels) { appel in
                    VueAppelOutil(appel: appel)
                }
            }
            .padding(.top, Espace.fin)
        } label: {
            resume
        }
        .tint(Couleurs.texteSecondaire)
        .animation(Ressort.direct, value: deplie)
    }

    private var resume: some View {
        HStack(spacing: Espace.serre) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 11))
            Text(libelleResume)
                .secondaire()
            if groupe.enAttente > 0 {
                PointVital(etat: .neutre, vivant: true)
            }
            if groupe.echecs > 0 {
                PastilleEtat("\(groupe.echecs) échec\(groupe.echecs > 1 ? "s" : "")", etat: .danger)
            }
        }
        .foregroundStyle(Couleurs.texteSecondaire)
    }

    private var libelleResume: String {
        let n = groupe.appels.count
        return n == 1 ? (groupe.appels.first?.nom ?? "outil") : "\(n) appels d'outils"
    }
}

/// Un appel unique, déplié : nom, paramètres, résultat — ou l'attente.
private struct VueAppelOutil: View {
    let appel: AppelOutil

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.fin) {
            Text(appel.nom).monoPetit().foregroundStyle(Couleurs.encre)
            if let detail = appel.detail, !detail.isEmpty {
                Text(detail).monoMinuscule().foregroundStyle(Couleurs.texteTertiaire).lineLimit(3)
            }
            resultat
        }
        .padding(Espace.serre)
        .background(appel.enEchec ? Couleurs.etatDangerVoile : Couleurs.fondCreuse,
                    in: RoundedRectangle(cornerRadius: Rayon.etiquette, style: .continuous))
    }

    @ViewBuilder private var resultat: some View {
        if let resultat = appel.resultat {
            Text(resultat)
                .monoMinuscule()
                .foregroundStyle(appel.enEchec ? Couleurs.etatDanger : Couleurs.texteSecondaire)
                .lineLimit(6)
        } else {
            HStack(spacing: Espace.fin) {
                PointVital(etat: .neutre, vivant: true)
                Text("en attente de résultat").legende().foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }
}
#endif
