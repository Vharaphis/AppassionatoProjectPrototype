class_name CardData
extends Resource

@export var card_name: String = ""
@export var cost: int = 0
@export var temporality: float = 1.0
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var effects: String = ""
	#list<CardEffect>
