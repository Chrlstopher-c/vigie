# Vigie — à faire

## 🔴 URGENT — le PC et le VPS sont confondus dans tout le produit

Constaté sur l'appareil le 2026-08-17 : fil créé sur le PC, basculé sur le VPS,
**l'affichage ne bouge pas** ; et partout dans l'app on lit « PC en ligne » /
« PC éteint » alors que le PC est éteint **et que le fil tourne sur le VPS**.
L'app parle d'une machine qui n'a rien à voir avec ce qui est regardé.

### Racine A — l'état d'UNE machine est présenté comme l'état de la liaison

`Lecture.pcEnLigne` (`Contrat/Enveloppe.swift`) vaut `true` sur `.fraiche` et
`false` sur tout le reste : il ne dit donc pas « le PC est éteint » mais
**« ce relevé a été servi daté »**. `Liaison.appliquer` en fait un régime
**global** `.posteEteint`, libellé « PC éteint », affiché en permanence en haut de
**tous** les écrans — y compris sur un fil hébergé par le VPS.

Trois notions distinctes ont fusionné et doivent être re-séparées :

1. **La liaison au Pi** — joignable / perdue / session à rouvrir. Globale, c'est
   la seule chose qui mérite un bandeau permanent.
2. **La fraîcheur d'un relevé** — `.fraiche` vs `.datee`. Propriété **du relevé**
   affiché, pas du parc. C'est déjà ce que porte `MentionFraicheur`.
3. **L'état d'une machine** — `MachineApi.enLigne`, **par machine**, lu sur
   `/machines`. Le poste de travail n'est qu'une machine parmi N.

Cible : le bandeau global ne parle plus jamais du PC. L'état d'une machine ne
s'affiche que là où cette machine est le sujet (carte de machine, fil qui y
tourne, session tmux qui en dépend). Quand le PC dort et que le VPS travaille,
l'app doit dire « le parc tourne », jamais « PC éteint ».

`☠` Ne pas jeter la distinction pour autant : les routes natives `pi-web`
(`/api/status`, `/api/sessions`, `/api/launch`, tmux) sont **réellement** adossées
au seul poste de travail, et `pcAbsent` y garde tout son sens. C'est **là** que
« le PC dort » est la bonne phrase — et nulle part ailleurs.

### Racine B — la machine d'un fil n'est pas relue après un changement

`DetailFilApi` ne porte **pas** de champ `machine` (commentaire assumé dans
`Contrat/FilEvenement.swift` : « la machine d'un fil se lit sur la liste, pas sur
le détail »). Après un `POST /machine`, l'écran de conversation n'a donc rien à
relire : la valeur affichée vient du `FilApi` de la **liste**, rafraîchi seulement
en revenant en arrière. D'où « rien ne bouge ».

Deux issues, la première est la bonne :
- [ ] Ajouter `machine` à la réponse du détail côté serveur, et au contrat.
- [ ] À défaut : relire la liste des fils après l'écriture, et propager.

### À faire aussi dans la foulée

- [ ] Nommer les machines par leur identité réelle partout (poste, VPS, …) plutôt
      que par « PC » — le mot désigne une machine précise, pas une catégorie.
- [ ] Vérifier que le changement de machine d'un fil **aboutit réellement**
      côté serveur (`ReglagesFilFeuille.swift:165`) : le symptôme observé est
      compatible avec un affichage figé comme avec une écriture sans effet.

## Ergonomie — le glissement de bord a disparu

La refonte masque la barre de navigation système (`.toolbar(.hidden)` dans la
coquille et quatre écrans), ce qui neutralise l'`interactivePopGestureRecognizer` :
le retour arrière ne se fait plus que par le chevron. Sur une app tenue d'une
main c'est un idiome perdu.

- [ ] Rétablir le glissement de bord tout en gardant l'en-tête de la charte.

## D'abord : confronter au réel

1. **Poser l'IPA sur l'iPhone** et ouvrir chaque écran. Rien de ce qui suit n'a
   de sens avant : tout le code d'interface a été écrit sans simulateur, sans
   preview et sans débogueur.
2. **Capturer chaque route au `curl`** depuis le Pi, et comparer aux `Codable`
   du contrat. Les formes ont été dérivées des sources, jamais observées.
3. Vérifier les trois sondes de `Diagnostic/` sur l'appareil : autorisation
   réellement accordée, aller-retour de trousseau, modes de fond déclarés.
4. Vérifier que `Reprise` s'enregistre (`reveilEnregistre`) — un identifiant
   absent de `BGTaskSchedulerPermittedIdentifiers` échoue **à l'exécution**.

## Notifications — brancher sur les vrais événements

Ce qui a été prouvé dans les labs EchoLabs, c'est le **mécanisme** : une locale
part, elle s'affiche, ses actions reviennent à l'app. Ce qui n'a jamais été
observé, c'est ce mécanisme déclenché par un **événement réel du Pi** — la chaîne
`Alerte/` est écrite et câblée, elle n'a simplement jamais sonné pour un vrai
mandat.

