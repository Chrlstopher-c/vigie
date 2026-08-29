# Vigie — état

Licence : **AGPL-3.0-or-later** (`LICENSE`).

Client iOS natif de ccremote. Plan de référence : `/home/trinity/PLAN-VIGIE.md`
(les **décisions de Chris du 2026-08-17**, en fin de document, priment sur tout
le reste). Chaîne de compilation portée d'EchoLabs, bundle `com.echo.labs`.

`☠` **Le dépôt ne porte aucune adresse réelle.** Le tunnel Cloudflare et le repli
LAN vivent dans `.env.local` (non suivi, calqué sur `.env.example`) ; `build.sh`
les injecte dans `.build/Info.plist`, généré depuis `Info.template.plist`. Sans
`.env.local`, la compilation reste valide mais embarque les adresses d'exemple —
l'adresse effective se saisit alors dans les Réglages.

## Au 2026-08-17 — refonte « Quart de nuit »

**Frontend intégralement refondu (DA sombre, voir `Sources/Vigie/Charte/CHARTE.md`).
Compile en `xtool/Vigie.ipa`, 117 tests du noyau verts à cette date. Toutes les capacités du
contrat ont désormais une surface.**

Ce qui existe, par domaine :

| Domaine | État |
|---|---|
| `Charte/` | « Quart de nuit » : Teinte/Typo/Trame/Elan/Haptique/Allures, composants, markdown partagé |
| `Coquille/` | 5 onglets (Quart absorbe Décisions), barre badgée, minuterie unique |
| `Lien/` | `ClientPi` (2 sessions), jeton en trousseau, refus de redirection |
| `Quart/` | pièce d'entrée : file tranchable sur place + pouls + cloche + portillon |
| `Decisions/` | cartes à rail, garde Face ID, quatre 409, tampon jusqu'au relevé |
| `Fil/` | liste + création, conversation-document, moteur par message, tenue ⋯ (renommer/machine/autonomie/rappels/compacter/archiver) |
| `Parc/` | fil segmenté en valises, sous-agents navigables, instruction au lead |
| `Machines/` | jauges à seuils, quotas 5 h/7 j, réveil du poste |
| `Dictee/` | dictée locale (Speech, A12), micro dans le composeur du fil — **vue tourner sur l'appareil** |
| `Terminal/` | ^C/^D armés, capture collée au bas, barre de touches |
| `Alerte/` | canal + faits du parc (lu/remis distincts, marquer lu) |
| `Reglages/` | serveur, orchestrateur, alerte, à propos + signature |
| `Diagnostic/` | sonde de chaîne, écran caché (appui long sur la version) |
| `VigieNoyau/` | contrat, miroir, veille, markdown, parc, machines, fil — intouché |

## 2026-08-18 — `/health` branché

`GET /health` était déclaré, décodé et mémorisé, et **appelé nulle part** : Vigie
déduisait tout de la fraîcheur des relevés. Il est désormais la première lecture
du lot de `ReleveParc`, et son verdict est croisé avec `/api/status` dans
`EtatChaine` (noyau, 6 tests).

Ce que ça donne de neuf, et que rien ne disait avant :

- **control plane muet** — un bandeau explique le vide de l'écran, au lieu d'un
  « échec de lecture » qui ne dit pas où ça casse.
- **superviseur tombé** — poste allumé, control plane qui ne le voit pas. C'est
  exactement le défaut du 14/08 côté ccremote : toutes les routes du harness
  répondaient « machine absente » sur une machine parfaitement vivante.

`☠` Un échec de `/health` ne se dit PAS en `dernierEchec` : c'est la première des
cinq requêtes du lot, et si elle tombe les quatre autres tomberont pareil. Le
message reviendrait cinq fois pour une seule panne.

**144 tests du noyau verts, IPA recompilé.**

## 2026-08-19 — Artefacts : script/HTML de l'orchestrateur affichés dans le fil

Le serveur a gagné cette nuit un type d'évènement `artefact` (migration 30,
`ccremote` branche `equipe/…` non fusionnée sur `master`, commit `cf81381`) :
l'orchestrateur peut produire un script (shell/Python/Lua) ou une page HTML et
le présenter comme un bloc du fil, avec la MÊME forme qu'une pièce jointe
(`PieceJointeApi` — réutilisé tel quel, aucun nouveau contrat). Vigie l'affiche
désormais.

Nouveau, dans `VigieNoyau/Fil/` (pur, testé) :
- `TypeEvenementApi.artefact` (`Contrat/Jetons.swift`).
- `LangageArtefact` — reconnaissance du langage par EXTENSION du nom de
  fichier (`.html/.sh/.py/.lua`, liste fermée, alignée sur le serveur), pas par
  le MIME servi.
- `BlocAgent.artefact(seq:piece:at:)` et son branchement dans
  `SegmentationFil` — sans lui, un évènement `artefact` retombait dans le
  `default:` et se lisait comme un simple `.fait` texte, sans code ni pièce.

