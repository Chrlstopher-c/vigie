#if canImport(SwiftUI)
import Foundation

/// Les destinations poussées à l'intérieur du domaine Parc, dans la
/// `NavigationStack` que la coquille attribue à chaque domaine.
enum RouteParc: Hashable {
    case equipe(String)
}
#endif
