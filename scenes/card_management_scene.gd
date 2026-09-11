extends Control
class_name CardManagementScene

const FIGHTING_ENEMIES_SCENE := "res://scenes/fightingEnemiesScene.tscn"

@export var starting_hand_size: int = 5

@onready var deck: Deck = %Deck
@onready var hand: Hand = %Hand
@onready var playing_area: PlayingArea = %PlayingArea
@onready var play_button: Button = %PlayButton

func _ready() -> void:
	hand.card_selected.connect(_on_hand_card_selected)
	playing_area.card_selected.connect(_on_playing_area_card_selected)
	playing_area.composition_changed.connect(_on_composition_changed)
	play_button.pressed.connect(_on_play_pressed)
	play_button.disabled = true
	draw_to_hand(starting_hand_size)

func draw_to_hand(amount: int) -> void:
	for i in amount:
		var card_data := deck.draw_card()
		if card_data == null:
			break
		hand.draw_card(card_data)

func _on_hand_card_selected(card: Card) -> void:
	hand.remove_card(card)
	playing_area.add_card(card)

func _on_playing_area_card_selected(card: Card) -> void:
	playing_area.remove_card(card)
	hand.add_card(card)

func _on_composition_changed(sequence: Array[CardData]) -> void:
	play_button.disabled = sequence.is_empty()

func _on_play_pressed() -> void:
	hand.set_locked(true)
	playing_area.set_locked(true)
	CombatContext.card_sequence = playing_area.get_sequence()
	get_tree().change_scene_to_file(FIGHTING_ENEMIES_SCENE)
