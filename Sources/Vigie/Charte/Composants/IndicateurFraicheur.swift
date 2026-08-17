// Indicateur de fraîcheur : « relevé il y a 3 h » — jamais un spinner.
// Vigie s'ouvre toujours sur le miroir daté ; ce composant dit l'âge de la
// donnée et se rafraîchit seul toutes les 30 s.
#if canImport(SwiftUI)
import SwiftUI

public struct IndicateurFraicheur: View {
    private let releveA: Date

    public init(releveA: Date) {
        self.releveA = releveA
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { contexte in
            let age = contexte.date.timeIntervalSince(releveA)
            HStack(spacing: Espace.serre) {
                PointVital(etat: etat(pourAge: age), vivant: age < 120)
                Text("relevé \(Self.formateur.localizedString(fromTimeInterval: -max(age, 0)))")
                    .monoPetit()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
    }

    /// Frais < 2 min, vieillissant < 1 h, périmé au-delà.
    private func etat(pourAge age: TimeInterval) -> EtatSemantique {
        if age < 120 { return .sain }
        if age < 3600 { return .vigilance }
        return .danger
    }

    // MainActor : le formateur n'est pas Sendable, et body ne quitte jamais l'acteur principal.
    @MainActor private static let formateur: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.unitsStyle = .short
        return f
    }()
}
#endif
