class_name SlowEffect
extends CardEffect

## Slows the enemies returned by `targets`. The duration is scaled by Ampli.

@export var targets: TargetSelector
## Speed multiplier while slowed (0.5 = half speed).
@export var factor: float = 0.5
@export var duration: float = 2.0

func execute(ctx: EffectContext) -> void:
	if targets == null:
		push_warning("SlowEffect without a TargetSelector, nothing to slow.")
		return
	for enemy in targets.select(ctx):
		enemy.apply_slow(factor, duration * ctx.effect_multiplier)
