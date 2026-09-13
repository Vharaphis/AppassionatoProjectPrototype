class_name EffectContext
extends RefCounted

## Everything an effect may need to do its job. Built once by the CombatRuntime
## and refreshed before each card is played, so effects stay pure data.

var player: Player
var enemies_root: Node3D
var level: Level
var reader: CardReader

## Card currently being played and its position on the track.
var source: CardInstance
var card_index: int = -1
## Card played just before this one (for future "Combo" keywords).
var previous_card: CardInstance
## Multiplier applied to the numbers of the effects (for future "Ampli" cards).
var effect_multiplier: float = 1.0

func get_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if enemies_root == null:
		return enemies
	for child in enemies_root.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			enemies.append(child)
	return enemies

func scale_amount(amount: int) -> int:
	return int(round(amount * effect_multiplier))
