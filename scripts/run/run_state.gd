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

@export_group("Récompense")
## Nombre de cartes proposées par la scène de récompense.
@export var reward_choices: int = 3
## Cartes tirables en récompense. Un pool de N cartes ne peut pas proposer plus de
## N choix distincts : au-delà, les doublons sont assumés (cf. roll_reward).
@export var reward_pool: Array[CardData] = []

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

@onready var deck: Deck = $Deck

## Cartes verrouillées sur la piste pendant la préparation, lues par le combat.
var card_sequence: Array[CardInstance] = []
var round_index: int = 1
var player_health: int = 100
var kills_total: int = 0

func _ready() -> void:
	reset_run()

## Repart d'une run neuve : deck d'origine, PV pleins, manche 1.
func reset_run() -> void:
	round_index = 1
	player_health = player_max_health
	kills_total = 0
	card_sequence.clear()
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

## Tire les cartes proposées en récompense. Cartes distinctes tant que le pool le
## permet, doublons au-delà (pool de 2 cartes = 3 propositions impossibles à
## rendre toutes différentes).
func roll_reward() -> Array[CardData]:
	var picks: Array[CardData] = []
	if reward_pool.is_empty():
		push_warning("RunState.reward_pool est vide : aucune récompense à proposer.")
		return picks
	var bag := reward_pool.duplicate()
	bag.shuffle()
	for i in reward_choices:
		var data: CardData = bag[i] if i < bag.size() else reward_pool.pick_random()
		picks.append(data)
	return picks

func add_card_to_deck(data: CardData) -> void:
	deck.add_card(data)
