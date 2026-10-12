class_name SpikerBehavior
extends EnemyBehavior

## Slow melee enemy: in range, it stops, locks its facing, then thrusts a spear
## straight ahead. Sidestepping the line dodges it, running away is not needed.

enum State { CHASE, WINDUP, THRUST, RECOVER }

@export var attack_range: float = 3.5
@export var windup_time: float = 0.7
@export var thrust_duration: float = 0.2
@export var recover_time: float = 0.9
@export var thrust_damage: int = 15
@export var thrust_length: float = 4.0
@export var thrust_width: float = 1.2
## Rough radius of the player, added to the hit box.
@export var target_radius: float = 0.4

var state: State = State.CHASE
var _timer: float = 0.0
var _facing: Vector3 = Vector3.ZERO
var _has_hit: bool = false

@onready var _spear: Node3D = get_parent().get_node_or_null("Visual/Spear")
@onready var _spear_rest_z: float = _spear.position.z if _spear else 0.0

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	_timer -= delta
	match state:
		State.CHASE:
			if enemy.distance_to_target() <= attack_range:
				_facing = enemy.direction_to_target()
				_enter(State.WINDUP, windup_time)
				return Vector3.ZERO
			return enemy.direction_to_target() * enemy.data.move_speed
		State.WINDUP:
			# Spear pulls back: the telegraph. The spear mesh is 2 m long, so its center sits 1 m behind the tip.
			_set_spear_z(_spear_rest_z - 0.6 * (1.0 - _timer / windup_time))
			if _timer <= 0.0:
				_has_hit = false
				_set_spear_z(thrust_length - 1.0)
				_enter(State.THRUST, thrust_duration)
		State.THRUST:
			if not _has_hit:
				_try_hit(enemy)
			if _timer <= 0.0:
				_enter(State.RECOVER, recover_time)
		State.RECOVER:
			_set_spear_z(lerpf(_spear_rest_z, thrust_length - 1.0, maxf(_timer, 0.0) / recover_time))
			if _timer <= 0.0:
				_set_spear_z(_spear_rest_z)
				_enter(State.CHASE, 0.0)
	return Vector3.ZERO

func get_facing(_enemy: Enemy) -> Vector3:
	return Vector3.ZERO if state == State.CHASE else _facing

## Box in front of the visual, checked in its local space (+Z = forward).
func _try_hit(enemy: Enemy) -> void:
	var player := enemy.target as Player
	if player == null:
		return
	var local := enemy.visual.global_transform.affine_inverse() * player.global_position
	if local.z < 0.0 or local.z > thrust_length + target_radius:
		return
	if absf(local.x) > thrust_width / 2.0 + target_radius:
		return
	_has_hit = true
	player.health.take_damage(thrust_damage)

func _set_spear_z(z: float) -> void:
	if _spear:
		_spear.position.z = z

func _enter(new_state: State, duration: float) -> void:
	state = new_state
	_timer = duration
