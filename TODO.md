# Vigie — à faire

*Priorités arrêtées par Chris le 2026-08-18.* Ce qu'il utilise réellement, dans
l'ordre : **l'orchestrateur et ses fils**, **les équipes et leurs sous-agents**,
**l'allumage à distance des machines**, **les stats du parc**. Tout le reste est
du décor : quand un arbitrage se pose, c'est ce classement qui tranche.

## 🔴 D'abord : confronter au réel

Rien de ce qui suit n'a de sens avant. Tout le code d'interface a été écrit sans
simulateur, sans preview et sans débogueur.

1. **Poser l'IPA sur l'iPhone** et ouvrir chaque écran.
2. **Capturer chaque route au `curl`** depuis le Pi et comparer aux `Codable` du
   contrat. Les formes ont été dérivées des sources, jamais observées.
3. Vérifier les trois sondes de `Diagnostic/` sur l'appareil : autorisation
   accordée, aller-retour de trousseau, modes de fond déclarés.
4. Vérifier que `Reprise` s'enregistre (`reveilEnregistre`) — un identifiant
   absent de `BGTaskSchedulerPermittedIdentifiers` échoue **à l'exécution**.
5. Vérifier la cohabitation **dictée / canal d'alerte** : dicter pendant que
   `MaintienVie` tient sa session est raisonné, pas mesuré.

## Notifications — brancher sur les vrais événements

Ce qui a été prouvé dans les labs EchoLabs, c'est le **mécanisme**. Ce qui n'a
jamais été observé, c'est ce mécanisme déclenché par un **événement réel du Pi**.

- [ ] Provoquer un vrai mandat sur le Pi, app fermée, et vérifier que l'alerte
      arrive. C'est la seule preuve qui compte : tout le reste de Vigie peut
      marcher, si celle-ci ne part pas le produit ne sert à rien.
- [ ] Reprendre les autres circuits un par un : rallonge, `equipe_terminee`,
      `equipe_echouee`. Même sondage (`CentreAlerte.sonder`), routes et
      catégories différentes.
- [ ] Vérifier sur l'appareil les deux circuits ajoutés le 17/08 :
      `sonnerLesArbitrages` (arbitrage d'inspection, catégorie sans boutons) et
      `sonnerLesReponses` (fil quitté en génération) — surtout le cas « je
      verrouille sans quitter ».
- [ ] Vérifier la **déduplication** sur la durée : une même proposition sondée
      par le canal audio, puis par le rattrapage d'ouverture, puis par un réveil
      de fond ne doit sonner qu'une fois.
- [ ] Vérifier les **actions** de notification (accorder / refuser depuis l'écran
      verrouillé) contre le vrai serveur — `ActionRecue` écrit réellement, la
      route n'a jamais été appelée depuis ce chemin.
- [ ] Mesurer le délai réel entre l'événement sur le Pi et l'alerte sur le
      téléphone, dans les quatre régimes (app ouverte, en fond avec audio, en
      fond sans audio, app tuée).

## 🆕 Artéfact de l'orchestrateur — accordé par Chris le 2026-08-18

L'orchestrateur doit pouvoir **présenter un fichier** (sh, py, lua, html…) dans
le fil : affichage direct dans l'app, téléchargement, et pour le HTML une
bascule code source / rendu. Demande d'origine côté serveur : `ccremote/TODO.md`,
section du 08/08.

`☠` **La forme choisie côté serveur décide de tout le travail client.** Si
l'artéfact réutilise le mécanisme de **pièces jointes** existant (migration 24,
`control-plane/pieces-jointes/`, servi par `GET …/conversations/:id/pieces/:f`),
alors Vigie a déjà presque tout : `PieceJointeApi`, `Route.pieceJointe`,
`VignettePieceDistante`, `VisionneusePieceEcran` (image / texte / JSON / PDF).
Un second mécanisme obligerait à écrire un second chemin d'octets pour rien.
**À porter comme argument au moment de trancher côté Pi.**

- [ ] **Coloration syntaxique** dans la visionneuse : `RenduMarkdownCode` existe
      déjà et sait rendre un bloc `code`. Aujourd'hui `VisionneusePieceEcran`
      rend `text/*` en texte brut monospace.
- [ ] **Reconnaître les types de code** : `text/x-shellscript`, `text/x-python`,
      `application/x-lua`, `text/html`. `☠` Ne pas se fier au seul MIME du
      serveur — se rabattre sur l'extension du `nom`, un type générique
      (`application/octet-stream`) est le cas courant.
