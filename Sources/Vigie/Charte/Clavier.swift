// Congédier le clavier.
//
// `☠` SwiftUI ne ferme un clavier sur AUCUN geste par défaut : ni le toucher
// hors du champ, ni le défilement. Sur un écran qui porte à la fois un champ
// et des actions, l'utilisateur se retrouve enfermé — le clavier masque la
// moitié de l'écran et rien ne le renvoie. C'est le défaut le plus bloquant
// qu'une interface iOS puisse avoir, et il ne se voit qu'à l'usage.
//
// Trois issues sont posées ensemble, parce qu'aucune ne couvre tous les cas :
// le toucher dans le vide, le défilement, et un bouton explicite au-dessus des
// touches pour les mains qui ne cherchent pas.
#if canImport(SwiftUI)
import SwiftUI
import UIKit

public enum Clavier {
    /// Retire le focus du premier répondeur, quel qu'il soit. Passe par UIKit :
    /// `@FocusState` est local à une vue et ne peut pas être atteint depuis
    /// l'extérieur, alors que le clavier, lui, est global.
    @MainActor
    public static func fermer() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

public extension View {
    /// À poser sur tout écran contenant au moins un champ de saisie.
    ///
    /// Le toucher est capté par un fond transparent plutôt que par le contenu :
    /// un `onTapGesture` posé sur la vue entière intercepterait les touchers
    /// destinés aux boutons qu'elle contient.
    func congedieLeClavier() -> some View {
        background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { Clavier.fermer() }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    Clavier.fermer()
                } label: {
                    Label("Terminé", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.titleAndIcon)
                }
                .tint(Couleurs.accentPrimaire)
            }
        }
    }

    /// Variante pour les surfaces qui ne défilent pas (feuilles courtes,
    /// modales) : le geste de défilement n'existe pas, seuls le toucher et le
    /// bouton restent.
    func congedieLeClavierSansDefilement() -> some View {
        background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { Clavier.fermer() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Terminé") { Clavier.fermer() }
                    .tint(Couleurs.accentPrimaire)
            }
        }
    }
}

/// Barre d'accessoires du terminal : les touches qu'un clavier iOS n'a pas et
/// dont un shell ne peut pas se passer.
///
/// C'est le seul endroit où un client natif écrase franchement Safari mobile —
/// dans le navigateur, envoyer un Ctrl-C à tmux est simplement impossible.
public struct BarreTerminal: View {
    private let envoyer: @MainActor (String) -> Void

    private let touches: [(String, String)] = [
        ("esc", "Esc"),
        ("tab", "⇥"),
        ("ctrl", "^"),
        ("up", "↑"),
        ("down", "↓"),
        ("left", "←"),
        ("right", "→"),
    ]

    public init(envoyer: @escaping @MainActor (String) -> Void) {
        self.envoyer = envoyer
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Espace.serre) {
                ForEach(touches, id: \.0) { code, libelle in
                    Button {
                        envoyer(code)
                    } label: {
                        Text(libelle)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Couleurs.encre)
                            .frame(minWidth: 40, minHeight: 34)
                            .background(Couleurs.surface, in: .rect(cornerRadius: Rayon.boutonPetit))
                            .overlay {
                                RoundedRectangle(cornerRadius: Rayon.boutonPetit)
                                    .strokeBorder(Couleurs.filetAppuye, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .reagitAuToucher(echelle: 0.92)
                }
                Spacer(minLength: 0)
                Button {
                    Clavier.fermer()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .frame(minWidth: 40, minHeight: 34)
                }
                .tint(Couleurs.accentPrimaire)
            }
            .padding(.horizontal, Espace.standard)
        }
        .scrollIndicators(.hidden)
        .frame(height: 46)
        .background(.regularMaterial)
        .overlay(alignment: .top) { FiletHorizontal() }
        .sensoryFeedback(Retour.contact, trigger: UUID())
    }
}
#endif
