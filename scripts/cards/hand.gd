extends HBoxContainer
class_name Hand

signal card_selected(card: Card)
signal card_discard_requested(card: Card)

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

func draw_card(instance: CardInstance) -> Card:
	var card := CARD_SCENE.instantiate() as Card
	card.card_instance = instance
	add_card(card)
	return card

func add_card(card: Card) -> void:
	add_child(card)
	card.clicked.connect(_on_card_clicked)
	card.right_clicked.connect(_on_card_right_clicked)

func remove_card(card: Card) -> void:
	card.clicked.disconnect(_on_card_clicked)
	card.right_clicked.disconnect(_on_card_right_clicked)
	remove_child(card)

func card_count() -> int:
	return get_child_count()

## The runtime cards of the hand, left to right.
func get_instances() -> Array[CardInstance]:
	var instances: Array[CardInstance] = []
	for child in get_children():
		instances.append((child as Card).card_instance)
	return instances

func _on_card_clicked(card: Card) -> void:
	card_selected.emit(card)

func _on_card_right_clicked(card: Card) -> void:
	card_discard_requested.emit(card)

func set_locked(value: bool) -> void:
	for child in get_children():
		(child as Card).locked = value
