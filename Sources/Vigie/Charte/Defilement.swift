// Réactions au défilement — ce qui distingue immédiatement une liste iOS
// d'une liste web : les éléments ne se contentent pas d'entrer dans le cadre,
// ils y réagissent.
#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Une carte qui se replie légèrement en approchant des bords du cadre.
    /// Opacité, échelle et léger recul en profondeur — jamais de rotation 3D,
    /// qui coûte cher sur A12 et vieillit mal.
    func replisAuxBords() -> some View {
        scrollTransition(axis: .vertical) { contenu, phase in
            contenu
                .opacity(phase.isIdentity ? 1 : 0.35)
                .scaleEffect(phase.isIdentity ? 1 : 0.94)
                .blur(radius: phase.isIdentity ? 0 : 1.5)
        }
    }

    /// Variante douce pour les lignes denses (fil, terminal) : seule l'opacité
    /// bouge. Réduire une ligne de texte la rend illisible avant de disparaître.
    func estompeAuxBords() -> some View {
        scrollTransition(axis: .vertical) { contenu, phase in
            contenu.opacity(phase.isIdentity ? 1 : 0.45)
        }
    }

    /// Entrée par le bas avec ressort, pour un élément qui apparaît en tête de
    /// liste sans que l'utilisateur ait fait défiler.
    func arriveeParLeBas(rang: Int = 0) -> some View {
        modifier(ArriveeParLeBas(rang: rang))
    }

    /// Accroche le défilement sur les éléments : la liste s'arrête sur une
    /// carte, jamais entre deux. À réserver aux listes de cartes pleine largeur.
    func accrocheParElement() -> some View {
        scrollTargetLayout()
    }
}

private struct ArriveeParLeBas: ViewModifier {
    let rang: Int
    @State private var pose = false

    func body(content: Content) -> some View {
        content
            .opacity(pose ? 1 : 0)
            .offset(y: pose ? 0 : 14)
            .scaleEffect(pose ? 1 : 0.97, anchor: .top)
            .onAppear {
                withAnimation(Ressort.cascade(rang)) { pose = true }
            }
    }
}

/// En-tête qui se condense au défilement : le titre rétrécit et une matière
/// translucide apparaît derrière. C'est le geste de barre de navigation d'iOS,
/// que SwiftUI ne donne pas gratuitement hors d'une List.
public struct EnteteCondensable<Contenu: View>: View {
    private let titre: String
    private let contenu: Contenu
    @State private var decalage: CGFloat = 0

    public init(_ titre: String, @ViewBuilder contenu: () -> Contenu) {
        self.titre = titre
        self.contenu = contenu()
    }

    private var condense: Bool { decalage < -18 }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: 0)
                    .onGeometryChange(for: CGFloat.self) { cadre in
                        cadre.frame(in: .scrollView).minY
                    } action: { valeur in
                        withAnimation(Ressort.direct) { decalage = valeur }
                    }
                contenu
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) { barre }
    }

    private var barre: some View {
        HStack {
            Text(titre)
                .font(.system(size: condense ? 19 : 27, weight: .semibold, design: .serif))
                .foregroundStyle(Couleurs.encre)
            Spacer()
        }
        .padding(.horizontal, Espace.ecran)
        .padding(.vertical, condense ? 10 : 16)
        .background {
            if condense {
                Rectangle()
                    .fill(.regularMaterial)
                    .overlay(alignment: .bottom) { FiletHorizontal() }
                    .ignoresSafeArea(edges: .top)
                    .transition(.opacity)
            }
        }
    }
}
#endif
