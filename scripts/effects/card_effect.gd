@abstract
class_name CardEffect
extends Resource

## Base class of every card effect. Effects are Resources so a card is authored
## in the inspector instead of being coded by hand.

@abstract func execute(ctx: EffectContext) -> void
