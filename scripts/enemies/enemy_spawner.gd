extends Node3D
class_name EnemySpawner

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
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
@export var max_enemies: int = 60

@export_group("Placement")
## Enemies appear on a ring around the target, between these two distances.
@export var min_spawn_distance: float = 17.0
@export var max_spawn_distance: float = 22.0
## Enemies never spawn closer than this, even after being pushed back inside the walls.
@export var safe_distance: float = 6.0
## Distance kept from the walls.
@export var wall_margin: float = 1.0

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

## Stops spawning and freezes the enemies already spawned.
func stop() -> void:
	_timer.stop()
	for enemy in get_enemies():
		enemy.target = null

func get_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child in enemies_container.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			enemies.append(child)
	return enemies

func spawn_enemy() -> Enemy:
	if enemy_scene == null or not is_instance_valid(target):
		return null
	if get_enemies().size() >= max_enemies:
		return null
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.target = target
	enemies_container.add_child(enemy)
	enemy.global_position = _pick_spawn_position()
	enemy_spawned.emit(enemy)
	return enemy

func _on_timer_timeout() -> void:
	for i in enemies_per_spawn:
		spawn_enemy()

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
