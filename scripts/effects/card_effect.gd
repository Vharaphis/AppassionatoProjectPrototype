@abstract
class_name CardEffect
extends Resource

## Base class of every card effect. Effects are Resources so a card is authored
## in the inspector instead of being coded by hand.

@abstract func execute(ctx: EffectContext) -> void

## Called on the cooldown slots before the card plays, to telegraph the action
## for `duration` seconds. Nothing by default.
func preview(_ctx: EffectContext, _duration: float) -> void:
	pass
