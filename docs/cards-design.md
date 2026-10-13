# Design des cartes et actions du joueur

## 0. État actuel (pour référence, ne pas remplir)

- **Préparation** : 5 cartes piochées. Le joueur les place sur la piste, dans un ordre de gauche à droite, puis lance le combat.
  Les cartes non jouées vont à la défausse.
- **Combat** : le lecteur lit la piste en boucle, une case toutes les `60 / bpm × beats_per_slot` s (80 BPM, 1,5 temps par case = 1,125 s).
  Chaque carte a une **temporalité** : une suite de cases, `o` = l'effet se joue, `x` = temps mort.
- **Fin de manche** : on choisit 1 carte parmi 3 en récompense, ajoutée au deck. La piste retourne à la défausse.
- **Deck de départ** : 5 Slash + 4 Shield. Le `cost` existe dans les données mais n'est utilisé nulle part.
- **Cartes existantes** :

| Nom | Coût | Temporalité | Effet |
|---|---|---|---|
| Slash | 1 | `o` | 5 dégâts à l'ennemi le plus proche |
| Shield | 1 | `xo` | +2 armure (absorbée avant les PV) |

- **Prévu dans le code mais pas implémenté** : mots-clés Flow (modifie la temporalité), Combo (dépend de la carte précédente),
  Ampli (multiplie les effets), Évolue, Métamorphe.

## 1. Intention

Le joueur dois composer la piste de lecture la plus optimale en fonction des cartes qu'il pioche. Pour ce faire il a des point de mana qu'il doit investir à chaque manche pour jouer des cartes.
Les cartes que le joueur ne jouent pas sont retenue et gardées pour le prochain round, le joueur doit donc ainsi composer avec l'entièreté de son deck et pas ne jamais jouer les cartes qui ne 
lui plaisent plus.

## 2. Boucle de jeu voulue

Le joueur choisis les cartes qu'il veut jouer, une fois les cartes choisis il lance le round de survie où il doit se concentrer sur l'esquive des ennemis pendant que les cartes se jouent en automatique.
Quand le joueur à rempli l'objectif de survie il peut alors choisir une carte parmis 3 pour les ajouter à son deck. Ainsi reprendre une nouvelle phase de prépration pour un round encore plus dur...

### 2.1 Préparation (avant le combat)

Le joueur pioche 3 cartes en mains à chaque fois. La taille de sa main max est de 8 cartes. Il possède 4 points de mana à investir à chaque round. Durant la partie le joueur peut défausser et repiocher jusqu'à 3 cartes. Il n'y a pas de taille à la piste de lecture puisque la limite se créé autour du coût en mana.


### 2.2 Combat

Pendant le combat le joueur se contente de se déplacer et d'esquiver les attaques, les cartes sont jouées automatiquement. 
Plus tard le joueur pourra intéragir avec des reliques mais pour le moment on se contente des déplacements.
La tempo change en fonction du niveau, le mieux serait de la caler sur la musique du jeu et comme les niveaux auront différentes musiques associée ça revient au même.

### 2.3 Entre deux manches

La joueur doit choisir entre 3 cartes à la fin de la manche. La carte choisie est ajoutée à la défausse.

## 3. Règles

| Règle | Valeur actuelle | Valeur voulue | Notes |
|---|---|---|---|
| Cartes piochées par manche | 5 | 3 | |
| Taille max de la piste | illimitée | illimitée | |
| Rôle du coût | aucun | limiter le nombre de cartes jouées sur la piste (4pts de mana max par round) | chaque round le joueur dispose de 4pts de mana, pas de plus, pas de moins |
| Ressource (énergie, mana...) | aucune | mana | |
| Taille du deck de départ | 9 | 6 | |
| Choix en récompense | 3, on en garde 1 | 3, on en garde 1 qui va dans la défausse | |
| Retirer une carte du deck | impossible | impossible | a prévoir pour une future update |
| Améliorer une carte | impossible | impossible | pas prévue |
| Rechargement de la piste | aucun | 2,5 s de pause après la dernière carte, puis la lecture reprend | retour de playtest, `CardReader.reload_duration` |
| Tempo (BPM) | 80 fixe | en fonction de la musique du niveau | à ne pas implémenter durant le proto car pas de musique |

## 4. Mots-clés

/!\ Supprimer les mots-clés pas dans ce tableau /!\

