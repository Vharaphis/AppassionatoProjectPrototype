extends PanelContainer
class_name Card

signal clicked(card: Card)

const PLAY_SYMBOL := "●"
const COOLDOWN_SYMBOL := "○"
const DIM_MODULATE := Color(0.65, 0.65, 0.7)
## Teinte de la carte retenue dans l'écran de récompense.
const SELECTED_MODULATE := Color(1.15, 1.15, 0.85)

var locked: bool = false
## Mise en avant par l'écran de récompense. Sans rapport avec `active_slot`, qui
## est le surlignage du lecteur : les deux ne coexistent jamais dans une scène.
var is_selected: bool = false

## Runtime card shown by this node. When null, `card_data` is displayed instead
## (handy to preview a card directly in the editor).
var card_instance: CardInstance:
	set(value):
		card_instance = value
		if is_node_ready():
			_refresh()

## Slot highlighted by the reader, -1 when the reader is not on this card.
var active_slot: int = -1

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

func get_data() -> CardData:
	return card_instance.data if card_instance else card_data

## Called by the combat scene when the reader enters a slot of this card.
func set_active_slot(slot_index: int) -> void:
	active_slot = slot_index
	modulate = Color.WHITE
	_refresh_temporality()

## Called when the reader is somewhere else on the track.
func clear_active_slot() -> void:
	active_slot = -1
	modulate = DIM_MODULATE
	_refresh_temporality()

## Appelé par l'écran de récompense quand cette carte est celle qu'on garde.
func set_selected(value: bool) -> void:
	is_selected = value
	modulate = SELECTED_MODULATE if value else Color.WHITE

func _refresh() -> void:
	var data := get_data()
	if data == null:
		return
	name_label.text = data.card_name
	cost_badge.text = str(data.cost)
	description_label.text = data.description
	if data.icon:
		icon_rect.texture = data.icon
	_refresh_temporality()

func _refresh_temporality() -> void:
	if temporality_badge == null:
		return
	var temporality := card_instance.get_temporality() if card_instance else _data_temporality()
	var slots := PackedStringArray()
	for i in temporality.length():
		var symbol := PLAY_SYMBOL if temporality[i] == CardData.PLAY_CHAR else COOLDOWN_SYMBOL
		slots.append("[%s]" % symbol if i == active_slot else symbol)
	temporality_badge.text = " ".join(slots)

func _data_temporality() -> String:
	var data := get_data()
	return data.temporality if data else ""
