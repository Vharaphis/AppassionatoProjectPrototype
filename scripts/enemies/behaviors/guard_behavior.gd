class_name GuardBehavior
extends EnemyBehavior

## Stands between the player and the nearest ranged ally, facing the player,
## and takes reduced damage from the front. Chases when no ranged ally is alive.

enum State { CHASE, GUARD }

@export var frontal_reduction: float = 0.7
@export var front_arc_degrees: float = 120.0
@export var guard_distance: float = 3.0
@export var reduced_hit_color: Color = Color(0.6, 0.8, 1.0, 0.8)

var state: State = State.CHASE
var _ward: Enemy

func physics_step(enemy: Enemy, _delta: float) -> Vector3:
	if not _is_alive(_ward):
		_ward = _pick_ward(enemy)
	if _ward == null or not is_instance_valid(enemy.target):
		state = State.CHASE
		return enemy.direction_to_target() * enemy.data.move_speed
	state = State.GUARD
	var ward_to_player := enemy.target.global_position - _ward.global_position
	ward_to_player.y = 0.0
	var goal := _ward.global_position + ward_to_player.normalized() * guard_distance
	var to_goal := goal - enemy.global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.3:
		return Vector3.ZERO
	return to_goal.normalized() * enemy.data.move_speed

func get_facing(enemy: Enemy) -> Vector3:
	return enemy.direction_to_target()

func modify_damage(enemy: Enemy, amount: int, source_position: Vector3) -> int:
	if source_position == Vector3.INF:
		return amount
	var to_source := source_position - enemy.global_position
	to_source.y = 0.0
	if to_source.length_squared() < 0.0001:
		return amount
	if rad_to_deg(enemy.get_forward().angle_to(to_source.normalized())) > front_arc_degrees / 2.0:
		return amount
	enemy.set_tint(reduced_hit_color)
	get_tree().create_timer(0.15).timeout.connect(enemy.clear_tint)
	return maxi(1, roundi(amount * (1.0 - frontal_reduction)))

func _pick_ward(enemy: Enemy) -> Enemy:
	var best: Enemy
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(&"ranged"):
		var ally := node as Enemy
		if not _is_alive(ally) or ally == enemy:
			continue
		var distance := ally.global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best = ally
			best_distance = distance
	return best

func _is_alive(other: Enemy) -> bool:
	return is_instance_valid(other) and not other.is_queued_for_deletion() and not other.health.is_dead
