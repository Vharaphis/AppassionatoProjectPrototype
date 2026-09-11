extends HBoxContainer
class_name Hand

signal card_selected(card: Card)

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

func draw_card(card_data: CardData) -> Card:
	var card := CARD_SCENE.instantiate() as Card
	card.card_data = card_data
	add_card(card)
	return card

func add_card(card: Card) -> void:
	add_child(card)
	card.clicked.connect(_on_card_clicked)

func remove_card(card: Card) -> void:
	card.clicked.disconnect(_on_card_clicked)
	remove_child(card)

func card_count() -> int:
	return get_child_count()

func _on_card_clicked(card: Card) -> void:
	card_selected.emit(card)

func set_locked(value: bool) -> void:
	for child in get_children():
		(child as Card).locked = value
