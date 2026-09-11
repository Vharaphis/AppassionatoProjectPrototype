extends Node
class_name Deck

signal deck_emptied

@export var starting_cards: Array[CardData] = []

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

func _ready() -> void:
	reset()

func reset() -> void:
	draw_pile = starting_cards.duplicate()
	discard_pile.clear()
	shuffle()

func shuffle() -> void:
	draw_pile.shuffle()

func draw_card() -> CardData:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			deck_emptied.emit()
			return null
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		shuffle()
	return draw_pile.pop_back()

func discard(card_data: CardData) -> void:
	discard_pile.append(card_data)

func cards_remaining() -> int:
	return draw_pile.size()