Nouveau domaine `Sources/Vigie/Artefact/` (app, non testable par `swift test` —
SwiftUI/WebKit) :
- `CarteArtefact.swift` — badge de langage, nom, taille, code en clair
  (`Teinte.terminalFond`/`terminalTexte`, même traitement que les blocs de code
  markdown), bascule Code/Rendu pour le HTML, partage/export par `ShareLink`
  sur une copie locale nommée comme la pièce.
- `RenduHTMLIsole.swift` — le rendu HTML, contenu NON FIABLE. Mécanisme
  d'isolement (documenté en tête de fichier, à faire confirmer par Chris sur
  l'appareil — pas de simulateur ici) : `WKWebViewConfiguration.websiteDataStore
  = .nonPersistent()` + `loadHTMLString(_:baseURL: nil)` (origine opaque) +
  `WKNavigationDelegate` qui refuse toute navigation hors du chargement
  initial + `createWebViewWith` qui bloque `window.open`. Filet supplémentaire,
  propre à Vigie : le jeton de session ne vit dans AUCUN `WKWebsiteDataStore` —
  `ClientPi` le pose à la main en en-tête `Cookie:` sur `URLSession`, jamais
  via `WKHTTPCookieStore` — donc rien à lire même en cas de fuite du sandbox.

**10 tests du noyau ajoutés sur ce domaine** (135 au total, 0 régression), IPA
recompilé et signé par `build.sh` (17 Mo, aucune erreur). Les tests de
décodage/segmentation ont été éprouvés dans les deux sens : branchement
`.artefact` annulé → 3 tests rouges (l'évènement retombait en `.fait`
générique, sans pièce) ; `LangageArtefact.depuis` cassé → 8 tests rouges ; les
deux restaurés, suite verte à nouveau.

`☠` **Non éprouvé, faute d'appareil** — à valider par Chris :
- Le rendu visuel de la carte (alignement, lisibilité, cohérence avec la
  charte à l'œil).
- Le mécanisme d'isolement de `RenduHTMLIsole` en conditions réelles : aucun
  Playwright ni WebKit Inspector sur cette chaîne pour rejouer la preuve
  « `document.cookie` lève une exception » que l'équipe serveur a faite en
  navigateur. Le raisonnement (origine opaque + magasin éphémère + navigation
  bloquée + jeton jamais dans un `WKWebsiteDataStore`) est solide mais reste
  un raisonnement, pas une mesure.
- `ShareLink` sur la copie locale : le nom de fichier et l'extension
  survivent-ils réellement à un envoi Mail/AirDrop/Fichiers ?
- Cohabitation avec le reste du fil en défilement (un artefact volumineux
  dans une longue conversation).

## Ce qui n'a JAMAIS été exercé

`☠` **Aucune requête HTTP réelle n'a été faite contre le Pi.** Toutes les formes
de réponse sont dérivées de la lecture des sources du dépôt `ccremote`. Le
premier vrai jour de recette doit être une capture `curl` de chaque route, pas
une session de codage.

`☠` **L'IPA n'a pas été posé sur l'appareil depuis que ces domaines existent.**
Rien de ce qui touche `UserNotifications`, `BGTaskScheduler`, `LocalAuthentication`
ni la veille audio n'a été vu tourner dans cette application-ci. (Les mesures
d'EchoLabs, elles, tiennent — voir `PLAN-VIGIE.md`.)

**Exception, 2026-08-18 : la dictée a tourné sur l'appareil et fonctionne.**
Reste à vérifier au prochain passage la cohabitation micro / canal d'alerte —
dicter pendant que `MaintienVie` tient sa session est raisonné, pas encore
mesuré.

## Côté serveur : rien n'est fait

Les quatre chantiers du §4 du plan sont **entiers**, et deux d'entre eux
conditionnent la justesse du client :

- **C** — `check_session` rend 303 sur `/api/*` ; URLSession suit la redirection
  et rendrait le HTML de `/login` en 200 à un décodeur JSON. `RefusRedirection`
  pare le coup côté client, mais la route doit rendre 401.
- **D** — pas de curseur `since` sur les notifications, liste plafonnée à 50 :
  le rattrapage est un « à peu près », et `EtatCanal.rattrapageIncomplet` le dit
  au lieu de le masquer.
- **A** — aucune notification serveur pour une proposition de mandat. Vigie la
  détecte donc **par différence** sur `/orchestrator/propositions`.
- **B** — pas de long-poll `/api/alerte/attente`. Le sondage de la veille audio
  bat toutes les 25 s à la place.

## Rappels de chaîne

- Signature valide **7 jours** ; `deploy.sh` compile puis ouvre Impactor, le
  dépôt de l'IPA reste manuel.
- Le conteneur change d'UUID à chaque pose : **jamais de chemin absolu persisté**.
- `UserDefaults`, `Documents/` et le trousseau **survivent** à un resignage
  (mesuré le 2026-08-17).
