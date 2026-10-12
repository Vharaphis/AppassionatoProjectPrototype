class_name CircleTargets
extends TargetSelector

## Enemies within `radius` of the player.

@export var radius: float = 3.0

func select(ctx: EffectContext) -> Array[Enemy]:
	var hits: Array[Enemy] = []
	if ctx.player == null:
		return hits
	var origin := ctx.player.global_position
	for enemy in ctx.get_enemies():
		var to_enemy := enemy.global_position - origin
		to_enemy.y = 0.0
		if to_enemy.length() <= radius:
			hits.append(enemy)
	return hits

func show_area(ctx: EffectContext) -> void:
	if ctx.player:
		AreaFlash.sector(ctx.player.get_parent(), ctx.player.global_position, Vector3.FORWARD, 360.0, radius, FLASH_COLOR)
