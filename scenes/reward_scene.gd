extends Control
class_name RewardScene

## Écran de récompense : trois cartes tirées du pool de la run, le joueur en garde
## une, elle entre dans son deck et on repart en préparation.

const CARD_SCENE := preload("res://scenes/cards/card.tscn")
const CARD_MANAGEMENT_SCENE := "res://scenes/cardManagementScene.tscn"

@onready var title_label: Label = %TitleLabel
@onready var choices: HBoxContainer = %Choices
@onready var confirm_button: Button = %ConfirmButton

var _cards: Array[Card] = []
var _selected: CardData

func _ready() -> void:
	# finish_round() a déjà incrémenté la manche, la manche gagnée est la précédente.
	title_label.text = "Manche %d réussie — choisis une carte" % (RunState.round_index - 1)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm_pressed)
	_build_choices()

func _build_choices() -> void:
	for data in RunState.roll_reward():
		var card := CARD_SCENE.instantiate() as Card
		choices.add_child(card)
		card.card_data = data
		card.set_selected(false)
		card.clicked.connect(_on_card_clicked)
		_cards.append(card)
	if _cards.is_empty():
		# Pool vide : on ne bloque pas la boucle pour autant.
		confirm_button.text = "Continuer"
		confirm_button.disabled = false

func _on_card_clicked(card: Card) -> void:
	_selected = card.get_data()
	for other in _cards:
		other.set_selected(other == card)
	confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	RunState.add_card_to_deck(_selected)
	get_tree().change_scene_to_file(CARD_MANAGEMENT_SCENE)
