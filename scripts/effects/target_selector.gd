@abstract
class_name TargetSelector
extends Resource

## Picks the enemies an effect applies to. Kept separate from the effects so any
## effect can be combined with any targeting rule.

@abstract func select(ctx: EffectContext) -> Array[Enemy]
