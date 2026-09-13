extends HBoxContainer
class_name PlayingArea

signal card_selected(card: Card)
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
