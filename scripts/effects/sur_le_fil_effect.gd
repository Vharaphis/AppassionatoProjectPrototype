class_name SurLeFilEffect
extends CardEffect

## While the reader stays on the slot that played it, the player's health cannot
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
	# Next slot_entered comes before the next card_played: a following `o` of this
	# card sets the window again right after it is cleared here.
	await ctx.reader.slot_entered
	if is_instance_valid(health):
		health.health_floor = 0
		health.damage_to_armor = false
