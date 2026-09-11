extends Control
class_name FightingEnemiesScene

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

@onready var played_cards_display: HBoxContainer = %PlayedCardsDisplay

func _ready() -> void:
	for card_data in CombatContext.card_sequence:
		var card := CARD_SCENE.instantiate() as Card
		played_cards_display.add_child(card)
		card.card_data = card_data
		card.locked = true
