class_name ChaseBehavior
extends EnemyBehavior

## Walks straight at the target at the enemy's move speed.

func physics_step(enemy: Enemy, _delta: float) -> Vector3:
	return enemy.direction_to_target() * enemy.data.move_speed
