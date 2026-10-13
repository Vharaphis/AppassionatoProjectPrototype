extends Node

## État qui survit aux changements de scène : le deck, les PV du joueur, la manche
## en cours et la piste verrouillée pendant la préparation.
##
## Autoload "RunState", déclaré sous forme de scène (res://scenes/run/runState.tscn)
## pour que le Deck et le pool de récompense restent éditables dans l'inspecteur.
## Pas de `class_name` ici : il entrerait en collision avec le nom du singleton.

signal run_reset
signal round_finished(round_index: int)

@export_group("Objectif")
## Ennemis à tuer pour terminer la première manche.
@export var base_kills: int = 8
## Ennemis supplémentaires demandés à chaque manche suivante.
@export var kills_per_round: int = 2

@export_group("Préparation")
## Mana à dépenser sur la piste à chaque manche. Le mana non dépensé est perdu.
@export var mana_per_round: int = 4
## Cartes piochées au début de chaque préparation, dans la limite de `max_hand_size`.
@export var draw_per_round: int = 3
@export var max_hand_size: int = 8
## Défausser une carte de la main pour en repiocher une, autant de fois par manche.
@export var redraws_per_round: int = 3

@export_group("Récompense")
## Nombre de cartes proposées par la scène de récompense.
@export var reward_choices: int = 3
## Cartes tirables en récompense. Un pool de N cartes ne peut pas proposer plus de
## N choix distincts : au-delà, les doublons sont assumés (cf. roll_reward).
@export var reward_pool: Array[CardData] = []
## Poids de tirage par rareté (commune, peu commune, rare, mythique) :
## `base + par manche × (manche - 1)`, jamais sous le minimum. Valeurs provisoires.
@export var rarity_base_weights: Array[float] = [60.0, 30.0, 8.0, 2.0]
@export var rarity_weights_per_round: Array[float] = [-4.0, 1.5, 1.5, 1.0]
@export var rarity_min_weights: Array[float] = [15.0, 0.0, 0.0, 0.0]

@export_group("Difficulté")
@export var base_spawn_interval: float = 1.0
@export var spawn_interval_step: float = 0.05
@export var min_spawn_interval: float = 0.35
@export var base_max_enemies: int = 15
@export var max_enemies_step: int = 2
@export var max_enemies_cap: int = 25

@export_group("Joueur")
## Doit correspondre au max_health du HealthComponent de player.tscn.
@export var player_max_health: int = 100

@export_group("Debug")
## Manche de départ d'une run neuve, pour tester une manche avancée : objectif,
## difficulté et table de spawn suivent tous. 0 = manche 1.
@export var debug_start_round: int = 0

@onready var deck: Deck = $Deck

## Cartes verrouillées sur la piste pendant la préparation, lues par le combat.
var card_sequence: Array[CardInstance] = []
## Cartes non jouées, gardées en main d'une manche à l'autre.
var hand: Array[CardInstance] = []
var round_index: int = 1
var player_health: int = 100
var kills_total: int = 0

func _ready() -> void:
	reset_run()

## Repart d'une run neuve : deck d'origine, PV pleins, manche 1.
func reset_run() -> void:
	round_index = debug_start_round if debug_start_round > 0 else 1
	player_health = player_max_health
	kills_total = 0
	card_sequence.clear()
	hand.clear()
	deck.reset()
	run_reset.emit()

func kills_required() -> int:
	return base_kills + kills_per_round * (round_index - 1)

func spawn_interval() -> float:
	return maxf(min_spawn_interval, base_spawn_interval - spawn_interval_step * (round_index - 1))

func max_enemies() -> int:
	return mini(base_max_enemies + max_enemies_step * (round_index - 1), max_enemies_cap)

## Fin de manche gagnée : on sauve les PV, la piste retourne à la défausse et on
## passe à la manche suivante.
func finish_round(current_health: int, kills: int) -> void:
	player_health = clampi(current_health, 0, player_max_health)
	kills_total += kills
	discard_sequence()
	round_index += 1
	round_finished.emit(round_index)

## Renvoie les cartes de la piste à la défausse. Sans ça elles quittent le deck
## définitivement et la pioche finit par se vider : plus rien à jouer, soft lock.
func discard_sequence() -> void:
	for instance in card_sequence:
		deck.discard(instance)
	card_sequence.clear()

func rarity_weight(rarity: CardData.Rarity, round_number: int) -> float:
	return maxf(rarity_min_weights[rarity], rarity_base_weights[rarity] + rarity_weights_per_round[rarity] * (round_number - 1))

## Tire les cartes proposées en récompense, pondérées par rareté selon la manche.
## Cartes distinctes tant que le pool le permet, doublons au-delà (pool de 2
## cartes = 3 propositions impossibles à rendre toutes différentes).
func roll_reward() -> Array[CardData]:
	var picks: Array[CardData] = []
	if reward_pool.is_empty():
		push_warning("RunState.reward_pool est vide : aucune récompense à proposer.")
		return picks
	var bag: Array[CardData] = []
	for data in reward_pool:
		if data and not bag.has(data):
			bag.append(data)
	for i in reward_choices:
		if bag.is_empty():
			picks.append(reward_pool.pick_random())
			continue
		var data := _pick_weighted(bag)
		bag.erase(data)
		picks.append(data)
	return picks

func _pick_weighted(cards: Array[CardData]) -> CardData:
	var total := 0.0
	for data in cards:
		total += rarity_weight(data.rarity, round_index)
	if total <= 0.0:
		return cards.pick_random()
	var roll := randf() * total
	for data in cards:
		roll -= rarity_weight(data.rarity, round_index)
		if roll < 0.0:
			return data
	# Float rounding can leave roll at ~0 after the loop.
	return cards.back()

func add_card_to_deck(data: CardData) -> void:
	deck.add_card(data)
