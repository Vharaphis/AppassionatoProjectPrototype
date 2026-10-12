class_name CombatRuntime
extends Node

## Executes the effects of the cards the reader plays, and owns the shared
## context handed to them.

@export var player: Player
@export var enemies_root: Node3D
@export var level: Level
@export var reader: CardReader

var context: EffectContext

func _ready() -> void:
	context = EffectContext.new()
	context.player = player
	context.enemies_root = enemies_root
	context.level = level
	context.reader = reader
	if reader:
		reader.card_played.connect(_on_card_played)
		reader.slot_entered.connect(_on_slot_entered)

func play_card(instance: CardInstance, card_index: int = -1) -> void:
	if instance == null:
		return
	context.source = instance
	context.card_index = card_index
	context.effect_multiplier = 1.0
	for effect in instance.get_effects():
		if effect:
			effect.execute(context)

func _on_card_played(instance: CardInstance, card_index: int) -> void:
	play_card(instance, card_index)

## Cooldown slot: the card telegraphs its next play (e.g. the dash arrow).
func _on_slot_entered(card_index: int, _slot_index: int, plays: bool) -> void:
	if plays or card_index < 0 or card_index >= reader.sequence.size():
		return
	var instance := reader.sequence[card_index]
	for effect in instance.get_effects():
		if effect:
			effect.preview(context, reader.get_slot_duration())
