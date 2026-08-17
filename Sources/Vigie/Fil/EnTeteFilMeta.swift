// Bandeau de méta d'un fil ouvert : modèle, contexte, compactions, machine,
// plafond d'autonomie. Défile horizontalement — sept chiffres ne tiennent pas
// sur un iPhone XS sans se tasser illisibles.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct EnTeteFilMeta: View {
    let modele: String?
    let effort: String?
    let contextPct: Int?
    let compactions: Int
    let machine: String?
    let plafondAutonomie: ReglagePlafondApi

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Espace.serre) {
                if let modele { PuceMono(libelleMoteur(modele)) }
                if let contextPct { PuceMono("contexte \(contextPct) %") }
                if compactions > 0 {
                    PuceMono("\(compactions) compaction\(compactions > 1 ? "s" : "")")
                }
                if let machine { PuceMono(machine) }
                PuceMono(plafondAutonomie.libelle)
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.bottom, Espace.serre)
        }
        .scrollIndicators(.hidden)
    }

    private func libelleMoteur(_ modele: String) -> String {
        guard let effort else { return modele }
        return "\(modele) · \(effort)"
    }
}
#endif