| Mot-clé | Effet | Exemple | Cas limites / questions |
|---|---|---|---|
| Berserk | joue l’effet désigné comme “Berserk” si le joueur a moins de 20% de ses points de vie quand la carte est lue. | partition Dash | |
| Solo | joue l’effet désigné comme “Solo” si la partition est la seule de ce type dans la piste de jeu. | partition Picking | |

## 5. Partitions (anciennements Cartes)

# Attributs des partitions

Une partition possède les attributs suivants :

- Nom : unique à chaque partition, il permet de l'identifier.
- Rareté : indique dans quelle pool la carte peut être obtenue. Il existe 4 tiers de rareté (commune / peu commune / rare / mythique).
- Coût : représente l’investissement que doit faire le joueur pour jouer la carte sur sa zone de jeu.
- Temporalité : indique quand l’action est jouée et si un temps mort a lieu lors de la lecture de la carte. Elle prend la forme d’une jauge qui est remplie de 2 manières différentes :
    - La jauge est colorée : au passage du lecteur sur cette partie de la jauge, l’effet de l’action est lu et donc joué.
    - La jauge est grisée/barrée : au passage du lecteur sur cette partie de la jauge, l’action est en cooldown, ce faisant rien ne se passe.
        - Le but de la jauge grisée est de limiter les effets snowball de certaines cartes ainsi que de préparer le joueur pour certaines actions complexes. Par exemple, on peut attendre d’un dash d’avoir une temporalité (grisée/colorée). Pendant la temporalité grisée, le jeu indique la portée du dash à venir pour prévenir le joueur de l’action.
- Type : la catégorie à laquelle appartient la partition. Les différents types sont :
    - Attaque : toutes les partitions qui affectent les ennemis.
    - Préparation : toutes les partitions qui affectent le personnage joueur.
    - Flot : toutes les partitions qui manipulent la lecture du jeu.
- Effet : la description de l’action effectuée lors de la lecture de la partition.

aussi il serait bien de généré des visuel prototype pour les différents type de carte :
- une épée pour les attaques
- un bouclier pour les préparations
- une étoile pour les flots

# Effets généraux (Mots-clés) des actions de partitions

À l’instar de nombreux jeux de cartes, des mots-clés peuvent être employés pour désigner un effet global (exemple : vol dans Magic, râle d’agonie dans Hearthstone, etc.).

- Berserk : joue l’effet désigné comme “Berserk” si le joueur a moins de 20% de ses points de vie quand la carte est lue.
- Solo : joue l’effet désigné comme “Solo” si la partition est la seule de ce type dans la piste de jeu.

# Liste de partitions

La colonne Mot-clé et Effet du mot-clé vont ensemble, si un mot-clé est présent et que la condition du mot-clé est respectée on joue alors l'effet du mot-clé.
La colonne gabarit s'applique pour le moment uniquement aux Attaques et désigne la forme que vont prendre les dégats de l'attaque. Par exemple sous forme de projectile, de cone, en zone circulaire, etc...

| Nom | Coût | Temporalité | Effet | Mot-clé | Effet du mot-clé | Gabarit | Ciblage | Type | Rareté |
|---|---|---|---|---|---|---|---|---|---|
| Shred | 1 | `o` | 5 dégâts | none | none | face au joueur (direction du regard, vers la souris) | cône | Attaque | commune |
| Ampli | 2 | `xo` | Multiplie par 2 tous les nombres de la prochaine lecture (`o`) d'une partition de type Attaque ou Préparation | none | none | soi | none | Flot | rare |
| Dash | 1 | `xo` | Ruée de 4m dans une direction | Berserk | 3 dégâts en autour du joueur à la fin de la ruée | souris | cercle de 2m | Préparation | peu commune |
| Growl | 2 | `o` | 5 dégâts autour du joueur | Berserk | Ralentit les cibles touchées pendant 2 sec | soi | cercle | Attaque | peu commune |
| Sur le fil | 3 | `xoo` | empèche les pv du joueur de tomber sous les 19% de pv | Berserk | convertit les points de dégâts encaissés en point d'armure | soi | none | Flot | mythique |
| Shield up | 1 | `o` | 3 points d'armure au joueur | none | none | soi | none | Préparation | commune |
| Picking | 0 | `o` | 4x2 dégâts aux cibles les plus proches | Solo | les projectiles rebondissent 4 fois entres les ennemis | plus proche | projectile | Attaque | commune |

