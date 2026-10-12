class_name BerserkCondition
extends KeywordCondition

## Berserk: the player is below `health_ratio` of their max HP.

@export var health_ratio: float = 0.2

func get_keyword_name() -> String:
	return "Berserk"

func is_met(ctx: EffectContext) -> bool:
	if ctx.player == null:
		return false
	var health := ctx.player.health
	return health.current_health < health.max_health * health_ratio
