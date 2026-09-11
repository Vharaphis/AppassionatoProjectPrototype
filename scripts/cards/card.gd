extends PanelContainer
class_name Card

signal clicked(card: Card)

var locked: bool = false

@export var card_data: CardData:
	set(value):
		card_data = value
		if is_node_ready():
			_refresh()

@onready var name_label: Label = %NameLabel
@onready var cost_badge: Label = %CostBadge
@onready var temporality_badge: Label = %TemporalityBadge
@onready var icon_rect: TextureRect = %Icon
@onready var description_label: RichTextLabel = %DescriptionLabel

func _ready() -> void:
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

func set_locked(value: bool) -> void:
	for child in get_children():
		(child as Card).locked = value

func _refresh() -> void:
	if card_data == null:
		return
	name_label.text = card_data.card_name
	cost_badge.text = str(card_data.cost)
	temporality_badge.text = "%.1fs" % card_data.temporality
	description_label.text = card_data.description
	if card_data.icon:
		icon_rect.texture = card_data.icon
