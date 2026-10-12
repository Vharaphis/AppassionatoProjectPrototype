@abstract
class_name TargetSelector
extends Resource

## Picks the enemies an effect applies to. Kept separate from the effects so any
## effect can be combined with any targeting rule.

const FLASH_COLOR := Color(1.0, 0.45, 0.3, 0.45)

@abstract func select(ctx: EffectContext) -> Array[Enemy]

## Draws the targeted area on the floor. Nothing by default (e.g. closest enemies).
func show_area(_ctx: EffectContext) -> void:
	pass
