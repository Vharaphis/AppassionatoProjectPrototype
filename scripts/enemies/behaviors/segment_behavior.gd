class_name SegmentBehavior
extends EnemyBehavior

## Body segment of the Sneaker chain: sits on the head's trail at a fixed
## distance. A dead segment leaves a gap, the others keep their own distance.

var head: Enemy
var leader: EncircleBehavior
## Distance behind the head along its path.
var distance: float = 1.0

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	if not is_instance_valid(head) or head.is_queued_for_deletion():
		# The chain dies with its head.
		enemy.health.take_damage(enemy.health.current_health)
		return Vector3.ZERO
	var goal := leader.trail_point(distance)
	goal.y = enemy.global_position.y
	return (goal - enemy.global_position) / delta
