// Les quatre boutons de Vigie. Usage : Button("…") { }.buttonStyle(.vigiePrimaire).
// Primaire = encre (action par défaut) ; accent = orange (créer, approuver) ;
// secondaire = fantôme (annuler, options) ; destructif = liseré rouge (refuser, arrêter).
// Un écran ne montre jamais deux boutons accent côte à côte.
#if canImport(SwiftUI)
import SwiftUI

private struct GabaritBouton: ViewModifier {
    let presse: Bool

    func body(content: Content) -> some View {
        content
            .libelleBouton()
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 34)
            .scaleEffect(presse ? 0.97 : 1)
            .animation(Mouvement.reponseImmediate, value: presse)
    }
}

public struct BoutonPrimaire: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Couleurs.texteSurSombre)
            .modifier(GabaritBouton(presse: configuration.isPressed))
            .background(
                configuration.isPressed ? Couleurs.encrePressee : Couleurs.encre,
                in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
            )
    }
}

public struct BoutonAccent: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .modifier(GabaritBouton(presse: configuration.isPressed))
            .background(
                configuration.isPressed ? Couleurs.accentAppuye : Couleurs.accentPrimaire,
                in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
            )
    }
}

public struct BoutonSecondaire: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Couleurs.encre : Couleurs.texteSecondaire)
            .modifier(GabaritBouton(presse: configuration.isPressed))
            .background(
                configuration.isPressed ? Couleurs.surface : .clear,
                in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
                    .strokeBorder(Couleurs.filetAppuye, lineWidth: Trait.filet)
            )
    }
}

public struct BoutonDestructif: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : Couleurs.etatDanger)
            .modifier(GabaritBouton(presse: configuration.isPressed))
            .background(
                configuration.isPressed ? Couleurs.etatDanger : Couleurs.etatDangerVoile.opacity(0.4),
                in: RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Rayon.bouton, style: .continuous)
                    .strokeBorder(Couleurs.etatDanger, lineWidth: Trait.appuye)
            )
    }
}

extension ButtonStyle where Self == BoutonPrimaire {
    public static var vigiePrimaire: BoutonPrimaire { BoutonPrimaire() }
}
extension ButtonStyle where Self == BoutonAccent {
    public static var vigieAccent: BoutonAccent { BoutonAccent() }
}
extension ButtonStyle where Self == BoutonSecondaire {
    public static var vigieSecondaire: BoutonSecondaire { BoutonSecondaire() }
}
extension ButtonStyle where Self == BoutonDestructif {
    public static var vigieDestructif: BoutonDestructif { BoutonDestructif() }
}
#endif
