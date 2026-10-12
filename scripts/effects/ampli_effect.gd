class_name AmpliEffect
extends CardEffect

## Multiplies every number of the next Attaque or Préparation read. Flot cards
## neither use nor consume it, and two Amplis in a row do not stack.

@export var factor: float = 2.0

func execute(ctx: EffectContext) -> void:
	ctx.pending_multiplier = maxf(ctx.pending_multiplier, factor)
	if ctx.player:
		ctx.player.set_amplified(true)
