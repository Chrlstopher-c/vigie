#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

/// Point d'entrée.
///
/// Il ne fait que trois choses, et il ne doit jamais en faire plus : installer
/// le délégué d'application (les rappels de notification n'arrivent pas par
/// SwiftUI), construire le câblage une seule fois, et poser la coquille.
@main
struct VigieApp: App {
    @UIApplicationDelegateAdaptor(DelegueApplication.self) private var delegue

    /// `@State` et pas une variable calculée : le câblage détient la session
    /// HTTP, le miroir et la minuterie. Le reconstruire à chaque évaluation de
    /// `body` rouvrirait une session par recomposition.
    @State private var cablage = Cablage()

    init() {
        Trace.seuil = .info
    }

    var body: some Scene {
        WindowGroup {
            Coquille()
                .cable(cablage)
        }
    }
}
#endif
