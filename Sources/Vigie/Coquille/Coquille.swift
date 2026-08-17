#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Les domaines de Vigie.
///
/// `☠` **C'est le SEUL point de couplage entre les domaines.** Retirer un
/// domaine du produit doit être une ligne à supprimer ici, et rien d'autre.
/// Aucun écran n'a le droit d'en nommer un autre autrement qu'à travers ce type.
public enum Domaine: String, CaseIterable, Identifiable, Hashable, Sendable {
    /// L'atterrissage : file des décisions et pouls du parc.
    case quart
    /// Mandats, rallonges, arbitrages d'inspection — le domaine prioritaire.
    case decisions
    /// Les fils de l'orchestrateur.
    case fil
    /// Missions, détail d'équipe, sous-agents.
    case parc
    /// État, métriques, comptes Claude, réveil.
    case machines
    /// Le terminal tmux.
    case terminal
    case reglages
    /// L'état du canal d'alerte. Hors barre : on y va depuis les réglages, et
    /// une notification peut y renvoyer directement.
    case alerte

    public var id: String { rawValue }

    /// Ce que la barre affiche, dans cet ordre. `alerte` n'y est pas : sept
    /// entrées tiennent sur un écran de 5,8 pouces, huit non.
    public static let barre: [Domaine] = [
        .quart, .decisions, .fil, .parc, .machines, .terminal, .reglages,
    ]

    public var titre: String {
        switch self {
        case .quart: return "Quart"
        case .decisions: return "Décisions"
        case .fil: return "Fil"
        case .parc: return "Parc"
        case .machines: return "Machines"
        case .terminal: return "Terminal"
        case .reglages: return "Réglages"
        case .alerte: return "Alerte"
        }
    }

    /// Symboles volontairement anciens (iOS 14 au plus tard) : l'appareil est
    /// plafonné iOS 18 et un symbole absent se rend en carré vide, sans erreur.
    public var symbole: String {
        switch self {
        case .quart: return "house.fill"
        case .decisions: return "hand.raised.fill"
        case .fil: return "bubble.left.and.bubble.right.fill"
        case .parc: return "square.stack.3d.up.fill"
        case .machines: return "desktopcomputer"
        case .terminal: return "terminal.fill"
        case .reglages: return "gearshape.fill"
        case .alerte: return "bell.badge.fill"
        }
    }

    /// La vue racine du domaine. Chaque racine s'instancie SANS argument : tout
    /// ce dont elle a besoin vient de l'environnement (`\.clientPi`, `\.miroir`,
    /// `Cadence`, `Liaison`).
    @MainActor @ViewBuilder
    public var racine: some View {
        switch self {
        case .quart: QuartEcran()
        case .decisions: DecisionsEcran()
        case .fil: FilEcran()
        case .parc: ParcEcran()
        case .machines: MachinesEcran()
        case .terminal: TerminalEcran()
        case .reglages: ReglagesEcran()
        case .alerte: AlerteEcran()
        }
    }
}

/// La coquille : bandeau de liaison en haut, domaine au milieu, barre en bas.
///
/// Chaque domaine garde sa propre pile de navigation, vivante même quand il
/// n'est pas visible : revenir sur un fil ne doit jamais rejeter la position de
/// lecture. Sept piles simultanées coûtent quelques kilo-octets ; les recréer
/// coûterait un aller-retour réseau et un défilement perdu à chaque bascule.
public struct Coquille: View {
    @Environment(Cablage.self) private var cablage
    @Environment(Cadence.self) private var cadence
    @Environment(Liaison.self) private var liaison
    @Environment(\.scenePhase) private var phaseScene
    @Environment(\.clientPi) private var client

    @State private var domaine: Domaine = .quart
    @State private var amorce = false
    @State private var action = ActionRecue.partage

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            BandeauLien()
            contenu
            BarreDomaines(choisi: $domaine)
        }
        .background(Couleurs.fond)
        .preferredColorScheme(.light)
        .task { await amorcer() }
        .onChange(of: phaseScene) { _, phase in reagirALaScene(phase) }
        .onChange(of: action.ouverture) { _, demande in suivre(demande) }
        .fullScreenCover(isPresented: sessionAOuvrir) { EcranConnexion() }
    }

    private var contenu: some View {
        ZStack {
            ForEach(Domaine.barre) { candidat in
                NavigationStack {
                    candidat.racine
                        .navigationDestination(for: Domaine.self) { $0.racine }
                }
                .opacity(candidat == domaine ? 1 : 0)
                .allowsHitTesting(candidat == domaine)
                .environment(\.ecranVisible, candidat == domaine)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// La connexion s'impose dès que la liaison dit « session à rouvrir » : ni
    /// un écran d'erreur, ni un bouton à trouver. Sans session, rien n'est
    /// lisible, il n'y a donc rien d'autre à montrer.
    private var sessionAOuvrir: Binding<Bool> {
        Binding(
            get: { amorce && liaison.regime == .sessionRequise },
            set: { _ in }
        )
    }

    private func amorcer() async {
        guard !amorce else { return }
        await cablage.amorcer()
        let ouverte = await client.sessionOuverte
        if !ouverte { liaison.exigerSession() }
        amorce = true
    }

    /// Une notification touchée amène sur son domaine. `alerte` n'étant pas dans
    /// la barre, on retombe sur les Réglages, d'où il est accessible.
    private func suivre(_ demande: OuvertureDemandee?) {
        guard let demande else { return }
        withAnimation(Mouvement.changementEtat) {
            domaine = Domaine.barre.contains(demande.domaine) ? demande.domaine : .reglages
        }
        action.ouverture = nil
    }

    private func reagirALaScene(_ phase: ScenePhase) {
        cadence.scene(phase)
        // Le rattrapage d'ouverture : le canal 2, déterministe, celui qui rend
        // compte de tout ce qui s'est passé pendant que Vigie ne tournait pas.
        if phase == .active, amorce {
            Task { await CentreAlerte.partage.sonder(origine: .ouverture) }
        }
        guard phase != .active else { return }
        // Dernier instant garanti avant une mise à mort : le miroir doit être
        // sur le disque, pas dans un regroupement d'écriture en attente.
        Task { [miroir = cablage.miroir] in await miroir.ecrireMaintenant() }
    }
}

/// La barre de domaines. Écrite à la main plutôt qu'avec `TabView` : au-delà de
/// cinq onglets, `TabView` replie les suivants derrière un onglet « Plus » qui
/// les relègue dans une liste système, hors charte et à deux gestes de distance.
private struct BarreDomaines: View {
    @Binding var choisi: Domaine

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Domaine.barre) { domaine in
                Button {
                    guard domaine != choisi else { return }
                    withAnimation(Mouvement.changementEtat) { choisi = domaine }
                } label: {
                    etiquette(domaine)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Espace.serre)
        .padding(.horizontal, Espace.fin)
        .background(alignment: .top) { FiletHorizontal() }
        .background(Couleurs.fond)
    }

    private func etiquette(_ domaine: Domaine) -> some View {
        let actif = domaine == choisi
        return VStack(spacing: 3) {
            Image(systemName: domaine.symbole)
                .font(.system(size: 16, weight: actif ? .semibold : .regular))
            Text(domaine.titre)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(actif ? Couleurs.encre : Couleurs.texteTertiaire)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espace.fin)
        .contentShape(Rectangle())
    }
}
#endif