- [ ] **Bascule code / rendu pour le HTML.** `☠` C'est la SEULE partie qui porte
      un risque réel : un HTML produit par un modèle est du contenu non fiable.
      L'équivalent iOS de l'`iframe sandbox` sans `allow-same-origin`, c'est un
      `WKWebView` avec `WKWebViewConfiguration.websiteDataStore = .nonPersistent()`
      chargé par `loadHTMLString(_:baseURL: nil)` — **jamais** `loadFileURL`, qui
      donnerait une origine réelle. Et un `WKNavigationDelegate` qui refuse toute
      navigation postérieure au chargement initial : sans lui, un simple
      `<img src="https://…">` exfiltre vers l'extérieur.
- [ ] **Enregistrer l'artéfact** — sur iOS, pas de « download » : un
      `UIActivityViewController` (partage / « Enregistrer dans Fichiers »),
      alimenté par les octets déjà en mémoire.
- [ ] **Bien géré par discussion.** L'artéfact appartient au fil et doit y rester
      lisible après une **compaction** — contrainte à faire tenir côté serveur.
      Côté client, trancher si les octets se cachent localement par (fil,
      fichier) pour rester lisibles hors ligne : le miroir ne stocke que du JSON
      aujourd'hui.
- [ ] Composant replié par défaut dans la conversation, déplié au toucher —
      réutiliser le vocabulaire des valises (`VueSegmentFil`), pas un troisième.

## 🆕 Le parc devient multi-machines (le portable rejoint ccremote)

Décision du 2026-08-18 : `trinity-portable` devient une machine de travail.
Conséquences **côté Vigie**, indépendamment du chantier serveur :

- [ ] **`SectionPoste` ne parle que d'UN poste** (`/api/status`, `/api/wake`,
      routes natives de `pi-web`, adossées au seul PC fixe). À trois machines,
      cette section devient fausse par construction : le réveil doit se demander
      **depuis la carte de la machine**, pas depuis une section « Poste de
      travail » unique.
- [ ] `☠` `POST /api/wake` ne réveille **que** le PC fixe : la MAC est une
      constante côté Pi (`reveil-wol.ts`) et l'outil de l'orchestrateur porte un
      `z.enum(['pc'])` fermé — c'est un garde-fou délibéré, pas un oubli. Un
      réveil par machine dans Vigie **exige** d'abord le chantier serveur.
- [ ] Vérifier que `CarteMachine` et `ChargeMachines` tiennent à N machines : le
      libellé du parc, les groupes d'équipes et les métriques sont écrits
      génériquement, jamais exercés au-delà de deux.

## Ergonomie — le glissement de bord a disparu

La refonte masque la barre de navigation système (`.toolbar(.hidden)` dans la
coquille et quatre écrans), ce qui neutralise l'`interactivePopGestureRecognizer` :
le retour arrière ne se fait plus que par le chevron. Sur une app tenue d'une
main c'est un idiome perdu.

- [ ] Rétablir le glissement de bord tout en gardant l'en-tête de la charte.

## Bus d'alerte en arrière-plan — le rendre économe

L'isolation est déjà bonne : la `Cadence` des écrans est coupée hors avant-plan,
aucun domaine ne sonde en fond. **Le problème n'est pas le périmètre du bus,
c'est son débit.** Boucle à 25 s, **trois** requêtes HTTPS en série par tour, une
écriture miroir par lecture, un réarmement complet des alarmes à chaque tour. Sur
24 h ≈ 10 000 requêtes, ~10 000 écritures disque, ~14 000 opérations sur
`UNUserNotificationCenter`.

`☠` Le poste dominant n'est ni le CPU ni l'audio : c'est **la radio**. Sur
données mobiles une requête garde le modem en état haut une dizaine de secondes ;
à 25 s d'intervalle il ne redescend jamais. On paie une radio allumée en
permanence pour apprendre, 99 % du temps, que rien n'a changé.

### Gains client — sans dépendance serveur, sans risque

- [ ] **Ne plus réarmer l'alarme de silence à chaque tour** (`CentreAlerte.sonder`
      appelle `Armement.armerAlarmeDeSilence` inconditionnellement). La réarmer
      seulement quand le dernier contact a bougé significativement, ou qu'un
      événement est tombé. ~14 000 opérations/jour → quelques dizaines.
- [ ] **Ne plus écrire le miroir depuis le bus** : les trois lectures passent
      `memoriser:`, donc écrivent sur disque à chaque tour alors qu'aucun écran
      ne regarde. Le rattrapage d'ouverture remplit déjà le cache.
- [ ] **Cadence adaptative** au lieu de 25 s fixes : 25 s tant que ça bouge, puis
      60 s, puis 120 s après N tours vides ; retour à 25 s au premier événement.
- [ ] **Couper le sondage quand le parc est vide** : aucune équipe en cours ⇒
      personne ne peut demander de mandat. C'est le gain le plus propre.
- [ ] Vérifier que la session HTTP du bus réutilise bien sa connexion
      (keep-alive / HTTP-2) : à 25 s d'intervalle elle peut être refermée
      entre-temps, et on repaie une poignée TLS à chaque tour.

