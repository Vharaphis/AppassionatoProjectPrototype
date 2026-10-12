class_name SurLeFilEffect
extends CardEffect

## Until the reader leaves the slot that played it, the player's health cannot
## drop below `health_ratio` of max (and, with `damage_to_armor`, damage becomes
## armor). Each `o` slot plays it again, so the window covers all the `o` slots.

@export var health_ratio: float = 0.19
@export var damage_to_armor: bool = false

func execute(ctx: EffectContext) -> void:
	if ctx.player == null:
		return
	var health := ctx.player.health
	health.health_floor = ceili(health.max_health * health_ratio)
	health.damage_to_armor = damage_to_armor
	if ctx.reader == null:
		return
	# Cleared when the slot ends (also before a reload). A following `o` of this card
	# plays it again right after, so consecutive `o` slots chain the window.
	await ctx.reader.slot_exited
	if is_instance_valid(health):
		health.health_floor = 0
		health.damage_to_armor = false
