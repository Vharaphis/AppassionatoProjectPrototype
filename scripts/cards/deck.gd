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

## Draws a card and wraps it in a runtime instance, so the run never writes
## into the shared CardData resources.
func draw_card() -> CardInstance:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			deck_emptied.emit()
			return null
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		shuffle()
	return CardInstance.new(draw_pile.pop_back())

## Une carte gagnée en récompense entre dans la pioche, qui est remélangée : elle
## peut sortir dès la manche suivante au lieu d'attendre que la défausse revienne.
func add_card(data: CardData) -> void:
	if data == null:
		return
	draw_pile.append(data)
	shuffle()

func discard(instance: CardInstance) -> void:
	if instance == null or instance.data == null:
		return
	discard_pile.append(instance.data)

func cards_remaining() -> int:
	return draw_pile.size()

## Cartes du deck qui ne sont ni en main ni sur la piste.
func total_cards() -> int:
	return draw_pile.size() + discard_pile.size()
