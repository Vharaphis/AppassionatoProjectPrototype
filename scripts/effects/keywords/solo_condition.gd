class_name SoloCondition
extends KeywordCondition

## Solo: the card is the only one of its type (Attaque / Préparation / Flot) on the track.

func get_keyword_name() -> String:
	return "Solo"

func is_met(ctx: EffectContext) -> bool:
	if ctx.source == null or ctx.source.data == null or ctx.reader == null:
		return false
	var type := ctx.source.data.type
	var same_type := 0
	for instance in ctx.reader.sequence:
		if instance.data and instance.data.type == type:
			same_type += 1
	return same_type == 1
