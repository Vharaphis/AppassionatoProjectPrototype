extends Control
class_name CardManagementScene

const FIGHTING_ENEMIES_SCENE := "res://scenes/fightingEnemiesScene.tscn"
## Teinte des cartes de la main trop chères pour le mana restant.
const UNAFFORDABLE_MODULATE := Color(0.5, 0.5, 0.55)

@onready var hand: Hand = %Hand
@onready var playing_area: PlayingArea = %PlayingArea
@onready var play_button: Button = %PlayButton
@onready var round_label: Label = %RoundLabel
@onready var deck_label: Label = %DeckLabel
@onready var mana_label: Label = %ManaLabel
@onready var redraw_label: Label = %RedrawLabel

## Deck de la run, pas de la scène : il vit dans l'autoload pour survivre aux
## changements de scène (sinon les cartes gagnées en récompense seraient perdues).
var deck: Deck
var redraws_left: int = 0

func _ready() -> void:
	deck = RunState.deck
	hand.card_selected.connect(_on_hand_card_selected)
	hand.card_discard_requested.connect(_on_hand_card_discard_requested)
	playing_area.card_selected.connect(_on_playing_area_card_selected)
	playing_area.composition_changed.connect(_on_composition_changed)
	playing_area.card_dropped.connect(_on_track_card_dropped)
	hand.card_dropped.connect(_on_hand_card_dropped)
	play_button.pressed.connect(_on_play_pressed)
	play_button.disabled = true
	round_label.text = "Manche %d" % RunState.round_index
	redraws_left = RunState.redraws_per_round
	# La main de la manche précédente revient avant la pioche du tour.
	for instance in RunState.hand:
		hand.draw_card(instance)
	RunState.hand.clear()
	draw_to_hand(mini(RunState.draw_per_round, RunState.max_hand_size - hand.card_count()))
	_refresh_labels()

func draw_to_hand(amount: int) -> void:
	for i in amount:
		var instance := deck.draw_card()
		if instance == null:
			break
		hand.draw_card(instance)
	if hand.card_count() == 0:
		push_error("Pioche et défausse vides : des cartes ont quitté le deck sans y revenir.")

## Mana pas encore engagé sur la piste.
func mana_left() -> int:
	var spent := 0
	for instance in playing_area.get_sequence():
		spent += instance.get_cost()
	return RunState.mana_per_round - spent

func _on_hand_card_selected(card: Card) -> void:
	if card.card_instance.get_cost() > mana_left():
		return
	hand.remove_card(card)
	playing_area.add_card(card)

func _on_playing_area_card_selected(card: Card) -> void:
	playing_area.remove_card(card)
	hand.add_card(card)
	_refresh_labels()

## Glisser sur la piste : pose depuis la main (si le mana suffit) ou réordonne.
func _on_track_card_dropped(card: Card, index: int) -> void:
	if card.get_parent() == playing_area:
		playing_area.move_card(card, index)
		return
	if card.get_parent() != hand or card.card_instance.get_cost() > mana_left():
		return
	hand.remove_card(card)
	playing_area.add_card(card)
	playing_area.move_card(card, index)

## Glisser sur la main : retire de la piste ou réordonne la main.
func _on_hand_card_dropped(card: Card, index: int) -> void:
	if card.get_parent() == playing_area:
		playing_area.remove_card(card)
		hand.add_card(card)
		_refresh_labels()
	if card.get_parent() == hand:
		hand.move_card(card, index)

## Pioche d'abord, défausse ensuite : sinon la carte défaussée peut ressortir
## aussitôt quand la pioche vide remélange la défausse.
func _on_hand_card_discard_requested(card: Card) -> void:
	if redraws_left <= 0:
		return
	var replacement := deck.draw_card()
	if replacement == null:
		return
	redraws_left -= 1
	hand.remove_card(card)
	deck.discard(card.card_instance)
	card.queue_free()
	hand.draw_card(replacement)
	_refresh_labels()

func _on_composition_changed(sequence: Array[CardInstance]) -> void:
	play_button.disabled = sequence.is_empty()
	_refresh_labels()

## Les cartes non jouées restent en main pour la manche suivante.
func _on_play_pressed() -> void:
	hand.set_locked(true)
	playing_area.set_locked(true)
	RunState.hand = hand.get_instances()
	RunState.card_sequence = playing_area.get_sequence()
	get_tree().change_scene_to_file(FIGHTING_ENEMIES_SCENE)

func _refresh_labels() -> void:
	var mana := mana_left()
	mana_label.text = "Mana %d / %d" % [mana, RunState.mana_per_round]
	redraw_label.text = "Glisser ou cliquer pour jouer · clic droit : défausser et repiocher (%d)" % redraws_left
	deck_label.text = "Pioche %d  ·  défausse %d" % [deck.draw_pile.size(), deck.discard_pile.size()]
	for child in hand.get_children():
		var card := child as Card
		card.modulate = UNAFFORDABLE_MODULATE if card.card_instance.get_cost() > mana else Color.WHITE
