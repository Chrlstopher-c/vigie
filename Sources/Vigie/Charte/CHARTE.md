# CHARTE — la direction artistique de Vigie

Vigie est le même produit que la webapp ccremote : même palette, mêmes proportions, même
langage. Les valeurs viennent de `ccremote/design-v2/index.html` (maquette validée par Chris)
et de la prod `pi-web`. Ce dossier est la seule source de vérité visuelle : **aucun écran ne
définit une couleur, une taille de police, un rayon ou une courbe d'animation en dehors de
ces jetons.**

## Principes

1. **Crème, pas blanc.** Le fond de tout écran est `Couleurs.fond` (#FAF9F5). Le blanc pur
   n'existe que sur `surface` — les cartes. C'est ce contraste doux qui fait la signature.
2. **Thème unique clair.** La maquette validée n'a pas de variante sombre ; on n'en invente
   pas. La vue racine doit poser `.preferredColorScheme(.light)` pour verrouiller. Le seul
   îlot sombre est `ZoneTerminal` (terminal et blocs de code), à dessein.
3. **L'orange est une denrée rare.** `accentPrimaire` signifie « ceci réclame ta décision ou
   ton attention » : escalade, mission active, mandat en attente, bouton d'engagement.
   Jamais décoratif. Un écran sans urgence est un écran sans orange — c'est voulu.
4. **Trois familles, trois rôles.** Serif (New York, repli iOS de Source Serif 4) pour les
   titres et chiffres vedettes ; sans (SF Pro, repli d'Inter) pour le corps ; mono (SF Mono,
   repli de JetBrains Mono) pour toute donnée : chemins, quotas, horodatages, identifiants.
   Une donnée en sans ou un titre en gras sans serif trahit la charte.
5. **La couleur est sémantique ou n'est pas.** Tout état passe par `EtatSemantique`
   (sain / vigilance / danger / accent / neutre), qui porte teinte pleine, voile et encre
   lisible. Le jaune plein ne porte jamais de texte : sur voile vigilance, l'encre est
   `encreVigilance` (#8A6A12).
6. **Async dans les mouvements.** Rien n'apparaît brutalement, rien ne saute. Toute entrée
   de contenu passe par `.apparitionDouce(rang:)` (fondu + 6 pt, cascade de 50 ms par rang) ;
   tout changement d'état s'anime avec une courbe de `Mouvement`, nommée par intention.
   60 Hz sur A12 : opacité et transformations seulement, jamais de flou animé.
7. **Jamais un spinner quand une donnée datée existe.** Le miroir s'affiche avec
   `IndicateurFraicheur` (« relevé il y a 3 h »). Le squelette est réservé au tout premier
   remplissage ; `IndicateurActivite` aux actions en cours, pas aux écrans.
8. **Hiérarchie par retrait, pas par ombre.** fond → fondCreuse → fondProfond creusent ;
   `surface` + filet élève. Les ombres n'existent que sur le flottant (toast) et le halo
   des cartes actives.

## Vocabulaire des composants (`Composants/`)

| Brique | Rôle | Interdit de réinventer pour |
|---|---|---|
| `CarteVigie(relief:)` | conteneur universel ; `.active`, `.bordee(état)`, `.eteinte` | toute carte de mission, compte, réglage |
| `SectionVigie` | titre serif + contenu | toute rubrique d'écran |
| `LigneCleValeur` | clé grise / valeur mono | métadonnées de mission, réglages |
| `PastilleEtat`, `PointVital` | capsule d'état, point qui respire | statuts, témoins de lien |
| `.vigiePrimaire/.vigieAccent/.vigieSecondaire/.vigieDestructif` | les 4 boutons | tout bouton |
| `BoutonMaintenu` | maintien 1,5 s avant action irréversible | tout geste destructif engageant |
| `ChampSaisie` | champ à étiquette, aide, erreur inline | tout formulaire |
| `IndicateurFraicheur` | âge du miroir, auto-rafraîchi | tout affichage de donnée datée |
| `EtatVide` | vide expliqué | toute liste vide |
| `JaugeQuota`, `BarreProgression`, `BarreIndeterminee`, `IndicateurActivite` | quotas et progressions | fenêtres 5 h / 7 j, contexte |
| `SqueletteVigie` | premier chargement uniquement | — |
| `TuileStatistique` | compteur vedette du Pouls | les 6 compteurs de parc |
| `AvatarMachine` | initiales d'hôte + état | toute machine du parc |
| `EtiquetteOutil`, `LigneFil` | fil de mission typé par `GenreEvenement` | fils d'évènements |
| `BulleUtilisateur`, `BulleAgent`, `EncartOutil` | fil de conversation | l'orchestrateur |
| `PuceMono`, `PuceFiltre` | chips info et filtres | filtres tout/activité/autorisations |
| `BandeauAlerte` | bandeau d'état pleine largeur | lien coupé, avertissements |
| `ZoneTerminal(repliement:)` | îlot sombre mono | terminal tmux, blocs de code |
| `BasculeVigie` | rangée de réglage à interrupteur | tout réglage booléen |
| `.toastVigie(message:)` | confirmation éphémère | tout accusé d'action |

## Ce qu'on ne fait jamais

- Une couleur, taille, durée ou rayon littéral dans un écran.
- Deux boutons accent côte à côte ; un destructif sans confirmation ou maintien.
- Du texte sur jaune plein ; de l'orange décoratif.
- Un spinner plein écran ; une apparition sans animation ; un saut de mise en page.
- Un dégradé hors de la carte `.active` ; une ombre hors flottant/halo.
