#if canImport(SwiftUI)
import Foundation
import PhotosUI
import SwiftUI
import VigieNoyau

/// Un fil de l'orchestrateur : les tours segmentés, le bloc en cours de frappe,
/// et le composeur.
///
/// `☠` C'est le SEUL écran qui a le droit de battre à 400 ms, et seulement
/// pendant une génération : c'est le seul régime où l'écran change assez vite
/// pour qu'on le regarde. Au repos, il retombe à quatre secondes comme le reste.
///
/// `☠` Le curseur `depuis` n'est jamais remis à zéro tant que le fil est ouvert :
/// re-demander le fil entier à chaque battement de 400 ms le ferait clignoter et
/// rejetterait le défilement à chaque tour.
struct ConversationEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir
    @Environment(Cadence.self) private var cadence

    let identifiant: String
    let titre: String

    @State private var evenements: [EvenementApi] = []
    @State private var propositions: [String: PropositionApi] = [:]
    @State private var detail: DetailFilApi?
    @State private var partiel: PartielApi?
    @State private var curseur = 0
    @State private var generation = false
    @State private var brouillon = ""
    @State private var pieces: [PieceEnAttente] = []
    @State private var envoiEnCours = false
    @State private var refus: ErreurApi?
    @State private var releveA: Date?

    private var cle: String { "fil.\(identifiant)" }

    var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(titre: titre, releveA: releveA)
            entete
            fil
            Composeur(
                texte: $brouillon,
                pieces: pieces,
                generation: generation,
                envoiEnCours: envoiEnCours,
                ajouterPieces: ajouter(_:),
                retirerPiece: { identifiant in pieces.removeAll { $0.id == identifiant } },
                envoyer: { Task { await envoyer() } },
                interrompre: { Task { await interrompre() } }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await ouvrir() }
        .cadencePar(cle) { await battre() }
        .onChange(of: generation) { _, enCours in
            cadence.changerRegime(cle, enCours ? .generation : .repos)
        }
    }

    @ViewBuilder private var entete: some View {
        if let detail {
            EnTeteFilMeta(
                modele: detail.model,
                effort: detail.effort,
                contextPct: detail.contextPct,
                compactions: detail.compactions,
                machine: nil,
                plafondAutonomie: detail.plafondAutonomie
            )
        }
    }

    private var fil: some View {
        ScrollViewReader { defilement in
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.carte) {
                    if let refus, refus.genre != .transport {
                        BandeauAlerte(refus.message, etat: .vigilance)
                    }
                    ForEach(Array(segments.enumerated()), id: \.element.id) { rang, segment in
                        VueSegmentFil(
                            segment: segment,
                            propositionsConnues: propositions,
                            rang: rang
                        )
                    }
                    if let partiel { BlocPartielVue(partiel: partiel) }
                    // Ancre de défilement : le bas du fil, jamais un index de
                    // ligne — les lignes changent, le bas ne bouge pas.
                    Color.clear.frame(height: 1).id(Self.ancreBas)
                }
                .padding(.horizontal, Espace.ecran)
                .padding(.vertical, Espace.standard)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: curseur) { _, _ in
                withAnimation(Mouvement.changementEtat) {
                    defilement.scrollTo(Self.ancreBas, anchor: .bottom)
                }
            }
        }
    }

    private static let ancreBas = "fil.bas"

    private var segments: [SegmentFil] {
        SegmentationFil.segmenter(evenements)
    }

    // MARK: - Relevés

    private func ouvrir() async {
        if let cache = await miroir.lire(DetailFilApi.self, .fil(identifiant)) {
            appliquer(cache.valeur)
            releveA = cache.releveA
        }
        await lireLesPropositions()
    }

    @MainActor private func battre() async {
        // `☠` Le premier appel prend le fil entier ; les suivants n'en prennent
        // que la suite, par le curseur rendu par le serveur.
        if evenements.isEmpty {
            let lecture = await client.lire(
                DetailFilApi.self, Route.fil(identifiant), memoriser: .fil(identifiant)
            )
            if let charge = lecture.charge { appliquer(charge) }
            refus = lecture.erreur
        } else {
            let lecture = await client.lire(
                EvenementsFilApi.self, Route.evenementsFil(identifiant, depuis: curseur)
            )
            if let charge = lecture.charge { appliquerSuite(charge) }
            refus = lecture.erreur
        }
        if refus == nil { releveA = Date() }
    }

    private func appliquer(_ charge: DetailFilApi) {
        detail = charge
        evenements = charge.events
        curseur = charge.cursor
        generation = charge.generating
        partiel = charge.partial
    }

    private func appliquerSuite(_ charge: EvenementsFilApi) {
        // Le serveur ne rend que ce qui suit le curseur : on ajoute, on ne
        // remplace pas — et on se garde d'un doublon si un tour se recroise.
        let connus = Set(evenements.map(\.seq))
        evenements.append(contentsOf: charge.events.filter { !connus.contains($0.seq) })
        curseur = charge.cursor
        generation = charge.generating
        partiel = charge.partial
    }

    /// Un évènement `mandat` ne porte que l'IDENTIFIANT de la proposition : la
    /// carte se remplit en croisant avec la liste des propositions.
    private func lireLesPropositions() async {
        let lecture = await client.lire(
            [PropositionApi].self, Route.propositions, memoriser: .propositions
        )
        guard let charge = lecture.charge else { return }
        propositions = Dictionary(charge.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
    }

    // MARK: - Écritures

    private func ajouter(_ choisies: [PhotosPickerItem]) async {
        for item in choisies {
            guard let piece = await PieceEnAttente.depuis(item) else { continue }
            pieces.append(piece)
        }
    }

    private func envoyer() async {
        let texte = brouillon.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty || !pieces.isEmpty, !envoiEnCours else { return }
        envoiEnCours = true
        defer { envoiEnCours = false }
        // `☠` Le champ est `text`, et un texte VIDE est valide dès qu'il y a une
        // pièce : coller une capture sans écrire un mot est le geste normal.
        var champs: [String: ValeurJSON] = ["text": .texte(texte)]
        if !pieces.isEmpty { champs["pieces"] = .liste(pieces.map(\.charge)) }
        let corps = CorpsJSON(champs)
        switch await client.ecrire(Route.messageFil(identifiant), corps) {
        case .success:
            brouillon = ""
            pieces = []
            await battre()
        case .failure(let erreur):
            refus = erreur
        }
    }

    /// `☠` `interrupted: false` n'est PAS une erreur : le fil ne générait rien.
    private func interrompre() async {
        switch await client.ecrire(Route.interrompreFil(identifiant)) {
        case .success: await battre()
        case .failure(let erreur): refus = erreur
        }
    }
}
#endif
