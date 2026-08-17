#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// Les fils de l'orchestrateur : la liste, puis la conversation.
public struct FilEcran: View {
    @Environment(\.clientPi) private var client
    @Environment(\.miroir) private var miroir

    @State private var fils: [FilApi] = []
    @State private var releveA: Date?
    @State private var refus: ErreurApi?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.fil, releveA: releveA)
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .task { await ouvrir() }
        .cadencePar("fil") { await battre() }
        .navigationDestination(for: RouteFil.self) { route in
            switch route {
            case .conversation(let identifiant, let titre):
                ConversationEcran(identifiant: identifiant, titre: titre)
            }
        }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.standard) {
                if let refus, refus.genre != .transport, fils.isEmpty {
                    BandeauAlerte(refus.message, etat: .danger)
                }
                if fils.isEmpty {
                    vide
                } else {
                    ForEach(Array(fils.enumerated()), id: \.element.id) { rang, fil in
                        NavigationLink(value: RouteFil.conversation(fil.id, fil.titre)) {
                            CarteFil(fil: fil)
                        }
                        .buttonStyle(.vigieCarte)
                        .apparitionDouce(rang: rang)
                    }
                }
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.vertical, Espace.standard)
        }
        .scrollIndicators(.hidden)
        .refreshable { await battre() }
    }

    @ViewBuilder private var vide: some View {
        if releveA == nil && refus == nil {
            VStack(spacing: Espace.standard) {
                ForEach(0..<3, id: \.self) { rang in
                    CarteVigie { SqueletteVigie(hauteur: 13) }
                        .apparitionDouce(rang: rang)
                }
            }
        } else {
            EtatVide(
                symbole: "bubble.left.and.bubble.right",
                titre: "Aucun fil",
                explication: "L'orchestrateur n'a encore ouvert aucune conversation."
            )
        }
    }

    private func ouvrir() async {
        guard let cache = await miroir.lire([FilApi].self, .fils) else { return }
        fils = cache.valeur
        releveA = cache.releveA
    }

    @MainActor private func battre() async {
        let lecture = await client.lire([FilApi].self, Route.fils, memoriser: .fils)
        if let charge = lecture.charge {
            fils = charge
            releveA = Date()
        }
        refus = lecture.erreur
    }
}

/// Les destinations du domaine Fil. Le titre voyage avec l'identifiant : l'écran
/// s'ouvre ainsi avec son nom affiché avant même la première réponse.
enum RouteFil: Hashable {
    case conversation(String, String)
}

private struct CarteFil: View {
    let fil: FilApi

    var body: some View {
        CarteVigie(relief: fil.active ? .active : .standard) {
            VStack(alignment: .leading, spacing: Espace.serre) {
                HStack(spacing: Espace.serre) {
                    PointVital(etat: fil.active ? .sain : .neutre, vivant: fil.active)
                    Text(fil.titre)
                        .corpsAccentue()
                        .foregroundStyle(Couleurs.encre)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(Lisible.heure(fil.majA))
                        .monoMinuscule()
                        .foregroundStyle(Couleurs.texteTertiaire)
                }
                HStack(spacing: Espace.serre) {
                    if let modele = fil.model { PuceMono(modele) }
                    if let machine = fil.machine { PuceMono(machine) }
                    Spacer(minLength: 0)
                    if let contexte = fil.contextPct {
                        Text("contexte \(contexte) %")
                            .monoPetit()
                            .foregroundStyle(Couleurs.texteSecondaire)
                    }
                }
            }
        }
    }
}
#endif
