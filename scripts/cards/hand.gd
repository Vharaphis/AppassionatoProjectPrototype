extends HBoxContainer
class_name Hand

signal card_selected(card: Card)
## A card was dragged here; `index` = where it should land among the children.
signal card_dropped(card: Card, index: int)
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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Card

func _drop_data(at_position: Vector2, data: Variant) -> void:
	card_dropped.emit(data, _index_at(at_position.x))

func _index_at(x: float) -> int:
	for child in get_children():
		var card := child as Control
		if x < card.position.x + card.size.x / 2.0:
			return card.get_index()
	return get_child_count()

## Moves a card already in this container so it lands before the card at `index`.
func move_card(card: Card, index: int) -> void:
	if index > card.get_index():
		index -= 1
	move_child(card, clampi(index, 0, get_child_count() - 1))
