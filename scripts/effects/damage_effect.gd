class_name DamageEffect
extends CardEffect

## Deals `amount` damage to every enemy returned by `targets`.

@export var amount: int = 0
@export var targets: TargetSelector

func execute(ctx: EffectContext) -> void:
	if targets == null:
		push_warning("DamageEffect without a TargetSelector, nothing to hit.")
		return
	if amount <= 0:
		push_warning("DamageEffect with an amount of 0, it will do nothing.")
		return
	var damage := ctx.scale_amount(amount)
	for enemy in targets.select(ctx):
		enemy.take_damage(damage)
