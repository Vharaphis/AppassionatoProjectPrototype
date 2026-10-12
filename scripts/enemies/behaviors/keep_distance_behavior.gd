class_name KeepDistanceBehavior
extends EnemyBehavior

## Stays between `preferred_min` and `preferred_max` from the target: walks in
## when too far, backs off when too close, strafes slowly in between. Always
## faces the target. The arena walls stop it physically; hitting one flips the strafe.

@export var preferred_min: float = 9.0
@export var preferred_max: float = 14.0
## Strafe speed, as a fraction of the move speed.
@export var strafe_factor: float = 0.5

var _strafe_sign: float = 1.0

func _ready() -> void:
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0

func physics_step(enemy: Enemy, _delta: float) -> Vector3:
	var to_target := enemy.direction_to_target()
	if to_target == Vector3.ZERO:
		return Vector3.ZERO
	if enemy.is_on_wall():
		_strafe_sign = -_strafe_sign
	var distance := enemy.distance_to_target()
	var speed := enemy.data.move_speed
	if distance > preferred_max:
		return to_target * speed
	if distance < preferred_min:
		return -to_target * speed
	return to_target.cross(Vector3.UP) * _strafe_sign * speed * strafe_factor

func get_facing(enemy: Enemy) -> Vector3:
	return enemy.direction_to_target()
