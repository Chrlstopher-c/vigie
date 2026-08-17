// Le composeur : saisie multiligne, pièces jointes en attente, bouton
// d'envoi qui devient bouton d'ARRÊT pendant que l'orchestrateur génère.
//
// `☠` Le bouton n'est jamais désactivé pendant la génération (revue du
// 07/08 côté web) : le harness met les messages en file d'attente, rien
// n'interdit d'écrire pendant que l'orchestrateur répond. Le désactiver
// priverait l'opérateur du seul moyen d'interrompre un tour.
#if canImport(SwiftUI)
import PhotosUI
import SwiftUI
import UIKit

struct Composeur: View {
    @Binding var texte: String
    let pieces: [PieceEnAttente]
    let generation: Bool
    let envoiEnCours: Bool
    let ajouterPieces: ([PhotosPickerItem]) async -> Void
    let retirerPiece: (PieceEnAttente.ID) -> Void
    let envoyer: () -> Void
    let interrompre: () -> Void

    @State private var selectionPhotos: [PhotosPickerItem] = []

    private var videDeContenu: Bool {
        texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pieces.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.serre) {
            if !pieces.isEmpty { rangeePieces }
            HStack(alignment: .bottom, spacing: Espace.serre) {
                boutonTrombone
                ChampSaisie(texte: $texte, placebo: "Message à l'orchestrateur…", lignes: 1...6)
                    .frame(maxWidth: .infinity)
                boutonEnvoi
            }
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.vertical, Espace.standard)
        .background(.regularMaterial)
        .overlay(alignment: .top) { FiletHorizontal() }
        .onChange(of: selectionPhotos) { _, nouvelle in
            guard !nouvelle.isEmpty else { return }
            Task {
                await ajouterPieces(nouvelle)
                selectionPhotos = []
            }
        }
    }

    private var rangeePieces: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Espace.serre) {
                ForEach(pieces) { piece in
                    VignettePieceEnAttente(piece: piece) { retirerPiece(piece.id) }
                }
            }
        }
    }

    private var boutonTrombone: some View {
        PhotosPicker(
            selection: $selectionPhotos,
            maxSelectionCount: max(1, PieceEnAttente.plafondParMessage - pieces.count),
            matching: .images
        ) {
            Image(systemName: "paperclip")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Couleurs.texteSecondaire)
                .frame(width: 40, height: 40)
        }
        .disabled(pieces.count >= PieceEnAttente.plafondParMessage)
    }

    @ViewBuilder private var boutonEnvoi: some View {
        if generation {
            Button(action: interrompre) {
                Image(systemName: "stop.fill").font(.system(size: 13, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.vigieDestructif)
            .reagitAuToucher()
        } else {
            Button(action: envoyer) {
                Image(systemName: "arrow.up").font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.vigieAccent)
            .reagitAuToucher()
            .disabled(videDeContenu || envoiEnCours)
            .opacity(videDeContenu ? 0.5 : 1)
        }
    }
}

/// Vignette d'une pièce PAS ENCORE envoyée — mémoire locale, jamais l'URL du
/// Pi qui n'existe pas encore.
private struct VignettePieceEnAttente: View {
    let piece: PieceEnAttente
    let retirer: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            apercu
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous)
                        .strokeBorder(Couleurs.filet, lineWidth: Trait.filet)
                )
            Button(action: retirer) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Couleurs.texteSurSombre, Couleurs.encre)
            }
            .offset(x: 5, y: -5)
        }
        .apparitionDouce()
    }

    @ViewBuilder private var apercu: some View {
        if piece.type.hasPrefix("image/"), let image = UIImage(data: piece.donnees) {
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
        } else {
            VStack(spacing: 2) {
                Image(systemName: "doc.fill").font(.system(size: 14))
                Text(piece.tailleLisible).monoMinuscule()
            }
            .foregroundStyle(Couleurs.texteTertiaire)
            .background(Couleurs.fondCreuse)
        }
    }
}
#endif
