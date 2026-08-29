# Vigie — brief de direction artistique et de refonte frontend

Tu reprends **toute la couche de présentation** de Vigie : direction artistique,
système de design, composants, écrans, navigation, mouvement, typographie.

**Carte blanche.** Une seule contrainte imposée : la couleur primaire est
l'orange Anthropic, `#D97757` (« Badlands »). Tu en dérives la rampe complète,
les neutres, les couleurs sémantiques, tout le reste. Clair ou sombre, dense ou
aéré, sobre ou expressif : c'est ton choix, tu n'as personne à convaincre.

**Interdiction formelle de t'inspirer de l'existant.** Ni du frontend SwiftUI
actuel, ni de la webapp `ccremote/design-v2/index.html` dont il est copié. La
charte en place (`Sources/Vigie/Charte/`) est un relevé pixel de cette maquette
web ; elle est précisément ce qu'on remplace. Lis le code existant pour
comprendre **ce que fait** l'app — jamais pour reprendre **comment elle le
montre**. Si tu te surprends à conserver un agencement parce qu'il est là, c'est
le signal qu'il faut le refaire.

---

## 1. Le produit

Vigie est le **poste de garde** d'un parc d'agents Claude Code qui travaillent
seuls, 24 h/24, sur plusieurs machines. Le serveur — `ccremote`, hébergé sur un
Raspberry Pi — orchestre des « équipes » (missions) qui écrivent du code, et qui
s'arrêtent périodiquement pour demander une autorisation humaine : engager une
dépense, dépasser un budget, valider une inspection.

L'utilisateur unique s'appelle Chris. Il consulte Vigie **d'une main, sur un
iPhone XS**, souvent la nuit, souvent en marchant, souvent pour cinq secondes.

La question à laquelle chaque écran doit répondre avant toute autre :

> **Est-ce que quelque chose m'attend ? Et est-ce que ce que je regarde est frais ?**

Ce n'est pas un tableau de bord d'observabilité. Une équipe qui tourne bien n'a
rien à dire. Un mandat en attente doit être visible depuis le hall d'entrée, la
nuit, sans lunettes.

Trois conséquences que la DA doit porter :

- **Ce qui réclame une décision passe avant ce qui informe.** L'ancienne webapp
  ouvrait sur deux cents cartes de missions où un mandat en attente était une
  ligne parmi d'autres. C'est le défaut fondateur qu'on corrige.
- **La fraîcheur de la donnée est une information de premier rang**, pas une
  mention de bas de page. Une donnée de la veille prise pour l'instant présent
  est pire qu'un écran vide.
- **Le calme est un état normal, pas une panne.** « PC éteint » est le
  fonctionnement des nuits, 365 nuits par an. Le peindre en rouge ferait
  chercher un incident tous les soirs.

---

## 2. Les capacités à couvrir

Elles sont décrites en langage produit, sans présumer d'écran ni d'agencement.
**Le découpage en domaines qui suit est celui d'aujourd'hui — tu peux le refondre**
(regrouper, scinder, changer la navigation), à condition que toutes les capacités
listées restent atteignables.

### Décisions — le domaine prioritaire

Trois circuits que le serveur tient séparés, qu'on présente ensemble sans jamais
les fondre (chacun garde son objet, ses libellés, ses routes) :

- **Mandats** (`propositions`) : l'orchestrateur demande l'autorisation de lancer
  une équipe. Accorder / refuser.
- **Rallonges** : une équipe en cours demande un budget supplémentaire.
  Accorder / refuser.
- **Arbitrages d'inspection** : une inspection de mission attend un verdict
  humain. Confirmer / décliner (deux corps JSON sur la même route).

Règles dures :
- Toute décision qui engage une dépense passe par **Face ID** (`GardeFaceID`).
- Les gestes ne sont **jamais optimistes** : après l'écriture, on relit le
  serveur. Une carte tranchée reste affichée, tamponnée, jusqu'au relevé suivant
  — les faire disparaître instantanément rend deux gestes rapides indiscernables.
- L'ordre de la file est **structurel, jamais monétaire** (`trieesParUrgence()`).
- Un conflit (décision déjà tranchée ailleurs, mandat périmé) a un traitement
  dédié : `ConduiteApresConflit`.

### Quart — l'atterrissage

La file des décisions, plus un **pouls du parc** condensé au-dessus : équipes
actives, machines, quotas des comptes Claude, jauges. Le pouls est du contexte,
pas le sujet ; il ne bat qu'un tour sur cinq.

### Fil — les conversations de l'orchestrateur

