// La carte — brique de base de tous les écrans (.card / .mcard de la maquette).
// Surface blanche, filet, rayon 14 ; le relief porte l'état de ce qu'elle contient.
#if canImport(SwiftUI)
import SwiftUI

public struct CarteVigie<Contenu: View>: View {

    public enum Relief: Sendable {
        /// Carte standard.
        case standard
        /// Réclame l'attention : bande accent + fond dégradé + halo (.mcard.act).
        case active
        /// Bande latérale d'état sans emphase de fond (.paused / .dead).
        case bordee(EtatSemantique)
        /// Contenu clos, atténué (.done).
        case eteinte
    }

    private let relief: Relief
    private let contenu: Contenu

    public init(relief: Relief = .standard, @ViewBuilder contenu: () -> Contenu) {
        self.relief = relief
        self.contenu = contenu()
    }

    public var body: some View {
        contenu
            .padding(Espace.carte)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fondCarte)
            .overlay(alignment: .leading) { bandeLaterale }
            .clipShape(RoundedRectangle(cornerRadius: Rayon.carte, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Rayon.carte, style: .continuous)
                    .strokeBorder(couleurFilet, lineWidth: Trait.filet)
            )
            .modifier(HaloSiActive(active: estActive))
            .opacity(estEteinte ? 0.62 : 1)
            .animation(Mouvement.changementEtat, value: estActive)
    }

    private var estActive: Bool { if case .active = relief { true } else { false } }
    private var estEteinte: Bool { if case .eteinte = relief { true } else { false } }

    @ViewBuilder private var fondCarte: some View {
        if estActive {
            LinearGradient(
                colors: [Couleurs.accentVoile, Couleurs.surface],
                startPoint: .top, endPoint: .init(x: 0.5, y: 0.58)
            )
        } else {
            Couleurs.surface
        }
    }

    @ViewBuilder private var bandeLaterale: some View {
        switch relief {
        case .active:
            Rectangle().fill(Couleurs.accentPrimaire).frame(width: Trait.bandeEtat)
        case .bordee(let etat):
            Rectangle().fill(etat.teinte).frame(width: Trait.bandeEtat)
        case .standard, .eteinte:
            EmptyView()
        }
    }

    private var couleurFilet: Color {
        estActive ? Couleurs.accentPrimaire : Couleurs.filet
    }
}

/// Halo d'accent appliqué seulement quand la carte est active.
private struct HaloSiActive: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active { content.ombreActive() } else { content }
    }
}
#endif
