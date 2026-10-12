extends SceneTree

## Self-check of the preparation economy: mana, persistent hand, redraw, reward.
##   godot --headless --script res://tests/test_card_flow.gd
## Prints "OK" and exits 0, or stops on the first failed assert.

const PREP_SCENE := "res://scenes/cardManagementScene.tscn"

var _step := 0
var _rs: Node
var _deck_size := 0

func _process(_delta: float) -> bool:
	match _step:
		0:
			# Autoloads are only ready once the loop runs.
			_rs = root.get_node("RunState")
			_rs.reset_run()
			_deck_size = _rs.deck.total_cards()
			_rs.mana_per_round = 2
			change_scene_to_file(PREP_SCENE)
		1:
			var prep = current_scene
			assert(prep.hand.card_count() == 3)
			assert(_count_in(prep) == _deck_size)
			# Mana 2, three 1-cost cards: the third one is refused.
			for card in prep.hand.get_children():
				prep._on_hand_card_selected(card)
			assert(prep.playing_area.get_child_count() == 2)
			assert(prep.mana_left() == 0)
			# Redraw: 3 per round, then refused.
			var last = prep.hand.get_child(0)
			for i in 4:
				prep._on_hand_card_discard_requested(prep.hand.get_child(0))
			assert(prep.redraws_left == 0)
			assert(prep.hand.card_count() == 1)
			assert(prep.hand.get_child(0) != last)
			assert(_count_in(prep) == _deck_size)
			prep._on_play_pressed()
			assert(_rs.hand.size() == 1 and _rs.card_sequence.size() == 2)
			_rs.finish_round(100, 0)
			assert(_count_out() == _deck_size)
			# Reward goes to the discard pile.
			var discard_before: int = _rs.deck.discard_pile.size()
			_rs.add_card_to_deck(_rs.deck.discard_pile[0])
			_deck_size += 1
			assert(_rs.deck.discard_pile.size() == discard_before + 1)
			_rs.max_hand_size = 2
			change_scene_to_file(PREP_SCENE)
		2:
			var prep = current_scene
			# 1 kept card + draw capped by the hand size.
			assert(prep.hand.card_count() == 2)
			assert(prep.redraws_left == 3)
			assert(_count_in(prep) == _deck_size)
			print("OK")
			quit(0)
	_step += 1
	return false

func _count_out() -> int:
	return _rs.deck.total_cards() + _rs.hand.size() + _rs.card_sequence.size()

func _count_in(prep) -> int:
	return _rs.deck.total_cards() + prep.hand.card_count() + prep.playing_area.get_child_count()