- Liste des fils : titre, activité, modèle, machine, taux de contexte, âge.
- Conversation : les tours segmentés, le rendu **Markdown complet** (paragraphes,
  listes, tableaux, blocs de code, styles inline — analyseurs déjà écrits dans
  `VigieNoyau/Markdown/`), les blocs d'outils de l'agent, les cartes de mandat
  inlinées dans le fil, le bloc en cours de frappe pendant une génération.
- Composeur : texte multiligne, **pièces jointes** depuis la photothèque
  (`PhotosPicker`), envoi, interruption d'une génération en cours.
- Visionneuse plein écran d'une pièce jointe.
- Curseur incrémental : un fil ouvert ne re-demande jamais son historique entier.

**Capacités du contrat serveur aujourd'hui sans aucune surface — à créer** :
renommer un fil, l'archiver, le compacter, changer sa machine, changer son niveau
d'autonomie, lister/mettre en pause/supprimer ses **rappels** programmés,
afficher les **pièces jointes distantes** d'un message (`Route.pieceJointe`).

### Parc — les équipes

- Liste de toutes les missions, groupables **par état** ou **par projet**,
  avec un résumé de tête.
- Détail d'une équipe : son mandat, sa consommation (coût, contexte, prochain
  seuil), l'état de son dépôt git (branche, fichiers non commités — ce qui serait
  perdu), son fil d'événements, ses sous-agents.
- Gestes de pilotage : mettre en pause, reprendre, interrompre, inspecter,
  **terminer** (geste armé + Face ID, avec rappel de ce qui sera perdu).
- **Sans surface aujourd'hui — à créer** : le détail d'un sous-agent
  (`Route.sousAgent`), l'envoi d'une **instruction** à une mission en cours
  (`Route.instructionMission`).

### Machines — le matériel

- Les machines du parc : état, équipes hébergées, et sur demande leurs
  **métriques** (CPU, mémoire, charge). `☠` Les métriques coûtent un aller-retour
  **par machine**, jusqu'à Cloudflare pour le VPS : jamais en boucle, seulement
  à l'ouverture si le relevé est périmé et sur geste explicite.
- Les **comptes Claude** et leurs deux fenêtres de quota (5 h et 7 jours).
  `☠` Raisonner en **pourcentage, jamais en dollars** : sur abonnement les champs
  monétaires sont nuls. Distinguer « saturé » de « en dépassement payant » — ce
  dernier continue de tourner et coûte de l'argent réel.
- Le poste de travail : statut, **réveil Wake-on-LAN**.

### Terminal — tmux

C'est là qu'un client natif écrase le plus nettement Safari mobile : envoyer un
Ctrl-C à tmux depuis un navigateur mobile est simplement impossible.

- Liste des sessions tmux, création, fin de session.
- Détail d'une session : la **capture du panneau** rafraîchie à 400 ms tant que
  l'écran est regardé, un composeur qui envoie au shell, et une barre de touches
  spéciales (Ctrl-C, Échap, Tab, flèches, Entrée…) avec les séquences dangereuses
  derrière un geste armé.
- Le rendu terminal doit rester lisible : police à chasse fixe, épuration ANSI
  déjà faite dans le noyau (`EpurationAnsi`).

### Réglages

- Adresse du serveur (tunnel Cloudflare par défaut, repli LAN saisissable),
  test de liaison, **fermeture de session** (efface jeton + miroir, geste maintenu).
- Orchestrateur : modèle par défaut, niveau d'effort, bascule du compte Claude
  actif (redémarre les sessions tmux).
- Canal d'alerte : réglages, heures calmes, accès à l'écran d'état du canal.
- À propos : version, et **échéance de la signature** de l'app (7 jours en
  provisionnement gratuit — une jauge qui compte les jours restants avant que
  l'app cesse de se lancer).

### Alerte — l'état du canal

Le seul écran qui dise si la chaîne d'alerte tient debout, et surtout qui dise
**non** quand elle ne tient pas. Sa raison d'être : un canal mort et un parc calme
produisent exactement le même silence. Il doit montrer ce qui a **réellement eu
lieu** — dernier réveil de fond servi par iOS, dernier contact avec le Pi,
dernières alertes posées — jamais des intentions ni un verdict global opaque.

Les trois conditions (autorisation de notifier, maintien en vie audio, réveils de
fond) se montrent **séparément** : un verdict unique ne dirait pas laquelle
manque, donc ne dirait pas quoi faire.

**Sans surface aujourd'hui — à créer** : la liste in-app des notifications du
serveur, avec « marquer lue » et « tout marquer lu »
(`Route.notifications`, `marquerNotificationLue`, `marquerToutesNotificationsLues`).

