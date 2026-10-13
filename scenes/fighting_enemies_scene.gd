extends Node3D
class_name FightingEnemiesScene

const CARD_SCENE := preload("res://scenes/cards/card.tscn")
const CARD_MANAGEMENT_SCENE := "res://scenes/cardManagementScene.tscn"
const REWARD_SCENE := "res://scenes/rewardScene.tscn"

@onready var player: Player = %Player
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var card_reader: CardReader = %CardReader
@onready var combat_runtime: CombatRuntime = %CombatRuntime
@onready var objective: CombatObjective = %CombatObjective
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var played_cards_display: HBoxContainer = %PlayedCardsDisplay
@onready var game_over_panel: Control = %GameOverPanel
@onready var back_button: Button = %BackButton
@onready var victory_panel: Control = %VictoryPanel
@onready var victory_label: Label = %VictoryLabel
@onready var continue_button: Button = %ContinueButton

var _cards: Array[Card] = []
## Partition en cours de lecture, sous la barre de vie. Pivote à chaque changement de carte.
var _current_card: Card
var _current_index: int = -1
## Barre de rechargement de la piste, sous la carte en cours.
var _reload_bar: ProgressBar
## Victoire et mort peuvent tomber sur la même frame : le premier des deux gagne.
var _combat_over: bool = false

func _ready() -> void:
	_apply_run_state()
	_display_played_cards()
	_create_current_card()
	player.health.health_changed.connect(_on_player_health_changed)
	player.health.armor_changed.connect(_on_player_armor_changed)
	player.died.connect(_on_player_died)
	objective.progress_changed.connect(_on_objective_progress)
	objective.completed.connect(_on_objective_completed)
	card_reader.slot_entered.connect(_on_slot_entered)
	card_reader.reload_started.connect(_on_reload_started)
	card_reader.reload_finished.connect(_reload_bar.hide)
	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	game_over_panel.hide()
	victory_panel.hide()
	_refresh_health_label()
	_refresh_objective_label()
	card_reader.set_sequence(RunState.card_sequence)
	card_reader.start()
	enemy_spawner.start()

## Reprend les PV de la run et applique la difficulté de la manche en cours.
## L'armure, elle, ne persiste pas : le HealthComponent est recréé à chaque combat,
## sinon empiler Shield d'une manche sur l'autre serait un bouclier gratuit.
func _apply_run_state() -> void:
	player.health.set_current_health(RunState.player_health)
	enemy_spawner.spawn_interval = RunState.spawn_interval()
	enemy_spawner.max_enemies = RunState.max_enemies()
	objective.kills_required = RunState.kills_required()

func _display_played_cards() -> void:
	_cards.clear()
	for instance in RunState.card_sequence:
		var card := CARD_SCENE.instantiate() as Card
		played_cards_display.add_child(card)
		card.card_instance = instance
		card.locked = true
		_cards.append(card)

func _on_slot_entered(card_index: int, slot_index: int, _plays: bool) -> void:
	_show_current_card(card_index)
	_current_card.set_active_slot(slot_index)
	for i in _cards.size():
		if i == card_index:
			_cards[i].set_active_slot(slot_index)
		else:
			_cards[i].clear_active_slot()

func _on_player_health_changed(_current: int, _maximum: int) -> void:
	_refresh_health_label()

func _on_player_armor_changed(_current: int) -> void:
	_refresh_health_label()

func _refresh_health_label() -> void:
	var health := player.health
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	health_label.text = "HP %d / %d" % [health.current_health, health.max_health]
	if health.armor > 0:
		health_label.text += "   +%d" % health.armor

func _on_objective_progress(_kills: int, _required: int) -> void:
	_refresh_objective_label()

func _refresh_objective_label() -> void:
	objective_label.text = "Ennemis  %d / %d" % [objective.kills, objective.kills_required]

func _on_objective_completed() -> void:
	if not _end_combat():
		return
	victory_label.text = "Manche %d terminée" % RunState.round_index
	victory_panel.show()

func _on_player_died() -> void:
	if not _end_combat():
		return
	game_over_panel.show()

## Fige le combat. Renvoie false si la manche était déjà terminée.
func _end_combat() -> bool:
	if _combat_over:
		return false
	_combat_over = true
	enemy_spawner.stop()
	card_reader.stop()
	player.is_alive = false
	return true

func _on_continue_pressed() -> void:
	RunState.finish_round(player.health.current_health, objective.kills)
	get_tree().change_scene_to_file(REWARD_SCENE)

## Défaite : la run repart de zéro, sinon le deck et la manche continueraient de
## grossir d'une partie à l'autre.
func _on_back_pressed() -> void:
	RunState.reset_run()
	get_tree().change_scene_to_file(CARD_MANAGEMENT_SCENE)

func _create_current_card() -> void:
	_current_card = CARD_SCENE.instantiate() as Card
	health_bar.get_parent().add_child(_current_card)
	_current_card.position = Vector2(16.0, 52.0)
	_current_card.pivot_offset = _current_card.custom_minimum_size / 2.0
	_current_card.locked = true
	_current_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_card.hide()
	_reload_bar = ProgressBar.new()
	health_bar.get_parent().add_child(_reload_bar)
	_reload_bar.size = Vector2(_current_card.custom_minimum_size.x, 22.0)
	_reload_bar.max_value = 1.0
	_reload_bar.show_percentage = false
	_reload_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reload_label := Label.new()
	reload_label.text = "Rechargement"
	reload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reload_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reload_bar.add_child(reload_label)
	_reload_bar.hide()

## Retourne la carte affichée (demi-tour, échange, demi-tour) quand le lecteur
## passe à la carte suivante.
func _show_current_card(card_index: int) -> void:
	if card_index == _current_index or card_index >= RunState.card_sequence.size():
		return
	var first := _current_index == -1
	_current_index = card_index
	var instance := RunState.card_sequence[card_index]
	if first:
		_current_card.card_instance = instance
		_current_card.show()
		return
	var tween := _current_card.create_tween()
	tween.tween_property(_current_card, "scale:x", 0.0, 0.08)
	tween.tween_callback(func() -> void: _current_card.card_instance = instance)
	tween.tween_property(_current_card, "scale:x", 1.0, 0.08)

func _process(_delta: float) -> void:
	if _reload_bar.visible:
		_reload_bar.value = card_reader.get_reload_progress()

## Piste entièrement lue : plus rien ne joue pendant le rechargement.
func _on_reload_started(_duration: float) -> void:
	_current_card.clear_active_slot()
	for card in _cards:
		card.clear_active_slot()
	_reload_bar.value = 0.0
	# Sous la carte, à sa hauteur réelle (un long texte l'agrandit).
	_reload_bar.position = _current_card.position + Vector2(0.0, _current_card.size.y + 6.0)
	_reload_bar.show()
