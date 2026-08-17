// Rendu d'un `SegmentFil` — la brique que le fil ouvert empile, dans l'ordre
// que `SegmentationFil.segmenter` a déjà tranché.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct VueSegmentFil: View {
    let segment: SegmentFil
    /// Croisement `PropositionApi` par identifiant, pour les segments `.mandat`.
    /// Voir `VueMandatFil` : sans correspondance, la carte reste honnête.
    let propositionsConnues: [String: PropositionApi]
    let rang: Int

    var body: some View {
        Group {
            switch segment {
            case .operateur(let message):
                VueMessageOperateur(message: message)
            case .tour(let tour):
                VueTourAgent(tour: tour)
            case .mandat(_, let proposition, let at):
                VueMandatFil(identifiant: proposition, at: at, connue: propositionsConnues[proposition])
            case .compaction(_, let resume, let at):
                VueCompaction(resume: resume, at: at)
            }
        }
        // `Ressort.cascade` (via `.arriveeParLeBas`) : chaque segment entre avec
        // un léger décalage selon son rang, plafonné pour ne pas faire attendre
        // le douzième message d'un long fil.
        .arriveeParLeBas(rang: rang)
    }
}

private struct VueMessageOperateur: View {
    let message: MessageOperateur

    var body: some View {
        VStack(alignment: .trailing, spacing: Espace.serre) {
            if !message.pieces.isEmpty { rangeePieces }
            BulleUtilisateur(message.texte)
        }
    }

    private var rangeePieces: some View {
        HStack(spacing: Espace.serre) {
            Spacer(minLength: 0)
            ForEach(message.pieces, id: \.url) { piece in
                VignettePieceDistante(piece: piece)
            }
        }
        .padding(.leading, 54)
    }
}

private struct VueTourAgent: View {
    let tour: TourAgent

    var body: some View {
        BulleAgent {
            VStack(alignment: .leading, spacing: Espace.standard) {
                ForEach(tour.blocs) { bloc in
                    VueBlocAgent(bloc: bloc)
                }
                if let modele = tour.modele {
                    Text(LisibleMoteur.moteur(modele: modele, effort: tour.effort))
                        .monoMinuscule()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
            }
        }
    }
}

/// `résumé du fil compacté` — un filet et une ligne centrée, jamais une bulle :
/// ce n'est ni Chris ni l'agent qui parle, c'est un fait d'administration.
private struct VueCompaction: View {
    let resume: String
    let at: Int

    var body: some View {
        VStack(spacing: Espace.fin) {
            HStack(spacing: Espace.serre) {
                FiletHorizontal()
                Text("Fil compacté · \(heureFil(at))")
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
                    .fixedSize()
                FiletHorizontal()
            }
            if !resume.isEmpty {
                Text(resume)
                    .secondaire()
                    .foregroundStyle(Couleurs.texteSecondaire)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .apparitionDouce()
    }
}

/// Le couple modèle / effort d'un tour — repris de `Decisions/Lisible.swift`
/// dans sa forme, pas dans son code : deux domaines qui ne s'importent pas.
private enum LisibleMoteur {
    static func moteur(modele: String, effort: String?) -> String {
        guard let effort else { return modele }
        return "\(modele) · \(effort)"
    }
}
#endif
