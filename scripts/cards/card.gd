extends PanelContainer

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

func _refresh() -> void:
	if card_data == null:
		return
	name_label.text = card_data.card_name
	cost_badge.text = str(card_data.cost)
	temporality_badge.text = "%.1fs" % card_data.temporality
	description_label.text = card_data.description
	if card_data.icon:
		icon_rect.texture = card_data.icon
