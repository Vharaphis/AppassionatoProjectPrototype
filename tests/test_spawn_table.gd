extends SceneTree

## Self-check of the spawn weights. Run from the project folder:
##   godot --headless --script res://tests/test_spawn_table.gd
## Prints "OK" and exits 0, or stops on the first failed assert.

const EnemyDataScript := preload("res://scripts/data/enemy_data.gd")
const SpawnEntryScript := preload("res://scripts/data/spawn_entry.gd")
const SpawnTableScript := preload("res://scripts/data/spawn_table.gd")

func _init() -> void:
	var tracker := _entry(&"tracker", 1, 100.0, -10.0, 20.0, 100.0, 0)
	var shielder := _entry(&"shielder", 5, 10.0, 5.0, 0.0, 20.0, 3)

	# Weight formula, floor and cap.
	assert(tracker.weight_at(1) == 100.0)
	assert(tracker.weight_at(3) == 80.0)
	assert(tracker.weight_at(20) == 20.0)
	assert(shielder.weight_at(4) == 0.0)
	assert(shielder.weight_at(5) == 10.0)
	assert(shielder.weight_at(6) == 15.0)
	assert(shielder.weight_at(9) == 20.0)

	var table = SpawnTableScript.new()
	table.entries.append(tracker)
	table.entries.append(shielder)

	# Below min_round: never picked.
	for i in 200:
		assert(table.pick(4, {}).id == &"tracker")
	# At max_alive: excluded.
	for i in 200:
		assert(table.pick(9, {&"shielder": 3}).id == &"tracker")
	# Both allowed: both show up.
	var seen := {}
	for i in 500:
		seen[table.pick(9, {&"shielder": 2}).id] = true
	assert(seen.has(&"tracker") and seen.has(&"shielder"))
	# Nothing allowed: null.
	tracker.max_alive = 1
	assert(table.pick(4, {&"tracker": 1}) == null)

	print("OK")
	quit(0)

func _entry(id: StringName, min_round: int, base: float, per_round: float, floor_weight: float, cap: float, max_alive: int) -> Resource:
	var data = EnemyDataScript.new()
	data.id = id
	var entry = SpawnEntryScript.new()
	entry.enemy = data
	entry.min_round = min_round
	entry.base_weight = base
	entry.weight_per_round = per_round
	entry.min_weight = floor_weight
	entry.max_weight = cap
	entry.max_alive = max_alive
	return entry
