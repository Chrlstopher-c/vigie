// Vignette d'une pièce jointe déjà servie par le Pi.
//
// `☠` `PieceJointeApi.url` est LA SEULE route du contrat qui rend des octets,
// et elle est protégée par cookie de session (voir `ClientPi.octets`). Un
// `AsyncImage` nu échouerait dessus — d'où ce chargeur qui passe par le client
// unique plutôt que par `URLSession.shared`.
#if canImport(SwiftUI)
import SwiftUI
import UIKit
import VigieNoyau

struct VignettePieceDistante: View {
    let piece: PieceJointeApi
    @Environment(\.clientPi) private var client

    @State private var octets: Data?
    @State private var echec = false
    @State private var visionneuse = false

    private var estImage: Bool { piece.type.hasPrefix("image/") }

    var body: some View {
        Group {
            if estImage, let octets, let image = UIImage(data: octets) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if echec || !estImage {
                tuileDocument
            } else {
                SqueletteVigie(hauteur: 64)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Rayon.boutonPetit, style: .continuous)
                .strokeBorder(Couleurs.filet, lineWidth: Trait.filet)
        )
        .contentShape(.rect)
        .onTapGesture { if octets != nil || !estImage { visionneuse = true } }
        .task { await charger() }
        .fullScreenCover(isPresented: $visionneuse) {
            VisionneusePieceEcran(piece: piece, octetsDejaCharges: octets)
        }
    }

    private var tuileDocument: some View {
        VStack(spacing: Espace.fin) {
            Image(systemName: "doc.fill")
                .font(.system(size: 16))
                .foregroundStyle(Couleurs.texteTertiaire)
            Text(piece.nom)
                .monoMinuscule()
                .foregroundStyle(Couleurs.texteTertiaire)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(4)
        .background(Couleurs.fondCreuse)
    }

    /// Ne charge les octets que pour une image : un PDF ou un texte n'a besoin
    /// d'être récupéré qu'à l'ouverture de la visionneuse, pas pour la vignette.
    private func charger() async {
        guard estImage, octets == nil else { return }
        switch await client.octets(piece.url) {
        case .success(let donnees): octets = donnees
        case .failure: echec = true
        }
    }
}
#endif
