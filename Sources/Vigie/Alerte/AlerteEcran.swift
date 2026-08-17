#if canImport(SwiftUI)
import Foundation
import SwiftUI
import VigieNoyau

/// L'état du canal d'alerte — le seul écran qui dise si la chaîne tient debout,
/// et surtout qui dise NON quand elle ne tient pas.
///
/// `☠` Sa raison d'être : un canal mort et un parc calme produisent exactement
/// le même silence. Cet écran doit donc montrer ce qui a RÉELLEMENT eu lieu —
/// dernier réveil de fond servi par iOS, dernier contact avec le Pi, dernières
/// alertes posées — jamais des intentions ni un verdict global opaque.
public struct AlerteEcran: View {
    @Environment(\.clientPi) private var client
    @State private var centre = CentreAlerte.partage
    @State private var maintien = MaintienVie.partage

    public init() {}

    private var etat: EtatCanal { centre.etat }

    public var body: some View {
        VStack(spacing: 0) {
            EnteteDomaine(.alerte, releveA: etat.dernierContact)
            corps
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Couleurs.fond)
        .cadencePar("alerte") { await centre.sonder(origine: .premierPlan) }
    }

    private var corps: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.section) {
                verdict
                sectionCanaux
                sectionArmement
                sectionJournal
            }
            .padding(.horizontal, Espace.ecran)
            .padding(.bottom, Espace.section)
        }
        .scrollIndicators(.hidden)
        .refreshable { await centre.sonder(origine: .premierPlan) }
    }

    // MARK: - Verdict

    /// Trois conditions, montrées séparément : un verdict unique ne dirait pas
    /// laquelle manque, donc ne dirait pas quoi faire.
    @ViewBuilder private var verdict: some View {
        if !etat.autorisationAccordee {
            BandeauAlerte(
                "Notifications \(etat.autorisation) — rien ne sonnera. Réglages iOS → Vigie.",
                etat: .danger
            )
        } else if !etat.audioActif {
            BandeauAlerte(
                "Veille audio coupée : les alertes n'arriveront qu'à l'ouverture ou sur un "
                    + "réveil de fond, qu'iOS accorde environ une fois sur deux.",
                etat: .vigilance
            )
        } else if let panne = etat.derniereErreurTransport {
            BandeauAlerte("Dernier relevé en échec : \(panne)", etat: .vigilance)
        } else if etat.rattrapageIncomplet {
            BandeauAlerte(
                "Des faits ont quitté la fenêtre du serveur avant d'être vus : le rattrapage "
                    + "est incomplet.",
                etat: .vigilance
            )
        } else {
            BandeauAlerte("Le canal tient : veille audio active, dernier relevé abouti.", etat: .sain)
        }
    }

    // MARK: - Canaux

    private var sectionCanaux: some View {
        SectionVigie("Canaux") {
            CarteVigie {
                VStack(spacing: 0) {
                    LigneCleValeur("1 · Veille audio", valeur: maintien.statut,
                                   teinteValeur: teinte(etat.audioActif))
                    LigneCleValeur("Interruptions / reprises",
                                   valeur: "\(etat.audioInterruptions) / \(etat.audioReprises)")
                    LigneCleValeur("2 · Dernier contact", valeur: age(etat.dernierContact),
                                   teinteValeur: teinte(etat.dernierContact != nil))
                    LigneCleValeur("Origine", valeur: etat.derniereOrigine?.libelle ?? "—")
                    // `☠` Le réveil RÉELLEMENT servi, jamais celui qui a été demandé.
                    LigneCleValeur("3 · Réveil de fond servi", valeur: age(etat.dernierReveilReel),
                                   teinteValeur: teinte(etat.dernierReveilReel != nil))
                    LigneCleValeur("Réveils servis", valeur: "\(etat.reveilsReels)")
                    LigneCleValeur("Planification", valeur: libellePlanification, derniere: true)
                }
            }
        }
    }

    private var libellePlanification: String {
        guard etat.reveilEnregistre else { return "refusée par le système" }
        return etat.reveilReplanifie ? "acceptée" : "non replanifiée"
    }

    // MARK: - Armement

    private var sectionArmement: some View {
        SectionVigie("Pré-armé") {
            CarteVigie {
                VStack(spacing: 0) {
                    LigneCleValeur("4 · Alarmes de silence",
                                   valeur: "\(etat.alarmesArmees.count) armée(s)",
                                   teinteValeur: teinte(!etat.alarmesArmees.isEmpty))
                    LigneCleValeur("Prochaine", valeur: prochaineAlarme)
                    LigneCleValeur("Signature", valeur: echeanceSignature, derniere: true)
                }
            }
            Text("Ces deux alertes sont les seules à survivre à la mort de Vigie : elles sont "
                 + "déposées à l'avance dans le centre de notifications.")
                .legende()
                .foregroundStyle(Couleurs.texteTertiaire)
                .padding(.top, Espace.standard)
        }
    }

    private var prochaineAlarme: String {
        guard let prochaine = etat.alarmesArmees.min() else { return "aucune" }
        return prochaine.formatted(date: .omitted, time: .shortened)
    }

    private var echeanceSignature: String {
        guard let expiration = etat.expirationSignature else { return "illisible" }
        let jours = expiration.timeIntervalSinceNow / 86_400
        guard jours > 0 else { return "expirée" }
        return "\(Int(jours.rounded(.down))) j restants"
    }

    // MARK: - Journal

    private var sectionJournal: some View {
        SectionVigie("Dernières alertes") {
            if etat.derniers.isEmpty {
                EtatVide(
                    symbole: "bell.slash",
                    titre: "Rien de sonné",
                    explication: "Aucune alerte n'a encore été posée depuis cet appareil."
                )
            } else {
                CarteVigie {
                    VStack(spacing: 0) {
                        ForEach(Array(etat.derniers.enumerated()), id: \.element.id) { rang, echo in
                            LigneCleValeur(
                                "\(echo.genre.libelle) · \(echo.instant.formatted(date: .omitted, time: .shortened))",
                                valeur: echo.titre,
                                derniere: rang == etat.derniers.count - 1
                            )
                        }
                    }
                }
            }
        } accessoire: {
            PastilleEtat("\(etat.faitsSonnes)", etat: .neutre)
        }
    }

    // MARK: - Mise en forme

    private func teinte(_ bon: Bool) -> Color {
        bon ? EtatSemantique.sain.teinte : EtatSemantique.vigilance.teinte
    }

    private func age(_ instant: Date?) -> String {
        guard let instant else { return "jamais" }
        return Fraicheur.mention(depuis: instant)
    }
}
#endif
