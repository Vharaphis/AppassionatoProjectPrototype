extends PanelContainer
class_name Card

signal clicked(card: Card)
signal right_clicked(card: Card)

## Une case de la jauge de temporalité : colorée = l'effet se joue, grise = temps mort.
const SLOT_SYMBOL := "■"
const COOLDOWN_COLOR := Color(0.4, 0.4, 0.42)
const TYPE_NAMES := ["Attaque", "Préparation", "Flot"]
const TYPE_COLORS := [Color(0.88, 0.35, 0.31), Color(0.31, 0.56, 0.88), Color(0.88, 0.75, 0.31)]
const TYPE_ICONS := [preload("res://assets/icons/sword.svg"), preload("res://assets/icons/shield.svg"), preload("res://assets/icons/star.svg")]
const RARITY_NAMES := ["commune", "peu commune", "rare", "mythique"]
## Couleur de bordure par rareté.
const RARITY_COLORS := [Color(0.6, 0.6, 0.6), Color(0.31, 0.75, 0.37), Color(0.31, 0.56, 0.88), Color(0.71, 0.37, 0.88)]
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
@onready var type_label: Label = %TypeLabel
@onready var temporality_badge: RichTextLabel = %TemporalityBadge
@onready var icon_rect: TextureRect = %Icon
@onready var description_label: RichTextLabel = %DescriptionLabel

var _style := StyleBoxFlat.new()

func _ready() -> void:
	_style.bg_color = Color(0.13, 0.13, 0.15)
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(6)
	_style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", _style)
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton:
		# Left click on release: a press that turns into a drag never releases here.
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_clicked.emit(self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if locked or card_instance == null:
		return null
	var preview := (load(scene_file_path) as PackedScene).instantiate() as Card
	preview.card_instance = card_instance
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	return self

## Drops on a card go to its container (hand or track), at the card's position.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var parent := get_parent() as Control
	return parent != null and parent.has_method("_can_drop_data") and parent._can_drop_data(at_position + position, data)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	(get_parent() as Control)._drop_data(at_position + position, data)

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
	type_label.text = "%s · %s" % [TYPE_NAMES[data.type], RARITY_NAMES[data.rarity]]
	var lines := PackedStringArray([data.description])
	_append_keyword_labels(data.effects, lines)
	description_label.text = "\n".join(lines)
	icon_rect.texture = data.icon if data.icon else TYPE_ICONS[data.type]
	_style.border_color = RARITY_COLORS[data.rarity]
	_refresh_temporality()

func _refresh_temporality() -> void:
	if temporality_badge == null:
		return
	var data := get_data()
	var play_color: Color = TYPE_COLORS[data.type] if data else Color.WHITE
	var temporality := card_instance.get_temporality() if card_instance else _data_temporality()
	var slots := PackedStringArray()
	for i in temporality.length():
		var color := play_color if temporality[i] == CardData.PLAY_CHAR else COOLDOWN_COLOR
		var slot := "[color=#%s]%s[/color]" % [color.to_html(false), SLOT_SYMBOL]
		# Case lue en ce moment : surlignée pour suivre la tête de lecture.
		slots.append("[bgcolor=#ffffff66]%s[/bgcolor]" % slot if i == active_slot else slot)
	temporality_badge.text = "[font_size=22]%s[/font_size]" % " ".join(slots)

func _data_temporality() -> String:
	var data := get_data()
	return data.temporality if data else ""

## Keyword lines of the card, including keywords nested in another effect
## (e.g. the Berserk played at the end of a dash).
func _append_keyword_labels(effects: Array[CardEffect], lines: PackedStringArray) -> void:
	for effect in effects:
		if effect is KeywordEffect:
			lines.append((effect as KeywordEffect).get_label())
		elif effect is DashEffect:
			_append_keyword_labels((effect as DashEffect).on_end, lines)
