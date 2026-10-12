class_name ConeTargets
extends TargetSelector

## Enemies in a cone in front of the player, aimed where it looks (the mouse).

@export var angle: float = 90.0
@export var max_range: float = 4.0

func select(ctx: EffectContext) -> Array[Enemy]:
	var hits: Array[Enemy] = []
	if ctx.player == null:
		return hits
	var origin := ctx.player.global_position
	var min_dot := cos(deg_to_rad(angle) / 2.0)
	for enemy in ctx.get_enemies():
		var to_enemy := enemy.global_position - origin
		to_enemy.y = 0.0
		if to_enemy.length() > max_range:
			continue
		# Touching the player counts as in front, whatever the angle.
		if to_enemy.length_squared() < 0.25 or ctx.player.facing.dot(to_enemy.normalized()) >= min_dot:
			hits.append(enemy)
	return hits

func show_area(ctx: EffectContext) -> void:
	if ctx.player:
		AreaFlash.sector(ctx.player.get_parent(), ctx.player.global_position, ctx.player.facing, angle, max_range, FLASH_COLOR)