### Connexion

Un écran plein qui s'impose dès que la session est requise. Pas un message
d'erreur, pas un bouton à trouver : sans session, rien n'est lisible, il n'y a
donc rien d'autre à montrer.

### Diagnostic

Trois sondes de bout en bout (jeton, miroir, chaîne d'alerte) accessibles depuis
les réglages. Écran d'outillage, à traiter comme tel.

---

## 3. Ce que tu peux réécrire, ce que tu ne touches pas

### Carte blanche — réécris, supprime, réorganise à ta guise

- `Sources/Vigie/Charte/**` — toute la DA, tous les composants. Table rase
  assumée : ne garde un fichier que si tu l'as vraiment voulu.
- Tous les écrans et vues de `Alerte/`, `Decisions/`, `Diagnostic/`, `Fil/`,
  `Machines/`, `Parc/`, `Quart/`, `Reglages/`, `Terminal/`.
- `Coquille/Coquille.swift`, `EnteteDomaine.swift`, `BandeauLien.swift` — la
  structure de navigation elle-même. Barre d'onglets, pile, feuilles, ce que tu
  juges juste.
- `Lien/Connexion.swift` — **l'apparence seule** de l'écran de connexion (le
  reste du dossier `Lien/` est intouchable, et la logique d'authentification
  de ce fichier avec).

### Intouchable — c'est la machinerie, elle marche, elle est testée

- `Sources/VigieNoyau/**` en entier : contrats `Codable`, logique métier,
  formatage, segmentation, Markdown, miroir, veille. **C'est ta source de vérité
  sur les données disponibles.** Lis-le abondamment. Si un besoin d'affichage
  légitime manque (un libellé, un tri), tu peux **ajouter** — jamais modifier
  l'existant, jamais casser `Tests/VigieNoyauTests/`.
- `Sources/Vigie/Lien/**` — client HTTP, jeton, session, refus de redirection.
- `Sources/Vigie/Alerte/**` **sauf** `AlerteEcran.swift` — la chaîne d'alerte.
- `Decisions/Arbitrage.swift`, `GardeFaceID.swift`, `ConduiteApresConflit.swift`
  — l'exécution des décisions et la garde biométrique.
- `Coquille/Cadence.swift`, `Cablage.swift`, `DelegueApplication.swift`,
  `VigieApp.swift`.
- `Info.plist`, `build.sh`, `deploy.sh`, `xtool.yml`.
- `Package.swift` — sauf pour ajouter une section `resources:` si tu embarques
  une police (voir §4).

Tu **consommes** ces couches, tu ne les négocies pas. Concrètement :

```swift
@Environment(\.clientPi) private var client   // la seule sortie réseau
@Environment(\.miroir)   private var miroir   // l'état local persistant
@Environment(Cadence.self) private var cadence
@Environment(Liaison.self) private var liaison
```

Et les trois règles de câblage, non négociables :

1. **Une racine de domaine s'instancie sans argument.** Tout vient de
   l'environnement.
2. **Le miroir avant le réseau.** Un écran n'affiche jamais une attente quand une
   donnée datée existe sur disque.
3. **`.cadencePar("identifiant") { … }`, jamais un `Timer` local.** Il n'existe
   qu'une seule minuterie dans l'app, elle se suspend hors avant-plan et se règle
   sur l'écran visible. Les dix minuteries parallèles de la webapp sont exactement
   ce qui vidait la batterie.

---

## 4. Les contraintes de la chaîne de compilation

Lis-les en entier avant d'écrire une ligne. Elles ne sont pas devinables et
chacune a déjà coûté une session.

**Il n'y a ni simulateur, ni aperçu SwiftUI, ni débogueur.** Ce projet compile
du Swift iOS **sur Arch Linux** via xtool + le SDK Darwin. Le seul retour visuel
possible est : Chris signe l'IPA avec Impactor et l'installe sur son téléphone.
Tu ne verras jamais ton rendu. Écris en conséquence : préfère ce qui est
déterministe et robuste à ce qui demanderait trois itérations visuelles pour être
calé. Aucun `#Preview` ne sert à quoi que ce soit ici.

- **Compiler** : `./build.sh` depuis `/home/trinity/vigie`. Produit
  `xtool/Vigie.ipa`. C'est ton unique vérification — utilise-la souvent.
- **Adresses du serveur** : jamais en dur. Elles se lisent dans l'`Info.plist`
  via `Cablage.adresseParDefaut` / `Cablage.adresseLAN`, alimentés par
  `.env.local` (non suivi) au moment du build.
- **Tests du noyau** : `. ~/.local/share/swiftly/env.sh && swift test`. Doivent
  rester verts.
- **Swift 6, concurrence stricte.** `@MainActor`, `Sendable`, `@Observable`.
  C'est la première cause d'échec de compilation sur ce projet.
- **Cible : iPhone XS, iOS 18** (l'appareil est plafonné, il ne montera jamais).
  375 × 812 pt, encoche, pas de Dynamic Island, Face ID, puce A12. Rien
  d'introduit après iOS 18 ne compile ni ne s'exécute.
- **SF Symbols** : `☠` un symbole absent se rend en **carré vide, sans erreur ni
  avertissement**. N'utilise que des symboles dont tu es certain qu'ils existent
  en iOS 18 — en cas de doute, prends l'ancêtre iOS 14 du symbole.
- **Pas d'asset catalog.** L'icône est `Icone.png` + `xtool.yml`. Pas d'image
  embarquée : ce que tu dessines, tu le dessines en SwiftUI (`Shape`, `Canvas`,
  dégradés, symboles).
- **Polices** : le système est disponible sans réserve (y compris les serif et
  les designs `.rounded`/`.monospaced` de SF). Embarquer une police custom est
  possible en théorie (fichier + `UIAppFonts` + `resources:`) mais **n'a jamais
  été testé sur cette chaîne** : si tu t'y risques, isole-le dans un lot dédié et
  garde un repli système au cas où la police ne se charge pas.
- **Provisionnement gratuit** : pas de widget, pas de Live Activity, pas d'App
  Intents, pas d'App Group, pas de notification distante. Ce qui existe : les
  notifications **locales**, le haptique, Face ID, l'audio de fond.
- **Le conteneur change d'UUID à chaque réinstallation** : ne persiste jamais un
  chemin absolu.

### `☠` Le piège qui a rendu l'app muette

Un `onLongPressGesture` (ou tout geste custom) posé **sur** un `Button` ou un
`NavigationLink` **avale le toucher** : il gagne la course contre le geste
interne du contrôle, l'action ne part jamais, et **rien ne le signale** —
l'écran a simplement l'air mort. C'est arrivé sur trois écrans à la fois.

La parade : le retour à l'appui d'un contrôle se rend **toujours** depuis
`configuration.isPressed` dans un `ButtonStyle`, jamais depuis un geste posé
par-dessus. Garde cette règle quelle que soit la forme que prendra ta charte.

### Standards de code (non négociables)

- Fichier ≤ 500 lignes, fonction ≤ 35 lignes, ligne ≤ 120 colonnes.
- Un fichier = une responsabilité. Logique métier hors des vues.
- **Tout est en français** : noms de types, de fonctions, de propriétés,
  commentaires. Les identifiants du contrat serveur (`MissionApi`, `fiveHour`)
  gardent évidemment leur forme d'origine.
- Commentaires : denses en information, jamais décoratifs. La convention `☠`
  marque un piège vérifié sur le terrain — utilise-la quand tu en trouves un,
  et **reporte celles des fichiers que tu réécris**, elles ont chacune été payées.
- Linter maison disponible : `python3 /home/trinity/.claude/lint_standards.py Sources`.

---

## 5. Méthode de travail

Le chantier est vaste. Procède **par lots**, et à la fin de chaque lot :

1. `./build.sh` → doit sortir en 0.
2. `git commit` avec un message en français décrivant l'intention.

Ne laisse **jamais** le dépôt dans un état non compilable entre deux lots : c'est
la seule chose qui permette à Chris d'installer une version intermédiaire et de
te dire ce qui ne va pas.

Ordre suggéré (à adapter) : le système de design d'abord (couleurs, typographie,
espacement, mouvement, composants), puis la coquille et la navigation, puis les
domaines par ordre d'importance — Décisions et Quart avant tout, Fil ensuite,
puis Parc, Machines, Terminal, Réglages, Alerte, Diagnostic.

Écris ta direction artistique — les principes, les jetons, les règles d'emploi —
dans `Sources/Vigie/Charte/CHARTE.md` (déjà exclu de la compilation). C'est le
document que Chris lira pour comprendre tes choix, et celui qui empêchera la
charte de pourrir dans six mois.

Une dernière chose : **on ne te bride pas.** Si ta conviction est qu'un domaine
mérite un traitement radicalement différent des autres, que la barre d'onglets à
sept entrées est une erreur, ou qu'un écran doit disparaître au profit d'un
autre — fais-le, et explique-le dans `CHARTE.md`. Tu as le dernier mot sur la
forme. Le seul juge, ensuite, c'est le téléphone de Chris à trois heures du matin.