- [ ] Provoquer un vrai mandat sur le Pi, app fermée, et vérifier que l'alerte
      arrive. C'est la seule preuve qui compte : tout le reste de Vigie peut
      marcher, si celle-ci ne part pas le produit ne sert à rien.
- [ ] Reprendre les trois autres circuits un par un : rallonge, arbitrage
      d'inspection, notification du harness. Ils passent par le même sondage
      (`CentreAlerte.sonder`) mais pas par les mêmes routes ni les mêmes
      catégories.
- [ ] Vérifier la **déduplication** sur la durée : une même proposition sondée
      par le canal audio, puis par le rattrapage d'ouverture, puis par un réveil
      de fond ne doit sonner qu'une fois.
- [ ] Vérifier les **actions** de notification (accorder / refuser depuis l'écran
      verrouillé) contre le vrai serveur — `ActionRecue` écrit réellement, la
      route n'a jamais été appelée depuis ce chemin.
- [ ] Mesurer le délai réel entre l'événement sur le Pi et l'alerte sur le
      téléphone, dans les quatre régimes (app ouverte, en fond avec audio, en
      fond sans audio, app tuée).

## Bus d'alerte en arrière-plan — le rendre économe

Constat : l'isolation est déjà bonne — la `Cadence` des écrans est coupée hors
avant-plan, aucun domaine ne sonde en fond. Ce qui reste vivant est bien le seul
bus (`MaintienVie` + sa boucle). **Le problème n'est pas son périmètre, c'est son
débit.**

Coût mesuré sur le papier, jamais sur l'appareil : boucle à **25 s**, **trois**
requêtes HTTPS en série par tour (`/notifications`, `/propositions`,
`/rallonges`), une écriture miroir par lecture, et un réarmement complet des
alarmes de silence à chaque tour. Sur 24 h ≈ **10 000 requêtes**, ~10 000
écritures disque, ~14 000 opérations sur `UNUserNotificationCenter`.

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
      personne ne peut demander de mandat. Les périodes réellement mortes doivent
      coûter zéro requête. C'est le gain le plus propre.
- [ ] Vérifier que la session HTTP du bus réutilise bien sa connexion
      (keep-alive / HTTP-2) : à 25 s d'intervalle elle peut être refermée
      entre-temps, et on repaie une poignée TLS à chaque tour.

### Le bon dessin final — dépend du Pi

- [ ] **Un seul aller-retour au lieu de trois** : une route d'alerte native qui
      agrège les trois circuits et ne rend qu'un compteur + un jeton d'état. Le
      détail n'est téléchargé que si le jeton a changé — quelques dizaines
      d'octets au lieu de trois listes JSON complètes.
- [ ] **Long-poll** (chantier **B** de la section serveur) : requête ouverte
      60-90 s, réponse à l'événement. Le modem reste bas tant que rien ne
      circule, et l'alerte devient quasi instantanée au lieu d'avoir jusqu'à 25 s
      de retard. Conditionné à la mesure du seuil de coupure de Cloudflare
      Tunnel — déjà en attente plus bas.

### La question qu'il faut trancher avant de régler les seuils

Ce n'est pas « combien de batterie », c'est **combien de batterie pour quel délai
d'alerte**. Passer à 120 s en période calme, c'est accepter jusqu'à deux minutes
de retard sur un mandat. Arbitrage de Chris, à faire une fois qu'un vrai mandat
aura sonné au moins une fois (voir la section notifications).

## Serveur (`~/ccremote`, à faire sur le Pi — le clone local est en lecture seule)

- [ ] **C** — `check_session` : 401 JSON sur `/api/*`, 303 conservé sur le HTML.
- [ ] **D** — curseur `?since=<createdAt>` sur `GET /harness/notifications`.
- [ ] **A** — `signalerFait()` : journaliser un mandat en attente **sans le
      remettre** dans le fil de l'orchestrateur (sinon il reçoit une alerte
      annonçant sa propre proposition).
- [ ] **B** — `pi-web/alerte/` : long-poll natif, jamais derrière
      `harness_proxy.py` (5 s de timeout imposé).
- [ ] Durcir l'authentification du serveur.

## Client — ce qui manque encore

- [ ] Rappels d'un fil (`/rappels`), autonomie et machine d'un fil : les routes
      sont déclarées, aucun écran ne les appelle.
- [ ] Bascule de modèle / effort / mode rapide à l'envoi d'un message.
- [ ] Compaction et renommage d'un fil.
- [ ] Détail d'un sous-agent (`/missions/{id}/agents/{agentId}`).
- [ ] Les six labs d'EchoLabs à porter dans `Diagnostic/` (shader, neural…).
- [ ] Écran de recette hors ligne : vérifier que chaque domaine s'ouvre sur le
      miroir, tunnel coupé.

## Vérifications de terrain restées ouvertes

- [ ] Une locale déjà armée se déclenche-t-elle **après expiration du profil** ?
      Toute la valeur de l'alarme de silence en dépend — armer un déclencheur à
      J+8 pour le savoir.
- [ ] SideStore rafraîchit-il la signature en WiFi ? Si oui, la falaise
      hebdomadaire disparaît.
- [ ] Seuil de coupure de Cloudflare Tunnel sur une connexion maintenue.
