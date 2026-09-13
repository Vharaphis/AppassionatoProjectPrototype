class_name ArmorEffect
extends CardEffect

## Grants armor points to the player. Armor absorbs damage before health.

@export var amount: int = 0

func execute(ctx: EffectContext) -> void:
	if ctx.player == null or amount <= 0:
		return
	ctx.player.health.add_armor(ctx.scale_amount(amount))
