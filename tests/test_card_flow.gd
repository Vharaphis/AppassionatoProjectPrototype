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
			# Drag & drop: onto the track at an index, reorder, back to the hand.
			var a = prep.hand.get_child(0)
			var b = prep.hand.get_child(1)
			prep._on_track_card_dropped(a, 0)
			prep._on_track_card_dropped(b, 0)
			assert(prep.playing_area.get_children() == [b, a])
			prep._on_track_card_dropped(b, 2)
			assert(prep.playing_area.get_children() == [a, b])
			prep._on_hand_card_dropped(a, 0)
			assert(prep.hand.get_children() == [a] and prep.mana_left() == 1)
			assert(_count_in(prep) == _deck_size)
			# Rewards: distinct partitions, higher rarities more likely later.
			for i in 50:
				var offer: Array = _rs.roll_reward()
				assert(offer.size() == 3)
				assert(offer[0] != offer[1] and offer[1] != offer[2] and offer[0] != offer[2])
			assert(_rs.rarity_weight(3, 1) < _rs.rarity_weight(3, 8))
			assert(_rs.rarity_weight(0, 1) > _rs.rarity_weight(0, 8))
			_rs.reward_pool = _rs.reward_pool.slice(0, 2)
			assert(_rs.roll_reward().size() == 3)
			print("OK")
			quit(0)
	_step += 1
	return false

func _count_out() -> int:
	return _rs.deck.total_cards() + _rs.hand.size() + _rs.card_sequence.size()

func _count_in(prep) -> int:
	return _rs.deck.total_cards() + prep.hand.card_count() + prep.playing_area.get_child_count()
