// Éléments qui changent sous les yeux — chiffres qui roulent, symboles qui
// respirent, ouverture par agrandissement.
//
// Sur une app de surveillance, la moitié de l'écran est faite de valeurs qui
// évoluent. Les remplacer sèchement est le réflexe web ; les faire transiter
// est ce qui donne l'impression que l'app est vivante plutôt que rafraîchie.
#if canImport(SwiftUI)
import SwiftUI

/// Chiffre qui roule quand sa valeur change, au lieu d'être remplacé.
public struct ChiffreVivant: View {
    private let valeur: String
    private let vedette: Bool

    public init(_ valeur: String, vedette: Bool = false) {
        self.valeur = valeur
        self.vedette = vedette
    }

    public var body: some View {
        Group {
            if vedette {
                Text(valeur).chiffreVedette()
            } else {
                Text(valeur).monoDonnee()
            }
        }
        .contentTransition(.numericText())
        .animation(Ressort.direct, value: valeur)
    }
}

/// Symbole d'état qui se substitue par glissement plutôt que de clignoter, et
/// qui pulse tant qu'une activité est en cours.
public struct SymboleVivant: View {
    private let nom: String
    private let actif: Bool
    private let teinte: Color

    public init(_ nom: String, actif: Bool = false, teinte: Color = Couleurs.encre) {
        self.nom = nom
        self.actif = actif
        self.teinte = teinte
    }

    public var body: some View {
        Image(systemName: nom)
            .foregroundStyle(teinte)
            .contentTransition(.symbolEffect(.replace.downUp))
            .symbolEffect(.pulse, options: .repeating, isActive: actif)
    }
}

/// Compteur qui attire l'œil quand il augmente : le chiffre roule et le fond
/// bat une fois. Pour les tuiles du pouls, où une hausse est un événement.
public struct CompteurAttentif: View {
    private let etiquette: String
    private let valeur: Int
    private let alerte: Bool

    @State private var precedent: Int = 0
    @State private var battement = false

    public init(_ etiquette: String, valeur: Int, alerte: Bool = false) {
        self.etiquette = etiquette
        self.valeur = valeur
        self.alerte = alerte
    }

    public var body: some View {
        VStack(spacing: Espace.fin) {
            ChiffreVivant("\(valeur)", vedette: true)
                .foregroundStyle(alerte ? Couleurs.accentPrimaire : Couleurs.encre)
            Text(etiquette).legende()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espace.carte)
        .background {
            RoundedRectangle(cornerRadius: Rayon.encart)
                .fill(battement ? Couleurs.accentVoile : Couleurs.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Rayon.encart)
                .strokeBorder(Couleurs.filet, lineWidth: 1)
        }
        .scaleEffect(battement ? 1.03 : 1)
        .onChange(of: valeur) { ancien, nouveau in
            guard nouveau > ancien else { return }
            withAnimation(Ressort.acquiescement) { battement = true }
            withAnimation(Ressort.sortie.delay(0.45)) { battement = false }
        }
        .sensoryFeedback(Retour.contact, trigger: valeur)
    }
}

/// Point vital qui respire — une activité en cours, sans barre de progression.
public struct Respiration: View {
    private let teinte: Color
    @State private var ample = false

    public init(teinte: Color = Couleurs.accentPrimaire) {
        self.teinte = teinte
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(teinte.opacity(0.22))
                .scaleEffect(ample ? 1.9 : 1)
                .opacity(ample ? 0 : 0.9)
            Circle().fill(teinte).frame(width: 7, height: 7)
        }
        .frame(width: 18, height: 18)
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                ample = true
            }
        }
    }
}

public extension View {
    /// Marque cette vue comme origine d'une ouverture par agrandissement.
    /// Associée à `ouvertureAgrandie`, elle donne la transition signature
    /// d'iOS 18 : la carte touchée s'étire pour devenir l'écran de détail,
    /// au lieu de glisser depuis le bord.
    func origineAgrandissement(_ identifiant: some Hashable, dans espace: Namespace.ID) -> some View {
        matchedTransitionSource(id: identifiant, in: espace)
    }

    /// Se pose sur la destination d'une navigation.
    func ouvertureAgrandie(_ identifiant: some Hashable, dans espace: Namespace.ID) -> some View {
        navigationTransition(.zoom(sourceID: identifiant, in: espace))
    }
}
#endif
