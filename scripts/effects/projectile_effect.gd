class_name ProjectileEffect
extends CardEffect

## Fires `count` homing projectiles, one per closest enemy. With fewer enemies
## than projectiles, the extra ones go to the same targets again.

@export var count: int = 1
@export var damage: int = 1
@export var speed: float = 14.0
## Times each projectile jumps to another enemy after a hit.
@export var bounces: int = 0
## Maximum distance of a bounce.
@export var bounce_range: float = 8.0

func execute(ctx: EffectContext) -> void:
	if ctx.player == null or count <= 0:
		return
	var enemies := ctx.get_enemies()
	if enemies.is_empty():
		return
	var origin := ctx.player.global_position
	enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	for i in count:
		var projectile := PlayerProjectile.new()
		projectile.target = enemies[i % enemies.size()]
		projectile.damage = ctx.scale_amount(damage)
		projectile.speed = speed
		projectile.bounces = bounces
		projectile.bounce_range = bounce_range
		ctx.player.get_parent().add_child(projectile)
		projectile.global_position = origin + Vector3.UP
