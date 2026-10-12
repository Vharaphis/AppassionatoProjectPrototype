class_name ChaseBehavior
extends EnemyBehavior

## Walks at the target at the enemy's move speed. With `flank_distance` > 0 it
## aims beside the player instead, weaving from side to side, and converges as
## it gets close: a pack spreads out and surrounds instead of queueing.

## Sideways offset of the aim point, in meters. 0 = straight chase.
@export var flank_distance: float = 0.0
## Aims where the player will be in this many seconds.
@export var lead_time: float = 0.0
## Below this distance the offset fades out and the enemy goes straight in.
@export var commit_distance: float = 3.0
## Seconds per side-to-side sway.
@export var weave_period: float = 4.0

var _phase: float = randf() * TAU
var _time: float = 0.0

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	if flank_distance <= 0.0 or not is_instance_valid(enemy.target):
		return enemy.direction_to_target() * enemy.data.move_speed
	_time += delta
	var to_target := enemy.direction_to_target()
	var goal := enemy.target.global_position
	if enemy.target is CharacterBody3D:
		goal += (enemy.target as CharacterBody3D).velocity * lead_time
	var fade := clampf((enemy.distance_to_target() - commit_distance) / (flank_distance * 2.0), 0.0, 1.0)
	goal += to_target.cross(Vector3.UP) * flank_distance * fade * sin(_time * TAU / weave_period + _phase)
	var to_goal := goal - enemy.global_position
	to_goal.y = 0.0
	return to_goal.normalized() * enemy.data.move_speed if to_goal.length_squared() > 0.0001 else Vector3.ZERO
