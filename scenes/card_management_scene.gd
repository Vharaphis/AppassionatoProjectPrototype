extends Control
class_name CardManagementScene

const FIGHTING_ENEMIES_SCENE := "res://scenes/fightingEnemiesScene.tscn"

@export var starting_hand_size: int = 5

@onready var hand: Hand = %Hand
@onready var playing_area: PlayingArea = %PlayingArea
@onready var play_button: Button = %PlayButton
@onready var round_label: Label = %RoundLabel
@onready var deck_label: Label = %DeckLabel

## Deck de la run, pas de la scène : il vit dans l'autoload pour survivre aux
## changements de scène (sinon les cartes gagnées en récompense seraient perdues).
var deck: Deck

func _ready() -> void:
	deck = RunState.deck
	hand.card_selected.connect(_on_hand_card_selected)
	playing_area.card_selected.connect(_on_playing_area_card_selected)
	playing_area.composition_changed.connect(_on_composition_changed)
	play_button.pressed.connect(_on_play_pressed)
	play_button.disabled = true
	round_label.text = "Manche %d" % RunState.round_index
	draw_to_hand(starting_hand_size)
	_refresh_deck_label()

func draw_to_hand(amount: int) -> void:
	for i in amount:
		var instance := deck.draw_card()
		if instance == null:
			break
		hand.draw_card(instance)
	if hand.card_count() == 0:
		push_error("Pioche et défausse vides : des cartes ont quitté le deck sans y revenir.")

func _on_hand_card_selected(card: Card) -> void:
	hand.remove_card(card)
	playing_area.add_card(card)

func _on_playing_area_card_selected(card: Card) -> void:
	playing_area.remove_card(card)
	hand.add_card(card)

func _on_composition_changed(sequence: Array[CardInstance]) -> void:
	play_button.disabled = sequence.is_empty()

func _on_play_pressed() -> void:
	hand.set_locked(true)
	playing_area.set_locked(true)
	_discard_remaining_hand()
	RunState.card_sequence = playing_area.get_sequence()
	get_tree().change_scene_to_file(FIGHTING_ENEMIES_SCENE)

## Les cartes non jouées retournent à la défausse. Sans ça elles disparaissent avec
## la scène et le deck se vide manche après manche.
func _discard_remaining_hand() -> void:
	for child in hand.get_children():
		deck.discard((child as Card).card_instance)

func _refresh_deck_label() -> void:
	deck_label.text = "Pioche %d  ·  défausse %d" % [deck.draw_pile.size(), deck.discard_pile.size()]