Gabarits génériques (réutilisables par toute attaque, un effet comme le ralentissement se branche sur n'importe lequel) :
- **Cône** devant le joueur, orienté vers où il regarde, c.-à-d. la souris (Shred).
- **Cercle** autour du joueur (Growl, Berserk du Dash).
- **Projectile** vers les ennemis les plus proches (Picking).

### 5.1 Deck de départ

3 Shred / 2 Shield up / 1 Picking

### 5.2 Pool de récompenses

Toutes les cartes peuvent être tirée et le tirage est pondéré par rareté. Pour rappel les différentes rareré sont Commune < Peu Commune < Rare < Mythique.
Le pool évolue avec les manches, plus le joueur avance, plus les chance d'avoir une rareté élevé augmente.


## 6. Interface et lisibilité

Ajouter une logique de drag and drop quand on joue ou retire des cartes de la piste de lecture pour plus de feeling in game.
Le joueur doit voir pendant qu'il joue sa vie, l'objectif de fin de round et les cartes jouées.
Pour les cartes jouées : la carte actuellement jouée s'affiche en direct sous la barre de vie du joueur. Quand on passe à une carte suivante la carte pivote pour afficher l'autre carte.
chaque carte affiche la temporalité pour que le joueur ai un regard dessus.
La prochaine carte jouée n'est pas affichée pour le moment, ça sera à développer avec le temps.


## 7. Priorités

1. Économie de préparation : mana 4, pioche 3, main persistante (max 8), défausser/repiocher, récompense en défausse.
2. Attributs des partitions : type, rareté, icônes de type, temporalité affichée sur la carte.
3. Gabarits d'attaque + Shred, Shield up, Picking ; nouveau deck de départ (retrait de Slash et Shield).
4. Mots-clés Berserk et Solo (dont le Solo de Picking).
5. Growl (ralentissement) puis Dash (souris, aperçu de portée, Berserk).
6. Ampli.
7. Sur le fil.
8. Pool de récompenses pondéré par rareté.
9. Interface : drag & drop, HUD de combat (vie, objectif, carte jouée qui pivote).

## 8. Hors périmètre

- art des cartes
- musique
- sons
- équilibrage
- sauvegarde

tiens en toi à ce qui est listé ici et uniquement à ça dans le cadre de la conception du game et level design.

## 9. Décisions (questions tranchées)

- **Pioche** : 3 cartes par manche, y compris la première. Main pleine (8) : on ne pioche pas au-delà, le reste reste dans la pioche.
- **Défausser / repiocher** : jusqu'à 3 cartes **par manche**, le compteur repart à chaque préparation.
- **Mana** : 4 par manche, le mana non dépensé est perdu. Les cartes de la piste vont en défausse après le combat.
- **Shred** : orienté là où le joueur regarde ; le personnage se tourne vers la souris (retour de playtest, la direction du déplacement était trop dure à jouer).
- **Dash** : vers la souris projetée au sol. Invulnérable pendant la ruée, arrêté par les murs. Pendant la case `x`, la portée s'affiche au sol.
- **Ampli** : type Flot. Agit sur la prochaine lecture (`o`) d'une partition Attaque ou Préparation, donc jamais sur un autre Ampli ni sur une Flot.
  Double tous les nombres (dégâts, armure, durée du ralentissement, distance du dash). Sur Picking : double les dégâts par projectile, pas le nombre.
- **Picking** : 4 projectiles de 2 dégâts, un sur chacun des 4 ennemis les plus proches ; s'il y en a moins, les projectiles en trop vont sur les mêmes cibles.
- **Solo** : « seule de ce type » = seule partition de son **type** (Attaque / Préparation / Flot) sur la piste.
- **Sur le fil** (et sa conversion Berserk) : actif uniquement pendant ses cases `o`.
- **Partition** : renommage du texte affiché uniquement, le code garde `Card`.
- Slash et Shield sont supprimées. Les mots-clés morts du code (Flow, Combo, Évolue, Métamorphe) sont retirés ; le multiplicateur d'effet est gardé pour Ampli.
- **Récompenses** : pas deux fois la même carte dans une offre de 3. Poids par rareté croissants avec les manches, valeurs provisoires.
- **Icônes de type** : épée, bouclier, étoile en formes SVG simples.
