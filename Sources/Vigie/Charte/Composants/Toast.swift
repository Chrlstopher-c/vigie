// Toast (.toast) : confirmation éphémère encre sur ombre portée, posée par
// .toastVigie(message:) sur la vue racine d'un écran. Le message se dissout
// seul après 2,5 s ; poser un nouveau message remplace l'ancien.
#if canImport(SwiftUI)
import SwiftUI

private struct PorteToast: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .secondaire()
                    .foregroundStyle(Couleurs.texteSurSombre)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Couleurs.encre,
                                in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous))
                    .ombreFlottante()
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .task(id: message) { await dissoudre() }
            }
        }
        .animation(Mouvement.apparition, value: message)
    }

    private func dissoudre() async {
        try? await Task.sleep(for: .seconds(2.5))
        message = nil
    }
}

extension View {
    /// Affiche `message` en toast tant qu'il est non nil, puis le remet à nil.
    public func toastVigie(message: Binding<String?>) -> some View {
        modifier(PorteToast(message: message))
    }
}
#endif
