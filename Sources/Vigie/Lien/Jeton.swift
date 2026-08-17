#if canImport(SwiftUI)
import Foundation
import Security
import VigieNoyau

/// Le coffre du jeton de session.
///
/// `☠` Pourquoi ce fichier existe : le cookie posé par `pi-web` n'a **ni
/// `max_age` ni `expires`** (`app.py`, `set_cookie("session", …)`). C'est donc
/// un cookie de session au sens HTTP, et `HTTPCookieStorage` ne le conserve pas
/// d'un lancement à l'autre. Sans ce coffre, Vigie redemanderait le mot de passe
/// à chaque ouverture — sur une app consultée trente fois par jour.
///
/// On extrait donc la valeur du `Set-Cookie`, on la range ici, et `ClientPi`
/// pose lui-même l'en-tête `Cookie:`. Le serveur ne vérifie qu'une égalité de
/// détail du modèle d'authentification retiré de l'historique.
public struct CoffreJeton: Sendable {
    private let service: String
    private let compte: String
    /// Repli sur fichier, voir `enregistrer`.
    private let repli: URL

    public init(service: String = "com.echo.labs.vigie", compte: String = "session") {
        self.service = service
        self.compte = compte
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        repli = (base.first ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("Vigie", isDirectory: true)
            .appendingPathComponent("jeton.bin")
    }

    // MARK: - Trousseau

    /// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` : lisible par un réveil
    /// de fond après le premier déverrouillage, jamais exporté par une
    /// sauvegarde vers un autre appareil.
    ///
    /// `☠` Non vérifié sur cette chaîne : un IPA resigné par Impactor reçoit ses
    /// entitlements d'Impactor, pas d'xtool, et `errSecMissingEntitlement`
    /// (-34018) ne se voit qu'à l'exécution. D'où le repli fichier ci-dessous —
    /// il n'est pas de la prudence décorative, c'est le cas prévu.
    public func enregistrer(_ valeur: String) {
        guard let octets = valeur.data(using: .utf8) else { return }
        effacerDuTrousseau()
        // `[String: Any]` est imposé par l'API Security, qui ne prend qu'un
        // CFDictionary hétérogène. C'est la seule frontière non typée du projet.
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
            kSecValueData as String: octets,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let statut = SecItemAdd(requete as CFDictionary, nil)
        guard statut != errSecSuccess else { return }
        Trace.erreur("lien", "trousseau refusé (OSStatus \(statut)) — repli sur fichier protégé")
        ecrireRepli(octets)
    }

    public func lire() -> String? {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var trouve: CFTypeRef?
        let statut = SecItemCopyMatching(requete as CFDictionary, &trouve)
        // Le cast est le seul possible : l'API Security rend un CFTypeRef opaque.
        if statut == errSecSuccess, let octets = trouve as? Data {
            return String(data: octets, encoding: .utf8)
        }
        return lireRepli()
    }

    public func effacer() {
        effacerDuTrousseau()
        do {
            guard FileManager.default.fileExists(atPath: repli.path) else { return }
            try FileManager.default.removeItem(at: repli)
        } catch {
            Trace.erreur("lien", "repli du jeton non supprimé", error)
        }
    }

    private func effacerDuTrousseau() {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
        ]
        SecItemDelete(requete as CFDictionary)
    }

    // MARK: - Repli fichier

    /// `completeUntilFirstUserAuthentication` : même portée que le trousseau
    /// choisi plus haut. Pas `complete`, qui rendrait le jeton illisible à un
    /// réveil de fond sur appareil verrouillé — précisément le moment où Vigie
    /// en a besoin.
    private func ecrireRepli(_ octets: Data) {
        do {
            let dossier = repli.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: dossier.path) {
                try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
            }
            try octets.write(to: repli, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            Trace.erreur("lien", "repli du jeton impossible — session non persistée", error)
        }
    }

    private func lireRepli() -> String? {
        do {
            guard FileManager.default.fileExists(atPath: repli.path) else { return nil }
            return String(data: try Data(contentsOf: repli), encoding: .utf8)
        } catch {
            Trace.erreur("lien", "repli du jeton illisible", error)
            return nil
        }
    }
}

/// Extraction de la valeur du cookie dans un en-tête `Set-Cookie`.
///
/// Écrit à la main plutôt que via `HTTPCookie.cookies(withResponseHeaderFields:)`
/// : ce dernier **rejette** un cookie `Secure` quand l'URL n'est pas en https —
/// or Vigie doit rester joignable en clair sur le LAN quand le tunnel est coupé.
public enum LectureCookie {
    public static func valeur(nom: String, dans enTete: String) -> String? {
        for morceau in enTete.split(separator: ";") {
            let paire = morceau.trimmingCharacters(in: .whitespaces)
            guard paire.hasPrefix("\(nom)=") else { continue }
            let valeur = String(paire.dropFirst(nom.count + 1))
            return valeur.isEmpty ? nil : valeur
        }
        return nil
    }
}
#endif
