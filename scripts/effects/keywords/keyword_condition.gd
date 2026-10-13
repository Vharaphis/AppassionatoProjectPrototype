@abstract
class_name KeywordCondition
extends Resource

## Condition of a keyword (Berserk, Solo...), checked each time the card is read.

@abstract func get_keyword_name() -> String
@abstract func is_met(ctx: EffectContext) -> bool
