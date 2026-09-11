extends Node3D
class_name FightingEnemiesScene

const CARD_SCENE := preload("res://scenes/cards/card.tscn")
const CARD_MANAGEMENT_SCENE := "res://scenes/cardManagementScene.tscn"

@onready var player: Player = %Player
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var played_cards_display: HBoxContainer = %PlayedCardsDisplay
@onready var game_over_panel: Control = %GameOverPanel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_display_played_cards()
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	back_button.pressed.connect(_on_back_pressed)
	game_over_panel.hide()
	_on_player_health_changed(player.health.current_health, player.health.max_health)

func _display_played_cards() -> void:
	for card_data in CombatContext.card_sequence:
		var card := CARD_SCENE.instantiate() as Card
		played_cards_display.add_child(card)
		card.card_data = card_data
		card.locked = true

func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP %d / %d" % [current, maximum]

func _on_player_died() -> void:
	enemy_spawner.stop()
	game_over_panel.show()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(CARD_MANAGEMENT_SCENE)
