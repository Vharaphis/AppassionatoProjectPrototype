extends Node3D
class_name FightingEnemiesScene

const CARD_SCENE := preload("res://scenes/cards/card.tscn")
const CARD_MANAGEMENT_SCENE := "res://scenes/cardManagementScene.tscn"

@onready var player: Player = %Player
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var card_reader: CardReader = %CardReader
@onready var combat_runtime: CombatRuntime = %CombatRuntime
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var played_cards_display: HBoxContainer = %PlayedCardsDisplay
@onready var game_over_panel: Control = %GameOverPanel
@onready var back_button: Button = %BackButton

var _cards: Array[Card] = []

func _ready() -> void:
	_display_played_cards()
	player.health.health_changed.connect(_on_player_health_changed)
	player.health.armor_changed.connect(_on_player_armor_changed)
	player.died.connect(_on_player_died)
	back_button.pressed.connect(_on_back_pressed)
	card_reader.slot_entered.connect(_on_slot_entered)
	game_over_panel.hide()
	_refresh_health_label()
	card_reader.set_sequence(CombatContext.card_sequence)
	card_reader.start()

func _display_played_cards() -> void:
	_cards.clear()
	for instance in CombatContext.card_sequence:
		var card := CARD_SCENE.instantiate() as Card
		played_cards_display.add_child(card)
		card.card_instance = instance
		card.locked = true
		_cards.append(card)

func _on_slot_entered(card_index: int, slot_index: int, _plays: bool) -> void:
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

func _on_player_died() -> void:
	enemy_spawner.stop()
	card_reader.stop()
	game_over_panel.show()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(CARD_MANAGEMENT_SCENE)
