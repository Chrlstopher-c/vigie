#if canImport(SwiftUI)
import Foundation
import Observation
import VigieNoyau

/// Ce qu'un aller-retour réseau apprend sur l'état de la liaison.
///
/// Émis par `ClientPi` à CHAQUE requête, consommé par la coquille. Aucun écran
/// n'a à penser à tenir le bandeau à jour : c'est ce qui garantit qu'il ne ment
/// jamais, y compris depuis un domaine écrit trois semaines plus tard.
public struct VerdictLien: Sendable {
    public let instant: Date
    /// `nil` quand rien n'est revenu : on ne sait pas si le PC est éteint ou si
    /// c'est le Pi qui est muet. Les confondre est exactement l'erreur à éviter.
    public let pcEnLigne: Bool?
    public let erreur: ErreurApi?

    public init(instant: Date = Date(), pcEnLigne: Bool?, erreur: ErreurApi?) {
        self.instant = instant
        self.pcEnLigne = pcEnLigne
        self.erreur = erreur
    }
}

/// L'état de liaison, en permanence à l'écran.
///
/// Trois régimes, et le second n'est PAS une panne : le PC de travail éteint la
/// nuit est le fonctionnement normal du produit. L'afficher en rouge ferait
/// chercher un problème inexistant la moitié du temps ; l'afficher en vert ferait
/// prendre des données de la veille pour l'instant présent.
@MainActor @Observable
public final class Liaison {

    public enum Regime: Sendable, Equatable {
        /// Pi joignable, PC de travail en ligne : tout est frais.
        case nominal
        /// Pi joignable, PC de travail absent. Régime normal, données datées.
        case posteEteint
        /// Le Pi ne répond pas : tunnel coupé, control plane mort, réseau absent.
        case perdue
        /// Session close ou périmée : plus rien n'est lisible avant reconnexion.
        case sessionRequise
    }

    public private(set) var regime: Regime = .perdue
    /// Dernier aller-retour ABOUTI, quel qu'en soit le verdict sur le PC.
    public private(set) var dernierContact: Date?
    /// Dernier refus rencontré. Effacé au premier succès.
    public private(set) var dernierEchec: ErreurApi?
    /// Vrai tant qu'aucune requête n'a encore abouti depuis le lancement.
    public private(set) var jamaisJoint = true

    public init() {}

    public var libelle: String {
        switch regime {
        case .nominal: return "PC en ligne"
        case .posteEteint: return "PC éteint"
        case .perdue: return jamaisJoint ? "Pi injoignable" : "liaison perdue"
        case .sessionRequise: return "session à rouvrir"
        }
    }

    /// Complément de seconde ligne : dit depuis quand, ou pourquoi.
    public var precision: String? {
        switch regime {
        case .nominal:
            return nil
        case .posteEteint:
            return "registre du Pi — données datées"
        case .perdue:
            guard let dernierContact else { return dernierEchec?.message }
            return "dernier contact \(Fraicheur.texte(depuis: dernierContact))"
        case .sessionRequise:
            return dernierEchec?.message
        }
    }

    /// Applique un verdict. Seul point d'entrée : la coquille draine le flux de
    /// `ClientPi` et appelle ceci, personne d'autre.
    public func appliquer(_ verdict: VerdictLien) {
        if let erreur = verdict.erreur {
            appliquerErreur(erreur, instant: verdict.instant)
            return
        }
        jamaisJoint = false
        dernierContact = verdict.instant
        dernierEchec = nil
        // `pcEnLigne == nil` : l'aller-retour a abouti mais ne dit rien du poste
        // de travail (écriture, route binaire). On ne DÉGRADE pas le bandeau sur
        // une absence d'information — un envoi réussi ferait clignoter « PC
        // éteint » alors qu'il vient précisément d'être servi.
        guard let pcEnLigne = verdict.pcEnLigne else {
            if regime == .perdue || regime == .sessionRequise { regime = .nominal }
            return
        }
        regime = pcEnLigne ? .nominal : .posteEteint
    }

    private func appliquerErreur(_ erreur: ErreurApi, instant: Date) {
        dernierEchec = erreur
        switch erreur.genre {
        case .authentification:
            regime = .sessionRequise
        case .transport:
            regime = .perdue
        case .harnessInjoignable:
            // Le control plane est mort sur le Pi. Le Pi, lui, a répondu : c'est
            // un contact abouti, et surtout PAS un « PC éteint ».
            jamaisJoint = false
            dernierContact = instant
            regime = .perdue
        default:
            // 400/404/409/501 : le lien est bon, c'est le geste qui a été refusé.
            jamaisJoint = false
            dernierContact = instant
            if regime == .perdue || regime == .sessionRequise { regime = .nominal }
        }
    }

    /// Force le passage en « session à rouvrir » — utilisé par la déconnexion
    /// volontaire depuis les réglages.
    public func exigerSession() {
        regime = .sessionRequise
    }

    /// À appeler après une reconnexion réussie, avant la première lecture.
    public func sessionOuverte() {
        dernierEchec = nil
        regime = .perdue
        jamaisJoint = true
    }
}
#endif
