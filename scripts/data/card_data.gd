class_name CardData
extends Resource

## Character used in `temporality` for a slot where the effects are played.
const PLAY_CHAR := "o"
## Character used in `temporality` for a slot where the card is on cooldown.
const COOLDOWN_CHAR := "x"

@export var card_name: String = ""
@export var cost: int = 0
## Reading pattern, one character per slot of the reader:
## 'o' = the effects are played, 'x' = cooldown (the reader passes, nothing happens).
## Cooldown slots are usually written before the 'o' so the player sees the action coming.
@export var temporality: String = PLAY_CHAR:
	set(value):
		temporality = value.strip_edges().to_lower()
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var effects: Array[CardEffect] = []

func slot_count() -> int:
	return maxi(temporality.length(), 1)

func plays_at(slot_index: int) -> bool:
	if temporality.is_empty():
		return true
	return temporality[slot_index % temporality.length()] == PLAY_CHAR

## Returns an empty string when the card is valid, the reason otherwise.
func get_validation_error() -> String:
	if temporality.is_empty():
		return "temporality is empty"
	for character in temporality:
		if character != PLAY_CHAR and character != COOLDOWN_CHAR:
			return "temporality contains '%s', only '%s' and '%s' are allowed" % [character, PLAY_CHAR, COOLDOWN_CHAR]
	if not temporality.contains(PLAY_CHAR):
		return "temporality has no '%s', the card would never be played" % PLAY_CHAR
	return ""
