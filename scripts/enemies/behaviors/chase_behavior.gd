class_name ChaseBehavior
extends EnemyBehavior

## Walks straight at the target at the enemy's move speed.

func physics_step(enemy: Enemy, _delta: float) -> Vector3:
	if not is_instance_valid(enemy.target):
		return Vector3.ZERO
	var to_target := enemy.target.global_position - enemy.global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.0001:
		return Vector3.ZERO
	return to_target.normalized() * enemy.data.move_speed
