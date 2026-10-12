extends Node3D
class_name EnemySpawner

signal enemy_spawned(enemy: Enemy)

## Enemies this spawner can pick from, weighted by round.
@export var spawn_table: SpawnTable
## Node the spawned enemies chase, also the center of the spawn ring.
@export var target: Node3D
## Where spawned enemies are added. Defaults to this node.
@export var enemies_container: Node3D
## Optional: spawn positions are kept inside this level's walls.
@export var level: Level

@export_group("Rhythm")
@export var autostart: bool = true
@export var spawn_interval: float = 1.0
@export var enemies_per_spawn: int = 1
@export var max_enemies: int = 15
## Round used by the spawn table. 0 = the run's current round (RunState).
@export var round_override: int = 0

@export_group("Placement")
## Enemies appear on a ring around the target, between these two distances.
@export var min_spawn_distance: float = 17.0
@export var max_spawn_distance: float = 22.0
## Enemies never spawn closer than this, even after being pushed back inside the walls.
@export var safe_distance: float = 6.0
## Distance kept from the walls.
@export var wall_margin: float = 1.0

@export_group("Debug")
## Prints the weight of every entry at each spawn.
@export var debug_spawn: bool = false

var _timer: Timer

func _ready() -> void:
	if enemies_container == null:
		enemies_container = self
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	if autostart:
		start()

func start() -> void:
	_timer.wait_time = spawn_interval
	_timer.start()

## Stops spawning, freezes the enemies already spawned and clears their shots.
func stop() -> void:
	_timer.stop()
	for enemy in get_enemies():
		enemy.target = null
	get_tree().call_group(Projectile.GROUP, "queue_free")

func get_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child in enemies_container.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			enemies.append(child)
	return enemies

func get_round() -> int:
	return round_override if round_override > 0 else RunState.round_index

func spawn_enemy() -> Enemy:
	if spawn_table == null or not is_instance_valid(target):
		return null
	var alive := get_enemies()
	if alive.size() >= max_enemies:
		return null
	var alive_by_id := {}
	for other in alive:
		if other.data:
			alive_by_id[other.data.id] = alive_by_id.get(other.data.id, 0) + 1
	var round_index := get_round()
	var data := spawn_table.pick(round_index, alive_by_id)
	if debug_spawn:
		_log_pick(round_index, alive_by_id, data)
	if data == null or data.scene == null:
		return null
	var enemy := data.scene.instantiate() as Enemy
	if enemy == null:
		push_error("EnemyData '%s': the scene root is not an Enemy." % data.id)
		return null
	enemy.data = data
	enemy.target = target
	# Position set before entering the tree: otherwise the enemy exists for one
	# frame at the container origin, right on top of the player.
	enemy.position = enemies_container.to_local(_pick_spawn_position())
	enemies_container.add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy

func _on_timer_timeout() -> void:
	for i in enemies_per_spawn:
		spawn_enemy()

func _log_pick(round_index: int, alive_by_id: Dictionary, picked: EnemyData) -> void:
	var weights := spawn_table.weights_at(round_index, alive_by_id)
	var parts: PackedStringArray = []
	for i in weights.size():
		var entry := spawn_table.entries[i]
		var id: StringName = entry.enemy.id if entry and entry.enemy else &"?"
		parts.append("%s=%.1f" % [id, weights[i]])
	print("[spawn] round %d  %s  -> %s" % [round_index, ", ".join(parts), picked.id if picked else &"none"])

func _pick_spawn_position() -> Vector3:
	var center := target.global_position
	var best := center
	var best_distance := -1.0
	for attempt in 10:
		var angle := randf() * TAU
		var distance := randf_range(min_spawn_distance, max_spawn_distance)
		var candidate := _clamp_to_level(center + Vector3(cos(angle), 0.0, sin(angle)) * distance)
		var candidate_distance := candidate.distance_to(center)
		if candidate_distance >= safe_distance:
			return candidate
		if candidate_distance > best_distance:
			best = candidate
			best_distance = candidate_distance
	return best

func _clamp_to_level(point: Vector3) -> Vector3:
	if level == null:
		return point
	var rect := level.get_playable_rect().grow(-wall_margin)
	point.x = clampf(point.x, rect.position.x, rect.end.x)
	point.z = clampf(point.z, rect.position.y, rect.end.y)
	return point
