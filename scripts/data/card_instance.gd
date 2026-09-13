class_name CardInstance
extends RefCounted

## Runtime copy of a card. The CardData resources are shared between every copy
## of a card (and saved on disk), so nothing that changes during a run may be
## written into them: it lives here instead.

var data: CardData
## Overrides the temporality of the card for this run (empty = use the CardData one).
var temporality_override: String = ""
## Overrides the effects of the card for this run (empty = use the CardData ones).
var effects_override: Array[CardEffect] = []
## Free slot for the runtime state of future keywords (Évolue, Métamorphe...).
var state: Dictionary = {}

func _init(card_data: CardData = null) -> void:
	data = card_data

func get_card_name() -> String:
	return data.card_name if data else ""

func get_cost() -> int:
	return data.cost if data else 0

func get_description() -> String:
	return data.description if data else ""

func get_temporality() -> String:
	if not temporality_override.is_empty():
		return temporality_override
	return data.temporality if data else CardData.PLAY_CHAR

func get_effects() -> Array[CardEffect]:
	if not effects_override.is_empty():
		return effects_override
	return data.effects if data else [] as Array[CardEffect]

func slot_count() -> int:
	return maxi(get_temporality().length(), 1)

func plays_at(slot_index: int) -> bool:
	var temporality := get_temporality()
	if temporality.is_empty():
		return true
	return temporality[slot_index % temporality.length()] == CardData.PLAY_CHAR
