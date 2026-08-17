# Vigie — état

Client iOS natif de ccremote. Plan de référence : `/home/trinity/PLAN-VIGIE.md`
(les **décisions de Chris du 2026-08-17**, en fin de document, priment sur tout
le reste). Chaîne de compilation portée d'EchoLabs, bundle `com.echo.labs`.

## Au 2026-08-17

**L'application compile pour iOS et produit `xtool/Vigie.ipa`. 117 tests du
noyau verts sur Arch (`swift test`). Aucun écran n'est plus une coquille vide.**

Ce qui existe, par domaine :

| Domaine | État |
|---|---|
| `Charte/` | jetons, composants, ressorts, gestes, matières, clavier |
| `Coquille/` | barre à 7 domaines, minuterie unique, câblage, délégué |
| `Lien/` | `ClientPi` (2 sessions), jeton en trousseau, refus de redirection |
| `Quart/` | file du quart + pouls du parc |
| `Decisions/` | file, cartes, garde Face ID, lecture des quatre 409 |
| `Fil/` | liste, conversation segmentée, markdown, composeur, pièces |
| `Parc/` | liste groupée, détail d'équipe, gestes de pilotage |
| `Machines/` | santé, quotas, poste de travail (réveil, bascule de compte) |
| `Terminal/` | sessions tmux, capture, barre d'accessoires |
| `Alerte/` | veille audio, sondage, pose de locales, alarme de silence, BG |
| `Reglages/` | serveur, alerte, orchestrateur, à propos |
| `Diagnostic/` | sonde de chaîne, écran caché (appui long sur la version) |
| `VigieNoyau/` | contrat, miroir, veille, markdown, parc, machines, fil |

## Ce qui n'a JAMAIS été exercé

`☠` **Aucune requête HTTP réelle n'a été faite contre le Pi.** Toutes les formes
de réponse sont dérivées de la lecture des sources du dépôt `ccremote`. Le
premier vrai jour de recette doit être une capture `curl` de chaque route, pas
une session de codage.

`☠` **L'IPA n'a pas été posé sur l'appareil depuis que ces domaines existent.**
Rien de ce qui touche `UserNotifications`, `BGTaskScheduler`, `LocalAuthentication`
ni la veille audio n'a été vu tourner dans cette application-ci (les mesures
d'EchoLabs, elles, tiennent — voir `PLAN-VIGIE.md`).

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
