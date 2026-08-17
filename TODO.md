# Vigie — à faire

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
