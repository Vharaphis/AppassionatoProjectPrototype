class_name EncircleBehavior
extends EnemyBehavior

## Head of the Sneaker chain. Slides in to `orbit_radius_start`, then orbits the
## player while the radius shrinks to `orbit_radius_min` over `tighten_duration`.
## Records its path so the segments can follow it at a fixed distance.
## When the head dies, the whole chain dies with it.

enum State { APPROACH, ORBIT }

## Distance between two recorded trail points.
const TRAIL_STEP := 0.25

@export var segment: EnemyData
@export var segment_count: int = 14
@export var segment_spacing: float = 1.0
@export var orbit_radius_start: float = 12.0
@export var orbit_radius_min: float = 5.0
@export var tighten_duration: float = 10.0
## Linear speed along the orbit, in m/s.
@export var orbit_speed: float = 5.0
## Distance kept from the walls: near a wall the orbit squeezes toward the player.
@export var wall_margin: float = 1.0

var state: State = State.APPROACH
## Newest point first.
var trail: Array[Vector3] = []

var _started: bool = false
var _angle: float = 0.0
var _radius: float = 0.0
var _orbit_time: float = 0.0

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	if not is_instance_valid(enemy.target):
		return Vector3.ZERO
	var center := enemy.target.global_position
	if not _started:
		_start(enemy, center)
	match state:
		State.APPROACH:
			_radius = move_toward(_radius, orbit_radius_start, orbit_speed * delta)
			if _radius <= orbit_radius_start:
				state = State.ORBIT
		State.ORBIT:
			_orbit_time += delta
			_radius = lerpf(orbit_radius_start, orbit_radius_min, clampf(_orbit_time / tighten_duration, 0.0, 1.0))
	_angle += orbit_speed / maxf(_radius, 1.0) * delta
	var goal := _clamp_to_level(enemy, center + Vector3(cos(_angle), 0.0, sin(_angle)) * _radius)
	goal.y = enemy.global_position.y
	_record(enemy.global_position)
	return ((goal - enemy.global_position) / delta).limit_length(orbit_speed * 3.0)

## Point of the path `distance` meters behind the head (oldest point if the trail is shorter).
func trail_point(distance: float) -> Vector3:
	return trail[clampi(int(distance / TRAIL_STEP), 0, trail.size() - 1)]

func _start(enemy: Enemy, center: Vector3) -> void:
	_started = true
	var offset := enemy.global_position - center
	_angle = atan2(offset.z, offset.x)
	_radius = Vector2(offset.x, offset.z).length()
	trail.append(enemy.global_position)
	if segment == null or enemy.spawner == null:
		return
	for i in segment_count:
		var spawned := enemy.spawner.add_enemy(segment, enemy.global_position)
		if spawned and spawned.behavior is SegmentBehavior:
			var follower := spawned.behavior as SegmentBehavior
			follower.head = enemy
			follower.leader = self
			follower.distance = segment_spacing * (i + 1)

func _record(point: Vector3) -> void:
	if trail[0].distance_to(point) < TRAIL_STEP:
		return
	trail.push_front(point)
	var max_points := int(segment_spacing * (segment_count + 1) / TRAIL_STEP) + 2
	if trail.size() > max_points:
		trail.resize(max_points)

func _clamp_to_level(enemy: Enemy, point: Vector3) -> Vector3:
	if enemy.spawner == null or enemy.spawner.level == null:
		return point
	var rect := enemy.spawner.level.get_playable_rect().grow(-wall_margin)
	point.x = clampf(point.x, rect.position.x, rect.end.x)
	point.z = clampf(point.z, rect.position.y, rect.end.y)
	return point
