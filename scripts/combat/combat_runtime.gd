class_name CombatRuntime
extends Node

## Executes the effects of the cards the reader plays, and owns the shared
## context handed to them.

@export var player: Player
@export var enemies_root: Node3D
@export var level: Level
@export var reader: CardReader

var context: EffectContext

var _previous_card: CardInstance

func _ready() -> void:
	context = EffectContext.new()
	context.player = player
	context.enemies_root = enemies_root
	context.level = level
	context.reader = reader
	if reader:
		reader.card_played.connect(_on_card_played)

func play_card(instance: CardInstance, card_index: int = -1) -> void:
	if instance == null:
		return
	context.source = instance
	context.card_index = card_index
	context.previous_card = _previous_card
	context.effect_multiplier = 1.0
	for effect in instance.get_effects():
		if effect:
			effect.execute(context)
	_previous_card = instance

func _on_card_played(instance: CardInstance, card_index: int) -> void:
	play_card(instance, card_index)
