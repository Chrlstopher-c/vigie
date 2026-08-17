// Gestes natifs — ce qu'un doigt attend sur iOS et qu'aucun bouton ne remplace.
//
// Le glissement latéral, l'appui long qui soulève, la feuille à hauteurs
// multiples : trois idiomes que le web ne possède pas, et dont l'absence se
// remarque plus que celle d'une couleur.
#if canImport(SwiftUI)
import SwiftUI

/// Action de glissement, avec sa teinte et son retour haptique.
public struct ActionGlissee: Identifiable, Sendable {
    public let id = UUID()
    public let libelle: String
    public let symbole: String
    public let etat: EtatSemantique
    public let destructive: Bool
    public let effet: @MainActor @Sendable () -> Void

    public init(
        _ libelle: String,
        symbole: String,
        etat: EtatSemantique = .neutre,
        destructive: Bool = false,
        effet: @escaping @MainActor @Sendable () -> Void
    ) {
        self.libelle = libelle
        self.symbole = symbole
        self.etat = etat
        self.destructive = destructive
        self.effet = effet
    }
}

public extension View {
    /// Glissement vers la gauche : les actions engageantes.
    /// `☠` La première action de la liste est celle qu'un glissement franc
    /// déclenche sans lever le doigt — n'y placer jamais une action destructive
    /// non confirmable.
    func actionsGlissees(_ actions: [ActionGlissee]) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: !(actions.first?.destructive ?? false)) {
            ForEach(actions) { action in
                Button(role: action.destructive ? .destructive : nil) {
                    action.effet()
                } label: {
                    Label(action.libelle, systemImage: action.symbole)
                }
                .tint(action.etat.teinte)
            }
        }
    }

    /// Appui long qui soulève l'élément et présente ses actions, avec un aperçu
    /// agrandi. L'équivalent tactile du clic droit, et le seul endroit où l'on
    /// peut offrir beaucoup d'options sans encombrer l'écran.
    func menuAuToucher<Actions: View, Apercu: View>(
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder apercu: () -> Apercu
    ) -> some View {
        contextMenu(menuItems: actions, preview: apercu)
    }

    /// Feuille modale à la manière d'iOS : hauteurs multiples, poignée, coins
    /// arrondis, fond translucide. Une modale plein écran pour montrer trois
    /// lignes est un réflexe web.
    func feuille<Contenu: View>(
        presentee: Binding<Bool>,
        hauteurs: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder contenu: @escaping () -> Contenu
    ) -> some View {
        sheet(isPresented: presentee) {
            contenu()
                .presentationDetents(hauteurs)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.regularMaterial)
        }
    }

    /// Rétrécissement au contact, avec ressort au relâchement.
    ///
    /// `☠` **JAMAIS sur un `Button` ni sur un `NavigationLink`.** Il pose un
    /// `onLongPressGesture`, qui gagne la course contre le geste interne du
    /// bouton : le toucher est avalé, l'action ne part pas, et rien ne le
    /// signale — l'écran a juste l'air mort. Pour une carte cliquable, c'est
    /// `.buttonStyle(.vigieCarte)` qu'il faut, dont le retour vient de
    /// `configuration.isPressed` et non d'un geste concurrent.
    ///
    /// Réservé, donc, à ce qui se touche SANS être interactif : une vignette
    /// décorative, un bloc qui n'ouvre rien.
    func reagitAuToucher(echelle: CGFloat = 0.97) -> some View {
        modifier(ReagitAuToucher(echelle: echelle))
    }
}

private struct ReagitAuToucher: ViewModifier {
    let echelle: CGFloat
    @State private var presse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(presse ? echelle : 1)
            .animation(Ressort.direct, value: presse)
            .onLongPressGesture(minimumDuration: 0, pressing: { enCours in
                presse = enCours
            }, perform: {})
            .sensoryFeedback(Retour.contact, trigger: presse) { _, nouveau in nouveau }
    }
}

/// Bouton armé : il faut maintenir le doigt pour que l'action parte. Réservé
/// aux gestes irréversibles — éteindre une machine, couper le parc.
/// L'anneau se remplit pendant l'appui et l'haptique s'intensifie.
public struct GesteArme: View {
    private let libelle: String
    private let duree: Double
    private let action: @MainActor () -> Void

    @State private var avancee: Double = 0
    @State private var enCours = false

    public init(_ libelle: String, duree: Double = 1.5, action: @escaping @MainActor () -> Void) {
        self.libelle = libelle
        self.duree = duree
        self.action = action
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Rayon.bouton)
                .fill(Couleurs.etatDangerVoile)
            GeometryReader { cadre in
                RoundedRectangle(cornerRadius: Rayon.bouton)
                    .fill(Couleurs.etatDanger.opacity(0.85))
                    .frame(width: cadre.size.width * avancee)
            }
            Text(enCours ? "Maintiens…" : libelle)
                .libelleBouton()
                .foregroundStyle(avancee > 0.5 ? Couleurs.texteSurSombre : Couleurs.etatDanger)
        }
        .clipShape(.rect(cornerRadius: Rayon.bouton))
        .frame(height: 46)
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: duree, pressing: { presse in
            enCours = presse
            withAnimation(.linear(duration: presse ? duree : 0.2)) {
                avancee = presse ? 1 : 0
            }
        }, perform: {
            Texture.partagee.acquiescement()
            action()
        })
        .sensoryFeedback(Retour.engagement, trigger: enCours) { _, nouveau in nouveau }
    }
}
#endif
