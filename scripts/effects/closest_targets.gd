class_name ClosestTargets
extends TargetSelector

## The `count` enemies closest to the player.

@export var count: int = 1
## Maximum distance from the player. 0 = no limit.
@export var max_range: float = 0.0

func select(ctx: EffectContext) -> Array[Enemy]:
	if ctx.player == null:
		return [] as Array[Enemy]
	var origin := ctx.player.global_position
	var enemies := ctx.get_enemies()
	if max_range > 0.0:
		var limit := max_range * max_range
		enemies = enemies.filter(func(enemy: Enemy) -> bool:
			return enemy.global_position.distance_squared_to(origin) <= limit)
	enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	if count <= 0 or count >= enemies.size():
		return enemies
	return enemies.slice(0, count)
