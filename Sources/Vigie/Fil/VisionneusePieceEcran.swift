// Visionneuse plein écran d'une pièce jointe : image zoomable, texte, PDF, ou
// repli honnête pour ce qu'on ne sait pas prévisualiser sur le téléphone.
#if canImport(SwiftUI)
import PDFKit
import SwiftUI
import UIKit
import VigieNoyau

struct VisionneusePieceEcran: View {
    let piece: PieceJointeApi
    let octetsDejaCharges: Data?

    @Environment(\.dismiss) private var fermer
    @Environment(\.clientPi) private var client
    @State private var octets: Data?
    @State private var refus: ErreurApi?

    var body: some View {
        ZStack {
            Couleurs.encre.ignoresSafeArea()
            contenu
            barre
        }
        .task { await charger() }
    }

    @ViewBuilder private var contenu: some View {
        if let octets {
            vueSelonType(octets)
        } else if let refus {
            EtatVide(symbole: "exclamationmark.triangle", titre: "Pièce indisponible", explication: refus.message)
        } else {
            ProgressView().tint(Couleurs.texteSurSombre)
        }
    }

    @ViewBuilder private func vueSelonType(_ octets: Data) -> some View {
        if piece.type.hasPrefix("image/"), let image = UIImage(data: octets) {
            VueImageZoomable(image: image)
        } else if piece.type == "application/pdf" {
            VuePDF(donnees: octets)
        } else if piece.type.hasPrefix("text/") || piece.type == "application/json" {
            ScrollView {
                Text(String(decoding: octets, as: UTF8.self))
                    .terminal()
                    .padding(Espace.ecran)
            }
        } else {
            EtatVide(
                symbole: "doc",
                titre: piece.nom,
                explication: "Ce type de fichier ne se prévisualise pas sur le téléphone."
            )
        }
    }

    private var barre: some View {
        VStack {
            HStack {
                Spacer()
                Button { fermer() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Couleurs.texteSurSombre.opacity(0.85))
                }
            }
            .padding(Espace.ecran)
            Spacer()
            Text(piece.nom)
                .secondaire()
                .foregroundStyle(Couleurs.texteSurSombre.opacity(0.85))
                .padding(.bottom, Espace.section)
        }
    }

    private func charger() async {
        if let octetsDejaCharges { octets = octetsDejaCharges; return }
        switch await client.octets(piece.url) {
        case .success(let donnees): octets = donnees
        case .failure(let erreur): refus = erreur
        }
    }
}

/// Image au doigt : pincer pour zoomer, double-tap pour revenir.
private struct VueImageZoomable: View {
    let image: UIImage
    @State private var echelle: CGFloat = 1

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(echelle)
            .gesture(
                MagnificationGesture()
                    .onChanged { valeur in echelle = valeur }
                    .onEnded { _ in withAnimation(Ressort.direct) { echelle = max(1, min(echelle, 4)) } }
            )
            .onTapGesture(count: 2) { withAnimation(Ressort.direct) { echelle = 1 } }
    }
}

/// `PDFKit` n'a pas d'équivalent SwiftUI natif — le seul pont UIKit du domaine.
private struct VuePDF: UIViewRepresentable {
    let donnees: Data

    func makeUIView(context: Context) -> PDFView {
        let vue = PDFView()
        vue.autoScales = true
        vue.document = PDFDocument(data: donnees)
        vue.backgroundColor = .clear
        return vue
    }

    func updateUIView(_ vue: PDFView, context: Context) {}
}
#endif
