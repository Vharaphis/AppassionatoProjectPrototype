extends SceneTree

## Runs the fight scene headless at a given round and reports what spawned.
##   godot --headless --script res://tests/smoke_fight.gd -- <round> <game seconds>
## Script errors show up in the output; the player is made unkillable.
## For behaviours with a `state` variable, also reports the states reached.

const FIGHT_SCENE := "res://scenes/fightingEnemiesScene.tscn"
## Wall-clock safety so a broken scene never hangs the run.
const MAX_REAL_MSEC := 90000

var _round := 8
var _duration := 30.0
var _elapsed := 0.0
var _seen := {}
var _states := {}
var _player_damage := 0
var _started := false
var _fight: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_round = int(args[0])
	if args.size() > 1:
		_duration = float(args[1])
	Engine.time_scale = 4.0

func _process(delta: float) -> bool:
	if Time.get_ticks_msec() > MAX_REAL_MSEC:
		print("TIMEOUT")
		return true
	if not _started:
		# Autoloads are only ready once the loop runs.
		_started = true
		var run_state := root.get_node("RunState")
		run_state.round_index = _round
		for i in 3:
			var instance = run_state.deck.draw_card()
			if instance:
				run_state.card_sequence.append(instance)
		change_scene_to_file(FIGHT_SCENE)
		return false
	if _fight == null:
		_fight = current_scene
		if _fight == null:
			return false
		var player = _fight.get_node("%Player")
		player.health.max_health = 1000000
		player.health.set_current_health(1000000)
		_fight.get_node("%EnemySpawner").enemy_spawned.connect(_on_spawned)
		player.health.damaged.connect(func(amount: int) -> void: _player_damage += amount)
	for enemy in get_nodes_in_group("enemies"):
		if enemy.data and enemy.behavior and "state" in enemy.behavior:
			var states: Dictionary = _states.get_or_add(enemy.data.id, {})
			states[enemy.behavior.State.find_key(enemy.behavior.state)] = true
	_elapsed += delta
	if _elapsed < _duration:
		return false
	var alive := {}
	for enemy in get_nodes_in_group("enemies"):
		var id: StringName = enemy.data.id if enemy.data else &"?"
		alive[id] = alive.get(id, 0) + 1
	print("round %d  spawned %s  live projectiles %d" % [_round, _seen, get_nodes_in_group(&"enemy_projectiles").size()])
	print("alive %s  kills %d  player damage %d  nodes %d" % [alive, _fight.get_node("%CombatObjective").kills, _player_damage, get_node_count()])
	for id in _states:
		print("states %s: %s" % [id, _states[id].keys()])
	return true

func _on_spawned(enemy: Enemy) -> void:
	_seen[enemy.data.id] = _seen.get(enemy.data.id, 0) + 1