### Le bon dessin final — dépend du Pi

- [ ] **Un seul aller-retour au lieu de trois** : une route d'alerte native qui
      agrège les trois circuits et ne rend qu'un compteur + un jeton d'état. Le
      détail n'est téléchargé que si le jeton a changé.
- [ ] **Long-poll** (chantier **B** ci-dessous) : requête ouverte 60-90 s,
      réponse à l'événement. Le modem reste bas tant que rien ne circule, et
      l'alerte devient quasi instantanée au lieu d'avoir jusqu'à 25 s de retard.

### La question à trancher avant de régler les seuils

Ce n'est pas « combien de batterie », c'est **combien de batterie pour quel délai
d'alerte**. Passer à 120 s en période calme, c'est accepter jusqu'à deux minutes
de retard sur un mandat. Arbitrage de Chris, une fois qu'un vrai mandat aura
sonné au moins une fois.

## Serveur (`~/ccremote`, à faire sur le Pi — le clone local est en lecture seule)

- [ ] **C** — `check_session` : 401 JSON sur `/api/*`, 303 conservé sur le HTML.
- [ ] **D** — curseur `?since=<createdAt>` sur `GET /harness/notifications`,
      aujourd'hui plafonné à 50 sans curseur : le rattrapage est un « à peu près »,
      et `EtatCanal.rattrapageIncomplet` le dit au lieu de le masquer.
- [ ] **A** — `signalerFait()` : journaliser un mandat en attente **sans le
      remettre** dans le fil de l'orchestrateur (sinon il reçoit une alerte
      annonçant sa propre proposition). Vigie détecte donc les propositions
      **par différence** sur `/orchestrator/propositions`.
- [ ] **B** — `pi-web/alerte/` : long-poll natif, jamais derrière
      `harness_proxy.py` (5 s de timeout imposé).
- [ ] **E** — cookie de session sans `max_age` ni `expires` : il ne survit pas au
      relancement. `☠` Non corrigé par le commit `2e0689f` de la branche
      `local-models`, qui ne touche que le drapeau `secure`.
- [ ] Durcir l'authentification du serveur. `☠` Le
      détail du modèle d'authentification retiré de l'historique.
      Voir les notes locales.
- [ ] Réveil par machine (voir la section multi-machines ci-dessus).

## Client — ce qui manque encore

- [ ] Les six labs d'EchoLabs à porter dans `Diagnostic/` (shader, neural…).
- [ ] Écran de recette hors ligne : vérifier que chaque domaine s'ouvre sur le
      miroir, tunnel coupé.

## Confirmations restées ouvertes sur l'appareil

- [ ] Le rattachement d'un fil à une autre machine se voit **immédiatement** dans
      l'en-tête après le geste (corrigé le 17/08 par
      `ConversationEcran.rafraichirFilConnu()`, jamais vu tourner).
- [ ] Que le `POST …/machine` **aboutisse** réellement côté serveur
      (`ReglagesFilFeuille.swift:165`) — non vérifiable d'ici sans session
      authentifiée au `curl`. Le symptôme du 17/08 était compatible avec un
      affichage figé comme avec un ordre sans effet ; l'affichage est corrigé,
      l'ordre reste à prouver.
- [ ] Plus aucune mention de « PC » là où le sujet n'est pas le poste de travail.
- [ ] Le bandeau `EtatChaine` (branché le 18/08) : voir un `superviseurTombe`
      réel — poste allumé, superviseur arrêté.

## Vérifications de terrain restées ouvertes

- [ ] Une locale déjà armée se déclenche-t-elle **après expiration du profil** ?
      Toute la valeur de l'alarme de silence en dépend — armer un déclencheur à
      J+8 pour le savoir.
- [ ] SideStore rafraîchit-il la signature en WiFi ? Si oui, la falaise
      hebdomadaire disparaît.
- [ ] Seuil de coupure de Cloudflare Tunnel sur une connexion maintenue.

## Hors périmètre — décidé, ne pas rouvrir

- **L'agent conversationnel de la webapp v1** (`/api/agent/chat`,
  `/api/agent/usage`, `/api/agent/context-usage`). Décision de Chris du
  2026-08-18 : Vigie est le client de l'orchestrateur et du parc, pas un second
  chat. `Route.agentWebappHorsPerimetre` porte la note.
- **`POST /api/shutdown`** : éteint la machine de travail sans confirmation
  serveur. À rouvrir seulement derrière un geste armé et Face ID.
- **`GET /api/metrics`** (métriques live du PC par websocket, 3 s côté webapp) :
  Vigie lit `/machines/metriques` du harness, à la demande. Sonder en boucle
  coûterait la batterie d'une journée pour un chiffre regardé trois secondes.
