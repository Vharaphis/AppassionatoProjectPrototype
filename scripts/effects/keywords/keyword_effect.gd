class_name KeywordEffect
extends CardEffect

## Plays `effects` when the keyword condition holds at read time, `otherwise`
## when it does not (leave `otherwise` empty for a pure bonus).

@export var condition: KeywordCondition
## Shown on the card after the keyword name.
@export_multiline var text: String = ""
@export var effects: Array[CardEffect] = []
@export var otherwise: Array[CardEffect] = []

func execute(ctx: EffectContext) -> void:
	var met := condition != null and condition.is_met(ctx)
	for effect in effects if met else otherwise:
		if effect:
			effect.execute(ctx)

func get_label() -> String:
	return "[b]%s[/b] : %s" % [condition.get_keyword_name() if condition else "?", text]
