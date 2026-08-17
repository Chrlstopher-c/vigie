// Section « Alerte » des Réglages : l'interrupteur du maintien en vie (session
// audio), son état tel que le domaine `Alerte` le rapporte, et les heures
// calmes. Voir `PreferencesAlerte` pour le contrat de pont — `Alerte` n'a, au
// moment d'écrire ce fichier, posé que sa coquille vide.
#if canImport(SwiftUI)
import SwiftUI
import VigieNoyau

struct SectionAlerte: View {
    @State private var maintienEnVie = PreferencesAlerte.maintienEnVie
    @State private var heuresCalmesActives = PreferencesAlerte.heuresCalmesActives
    @State private var heureDebut = PreferencesAlerte.heureDebut
    @State private var heureFin = PreferencesAlerte.heureFin

    var body: some View {
        SectionVigie("Alerte") {
            CarteVigie {
                VStack(alignment: .leading, spacing: Espace.carte) {
                    blocMaintienEnVie
                    FiletHorizontal()
                    blocEtatCanal
                    FiletHorizontal()
                    blocHeuresCalmes
                }
            }
            NavigationLink(value: Domaine.alerte) {
                Text("État complet du canal d'alerte").libelleBouton()
            }
            .buttonStyle(.vigieSecondaire)
            .padding(.top, Espace.standard)
        }
    }

    // MARK: - Maintien en vie

    private var blocMaintienEnVie: some View {
        BasculeVigie(
            "Maintien en vie",
            sousLibelle: "session audio en arrière-plan, pour garder le canal éveillé",
            active: $maintienEnVie
        )
        .onChange(of: maintienEnVie) { _, valeur in
            // Ne fait QUE persister l'intention : démarrer ou couper la
            // session audio elle-même appartient au domaine `Alerte`, qui lit
            // ce réglage au lancement et au retour au premier plan.
            PreferencesAlerte.maintienEnVie = valeur
        }
        .sensoryFeedback(Retour.selection, trigger: maintienEnVie)
    }

    /// Lu depuis le pont UserDefaults — `nil` tant que `Alerte` n'a rien écrit.
    @ViewBuilder private var blocEtatCanal: some View {
        if let etat = PreferencesAlerte.etatCanalConnu() {
            VStack(spacing: 0) {
                LigneCleValeur("Session audio", valeur: etat.audioActif ? "active" : "coupée")
                LigneCleValeur("Autorisation", valeur: etat.autorisation)
                LigneCleValeur(
                    "Dernier contact",
                    valeur: etat.dernierContact.map(Self.formater) ?? "aucun",
                    derniere: true
                )
            }
        } else {
            Text("État non mesuré — le domaine Alerte n'a pas encore démarré la veille.")
                .legende()
                .foregroundStyle(Couleurs.texteTertiaire)
        }
    }

    // MARK: - Heures calmes

    private var blocHeuresCalmes: some View {
        VStack(alignment: .leading, spacing: Espace.standard) {
            BasculeVigie(
                "Heures calmes",
                sousLibelle: "\(Self.heure(heureDebut)) → \(Self.heure(heureFin))",
                active: $heuresCalmesActives
            )
            .onChange(of: heuresCalmesActives) { _, v in PreferencesAlerte.heuresCalmesActives = v }
            if heuresCalmesActives {
                reglageHeures
                Text("Seuls Mandat et Échec sonnent pendant les heures calmes ; le reste "
                     + "passe en niveau passif.")
                    .legende()
                    .foregroundStyle(Couleurs.texteTertiaire)
            }
        }
        .animation(Mouvement.changementEtat, value: heuresCalmesActives)
    }

    private var reglageHeures: some View {
        HStack(spacing: Espace.section) {
            Stepper("Début · \(Self.heure(heureDebut))", value: $heureDebut, in: 0...23)
                .onChange(of: heureDebut) { _, v in PreferencesAlerte.heureDebut = v }
            Stepper("Fin · \(Self.heure(heureFin))", value: $heureFin, in: 0...23)
                .onChange(of: heureFin) { _, v in PreferencesAlerte.heureFin = v }
        }
        .secondaire()
        .foregroundStyle(Couleurs.encre)
    }

    private static func heure(_ h: Int) -> String { String(format: "%02d h", h) }

    @MainActor private static func formater(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
#endif
