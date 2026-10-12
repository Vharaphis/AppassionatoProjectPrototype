extends SceneTree

## Self-check of the card targeting and effects, on a bare arena (no spawner).
##   godot --headless --script res://tests/test_effects.gd
## Prints "OK" and exits 0, or stops on the first failed assert.
## Untyped and loaded at runtime: naming the game classes here would compile them
## before the RunState autoload exists.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const TRACKER := "res://scenes/enemies/tracker.tres"

var _arena: Node3D
var _ctx
var _frame := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		# Autoloads (RunState, used by enemies) are only ready once the loop runs.
		_setup()
		return false
	if _frame == 2:
		_run()
		print("OK")
		quit(0)
	return false

func _setup() -> void:
	_arena = Node3D.new()
	root.add_child(_arena)
	var player = load(PLAYER_SCENE).instantiate()
	_arena.add_child(player)
	var enemies := Node3D.new()
	_arena.add_child(enemies)
	_ctx = load("res://scripts/effects/effect_context.gd").new()
	_ctx.player = player
	_ctx.enemies_root = enemies

func _run() -> void:
	var player = _ctx.player
	player.facing = Vector3(1, 0, 0)
	var front = _enemy(Vector3(3, 0, 0))
	var behind = _enemy(Vector3(-3, 0, 0))
	var far = _enemy(Vector3(10, 0, 0))

	# Cone: only in front of the movement direction, within range.
	var cone = load("res://scripts/effects/cone_targets.gd").new()
	assert(cone.select(_ctx) == [front])
	player.facing = Vector3(-1, 0, 0)
	assert(cone.select(_ctx) == [behind])

	# Circle: everything within the radius, any direction.
	var circle = load("res://scripts/effects/circle_targets.gd").new()
	circle.radius = 4.0
	var in_circle = circle.select(_ctx)
	assert(in_circle.size() == 2 and in_circle.has(front) and in_circle.has(behind) and not in_circle.has(far))

	# Projectiles: 4 shots, only 3 enemies, the closest ones get the extra.
	var shots = load("res://scripts/effects/projectile_effect.gd").new()
	shots.count = 4
	shots.damage = 2
	shots.execute(_ctx)
	var targets := {}
	for child in _arena.get_children():
		if child.get_script() == load("res://scripts/effects/player_projectile.gd"):
			targets[child.target] = targets.get(child.target, 0) + 1
	assert(targets.get(front, 0) + targets.get(behind, 0) == 3 and targets.get(far, 0) == 1)

	# Berserk: strictly below 20 % of max HP, checked at read time.
	var berserk = load("res://scripts/effects/keywords/berserk_condition.gd").new()
	player.health.set_current_health(20)
	assert(not berserk.is_met(_ctx))
	player.health.set_current_health(19)
	assert(berserk.is_met(_ctx))
	player.health.set_current_health(100)

	# Slow: only the targets, duration scaled by the multiplier, refresh without stacking.
	var slow = load("res://scripts/effects/slow_effect.gd").new()
	slow.targets = circle
	_ctx.effect_multiplier = 2.0
	slow.execute(_ctx)
	_ctx.effect_multiplier = 1.0
	assert(front.is_slowed() and behind.is_slowed() and not far.is_slowed())
	assert(is_equal_approx(front._slow_left, 4.0))
	front.apply_slow(0.8, 1.0)
	assert(is_equal_approx(front._slow_left, 4.0) and is_equal_approx(front._slow_factor, 0.5))

	# Dash: invulnerable while dashing; no camera here, so it follows `facing`.
	var dash = load("res://scripts/effects/dash_effect.gd").new()
	dash.execute(_ctx)
	assert(player.is_dashing() and player.health.is_invulnerable())

	# Solo: only partition of its type on the track.
	var solo = load("res://scripts/effects/keywords/solo_condition.gd").new()
	var picking = _instance("res://scenes/cards/Picking.tres")
	_ctx.reader = load("res://scripts/combat/card_reader.gd").new()
	_ctx.source = picking
	_ctx.reader.sequence.append(picking)
	_ctx.reader.sequence.append(_instance("res://scenes/cards/ShieldUp.tres"))
	assert(solo.is_met(_ctx))
	_ctx.reader.sequence.append(_instance("res://scenes/cards/Shred.tres"))
	assert(not solo.is_met(_ctx))
	_ctx.reader.free()

func _instance(path: String):
	return load("res://scripts/data/card_instance.gd").new(load(path))

func _enemy(at: Vector3):
	var data = load(TRACKER)
	var enemy = data.scene.instantiate()
	enemy.data = data
	_ctx.enemies_root.add_child(enemy)
	enemy.global_position = at
	return enemy
