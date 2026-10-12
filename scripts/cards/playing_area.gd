extends HBoxContainer
class_name PlayingArea

signal card_selected(card: Card)
## A card was dragged here; `index` = where it should land among the children.
signal card_dropped(card: Card, index: int)
signal composition_changed(sequence: Array[CardInstance])

func add_card(card: Card) -> void:
	add_child(card)
	card.clicked.connect(_on_card_clicked)
	_emit_composition_changed()

func remove_card(card: Card) -> void:
	card.clicked.disconnect(_on_card_clicked)
	remove_child(card)
	_emit_composition_changed()

## The cards of the track, left to right: exactly what the reader will play.
func get_sequence() -> Array[CardInstance]:
	var sequence: Array[CardInstance] = []
	for child in get_children():
		var instance := (child as Card).card_instance
		if instance:
			sequence.append(instance)
	return sequence

func _on_card_clicked(card: Card) -> void:
	card_selected.emit(card)

func set_locked(value: bool) -> void:
	for child in get_children():
		(child as Card).locked = value

func _emit_composition_changed() -> void:
	composition_changed.emit(get_sequence())

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
	_emit_composition_changed()
